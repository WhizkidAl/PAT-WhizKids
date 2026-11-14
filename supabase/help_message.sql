alter table private.pat_help_requests add column if not exists message text not null default '' check(length(message)<=500);
create or replace function public.pat_prepare_help_message(p_user_id uuid,p_participant_id uuid,p_request_id uuid,p_kind text,p_activity text,p_message text default '') returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb; previous private.pat_help_requests;
begin
 if p_message is null or length(p_message)>500 then raise exception 'Message must be at most 500 characters'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_participant_id::text,0));
 select * into previous from private.pat_help_requests where id=p_request_id;
 if found and previous.message is distinct from p_message then raise exception 'Request identity mismatch' using errcode='42501'; end if;
 result:=public.pat_prepare_help(p_user_id,p_participant_id,p_request_id,p_kind,p_activity);
 if result->>'rate_limited'='true' then return result; end if;
 update private.pat_help_requests set message=p_message where id=p_request_id;
 return result||jsonb_build_object('message',p_message);
end $$;
revoke all on function public.pat_prepare_help_message(uuid,uuid,uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.pat_prepare_help_message(uuid,uuid,uuid,text,text,text) to service_role;
