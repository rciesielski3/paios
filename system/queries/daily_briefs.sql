-- Fetch synthesized briefs by date range
-- Usage: psql -f system/queries/daily_briefs.sql -v start_date='2026-07-01' -v end_date='2026-07-12'

SELECT
  date,
  markdown_content,
  source_items_count,
  generated_at
FROM synthesized_briefs
WHERE date BETWEEN :start_date AND :end_date
ORDER BY date DESC;
