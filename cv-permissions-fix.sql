-- Fix storage path lookup without changing candidate visibility.
begin;
drop policy if exists cv_object_read on storage.objects;
drop policy if exists cv_object_add on storage.objects;
create policy cv_object_read on storage.objects for select to authenticated
using (
 storage.objects.bucket_id='candidate-cvs'
 and public.team_role() is not null
 and exists (
  select 1 from public.candidates c
  where c.id::text=(storage.foldername(storage.objects.name))[1]
 )
);
create policy cv_object_add on storage.objects for insert to authenticated
with check (
 storage.objects.bucket_id='candidate-cvs'
 and public.team_role() is not null
 and exists (
  select 1 from public.candidates c
  where c.id::text=(storage.foldername(storage.objects.name))[1]
 )
);
commit;
