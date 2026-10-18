-- jamTik core schema (Supabase / Postgres)
-- Run as a migration: supabase migration new init_schema, paste this in, then supabase db push

create extension if not exists pgcrypto;

-- PROFILES ------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (username ~ '^[a-z0-9_.]{3,30}$'),
  display_name text,
  bio text,
  avatar_url text,
  is_verified boolean not null default false,
  created_at timestamptz not null default now()
);

-- Users can edit their own profile, but never the verified flag.
revoke update on public.profiles from authenticated;
grant update (username, display_name, bio, avatar_url) on public.profiles to authenticated;

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username)
  values (new.id, 'user_' || substr(replace(new.id::text, '-', ''), 1, 10));
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

create table public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followee_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);

create table public.verification_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  account_type text not null check (account_type in ('promoter', 'artist', 'government', 'large_event')),
  official_name text not null,
  proof_links text,
  document_url text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

-- EVENTS AND TICKET TYPES ---------------------------------------------
create table public.events (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  cover_url text,
  venue text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  is_public boolean not null default true,
  per_person_limit int check (per_person_limit > 0),
  allow_resale boolean not null default true,
  allow_transfer boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.ticket_types (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  name text not null,
  price_jmd int not null check (price_jmd >= 0),         -- 0 = free ticket
  quantity int check (quantity > 0),                     -- null = unlimited
  resale_cap_jmd int check (resale_cap_jmd >= price_jmd), -- null = no resale above face value
  created_at timestamptz not null default now()
);

-- TICKETS AND RESALE --------------------------------------------------
create table public.tickets (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id),
  ticket_type_id uuid not null references public.ticket_types(id),
  owner_id uuid not null references public.profiles(id),
  original_buyer_id uuid not null references public.profiles(id), -- per-person cap counts this, so transfers can't dodge it
  status text not null default 'valid' check (status in ('valid', 'used', 'void')),
  qr_version int not null default 1,                     -- bump on transfer/resale so old QR codes stop working
  created_at timestamptz not null default now()
);
create index on public.tickets (owner_id);
create index on public.tickets (ticket_type_id);
create index on public.tickets (event_id, original_buyer_id);

create table public.resale_listings (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid unique not null references public.tickets(id) on delete cascade,
  seller_id uuid not null references public.profiles(id),
  price_jmd int not null check (price_jmd > 0),
  created_at timestamptz not null default now()
);

-- Enforce the resale rules in the database, not just the app.
create or replace function public.check_resale() returns trigger
language plpgsql as $$
declare t record;
begin
  select tt.price_jmd, coalesce(tt.resale_cap_jmd, tt.price_jmd) as cap,
         e.allow_resale, k.owner_id, k.status
    into t
    from public.tickets k
    join public.ticket_types tt on tt.id = k.ticket_type_id
    join public.events e on e.id = k.event_id
   where k.id = new.ticket_id;

  if t.owner_id is distinct from new.seller_id then raise exception 'You do not own this ticket'; end if;
  if t.status <> 'valid' then raise exception 'This ticket cannot be listed'; end if;
  if t.price_jmd = 0 then raise exception 'Free tickets cannot be resold'; end if;
  if not t.allow_resale then raise exception 'Resale is turned off for this event'; end if;
  if new.price_jmd > t.cap then raise exception 'Price is above the resale cap of % JMD', t.cap; end if;
  return new;
end $$;

create trigger resale_rules before insert or update on public.resale_listings
for each row execute function public.check_resale();

-- Issue tickets atomically. Call this ONLY from a trusted server (Edge Function)
-- after payment succeeds, or for free tickets. Never from the app directly.
create or replace function public.issue_tickets(p_user uuid, p_ticket_type uuid, p_qty int)
returns setof public.tickets
language plpgsql security definer set search_path = public as $$
declare tt record; ev record; sold int; bought int;
begin
  if p_qty < 1 then raise exception 'Quantity must be at least 1'; end if;

  -- Row lock: two buyers cannot take the last seat at the same time.
  select * into tt from ticket_types where id = p_ticket_type for update;
  if not found then raise exception 'Ticket type not found'; end if;
  select * into ev from events where id = tt.event_id;

  select count(*) into sold from tickets where ticket_type_id = tt.id and status <> 'void';
  if tt.quantity is not null and sold + p_qty > tt.quantity then
    raise exception 'Not enough tickets left';
  end if;

  if ev.per_person_limit is not null then
    select count(*) into bought from tickets
     where event_id = ev.id and original_buyer_id = p_user and status <> 'void';
    if bought + p_qty > ev.per_person_limit then
      raise exception 'Per-person ticket limit reached';
    end if;
  end if;

  return query
    insert into tickets (event_id, ticket_type_id, owner_id, original_buyer_id)
    select ev.id, tt.id, p_user, p_user from generate_series(1, p_qty)
    returning *;
end $$;

revoke all on function public.issue_tickets(uuid, uuid, int) from public, anon, authenticated;

-- ROW LEVEL SECURITY --------------------------------------------------
alter table public.profiles enable row level security;
alter table public.follows enable row level security;
alter table public.verification_requests enable row level security;
alter table public.events enable row level security;
alter table public.ticket_types enable row level security;
alter table public.tickets enable row level security;
alter table public.resale_listings enable row level security;

create policy "profiles readable" on public.profiles for select using (true);
create policy "edit own profile" on public.profiles for update using (auth.uid() = id);

create policy "follows readable" on public.follows for select using (true);
create policy "follow as self" on public.follows for insert with check (follower_id = auth.uid());
create policy "unfollow as self" on public.follows for delete using (follower_id = auth.uid());

create policy "see own verification requests" on public.verification_requests for select using (user_id = auth.uid());
create policy "apply for verification" on public.verification_requests for insert with check (user_id = auth.uid());

create policy "events readable" on public.events for select using (is_public or host_id = auth.uid());
create policy "create own events" on public.events for insert with check (host_id = auth.uid());
create policy "edit own events" on public.events for update using (host_id = auth.uid());

create policy "ticket types readable" on public.ticket_types for select using (
  exists (select 1 from public.events e where e.id = ticket_types.event_id and (e.is_public or e.host_id = auth.uid()))
);
create policy "hosts manage ticket types" on public.ticket_types for all
  using (exists (select 1 from public.events e where e.id = ticket_types.event_id and e.host_id = auth.uid()))
  with check (exists (select 1 from public.events e where e.id = ticket_types.event_id and e.host_id = auth.uid()));

-- No insert/update policies on tickets: only server-side functions change them.
create policy "see own tickets" on public.tickets for select using (owner_id = auth.uid());

create policy "listings readable" on public.resale_listings for select using (true);
create policy "list own ticket" on public.resale_listings for insert with check (seller_id = auth.uid());
create policy "delist own ticket" on public.resale_listings for delete using (seller_id = auth.uid());