-- Export all data for external archive/analysis
-- Join normalized items with their corresponding brief

SELECT
  b.date,
  b.markdown_content,
  b.source_items_count,
  n.source,
  n.source_id,
  n.title,
  n.url,
  n.priority,
  n.tags,
  n.created_at
FROM synthesized_briefs b
LEFT JOIN normalized_items n ON n.created_at::date = b.date
WHERE b.date BETWEEN :start_date AND :end_date
ORDER BY b.date DESC, n.priority DESC;
