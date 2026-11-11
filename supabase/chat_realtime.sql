-- Additive upgrade: existing private conversations remain readable by their owner.
alter table public.owned_pets add column if not exists is_discoverable boolean not null default false;
create policy "discoverable pets" on public.owned_pets for select to authenticated using (is_discoverable);
alter table public.chat_threads add column if not exists participant_id uuid references auth.users(id) on delete cascade;
alter table public.chat_threads add constraint chat_distinct_participants check (participant_id is null or participant_id <> user_id);
create unique index chat_participant_pet_unique on public.chat_threads (least(user_id, participant_id), greatest(user_id, participant_id), related_pet_id) where participant_id is not null;
create index chat_threads_participant_idx on public.chat_threads(participant_id);
create index chat_messages_thread_time_idx on public.chat_messages(thread_id,created_at,id);
alter table public.chat_messages add constraint chat_message_length check (char_length(btrim(text)) between 1 and 4000) not valid;

create table public.chat_reads (
 thread_id uuid not null references public.chat_threads(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 last_read_at timestamptz not null default now(),
 primary key(thread_id,user_id)
);
alter table public.chat_reads enable row level security;
revoke all on public.chat_reads from anon;
grant select,insert,update on public.chat_reads to authenticated;
create policy "participants read receipts" on public.chat_reads for select to authenticated using (exists(select 1 from public.chat_threads t where t.id=thread_id and (t.user_id=(select auth.uid()) or t.participant_id=(select auth.uid()))));
create policy "own read receipt insert" on public.chat_reads for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.chat_threads t where t.id=thread_id and (t.user_id=(select auth.uid()) or t.participant_id=(select auth.uid()))));
create policy "own read receipt update" on public.chat_reads for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()) and exists(select 1 from public.chat_threads t where t.id=thread_id and (t.user_id=(select auth.uid()) or t.participant_id=(select auth.uid()))));

drop policy "owner access chat_threads" on public.chat_threads;
revoke all on public.chat_threads from authenticated;
grant select,insert on public.chat_threads to authenticated;
create policy "chat participant select" on public.chat_threads for select to authenticated using(user_id=(select auth.uid()) or participant_id=(select auth.uid()));
create policy "chat participant create" on public.chat_threads for insert to authenticated with check(user_id=(select auth.uid()) and participant_id is not null and participant_id<>user_id and exists(select 1 from public.owned_pets p where p.id=related_pet_id and p.user_id=participant_id and p.is_discoverable));

drop policy "owner access chat_messages" on public.chat_messages;
revoke all on public.chat_messages from authenticated;
grant select,insert on public.chat_messages to authenticated;
create policy "chat member read messages" on public.chat_messages for select to authenticated using(exists(select 1 from public.chat_threads t where t.id=thread_id and (t.user_id=(select auth.uid()) or t.participant_id=(select auth.uid()))));
create policy "chat member send messages" on public.chat_messages for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.chat_threads t where t.id=thread_id and t.participant_id is not null and (t.user_id=(select auth.uid()) or t.participant_id=(select auth.uid()))));
alter publication supabase_realtime add table public.chat_threads, public.chat_messages, public.chat_reads;
