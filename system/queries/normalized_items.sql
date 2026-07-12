-- Fetch normalized items by source and date range
-- Usage: psql -f system/queries/normalized_items.sql -v source='github_releases' -v start_date='2026-07-01'

SELECT
  source_id,
  title,
  url,
  priority,
  tags,
  created_at
FROM normalized_items
WHERE source = :source
  AND created_at >= :start_date
ORDER BY priority DESC, created_at DESC;
