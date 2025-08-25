-- Enable extensions
create extension if not exists pgcrypto;
create extension if not exists vector;

-- Knowledge base tables
create table if not exists public.kb_docs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  abstract text,
  tags text[],
  date date,
  source_url text not null,
  jurisdiction text,
  evidence_level text,
  locale text default 'en',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.kb_chunks (
  id uuid primary key default gen_random_uuid(),
  doc_id uuid references public.kb_docs(id) on delete cascade,
  chunk_index int,
  content text not null,
  locale text default 'en',
  embedding vector(1536),
  created_at timestamptz default now()
);

-- Procedures (simplified)
create table if not exists public.procedures (
  id text primary key,
  name text not null,
  category text check (category in ('surgical','minimally_invasive','device','skincare')),
  indications text[],
  contraindications text[],
  risk text[],
  expected_downtime text,
  longevity text,
  evidence_level text,
  parameters jsonb,
  safe_ranges_ref text[],
  before_after_refs text[],
  locale text default 'en',
  sources text[],
  updated_at timestamptz default now()
);

-- Semantic index
create index if not exists idx_kb_chunks_doc on public.kb_chunks(doc_id);
create index if not exists idx_kb_chunks_embedding on public.kb_chunks using ivfflat (embedding vector_cosine_ops) with (lists = 100);

-- RLS: read-only for anon on kb tables
alter table public.kb_docs enable row level security;
alter table public.kb_chunks enable row level security;
alter table public.procedures enable row level security;

revoke all on public.kb_docs from anon;
revoke all on public.kb_chunks from anon;
revoke all on public.procedures from anon;

create policy if not exists p_select_kb_docs on public.kb_docs for select to anon using (true);
create policy if not exists p_select_kb_chunks on public.kb_chunks for select to anon using (true);
create policy if not exists p_select_procedures on public.procedures for select to anon using (true);


