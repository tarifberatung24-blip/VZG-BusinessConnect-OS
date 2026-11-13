-- BusinessConnect OS — seed data
-- PREREQUISITE: create the demo auth users first (Supabase dashboard → Authentication → Users,
-- or CLI: supabase auth admin create-user <email> <password> --no-confirm)
-- Emails used below:
--   admin@businessconnect.eu      / admin123
--   ivan@sofiatextile.bg          / demo1234
--   georgi@balkanmetal.bg         / demo1234
--   klaus@heidelberg-maschinen.de / demo1234
--   anna@alpine-food.de           / demo1234
-- This script only inserts companies owned by those profiles; if a profile is missing it skips.

do $$
declare
  v_ivan   uuid;
  v_georgi uuid;
  v_klaus  uuid;
  v_anna   uuid;
  v_admin  uuid;
begin
  select id into v_ivan   from public.profiles where email = 'ivan@sofiatextile.bg';
  select id into v_georgi from public.profiles where email = 'georgi@balkanmetal.bg';
  select id into v_klaus  from public.profiles where email = 'klaus@heidelberg-maschinen.de';
  select id into v_anna   from public.profiles where email = 'anna@alpine-food.de';
  select id into v_admin  from public.profiles where email = 'admin@businessconnect.eu';

  -- ============ BULGARIAN SUPPLIERS ============
  if v_ivan is not null then
    insert into public.companies (owner_id, name, country, city, category, tagline, description, services, certifications, languages, employees, founded, website, phone, email, moq, lead_time_days, monthly_capacity, rating, logo_color, verification_status, verified_at)
    values (v_ivan, 'Sofia Textile Works', 'BG', 'Sofia', 'textile', 'Knitted & woven apparel manufacturing',
      'Family-run textile manufacturer with 28 years of experience producing knitted and woven garments for German retail brands. Vertical production: cutting, sewing, finishing, quality control.',
      array['Cut & sew apparel','Knitwear','Private label','OEM/ODM','Sample development'],
      array['ISO 9001','ISO 14001','OEKO-TEX Standard 100'], array['Bulgarian','English','German'], 85, 1998,
      'https://sofiatextile.bg', '+359 2 987 6543', 'sales@sofiatextile.bg', '500 units/style', 21, '25,000 units/month', 4.9, '#7C3AED', 'verified', now());
  else raise notice 'skip: ivan@sofiatextile.bg profile missing'; end if;

  if v_georgi is not null then
    insert into public.companies (owner_id, name, country, city, category, tagline, description, services, certifications, languages, employees, founded, website, phone, email, moq, lead_time_days, monthly_capacity, rating, logo_color, verification_status, verified_at)
    values (v_georgi, 'Balkan Metalcraft', 'BG', 'Plovdiv', 'metal-production', 'Precision metal parts & structures',
      'CNC machining, laser cutting and welding of steel, aluminium and stainless parts. From prototypes to serial production for automotive and machinery customers.',
      array['CNC machining','Laser cutting','Welding','Sheet metal','Prototypes'],
      array['ISO 9001','ISO 3834','CE'], array['Bulgarian','English','German'], 60, 2005,
      'https://balkanmetal.bg', '+359 32 687 543', 'info@balkanmetal.bg', '100 units', 14, '40,000 parts/month', 4.8, '#0F766E', 'verified', now());
  else raise notice 'skip: georgi@balkanmetal.bg profile missing'; end if;

  -- TransEuro Logistics (owner: admin demo profile)
  if v_admin is not null then
      insert into public.companies (owner_id, name, country, city, category, tagline, description, services, certifications, languages, employees, founded, website, phone, email, moq, lead_time_days, monthly_capacity, rating, logo_color, verification_status, verified_at)
      values (v_admin, 'TransEuro Logistics', 'BG', 'Burgas', 'logistics', 'Freight & warehousing across the EU corridor',
        'Road freight DE↔BG with own fleet, bonded warehousing in Burgas and Sofia, customs clearance and groupage services.',
        array['FTL/LTL freight','Warehousing','Customs clearance','Groupage','Distribution'],
        array['ISO 9001','AEO'], array['Bulgarian','English','German','Turkish'], 120, 2001,
        'https://transeuro.eu', '+359 56 890 123', 'ops@transeuro.eu', '1 pallet', 2, '800 loads/month', 4.7, '#B45309', 'verified', now());
  else raise notice 'skip: admin@businessconnect.eu profile missing'; end if;

  -- ============ GERMAN BUYERS ============
  if v_klaus is not null then
    insert into public.companies (owner_id, name, country, city, category, tagline, description, services, certifications, languages, employees, founded, website, phone, email, moq, lead_time_days, monthly_capacity, rating, logo_color, verification_status, verified_at)
    values (v_klaus, 'Heidelberg Maschinen GmbH', 'DE', 'Heidelberg', 'outsourcing', 'Industrial machinery buyer — sourcing partner in BG',
        'Mid-size machinery builder sourcing precision components and sub-assemblies from Bulgarian manufacturers. Long-term framework agreements.',
        array['Sourcing','Framework agreements','Quality auditing'],
        array['ISO 9001'], array['German','English'], 210, 1972,
        'https://heidelberg-maschinen.de', '+49 6221 555 01', 'sourcing@heidelberg-maschinen.de', '', 0, '', 4.8, '#1D4ED8', 'verified', now());
  else raise notice 'skip: klaus@heidelberg-maschinen.de profile missing'; end if;

  if v_anna is not null then
    insert into public.companies (owner_id, name, country, city, category, tagline, description, services, certifications, languages, employees, founded, website, phone, email, moq, lead_time_days, monthly_capacity, rating, logo_color, verification_status, verified_at)
    values (v_anna, 'Alpine Food Group GmbH', 'DE', 'Munich', 'food-production', 'Food retail group seeking BG producers',
        'Regional food retailer looking for private-label producers of bakery, dairy and preserved foods in Bulgaria.',
        array['Private label','Retail distribution','Import/export'],
        array['IFS Food','ISO 22000'], array['German','English'], 340, 1988,
        'https://alpine-food.de', '+49 89 234 567', 'procurement@alpine-food.de', '', 0, '', 4.7, '#16A34A', 'verified', now());
  else raise notice 'skip: anna@alpine-food.de profile missing'; end if;

  raise notice 'Seed complete.';
end $$;

-- Seed a few reviews for the flagship companies
insert into public.reviews (company_id, author_name, author_country, rating, body)
select c.id, 'Markus Weber', 'DE', 5, 'Reliable partner — on time, consistent quality, zero surprises over 3 years.'
from public.companies c where c.name = 'Sofia Textile Works'
on conflict do nothing;

insert into public.reviews (company_id, author_name, author_country, rating, body)
select c.id, 'Petra Schneider', 'DE', 5, 'Clean documentation and easy customs handling on every shipment.'
from public.companies c where c.name = 'TransEuro Logistics'
on conflict do nothing;

insert into public.reviews (company_id, author_name, author_country, rating, body)
select c.id, 'Stefan Hoffmann', 'DE', 4, 'Good machining quality; sample approval took slightly longer than expected.'
from public.companies c where c.name = 'Balkan Metalcraft'
on conflict do nothing;
