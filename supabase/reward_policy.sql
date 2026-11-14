-- Reward policy v3. The guard applies to direct updates and all snapshot RPCs.
create or replace function private.pat_reward_bucket(s jsonb,e jsonb) returns text language sql immutable set search_path='' as $$
 select case when coalesce((s->'weeks'->(e->>'week')->'targets'->>(e->>'activity'))::int,(s->'targets'->>(e->>'activity'))::int,0)>0 then e->>'activity'
 when e->>'activity'='words' and coalesce((s->'weeks'->(e->>'week')->'targets'->>'speech')::int,(s->'targets'->>'speech')::int,0)>0 then 'speech'
 when coalesce((s->'weeks'->(e->>'week')->'targets'->>(e->>'discipline'))::int,(s->'targets'->>(e->>'discipline'))::int,0)>0 then e->>'discipline' end
$$;
create or replace function private.pat_reward_completion(s jsonb,k text) returns text language plpgsql immutable set search_path='' as $$
declare t record; n int; finished text; latest text; any_target boolean:=false;
begin
 for t in select key,value from jsonb_each_text(coalesce(s->'weeks'->k->'targets',s->'targets','{}')) loop
  if t.value is null or t.value::int<=0 then continue; end if; any_target:=true;
  select count(*),max(q.tm) into n,finished from (select e->>'time' tm from jsonb_array_elements(s->'entries') e where e->>'week'=k and private.pat_reward_bucket(s,e)=t.key and e->>'status'='approved' and e->>'outcome'='finished' and e->>'bonusWeek' is null and e->>'routine' is null and e->>'coinRemoved' is null and (e->>'rewardVersion' is null or e->>'workConfirmed'='true') order by e->>'time',e->>'id' limit t.value::int) q;
  if n<t.value::int then return null; end if;
  latest:=greatest(latest,finished);
 end loop;
 return case when any_target then latest else null end;
end $$;
create or replace function private.pat_reward_guard() returns trigger language plpgsql security invoker set search_path='' as $$
declare role_name text; e jsonb; prior jsonb; t record; k text; target jsonb; done text; assignment jsonb;
begin
 if auth.uid() is null then return new; end if;
 select access_role into role_name from public.participant_access where participant_id=new.participant_id and user_id=auth.uid() and can_write;
 if role_name is null then raise exception 'Participant write permission required' using errcode='42501'; end if;
 if new.snapshot is null then return new; end if;
 if role_name<>'clinician' then
  if new.configuration is distinct from old.configuration then raise exception 'Only the clinician can change the base configuration' using errcode='42501'; end if;
  if new.snapshot->'targets' is distinct from coalesce(old.snapshot->'targets',old.configuration->'targets') or new.snapshot->'assignments' is distinct from coalesce(old.snapshot->'assignments',old.configuration->'assignments','[]') or new.snapshot->'practice'->'minutes' is distinct from coalesce(old.snapshot->'practice'->'minutes',old.configuration->'practice'->'minutes') then raise exception 'Only the clinician can change agreed tasks, duration or coin limits' using errcode='42501'; end if;
  for t in select key,value from jsonb_each(coalesce(new.snapshot->'weeks','{}')) loop
   target:=coalesce(old.snapshot->'weeks'->t.key->'targets',old.snapshot->'targets',old.configuration->'targets');
   if t.value->'targets' is distinct from target then raise exception 'Only the clinician can change weekly targets' using errcode='42501'; end if;
  end loop;
 end if;
 -- Duplicate IDs or session claims cannot create repeated rewards.
 if exists(select 1 from jsonb_array_elements(new.snapshot->'entries') x group by x->>'id' having count(*)>1) or exists(select 1 from jsonb_array_elements(new.snapshot->'entries') x where x->>'outcome'='finished' and x->>'status' in ('pending','approved') group by coalesce(x->>'sessionKey',x->>'id') having count(*)>1) then raise exception 'This session is already recorded'; end if;
 for e in select value from jsonb_array_elements(new.snapshot->'entries') loop
  select value into prior from jsonb_array_elements(coalesce(old.snapshot->'entries','[]')) where value->>'id'=e->>'id';
  if e->>'rewardVersion'='3' and (coalesce(e->>'coins','0') not in ('0','1') or (e->>'status'<>'approved' and coalesce(e->>'coins','0')<>'0')) then raise exception 'Invalid coin award'; end if;
  if e is not distinct from prior then continue; end if;
  if prior is not null and role_name='tablet' and prior->>'status'='approved' and e is distinct from prior then raise exception 'A parent must change approved records' using errcode='42501'; end if;
  if prior is null and e->>'rewardVersion' is distinct from '3' then raise exception 'Please reopen the updated PAT app before recording work'; end if;
  if e->>'outcome'='finished' and e->>'status'='approved' then
   if role_name not in ('parent','clinician') then raise exception 'Dad must sign in with his parent account to approve work' using errcode='42501'; end if;
   if e->>'bonusWeek' is not null then
    k:=e->>'week';done:=private.pat_reward_completion(new.snapshot,k);
    if done is null then raise exception 'All agreed tasks must be completed before a bonus'; end if;
    if exists(select 1 from jsonb_array_elements(new.snapshot->'entries') x where x->>'id'<>e->>'id' and x->>'bonusWeek'=k and coalesce(x->>'bonusType','completion')=coalesce(e->>'bonusType','completion') and x->>'status' in ('pending','approved')) then raise exception 'Only one of each weekly bonus is allowed'; end if;
    if e->>'bonusType'='extra' then
     if (now() at time zone 'Australia/Perth')::date < k::date+6 then raise exception 'Extra work bonus becomes available on Sunday'; end if;
     if not exists(select 1 from jsonb_array_elements(new.snapshot->'entries') x where x->>'week'=k and x->>'status'='approved' and x->>'outcome'='finished' and x->>'workConfirmed'='true' and x->>'rewardVersion'='3' and x->>'bonusWeek' is null and x->>'routine' is null and x->>'coinRemoved' is null and private.pat_reward_bucket(new.snapshot,x) is not null and coalesce(nullif(x->>'started',''),x->>'time')>done) then raise exception 'A separate completed extra session after the agreed work is required'; end if;
    elsif coalesce(e->>'bonusType','completion')<>'completion' then raise exception 'Unknown bonus type'; end if;
   else
    if e->>'workConfirmed' is distinct from 'true' then raise exception 'Parent must confirm the actual work'; end if;
    select value into assignment from jsonb_array_elements(coalesce(new.snapshot->'assignments','[]')) where value->>'id'=e->>'activity';
    if e->>'activity'='speech' and e->>'storyCompleted' is distinct from 'true' then raise exception 'Confirm one complete Speech story'; end if;
    if e->>'routine' is null and e->>'activity'<>'speech' and (coalesce((e->>'engagementMinutes')::numeric,0)<=0 or (assignment is null and coalesce((e->>'engagementMinutes')::numeric,0)<10)) then raise exception 'Record actual practice time; standard practice requires at least ten minutes'; end if;
   end if;
  end if;
 end loop;
 -- Tablet cannot delete approved history and re-submit it as new work.
 if role_name='tablet' and exists(select 1 from jsonb_array_elements(coalesce(old.snapshot->'entries','[]')) x where x->>'status'='approved' and not exists(select 1 from jsonb_array_elements(new.snapshot->'entries') y where y->>'id'=x->>'id')) then raise exception 'A parent must change approved history' using errcode='42501'; end if;
 for t in select x->>'week' wk,private.pat_reward_bucket(new.snapshot,x) bucket,sum((x->>'coins')::int) coins from jsonb_array_elements(new.snapshot->'entries') x where x->>'rewardVersion'='3' and x->>'bonusWeek' is null and x->>'routine' is null group by 1,2 loop
  target:=coalesce(new.snapshot->'weeks'->t.wk->'targets',new.snapshot->'targets');
  if t.coins>coalesce((target->>t.bucket)::int,0) then raise exception 'Weekly activity coin limit reached'; end if;
 end loop;
 return new;
end $$;
revoke all on function private.pat_reward_bucket(jsonb,jsonb),private.pat_reward_completion(jsonb,text),private.pat_reward_guard() from public,anon;
grant execute on function private.pat_reward_bucket(jsonb,jsonb),private.pat_reward_completion(jsonb,text),private.pat_reward_guard() to authenticated;
drop trigger if exists pat_reward_guard on public.pat_hubs;
create trigger pat_reward_guard before update on public.pat_hubs for each row execute function private.pat_reward_guard();
