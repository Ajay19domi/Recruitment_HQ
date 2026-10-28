-- Recruitment HQ schema. Run once in Supabase SQL Editor.
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null default '',
 role text not null default 'recruiter' check(role in ('admin','manager','recruiter')),
 active boolean not null default false
);
create function public.team_role() returns text language sql stable security definer set search_path=public as $$
 select role from profiles where id=auth.uid() and active=true
$$;
create function public.new_profile() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into profiles(id,name) values(new.id,coalesce(new.raw_user_meta_data->>'name','Team member'));return new;end $$;
create trigger new_auth_user after insert on auth.users for each row execute function public.new_profile();
insert into profiles(id,name) select id,coalesce(raw_user_meta_data->>'name','Team member') from auth.users on conflict do nothing;
alter table public.profiles enable row level security;
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid() or public.team_role() in ('admin','manager'));
create policy profile_admin on public.profiles for update to authenticated using(public.team_role()='admin') with check(public.team_role()='admin');
create table public.candidates (
 id bigint primary key, name text not null check(length(trim(name))>0),role text not null,
 experience numeric not null check(experience between 0 and 60),location text not null,
 status text not null check(status in ('New','Contacted','Interview','Selected','Rejected')),
 owner text not null default 'Recruiter',assigned_to uuid references profiles(id),
 created_by uuid not null default auth.uid() references profiles(id),
 email text not null default '',phone text not null default '',notes text not null default '',
 created date not null default current_date
);
alter table public.candidates enable row level security;
create policy candidate_read on public.candidates for select to authenticated using(public.team_role() in ('admin','manager') or (public.team_role()='recruiter' and assigned_to=auth.uid()));
create policy candidate_insert on public.candidates for insert to authenticated with check(public.team_role() in ('admin','manager','recruiter') and created_by=auth.uid() and (public.team_role() in ('admin','manager') or assigned_to=auth.uid()));
create policy candidate_update on public.candidates for update to authenticated using(public.team_role() in ('admin','manager') or (public.team_role()='recruiter' and assigned_to=auth.uid())) with check(public.team_role() in ('admin','manager') or (public.team_role()='recruiter' and assigned_to=auth.uid()));
create policy candidate_delete on public.candidates for delete to authenticated using(public.team_role()='admin');
create function public.guard_candidate() returns trigger language plpgsql set search_path=public as $$ begin
 if new.created_by<>old.created_by or new.created<>old.created then raise exception 'Creation metadata cannot be changed';end if;
 if public.team_role()='recruiter' and (new.assigned_to is distinct from old.assigned_to or new.owner<>old.owner) then raise exception 'Only managers can reassign candidates';end if;return new;end $$;
create trigger candidate_guard before update on public.candidates for each row execute function public.guard_candidate();
create table public.interviews(id bigint primary key,candidate bigint not null references candidates(id) on delete cascade,date date not null,time time not null,mode text not null);
alter table public.interviews enable row level security;
create policy interview_read on public.interviews for select to authenticated using(exists(select 1 from candidates where candidates.id=interviews.candidate));
create policy interview_insert on public.interviews for insert to authenticated with check(public.team_role() is not null and exists(select 1 from candidates where candidates.id=interviews.candidate));
create policy interview_update on public.interviews for update to authenticated using(public.team_role() is not null and exists(select 1 from candidates where candidates.id=interviews.candidate)) with check(public.team_role() is not null and exists(select 1 from candidates where candidates.id=interviews.candidate));
create policy interview_delete on public.interviews for delete to authenticated using(public.team_role()='admin');
create table public.activity(id bigint generated always as identity primary key,text text not null,date timestamptz not null default now(),actor uuid references profiles(id) default auth.uid());
alter table public.activity enable row level security;
create policy activity_read on public.activity for select to authenticated using(public.team_role() in ('admin','manager') or (public.team_role()='recruiter' and actor=auth.uid()));
create function public.audit_candidate() returns trigger language plpgsql security definer set search_path=public as $$ begin
 insert into activity(text,actor) values (case when TG_OP='DELETE' then 'Deleted candidate: '||old.name else TG_OP||' candidate: '||new.name end,auth.uid());return null;end $$;
create trigger candidate_audit after insert or update or delete on public.candidates for each row execute function public.audit_candidate();
grant select,update on profiles to authenticated;
grant select,insert,update,delete on candidates,interviews to authenticated;
grant select on activity to authenticated;
revoke all on profiles,candidates,interviews,activity from anon;
-- AFTER creating your Auth user, replace YOUR_EMAIL below and run these separately:
-- update public.profiles set role='admin',active=true,name='Ajay Prakashan'
-- where id=(select id from auth.users where email='YOUR_EMAIL');
-- Atomic workspace mutations; all statements use caller RLS permissions.
create function public.save_changes(payload jsonb) returns void language plpgsql security invoker set search_path=public as $$
declare c jsonb;i jsonb;d jsonb;begin
 for d in select * from jsonb_array_elements(coalesce(payload->'deleted','[]')) loop
  delete from candidates where id=(d#>>'{}')::bigint;
  if not found then raise exception 'Deletion denied';end if;
 end loop;
 for c in select * from jsonb_array_elements(coalesce(payload->'candidates','[]')) loop
 insert into candidates(id,name,role,experience,location,status,owner,assigned_to,email,phone,notes,created)
 values((c->>'id')::bigint,c->>'name',c->>'role',(c->>'experience')::numeric,c->>'location',c->>'status',c->>'owner',(c->>'assigned_to')::uuid,coalesce(c->>'email',''),coalesce(c->>'phone',''),coalesce(c->>'notes',''),coalesce((c->>'created')::date,current_date))
 on conflict(id) do update set name=excluded.name,role=excluded.role,experience=excluded.experience,location=excluded.location,status=excluded.status,owner=excluded.owner,assigned_to=excluded.assigned_to,email=excluded.email,phone=excluded.phone,notes=excluded.notes;
 end loop;
 for i in select * from jsonb_array_elements(coalesce(payload->'interviews','[]')) loop
 insert into interviews(id,candidate,date,time,mode) values((i->>'id')::bigint,(i->>'candidate')::bigint,(i->>'date')::date,(i->>'time')::time,i->>'mode')
 on conflict(id) do update set candidate=excluded.candidate,date=excluded.date,time=excluded.time,mode=excluded.mode;
 end loop;end $$;
revoke all on function public.save_changes(jsonb) from public,anon;
grant execute on function public.save_changes(jsonb) to authenticated;
