-- Iron Records cloud sync: run once in Supabase -> SQL Editor -> New query -> Run.
-- One row per user holds your whole training log; a history table keeps recent snapshots as a safety net.

create table if not exists public.bp5_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  rev integer not null default 1,
  data jsonb not null,
  device text,
  updated_at timestamptz not null default now()
);

create table if not exists public.bp5_history (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  rev integer not null,
  data jsonb not null,
  device text,
  saved_at timestamptz not null default now()
);
create index if not exists bp5_history_user_idx on public.bp5_history (user_id, id desc);

-- Row level security: you can only ever see and change your own rows.
alter table public.bp5_state enable row level security;
alter table public.bp5_history enable row level security;

drop policy if exists "own state" on public.bp5_state;
create policy "own state" on public.bp5_state for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own history (read)" on public.bp5_history;
create policy "own history (read)" on public.bp5_history for select to authenticated
  using (auth.uid() = user_id);

-- Before an update, keep a snapshot of the old version (at most one per 30 minutes, newest 100 kept).
create or replace function public.bp5_keep_history() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.bp5_history h where h.user_id = old.user_id and h.saved_at > now() - interval '30 minutes') then
    insert into public.bp5_history (user_id, rev, data, device) values (old.user_id, old.rev, old.data, old.device);
    delete from public.bp5_history
      where user_id = old.user_id
        and id not in (select id from public.bp5_history where user_id = old.user_id order by id desc limit 100);
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists bp5_state_history on public.bp5_state;
create trigger bp5_state_history before update on public.bp5_state
  for each row execute function public.bp5_keep_history();
