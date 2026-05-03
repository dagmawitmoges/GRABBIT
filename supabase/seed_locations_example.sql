-- Example locations (e.g. after subcities table is removed). Safe to re-run.

insert into public.locations (sub_city, city, country, sort_order)
select v.sub_city, v.city, v.country, v.sort_order
from (
  values
    ('Bole'::varchar(100), 'Addis Ababa'::varchar(100), 'Ethiopia'::varchar(100), 1),
    ('Kazanchis', 'Addis Ababa', 'Ethiopia', 2),
    ('Piazza', 'Addis Ababa', 'Ethiopia', 3),
    ('Megenagna', 'Addis Ababa', 'Ethiopia', 4),
    ('CMC', 'Addis Ababa', 'Ethiopia', 5),
    ('Summit', 'Addis Ababa', 'Ethiopia', 6),
    ('Gerji', 'Addis Ababa', 'Ethiopia', 7),
    ('Sarbet', 'Addis Ababa', 'Ethiopia', 8),
    ('Kolfe', 'Addis Ababa', 'Ethiopia', 9),
    ('Nifas Silk', 'Addis Ababa', 'Ethiopia', 10)
) as v(sub_city, city, country, sort_order)
where not exists (
  select 1 from public.locations l
  where lower(trim(coalesce(l.sub_city, ''))) = lower(trim(coalesce(v.sub_city, '')))
    and lower(trim(l.city)) = lower(trim(v.city))
);
