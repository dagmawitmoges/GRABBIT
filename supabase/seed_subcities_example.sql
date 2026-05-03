-- Deprecated after migration `20260520120000_subcities_to_locations.sql`.
-- Use `seed_locations_example.sql` instead.

insert into public.subcities (name, sort_order)
select v.name, v.ord
from (
  values
    ('Bole', 1),
    ('Kazanchis', 2),
    ('Piazza', 3),
    ('Megenagna', 4),
    ('CMC', 5),
    ('Summit', 6),
    ('Gerji', 7),
    ('Sarbet', 8),
    ('Kolfe', 9),
    ('Nifas Silk', 10)
) as v(name, ord)
where not exists (select 1 from public.subcities s where s.name = v.name);
