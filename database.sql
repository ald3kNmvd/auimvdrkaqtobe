-- Выполнить один раз в SQL Editor нового проекта Supabase.
begin;
create table public.contact_admins (user_id uuid primary key references auth.users(id) on delete cascade);
alter table public.contact_admins enable row level security;
create policy own_admin on public.contact_admins for select to authenticated using (user_id=auth.uid());
grant select on public.contact_admins to authenticated;
revoke all on public.contact_admins from anon;
create table public.contacts (
 id uuid primary key default gen_random_uuid(),
 created_at timestamptz not null default now(),
 full_name text not null check(length(full_name) between 3 and 150),
 phone text not null check(phone ~ '^\+7[0-9]{10}$'),
 city text not null check(length(city) between 1 and 200),
 institution text not null check(length(institution) between 1 and 300),
 applicant_status text not null check(applicant_status in ('school','college','university')),
 direction text not null check(direction in ('district','juvenile','patrol','migration','road_safety')),
 language text not null check(language in ('ru','kk')),
 consent_at timestamptz not null default now(), consent_version text not null default 'admission-contact-v1',
 quiz_result text check(quiz_result in ('district','juvenile','patrol','migration','road_safety')),
 call_status text not null default 'Новая заявка' check(call_status in ('Новая заявка','Позвонили','Заинтересован','Не дозвонились')),
 comment text not null default '' check(length(comment)<=2000)
);
create table public.contact_tokens(token uuid primary key, contact_id uuid not null references public.contacts(id), created_at timestamptz not null default now());
alter table public.contact_tokens enable row level security;
revoke all on public.contact_tokens from anon, authenticated;
alter table public.contacts enable row level security;
revoke all on public.contacts from anon, authenticated;
grant select on public.contacts to authenticated;
grant update(call_status,comment) on public.contacts to authenticated;
create policy admin_read on public.contacts for select to authenticated using(exists(select 1 from public.contact_admins where user_id=auth.uid()));
create policy admin_update on public.contacts for update to authenticated using(exists(select 1 from public.contact_admins where user_id=auth.uid())) with check(exists(select 1 from public.contact_admins where user_id=auth.uid()));
create function public.submit_contact(p_token uuid,p_data jsonb) returns void language plpgsql security definer set search_path='' as $$
declare cid uuid;
begin
 if p_token is null or p_data->>'consent' is distinct from 'true' then raise exception 'Consent required'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_token::text,0));
 if exists(select 1 from public.contact_tokens where token=p_token) then return; end if;
 insert into public.contacts(full_name,phone,city,institution,applicant_status,direction,language)
 values(trim(p_data->>'fullName'),p_data->>'phone',trim(p_data->>'city'),trim(p_data->>'institution'),p_data->>'status',p_data->>'direction',p_data->>'language') returning id into cid;
 insert into public.contact_tokens(token,contact_id) values(p_token,cid);
end $$;
create function public.complete_contact_quiz(p_token uuid,p_result text) returns void language plpgsql security definer set search_path='' as $$
begin
 update public.contacts set quiz_result=p_result where id=(select contact_id from public.contact_tokens where token=p_token and created_at>now()-interval '2 hours') and quiz_result is null;
end $$;
revoke all on function public.submit_contact(uuid,jsonb) from public;
revoke all on function public.complete_contact_quiz(uuid,text) from public;
grant execute on function public.submit_contact(uuid,jsonb), public.complete_contact_quiz(uuid,text) to anon,authenticated;
commit;
-- После создания пользователя в Authentication → Users:
-- insert into public.contact_admins(user_id) values ('UUID_ВАШЕГО_ПОЛЬЗОВАТЕЛЯ');
