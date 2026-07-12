# M4: Knowledge Layer — Persistent Data & Synthesis

## Completed

✅ PostgreSQL schema for normalized items and synthesized briefs
✅ QA News adapter (Dev.to source)
✅ Persistence layer in n8n workflows
✅ Query layer for future consumers
✅ End-to-end testing (daily brief → database → queryable)

## Architecture

```
M3 Daily Brief Workflow
  ├─ GitHub Activity
  ├─ GitHub Releases
  ├─ Hacker News
  └─ QA News (NEW)
      ↓
    Merge → Dedup → Claude Synthesis
      ↓
    [Persist to DB] (NEW)
      ├─ normalized_items table
      └─ synthesized_briefs table
      ↓
    [Output] Telegram + Vault (existing)
```

## Database Schema

**normalized_items** — raw items from all adapters
```sql
source | source_id | title | url | content | priority | tags | created_at | workflow_run_id
```

**synthesized_briefs** — Claude-generated daily insights
```sql
date | markdown_content | insights | source_items_count | generated_at
```

**dedup_state** — 7-day rolling deduplication window
```sql
source_id | last_seen | workflow_run_id
```

## Query API

Access historical data via SQL queries in `system/queries/`:
- `daily_briefs.sql` — fetch briefs by date
- `normalized_items.sql` — fetch items by source
- `export_archive.sql` — export for external analysis

## QA News Source

Fetches from Dev.to #qa tag (free API, no auth).

**Config:** `system/config/qa-news-filter.yaml` (YAML in vault)

Update keywords, commit to git — next workflow run uses new config automatically.

## What's Next (M5+)

- [ ] RSS feeds for QA blogs (expand QA News beyond Dev.to)
- [ ] Dashboard/API to query briefs and items
- [ ] GitHub Intelligence module (repos you follow, PRs to review)
- [ ] Weekly review synthesis (aggregate insights across 7 days)

## Testing

Run manual trigger in n8n:
- [ ] All adapters produce normalized JSON
- [ ] PostgreSQL has new rows
- [ ] Telegram receives brief
- [ ] Query layer returns results
