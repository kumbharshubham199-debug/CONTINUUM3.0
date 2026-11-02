-- CONTINUUM initial Supabase database foundation.
-- This matches the SQL already run in the Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text,
 created_at timestamptz not null default now()
);
create table if not exists public.workspaces (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 created_at timestamptz not null default now()
);
create table if not exists public.workspace_members (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null references public.workspaces(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'Administrator'
  check (role in ('Administrator','Inventory Staff','Production Staff','Quality Staff','Dispatch Staff')),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(workspace_id,user_id)
);
create table if not exists public.manufacturing_records (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null references public.workspaces(id) on delete cascade,
 module text not null check (module in ('inventory','planning','production','quality','inspection','dispatch')),
 source_id text not null,
 data jsonb not null default '{}'::jsonb,
 created_by uuid references auth.users(id) on delete set null,
 updated_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(workspace_id,module,source_id)
);
create table if not exists public.activity_logs (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null references public.workspaces(id) on delete cascade,
 module text not null,
 action text not null,
 description text not null,
 actor_id uuid references auth.users(id) on delete set null,
 actor_name text,
 record_source_id text,
 created_at timestamptz not null default now()
);
create index if not exists idx_members_user on public.workspace_members(user_id);
create index if not exists idx_records_workspace_module on public.manufacturing_records(workspace_id,module);
create index if not exists idx_activity_workspace_date on public.activity_logs(workspace_id,created_at desc);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
 insert into public.profiles(id,full_name)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''))
 on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_workspace_member(target_workspace uuid)
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.workspace_members m
 where m.workspace_id=target_workspace and m.user_id=(select auth.uid()) and m.active=true); $$;
create or replace function public.is_workspace_admin(target_workspace uuid)
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.workspace_members m
 where m.workspace_id=target_workspace and m.user_id=(select auth.uid())
 and m.active=true and m.role='Administrator'); $$;

create or replace function public.create_workspace(workspace_name text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare new_workspace_id uuid;
begin
 if (select auth.uid()) is null then raise exception 'You must be signed in'; end if;
 if length(trim(workspace_name))<2 then raise exception 'Workspace name too short'; end if;
 insert into public.workspaces(name) values(trim(workspace_name)) returning id into new_workspace_id;
 insert into public.workspace_members(workspace_id,user_id,role)
 values(new_workspace_id,(select auth.uid()),'Administrator');
 return new_workspace_id;
end; $$;

alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.manufacturing_records enable row level security;
alter table public.activity_logs enable row level security;

drop policy if exists "Users view own profile" on public.profiles;
create policy "Users view own profile" on public.profiles for select to authenticated using(id=(select auth.uid()));
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
drop policy if exists "Members view their workspaces" on public.workspaces;
create policy "Members view their workspaces" on public.workspaces for select to authenticated using(public.is_workspace_member(id));
drop policy if exists "Members view workspace members" on public.workspace_members;
create policy "Members view workspace members" on public.workspace_members for select to authenticated using(public.is_workspace_member(workspace_id));
drop policy if exists "Members view records" on public.manufacturing_records;
create policy "Members view records" on public.manufacturing_records for select to authenticated using(public.is_workspace_member(workspace_id));
drop policy if exists "Members add records" on public.manufacturing_records;
create policy "Members add records" on public.manufacturing_records for insert to authenticated
with check(public.is_workspace_member(workspace_id) and created_by=(select auth.uid()));
drop policy if exists "Members update records" on public.manufacturing_records;
create policy "Members update records" on public.manufacturing_records for update to authenticated
using(public.is_workspace_member(workspace_id)) with check(public.is_workspace_member(workspace_id));
drop policy if exists "Admins delete records" on public.manufacturing_records;
create policy "Admins delete records" on public.manufacturing_records for delete to authenticated using(public.is_workspace_admin(workspace_id));
drop policy if exists "Members view activity" on public.activity_logs;
create policy "Members view activity" on public.activity_logs for select to authenticated using(public.is_workspace_member(workspace_id));
drop policy if exists "Members add activity" on public.activity_logs;
create policy "Members add activity" on public.activity_logs for insert to authenticated
with check(public.is_workspace_member(workspace_id) and actor_id=(select auth.uid()));

revoke all on function public.create_workspace(text) from public;
grant execute on function public.create_workspace(text) to authenticated;
revoke all on function public.is_workspace_member(uuid) from public;
grant execute on function public.is_workspace_member(uuid) to authenticated;
revoke all on function public.is_workspace_admin(uuid) from public;
grant execute on function public.is_workspace_admin(uuid) to authenticated;
grant select,update on public.profiles to authenticated;
grant select on public.workspaces to authenticated;
grant select on public.workspace_members to authenticated;
grant select,insert,update,delete on public.manufacturing_records to authenticated;
grant select,insert on public.activity_logs to authenticated;
