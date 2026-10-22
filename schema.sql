-- مزرعتي الذكية: مخطط أولي لقاعدة بيانات Supabase (PostgreSQL)
-- شغّل هذا الملف في SQL Editor داخل مشروع Supabase جديد بعد مراجعة الإعدادات.
-- يعتمد كل سجل على user_id لمنع المستخدمين من رؤية بيانات بعضهم.

create extension if not exists pgcrypto;

create table if not exists public.farm_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  farm_id uuid not null default gen_random_uuid(),
  record_type text not null check (record_type in ('animals','health','feed','finance','production','types')),
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists farm_records_user_type_idx
  on public.farm_records(user_id, record_type);
create index if not exists farm_records_farm_idx
  on public.farm_records(farm_id);

alter table public.farm_records enable row level security;

drop policy if exists "read own farm records" on public.farm_records;
create policy "read own farm records" on public.farm_records
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "insert own farm records" on public.farm_records;
create policy "insert own farm records" on public.farm_records
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "update own farm records" on public.farm_records;
create policy "update own farm records" on public.farm_records
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "delete own farm records" on public.farm_records;
create policy "delete own farm records" on public.farm_records
  for delete to authenticated using (auth.uid() = user_id);

-- تنبيه: لا تضع service_role key في تطبيق المتصفح. استخدم anon/publishable key فقط
-- مع تفعيل سياسات RLS واختبارها، ويفضل فصل farm_id بجدول مزارع وعضويات عند تعدد المستخدمين.
