-- Assigned Therapy-Games and the weekly parent check-in.
-- Apply on the PAT project only, after pat_foundation.sql, portable_practice_schema.sql,
-- tablet_access.sql, help_and_pin.sql and reward_policy.sql.
-- Do not apply this file to the Track project. Parents must not gain a write path there.
-- This file does not create accounts, send invitations, or change coin rules.
-- Coin caps stay on the existing hub snapshot targets. A game result becomes an ordinary
-- activity entry; pat_hub_audit copies it into pat_activity_records for parent approval.

create table public.pat_assigned_games (
 participant_id uuid not null references public.participants(id),
 catalogue_id text not null check(catalogue_id ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(catalogue_id) between 1 and 64),
 enabled boolean not null default true,
 bursts_per_day integer check(bursts_per_day is null or bursts_per_day between 0 and 20),
 config jsonb not null default '{}'::jsonb check(jsonb_typeof(config)='object' and octet_length(config::text)<=100000),
 updated_at timestamptz not null default now(),
 updated_by uuid references auth.users(id),
 primary key(participant_id, catalogue_id)
);
create table public.pat_parent_checkins (
 participant_id uuid not null references public.participants(id),
 week_start date not null check(extract(isodow from week_start)=1),
 practice_done boolean not null,
 bursts_per_day integer not null check(bursts_per_day between 0 and 20),
 clarity text not null check(clarity in ('hard','sometimes','mostly','clear')),
 repair_noticed boolean not null,
 repair_strategy text not null default '' check(repair_strategy in ('','Say the key word','Show or point','Tell it another way','Not sure') and (repair_noticed or repair_strategy='')),
 problems text not null default '' check(char_length(problems)<=1000),
 message_to_clinician text not null default '' check(char_length(message_to_clinician)<=1000),
 updated_at timestamptz not null default now(),
 updated_by uuid references auth.users(id),
 primary key(participant_id, week_start)
);
alter table public.pat_assigned_games enable row level security;
alter table public.pat_parent_checkins enable row level security;
revoke all on public.pat_assigned_games, public.pat_parent_checkins from public, anon, authenticated;
grant select, insert, update on public.pat_assigned_games to authenticated;
grant select, insert, update on public.pat_parent_checkins to authenticated;

-- The child tablet, a parent and the clinician can read the private game config.
-- Only the clinician can change it. Word lists are clinical settings, like coin targets.
create policy pat_game_read on public.pat_assigned_games for select to authenticated using (
 exists(select 1 from public.participant_access a where a.participant_id=pat_assigned_games.participant_id and a.user_id=(select auth.uid()) and a.can_view and a.access_role in ('parent','clinician','tablet'))
);
create policy pat_game_insert on public.pat_assigned_games for insert to authenticated with check (
 exists(select 1 from public.participant_access a where a.participant_id=pat_assigned_games.participant_id and a.user_id=(select auth.uid()) and a.can_view and a.can_write and a.access_role='clinician')
);
create policy pat_game_update on public.pat_assigned_games for update to authenticated using (
 exists(select 1 from public.participant_access a where a.participant_id=pat_assigned_games.participant_id and a.user_id=(select auth.uid()) and a.can_view and a.can_write and a.access_role='clinician')
) with check (
 exists(select 1 from public.participant_access a where a.participant_id=pat_assigned_games.participant_id and a.user_id=(select auth.uid()) and a.can_view and a.can_write and a.access_role='clinician')
);

-- A parent writes the check-in only for a child they are assigned to.
-- The clinician can read it. The tablet, school and other roles cannot.
create policy pat_checkin_read on public.pat_parent_checkins for select to authenticated using (
 exists(select 1 from public.participant_access a where a.participant_id=pat_parent_checkins.participant_id and a.user_id=(select auth.uid()) and a.can_view and a.access_role in ('parent','clinician'))
);
create policy pat_checkin_insert on public.pat_parent_checkins for insert to authenticated with check (
 exists(select 1 from public.participant_access a where a.participant_id=pat_parent_checkins.participant_id and a.user_id=(select auth.uid()) and a.can_view and a.can_write and a.access_role='parent')
);
create policy pat_checkin_update on public.pat_parent_checkins for update to authenticated using (
 exists(select 1 from public.participant_access a where a.participant_id=pat_parent_checkins.participant_id and a.user_id=(select auth.uid()) and a.can_view and a.can_write and a.access_role='parent')
) with check (
 exists(select 1 from public.participant_access a where a.participant_id=pat_parent_checkins.participant_id and a.user_id=(select auth.uid()) and a.can_view and a.can_write and a.access_role='parent')
);

create function private.pat_stamp_actor() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 new.updated_at=now();
 new.updated_by=auth.uid();
 return new;
end $$;
revoke all on function private.pat_stamp_actor() from public, anon, authenticated;
create trigger pat_assigned_game_actor before insert or update on public.pat_assigned_games for each row execute function private.pat_stamp_actor();
create trigger pat_checkin_actor before insert or update on public.pat_parent_checkins for each row execute function private.pat_stamp_actor();
