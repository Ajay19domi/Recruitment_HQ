-- Recruitment HQ: vacancy management. Run once after setup.sql.
begin;
create table public.vacancies (
 id uuid primary key default gen_random_uuid(),
 title text not null check(length(trim(title)) between 1 and 120),
 location text not null default 'Dubai, UAE',
 employment text not null default 'Full time',
 salary_min numeric check(salary_min>=0),
 salary_max numeric check(salary_max>=0),
 currency text not null default 'AED' check(currency in ('AED','INR','USD')),
 experience_min numeric check(experience_min between 0 and 60),
 experience_max numeric check(experience_max between 0 and 60),
 benefits text not null default '',requirements text not null default '',
 status text not null default 'Open' check(status in ('Open','On hold','Closed')),
 created_by uuid default auth.uid() references public.profiles(id),
 created_at timestamptz not null default now(),
 check(salary_min is null or salary_max is null or salary_max>=salary_min),
 check(experience_min is null or experience_max is null or experience_max>=experience_min)
);
alter table public.vacancies enable row level security;
create policy vacancy_read on public.vacancies for select to authenticated using(public.team_role() is not null);
create policy vacancy_insert on public.vacancies for insert to authenticated with check(public.team_role() in ('admin','manager') and created_by=auth.uid());
create policy vacancy_update on public.vacancies for update to authenticated using(public.team_role() in ('admin','manager')) with check(public.team_role() in ('admin','manager'));
create policy vacancy_delete on public.vacancies for delete to authenticated using(public.team_role()='admin');
grant select,insert,update,delete on public.vacancies to authenticated;
revoke all on public.vacancies from anon;
-- Initial confirmed vacancies. Update employer requirements when received.
insert into public.vacancies(title,location,salary_min,salary_max,experience_min,experience_max,benefits,requirements) values
 ('CCR Operator','UAE',2000,3000,6,8,'Accommodation and food provided.','Dry mortar / mix plant experience; PLC operations, batching systems and production monitoring.'),
 ('MEP Supervisor','Dubai, UAE',4000,4500,null,null,'','Employer requirements to be confirmed.'),
 ('Senior Draftsman','Dubai, UAE',null,null,null,null,'','Salary and employer requirements to be confirmed.');
create function public.audit_vacancy() returns trigger language plpgsql security definer set search_path=public as $$begin
 insert into public.activity(text,actor) values(case when TG_OP='DELETE' then 'Deleted vacancy: '||old.title else TG_OP||' vacancy: '||new.title end,auth.uid());return null;end $$;
create trigger vacancy_audit after insert or update or delete on public.vacancies for each row execute function public.audit_vacancy();

alter table public.candidates add column vacancy_id uuid references public.vacancies(id) on delete set null;
update public.candidates c set vacancy_id=v.id from public.vacancies v where c.role=v.title;
create or replace function public.save_changes(payload jsonb) returns void language plpgsql security invoker set search_path=public as $$
declare c jsonb;i jsonb;d jsonb;begin
 for d in select * from jsonb_array_elements(coalesce(payload->'deleted','[]')) loop
  delete from candidates where id=(d#>>'{}')::bigint;
  if not found then raise exception 'Deletion denied';end if;
 end loop;
 for c in select * from jsonb_array_elements(coalesce(payload->'candidates','[]')) loop
 insert into candidates(id,name,role,experience,location,status,owner,assigned_to,email,phone,notes,created,vacancy_id)
 values((c->>'id')::bigint,c->>'name',c->>'role',(c->>'experience')::numeric,c->>'location',c->>'status',c->>'owner',(c->>'assigned_to')::uuid,coalesce(c->>'email',''),coalesce(c->>'phone',''),coalesce(c->>'notes',''),coalesce((c->>'created')::date,current_date),(c->>'vacancy_id')::uuid)
 on conflict(id) do update set name=excluded.name,role=excluded.role,experience=excluded.experience,location=excluded.location,status=excluded.status,owner=excluded.owner,assigned_to=excluded.assigned_to,email=excluded.email,phone=excluded.phone,notes=excluded.notes,vacancy_id=excluded.vacancy_id;
 end loop;
 for i in select * from jsonb_array_elements(coalesce(payload->'interviews','[]')) loop
 insert into interviews(id,candidate,date,time,mode) values((i->>'id')::bigint,(i->>'candidate')::bigint,(i->>'date')::date,(i->>'time')::time,i->>'mode')
 on conflict(id) do update set candidate=excluded.candidate,date=excluded.date,time=excluded.time,mode=excluded.mode;
 end loop;end $$;

commit;
