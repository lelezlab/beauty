-- Celeb gallery table with pgvector index (run in Supabase SQL editor)
create table if not exists celeb_gallery (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  locale text default 'zh-CN',
  photo_url text,
  embed vector(512),
  meta jsonb
);

create index if not exists idx_celeb_embed on celeb_gallery using ivfflat (embed vector_cosine_ops);



