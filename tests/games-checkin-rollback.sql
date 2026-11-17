-- Role and results-mapping check. Run this whole file: it begins a transaction and rolls it back.
-- Apply supabase/family_games_and_checkins.sql first. Do not commit. Do not run against Track.
-- Uses example.invalid addresses and no participant names.
begin;
do $$
declare
 parent_uid uuid:=gen_random_uuid();
 clinician_uid uuid:=gen_random_uuid();
 tablet_uid uuid:=gen_random_uuid();
 school_uid uuid:=gen_random_uuid();
 other_uid uuid:=gen_random_uuid();
 pid uuid:=gen_random_uuid();
 other_pid uuid:=gen_random_uuid();
 result jsonb;
 affected integer;
 snapshot jsonb;
 cfg jsonb:='{"targets":{"all-aboard":14},"assignments":[{"id":"all-aboard","title":"All Aboard!","discipline":"speech","finish":"Finish one All Aboard round (one burst)."}],"practice":{"minutes":15}}'::jsonb;
 entry jsonb;
begin
 insert into auth.users(id,email,email_confirmed_at,aud,role) values
  (parent_uid,'checkin-parent@example.invalid',now(),'authenticated','authenticated'),
  (clinician_uid,'checkin-clinician@example.invalid',now(),'authenticated','authenticated'),
  (tablet_uid,'checkin-tablet@example.invalid',now(),'authenticated','authenticated'),
  (school_uid,'checkin-school@example.invalid',now(),'authenticated','authenticated'),
  (other_uid,'checkin-other@example.invalid',now(),'authenticated','authenticated');
 insert into public.participants(id,display_name) values(pid,'RLS check'),(other_pid,'RLS other');
 insert into public.pat_hubs(participant_id,configuration,snapshot,audio) values(pid,cfg,null,'{}'),(other_pid,cfg,null,'{}');
 insert into public.participant_access(participant_id,user_id,access_role,can_view,can_write) values
  (pid,parent_uid,'parent',true,true),
  (pid,clinician_uid,'clinician',true,true),
  (pid,tablet_uid,'tablet',true,true),
  (pid,school_uid,'school',true,true),
  (other_pid,other_uid,'parent',true,true);

 perform set_config('request.jwt.claims',jsonb_build_object('sub',parent_uid,'role','authenticated')::text,true);
 perform set_config('role','authenticated',true);
 insert into public.pat_parent_checkins(participant_id,week_start,practice_done,bursts_per_day,clarity,repair_noticed,repair_strategy,problems,message_to_clinician)
  values(pid,'2026-11-16',true,2,'mostly',true,'Show or point','None','Hello');
 update public.pat_parent_checkins set bursts_per_day=1,clarity='clear',repair_strategy='Say the key word' where participant_id=pid and week_start='2026-11-16';
 if not exists(select 1 from public.pat_parent_checkins where participant_id=pid and bursts_per_day=1 and repair_strategy='Say the key word' and updated_by=parent_uid) then
  raise exception 'Parent check-in was not saved';
 end if;
 begin
  insert into public.pat_parent_checkins(participant_id,week_start,practice_done,bursts_per_day,clarity,repair_noticed)
   values(other_pid,'2026-11-16',true,2,'clear',false);
  raise exception 'Parent wrote another child check-in';
 exception when insufficient_privilege then null;
 end;
 begin
  insert into public.pat_assigned_games(participant_id,catalogue_id,config) values(pid,'all-aboard','{}'::jsonb);
  raise exception 'Parent changed a game assignment';
 exception when insufficient_privilege then null;
 end;

 perform set_config('request.jwt.claims',jsonb_build_object('sub',clinician_uid,'role','authenticated')::text,true);
 if not exists(select 1 from public.pat_parent_checkins where participant_id=pid and message_to_clinician='Hello') then
  raise exception 'Clinician could not read the check-in';
 end if;
 update public.pat_parent_checkins set problems='changed' where participant_id=pid;
 get diagnostics affected=row_count;
 if affected<>0 then raise exception 'Clinician changed a parent check-in'; end if;
 begin
  insert into public.pat_parent_checkins(participant_id,week_start,practice_done,bursts_per_day,clarity,repair_noticed)
   values(pid,'2026-11-09',false,0,'hard',false);
  raise exception 'Clinician inserted a check-in';
 exception when insufficient_privilege then null;
 end;
 insert into public.pat_assigned_games(participant_id,catalogue_id,enabled,bursts_per_day,config)
  values(pid,'all-aboard',true,2,'{"title":"All Aboard!"}'::jsonb);
 if not exists(select 1 from public.pat_assigned_games where participant_id=pid and catalogue_id='all-aboard' and updated_by=clinician_uid) then
  raise exception 'Clinician could not assign the game';
 end if;

 perform set_config('request.jwt.claims',jsonb_build_object('sub',parent_uid,'role','authenticated')::text,true);
 if not exists(select 1 from public.pat_assigned_games where participant_id=pid and catalogue_id='all-aboard') then
  raise exception 'Parent could not read the assigned game';
 end if;

 perform set_config('request.jwt.claims',jsonb_build_object('sub',tablet_uid,'role','authenticated')::text,true);
 if not exists(select 1 from public.pat_assigned_games where participant_id=pid) then raise exception 'Tablet could not read the assigned game'; end if;
 if exists(select 1 from public.pat_parent_checkins where participant_id=pid) then raise exception 'Tablet read the parent check-in'; end if;
 begin
  insert into public.pat_parent_checkins(participant_id,week_start,practice_done,bursts_per_day,clarity,repair_noticed)
   values(pid,'2026-11-09',true,2,'clear',false);
  raise exception 'Tablet wrote a check-in';
 exception when insufficient_privilege then null;
 end;
 update public.pat_assigned_games set bursts_per_day=9 where participant_id=pid;
 get diagnostics affected=row_count;
 if affected<>0 then raise exception 'Tablet changed the assigned game'; end if;

 perform set_config('request.jwt.claims',jsonb_build_object('sub',school_uid,'role','authenticated')::text,true);
 if exists(select 1 from public.pat_assigned_games where participant_id=pid) then raise exception 'School read the game config'; end if;
 if exists(select 1 from public.pat_parent_checkins where participant_id=pid) then raise exception 'School read the check-in'; end if;

 perform set_config('request.jwt.claims',jsonb_build_object('sub',other_uid,'role','authenticated')::text,true);
 if exists(select 1 from public.pat_parent_checkins where participant_id=pid) then raise exception 'Another parent read the check-in'; end if;
 if exists(select 1 from public.pat_assigned_games where participant_id=pid) then raise exception 'Another parent read the game'; end if;

 perform set_config('request.jwt.claims',jsonb_build_object('sub',parent_uid,'role','authenticated')::text,true);
 entry:=jsonb_build_object(
  'id','all-aboard:2026-11-16T01:00:00.000Z:2026-11-16T01:04:00.000Z',
  'sessionKey','all-aboard:2026-11-16T01:00:00.000Z:2026-11-16T01:04:00.000Z',
  'activity','all-aboard','discipline','speech','title','All Aboard!',
  'week','2026-11-16','date','2026-11-16','time','2026-11-16T01:04:00.000Z','started','2026-11-16T01:00:00.000Z',
  'outcome','finished','status','pending','rewardVersion','3','coins',0,'routine',null,'bonusWeek',null,
  'gameResult',jsonb_build_object(
    'level','1','durationMs',240000,
    'attempts',jsonb_build_array(jsonb_build_object('intendedText','spell','heardText','bell','correct',false)),
    'words',jsonb_build_array(jsonb_build_object('text','spell','correct',0,'incorrect',1)),
    'repairs',jsonb_build_array(jsonb_build_object('strategyLabel','Say the key word','success',true))
  )
 );
 snapshot:=jsonb_build_object('version','4','entries',jsonb_build_array(entry),'targets',cfg->'targets','assignments',cfg->'assignments','practice',cfg->'practice');
 result:=public.pat_save_snapshot(pid,0,snapshot,'{}');
 if result->>'conflict'<>'false' then raise exception 'Game result snapshot was not saved'; end if;
 if not exists(select 1 from public.pat_activity_records where participant_id=pid and record_id=entry->>'id' and activity_id='all-aboard' and outcome='finished' and approval_status='pending' and payload->'gameResult'->>'level'='1' and (payload->'gameResult'->>'durationMs')='240000' and payload->'gameResult'->'words'->0->>'text'='spell' and (payload->'gameResult'->'words'->0->>'incorrect')='1' and payload->'gameResult'->'repairs'->0->>'strategyLabel'='Say the key word') then
  raise exception 'Game result was not mapped into an activity record';
 end if;
 entry:=entry||jsonb_build_object('status','approved','workConfirmed',true,'engagementMinutes',4,'coins',1);
 snapshot:=jsonb_set(snapshot,'{entries}',jsonb_build_array(entry));
 result:=public.pat_save_snapshot(pid,1,snapshot,'{}');
 if result->>'conflict'<>'false' then raise exception 'Parent approval of the game burst was rejected'; end if;
 if not exists(select 1 from public.pat_activity_records where participant_id=pid and record_id=entry->>'id' and approval_status='approved' and observed_engagement_minutes=4 and (payload->>'coins')='1') then
  raise exception 'Approved game burst did not stay on the activity record';
 end if;

 perform set_config('request.jwt.claims',jsonb_build_object('sub',gen_random_uuid(),'role','authenticated')::text,true);
 if exists(select 1 from public.pat_parent_checkins where participant_id=pid) then raise exception 'Unrelated account read a check-in'; end if;
 if exists(select 1 from public.pat_assigned_games where participant_id=pid) then raise exception 'Unrelated account read a game'; end if;
end $$;
rollback;
