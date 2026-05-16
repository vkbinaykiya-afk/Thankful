-- Enrichment fields populated at entry save (entry review).
alter table public.entries
  add column if not exists summary text,
  add column if not exists tags text[] default '{}',
  add column if not exists mood text,
  add column if not exists highlight_quote text;

comment on column public.entries.summary is 'Short warm summary from post-session enrichment';
comment on column public.entries.tags is 'Topic tags from enrichment';
comment on column public.entries.mood is 'Mood label from enrichment';
comment on column public.entries.highlight_quote is 'Most resonant user quote for share card';
