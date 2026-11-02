-- CONTINUUM role-based authorization hardening
-- Run this AFTER the initial supabase-schema.sql in Supabase SQL Editor.
-- Roles: Administrator, Inventory Staff, Production Staff, Quality Staff, Dispatch Staff.

create or replace function public.can_edit_module(target_workspace uuid, target_module text)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists (
    select 1
    from public.workspace_members m
    where m.workspace_id = target_workspace
      and m.user_id = (select auth.uid())
      and m.active = true
      and (
        m.role = 'Administrator'
        or (m.role = 'Inventory Staff' and target_module = 'inventory')
        or (m.role = 'Production Staff' and target_module in ('planning','production'))
        or (m.role = 'Quality Staff' and target_module in ('quality','inspection'))
        or (m.role = 'Dispatch Staff' and target_module = 'dispatch')
      )
  );
$$;

revoke all on function public.can_edit_module(uuid,text) from public;
grant execute on function public.can_edit_module(uuid,text) to authenticated;

-- Remove broad member-write policies from the initial foundation.
drop policy if exists "Members add records" on public.manufacturing_records;
drop policy if exists "Members update records" on public.manufacturing_records;
drop policy if exists "Admins delete records" on public.manufacturing_records;

create policy "Authorized roles add module records"
on public.manufacturing_records for insert to authenticated
with check (
  public.can_edit_module(workspace_id,module)
  and created_by = (select auth.uid())
);

create policy "Authorized roles update module records"
on public.manufacturing_records for update to authenticated
using (public.can_edit_module(workspace_id,module))
with check (public.can_edit_module(workspace_id,module));

create policy "Only administrators delete records"
on public.manufacturing_records for delete to authenticated
using (public.is_workspace_admin(workspace_id));

-- Activity history is append-only for authenticated workspace members.
-- No UPDATE or DELETE grants/policies are added for activity_logs.
revoke update, delete on public.activity_logs from authenticated;
grant select, insert on public.activity_logs to authenticated;

-- Membership changes are intentionally not exposed to browser clients.
-- Employee invitation/deactivation must be implemented with a trusted server-side
-- function; never put a Supabase service-role key in frontend JavaScript.
revoke insert, update, delete on public.workspace_members from authenticated;

