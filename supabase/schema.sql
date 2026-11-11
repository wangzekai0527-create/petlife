-- PetLife authenticated schema. Private data is isolated by Supabase Auth user ID.
create extension if not exists pgcrypto;

create or replace function public.set_current_timestamp_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.user_accounts (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  phone text not null default '',
  city text not null default '',
  bio text not null default '',
  avatar_symbol text not null default 'person.crop.circle.fill',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.owned_pets (
  id uuid primary key,
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  name text not null,
  species text not null,
  breed text not null,
  age_text text not null,
  city text not null,
  bio text not null,
  interests text[] not null default '{}',
  looking_for text not null,
  accent text not null,
  owner_name text not null,
  vaccinated boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.holiday_memories (
  id uuid primary key,
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  title text not null,
  subtitle text not null,
  date_text text not null,
  ornament text not null,
  accent text not null,
  story text not null,
  photo_storage_path text,
  audio_storage_path text,
  audio_display_name text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.upload_videos (
  id uuid primary key,
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  title text not null,
  duration text not null,
  caption text not null,
  tags text[] not null default '{}',
  status text not null,
  selected_asset_count integer not null default 0,
  accent text not null,
  publish_date_text text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.feed_posts (
  id uuid primary key,
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  related_pet_id uuid references public.owned_pets(id) on delete set null,
  author_name text not null,
  pet_name text not null,
  topic text not null,
  city text not null,
  content text not null,
  tags text[] not null default '{}',
  likes integer not null default 0,
  liked_by_current_user boolean not null default false,
  created_at_text text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.post_comments (
  id uuid primary key,
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  post_id uuid not null references public.feed_posts(id) on delete cascade,
  author_name text not null,
  body text not null,
  created_at_text text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.chat_threads (
  id uuid primary key,
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  related_pet_id uuid not null,
  title text not null,
  subtitle text not null,
  unread_count integer not null default 0,
  accent text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.chat_messages (
  id uuid primary key,
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  text text not null,
  is_from_current_user boolean not null default false,
  sent_at_text text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_owned_pets_user_id on public.owned_pets(user_id);
create index if not exists idx_holiday_memories_user_id on public.holiday_memories(user_id);
create index if not exists idx_upload_videos_user_id on public.upload_videos(user_id);
create index if not exists idx_feed_posts_user_id on public.feed_posts(user_id);
create index if not exists idx_post_comments_user_id on public.post_comments(user_id);
create index if not exists idx_post_comments_post_id on public.post_comments(post_id);
create index if not exists idx_chat_threads_user_id on public.chat_threads(user_id);
create index if not exists idx_chat_messages_user_id on public.chat_messages(user_id);
create index if not exists idx_chat_messages_thread_id on public.chat_messages(thread_id);

drop trigger if exists set_user_accounts_updated_at on public.user_accounts;
create trigger set_user_accounts_updated_at
before update on public.user_accounts
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_owned_pets_updated_at on public.owned_pets;
create trigger set_owned_pets_updated_at
before update on public.owned_pets
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_holiday_memories_updated_at on public.holiday_memories;
create trigger set_holiday_memories_updated_at
before update on public.holiday_memories
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_upload_videos_updated_at on public.upload_videos;
create trigger set_upload_videos_updated_at
before update on public.upload_videos
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_feed_posts_updated_at on public.feed_posts;
create trigger set_feed_posts_updated_at
before update on public.feed_posts
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_post_comments_updated_at on public.post_comments;
create trigger set_post_comments_updated_at
before update on public.post_comments
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_chat_threads_updated_at on public.chat_threads;
create trigger set_chat_threads_updated_at
before update on public.chat_threads
for each row execute function public.set_current_timestamp_updated_at();

drop trigger if exists set_chat_messages_updated_at on public.chat_messages;
create trigger set_chat_messages_updated_at
before update on public.chat_messages
for each row execute function public.set_current_timestamp_updated_at();

alter table public.user_accounts enable row level security;
alter table public.owned_pets enable row level security;
alter table public.holiday_memories enable row level security;
alter table public.upload_videos enable row level security;
alter table public.feed_posts enable row level security;
alter table public.post_comments enable row level security;
alter table public.chat_threads enable row level security;
alter table public.chat_messages enable row level security;


revoke all on public.user_accounts from anon;
grant select, insert, update, delete on public.user_accounts to authenticated;
drop policy if exists "owner access user_accounts" on public.user_accounts;
create policy "owner access user_accounts" on public.user_accounts
for all to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

revoke all on public.owned_pets from anon;
grant select, insert, update, delete on public.owned_pets to authenticated;
drop policy if exists "owner access owned_pets" on public.owned_pets;
create policy "owner access owned_pets" on public.owned_pets
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on public.holiday_memories from anon;
grant select, insert, update, delete on public.holiday_memories to authenticated;
drop policy if exists "owner access holiday_memories" on public.holiday_memories;
create policy "owner access holiday_memories" on public.holiday_memories
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on public.upload_videos from anon;
grant select, insert, update, delete on public.upload_videos to authenticated;
drop policy if exists "owner access upload_videos" on public.upload_videos;
create policy "owner access upload_videos" on public.upload_videos
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on public.feed_posts from anon;
grant select, insert, update, delete on public.feed_posts to authenticated;
drop policy if exists "owner access feed_posts" on public.feed_posts;
create policy "owner access feed_posts" on public.feed_posts
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on public.post_comments from anon;
grant select, insert, update, delete on public.post_comments to authenticated;
drop policy if exists "owner access post_comments" on public.post_comments;
create policy "owner access post_comments" on public.post_comments
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on public.chat_threads from anon;
grant select, insert, update, delete on public.chat_threads to authenticated;
drop policy if exists "owner access chat_threads" on public.chat_threads;
create policy "owner access chat_threads" on public.chat_threads
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on public.chat_messages from anon;
grant select, insert, update, delete on public.chat_messages to authenticated;
drop policy if exists "owner access chat_messages" on public.chat_messages;
create policy "owner access chat_messages" on public.chat_messages
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create index if not exists idx_feed_posts_related_pet_id on public.feed_posts(related_pet_id);
create index if not exists idx_chat_messages_thread_id on public.chat_messages(thread_id);
insert into storage.buckets (id, name, public)
values ('petner', 'petner', false)
on conflict (id) do nothing;

drop policy if exists "owner select petner media" on storage.objects;
create policy "owner select petner media" on storage.objects
for select to authenticated
using (bucket_id = 'petner' and (storage.foldername(name))[1] = 'users' and (storage.foldername(name))[2] = (select auth.uid())::text);

drop policy if exists "owner insert petner media" on storage.objects;
create policy "owner insert petner media" on storage.objects
for insert to authenticated
with check (bucket_id = 'petner' and (storage.foldername(name))[1] = 'users' and (storage.foldername(name))[2] = (select auth.uid())::text);

drop policy if exists "owner update petner media" on storage.objects;
create policy "owner update petner media" on storage.objects
for update to authenticated
using (bucket_id = 'petner' and (storage.foldername(name))[1] = 'users' and (storage.foldername(name))[2] = (select auth.uid())::text)
with check (bucket_id = 'petner' and (storage.foldername(name))[1] = 'users' and (storage.foldername(name))[2] = (select auth.uid())::text);

drop policy if exists "owner delete petner media" on storage.objects;
create policy "owner delete petner media" on storage.objects
for delete to authenticated
using (bucket_id = 'petner' and (storage.foldername(name))[1] = 'users' and (storage.foldername(name))[2] = (select auth.uid())::text);
