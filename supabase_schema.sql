-- Supabase SQL Schema for ML Smart Expense Tracker
-- Run this in Supabase SQL Editor

-- Enable UUID extension
create extension if not exists "pgcrypto";

-- Expenses table
create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,                 -- supabase auth user id
  amount numeric not null,
  category text not null,
  payment text,
  note text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  synced boolean default true   -- server rows are synced
);

-- Budgets table
create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  category text not null,
  limit_amount numeric not null,
  period_start date not null,
  period_end date not null,
  created_at timestamptz default now()
);

-- Finance table for dashboard values
create table public.finance (
  id integer primary key default 1,
  balance numeric not null default 0,
  daily_spending numeric not null default 0,
  savings numeric not null default 0,
  user_id uuid, -- Optional: can be null for global finance or linked to user
  updated_at timestamptz default now()
);

-- Create indexes for better query performance
create index idx_expenses_user_id on public.expenses(user_id);
create index idx_expenses_created_at on public.expenses(created_at);
create index idx_budgets_user_id on public.budgets(user_id);
create index idx_finance_user_id on public.finance(user_id);

-- Enable Row Level Security (RLS)
alter table public.expenses enable row level security;
alter table public.budgets enable row level security;
alter table public.finance enable row level security;

-- RLS Policies for expenses
-- Allow users to see only their own expenses
create policy "Users can view own expenses"
  on public.expenses for select
  using (auth.uid() = user_id);

-- Allow users to insert their own expenses
create policy "Users can insert own expenses"
  on public.expenses for insert
  with check (auth.uid() = user_id);

-- Allow users to update their own expenses
create policy "Users can update own expenses"
  on public.expenses for update
  using (auth.uid() = user_id);

-- Allow users to delete their own expenses
create policy "Users can delete own expenses"
  on public.expenses for delete
  using (auth.uid() = user_id);

-- RLS Policies for budgets
-- Allow users to see only their own budgets
create policy "Users can view own budgets"
  on public.budgets for select
  using (auth.uid() = user_id);

-- Allow users to insert their own budgets
create policy "Users can insert own budgets"
  on public.budgets for insert
  with check (auth.uid() = user_id);

-- Allow users to update their own budgets
create policy "Users can update own budgets"
  on public.budgets for update
  using (auth.uid() = user_id);

-- Allow users to delete their own budgets
create policy "Users can delete own budgets"
  on public.budgets for delete
  using (auth.uid() = user_id);

-- RLS Policies for finance
-- Allow authenticated users to view finance data
create policy "Users can view finance"
  on public.finance for select
  using (true);

-- Allow authenticated users to insert finance data
create policy "Users can insert finance"
  on public.finance for insert
  with check (true);

-- Allow authenticated users to update finance data
create policy "Users can update finance"
  on public.finance for update
  using (true);









