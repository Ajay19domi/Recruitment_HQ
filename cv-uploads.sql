-- Recruitment HQ: private CV files. Run once after setup.sql.
begin;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('candidate-cvs','candidate-cvs',false,10485760,array['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict(id) do update set public=false,file_size_limit=10485760,allowed_mime_types=excluded.allowed_mime_types;
create table public.candidate_cvs (
 id uuid primary key default gen_random_uuid(),
 candidate_id bigint not null references public.candidates(id) on delete cascade,
 path text unique not null,
 filename text not null check(length(filename) between 1 and 255),
 mime text not null check(mime in ('application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document')),
 size bigint not null check(size between 1 and 10485760),
 uploaded_by uuid not null default auth.uid() references public.profiles(id),
 created_at timestamptz not null default now(),
 check(split_part(path,'/',1)=candidate_id::text)
);
alter table public.candidate_cvs enable row level security;
create policy cv_read on public.candidate_cvs for select to authenticated using(public.team_role() is not null and exists(select 1 from public.candidates c where c.id=candidate_id));
create policy cv_add on public.candidate_cvs for insert to authenticated with check(public.team_role() is not null and uploaded_by=auth.uid() and exists(select 1 from public.candidates c where c.id=candidate_id));
create policy cv_delete on public.candidate_cvs for delete to authenticated using(public.team_role()='admin');
grant select,insert,delete on public.candidate_cvs to authenticated;
revoke all on public.candidate_cvs from anon;
create policy cv_object_read on storage.objects for select to authenticated using(bucket_id='candidate-cvs' and public.team_role() is not null and exists(select 1 from public.candidates c where c.id::text=(storage.foldername(storage.objects.name))[1]));
create policy cv_object_add on storage.objects for insert to authenticated with check(bucket_id='candidate-cvs' and public.team_role() is not null and exists(select 1 from public.candidates c where c.id::text=(storage.foldername(storage.objects.name))[1]));
-- Check metadata independent of caller visibility, so reassignment cannot allow deletion.
create function public.cv_file_linked(object_path text) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.candidate_cvs where path=object_path)
$$;
revoke all on function public.cv_file_linked(text) from public,anon;
grant execute on function public.cv_file_linked(text) to authenticated;
-- Only admins delete linked files; uploaders may clean up a failed unlinked upload.
create policy cv_object_delete on storage.objects for delete to authenticated using(bucket_id='candidate-cvs' and (public.team_role()='admin' or (public.team_role() is not null and owner_id=auth.uid()::text and not public.cv_file_linked(name))));
create function public.audit_cv() returns trigger language plpgsql security definer set search_path=public as $$begin
 insert into public.activity(text,actor) values(case when TG_OP='DELETE' then 'Deleted CV: '||old.filename else 'Uploaded CV: '||new.filename end,auth.uid());return null;end $$;
create trigger cv_audit after insert or delete on public.candidate_cvs for each row execute function public.audit_cv();
commit;
