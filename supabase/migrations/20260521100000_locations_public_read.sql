-- locations had RLS enabled with no policy → signup fetch returned [].
-- Allow anyone to read the catalog (adjust if you need stricter rules).

drop policy if exists "locations_select_public" on public.locations;

create policy "locations_select_public"
  on public.locations
  for select
  to anon, authenticated
  using (true);
