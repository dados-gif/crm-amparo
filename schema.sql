-- Execute no SQL Editor do novo projeto Supabase. Não utilizar banco de outro produto.
create extension if not exists pgcrypto;
create table public.profiles (id uuid primary key references auth.users(id) on delete cascade, full_name text not null default '', role text not null default 'agent' check(role in ('admin','manager','agent')), active boolean not null default false, monday_user_id text unique, created_at timestamptz not null default now());
create table public.leads (id uuid primary key default gen_random_uuid(), name text not null check(char_length(trim(name))>0), phone text, email text, source text not null default 'crm', status text not null default 'Novo', owner_id uuid references public.profiles(id) on delete set null, monday_item_id text unique, monday_board_id text, monday_raw jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.activities (id uuid primary key default gen_random_uuid(), lead_id uuid not null references public.leads(id) on delete cascade, author_id uuid not null default auth.uid() references public.profiles(id), kind text not null, body text not null check(length(trim(body))>0), created_at timestamptz not null default now());
create table public.import_runs (id uuid primary key default gen_random_uuid(), executed_by uuid references public.profiles(id), board_id text not null, imported int not null default 0, updated int not null default 0, skipped int not null default 0, created_at timestamptz not null default now());
create index leads_owner_status_idx on public.leads(owner_id,status);
create index activities_lead_date_idx on public.activities(lead_id,created_at desc);
create or replace function public.touch_lead() returns trigger language plpgsql set search_path=public as $$begin new.updated_at=now();return new;end$$;
create trigger lead_timestamp before update on public.leads for each row execute function public.touch_lead();
create or replace function public.my_role() returns text language sql stable security definer set search_path=public as $$select role from public.profiles where id=(select auth.uid()) and active=true$$;
create or replace function public.is_enabled() returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.profiles where id=(select auth.uid()) and active=true)$$;
alter table public.profiles enable row level security;
alter table public.leads enable row level security;
alter table public.activities enable row level security;
alter table public.import_runs enable row level security;
create policy profiles_read on public.profiles for select to authenticated using(public.is_enabled());
create policy leads_read on public.leads for select to authenticated using(public.is_enabled() and (public.my_role() in ('admin','manager') or owner_id=(select auth.uid())));
create policy leads_insert on public.leads for insert to authenticated with check(public.is_enabled() and (public.my_role() in ('admin','manager') or owner_id=(select auth.uid())) and monday_item_id is null);
create policy leads_update on public.leads for update to authenticated using(public.is_enabled() and (public.my_role() in ('admin','manager') or owner_id=(select auth.uid()))) with check(public.is_enabled() and (public.my_role() in ('admin','manager') or owner_id=(select auth.uid())));
create policy activities_read on public.activities for select to authenticated using(public.is_enabled() and exists(select 1 from public.leads l where l.id=lead_id and (public.my_role() in ('admin','manager') or l.owner_id=(select auth.uid()))));
create policy activities_insert on public.activities for insert to authenticated with check(public.is_enabled() and author_id=(select auth.uid()) and exists(select 1 from public.leads l where l.id=lead_id and (public.my_role() in ('admin','manager') or l.owner_id=(select auth.uid()))));
create policy imports_read on public.import_runs for select to authenticated using(public.my_role()='admin');
-- IMPORTANT: não oferecer políticas de update/delete em activities, garantindo trilha imutável para usuários comuns.
-- IMPOR admin inicial MANUALMENTE após criar usuário pelo Supabase Auth:
-- insert into public.profiles(id,full_name,role,active) values('<UUID_AUTH_USER>','Administrador MCMV','admin',true);
