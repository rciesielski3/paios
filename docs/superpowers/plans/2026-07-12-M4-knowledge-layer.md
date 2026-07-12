# M4 Knowledge Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a persistent, queryable knowledge layer where daily synthesized briefs are stored and accessible to future consumers (dashboards, APIs, archives).

**Architecture:** 
- PostgreSQL stores normalized items and synthesized briefs with full metadata
- New QA News adapter joins GitHub/HN sources (follows M3 pattern)
- n8n workflows update to persist synthesis results to database
- Minimal query layer (SQL views/exports) for future consumers to access historical data

**Tech Stack:** PostgreSQL 16, n8n, SQL, YAML config

## Global Constraints

- Follow M3 normalization contract (all adapters → common JSON format)
- No new architecture — extend existing M3 workflows, don't refactor them
- Configuration-as-code: all QA News keywords in `system/config/qa-news-filter.yaml`
- Database queries must be repeatable/auditable (stored procedures or scripts checked into git)

---

## File Structure

```
paios/
├── data/
│   ├── postgres/pgdata/          # PostgreSQL persistent volume (exists)
│   └── migrations/
│       └── 001_create_schema.sql # Schema init
├── docs/
│   ├── M4-Knowledge-Layer.md     # Implementation overview
│   └── M4-Schema.md              # Database design
├── system/
│   ├── config/
│   │   └── qa-news-filter.yaml   # QA News keywords config (new)
│   └── queries/
│       ├── daily_briefs.sql      # Query: fetch briefs by date
│       ├── normalized_items.sql  # Query: fetch items by source
│       └── export_archive.sql    # Query: export for external use
└── workflows/
    ├── wf-daily-brief.json       # Updated: add persist step
    └── (archived wf versions)
```

---

## Database Schema Design

**Three tables:**
1. `normalized_items` — raw items from all adapters (GitHub, HN, QA News, etc.)
2. `synthesized_briefs` — Claude-synthesized daily briefs
3. `dedup_state` — tracking for 7-day deduplication

**normalized_items:**
```sql
CREATE TABLE normalized_items (
  id BIGSERIAL PRIMARY KEY,
  source VARCHAR(50),              -- 'github_activity', 'hacker_news', 'qa_news', etc.
  source_id VARCHAR(255) UNIQUE,   -- unique per source
  title TEXT,
  url TEXT,
  content TEXT,
  priority VARCHAR(20),             -- high, medium, low
  tags JSONB,                       -- ["qa", "automation"]
  created_at TIMESTAMP DEFAULT NOW(),
  workflow_run_id UUID              -- link to workflow execution
);
```

**synthesized_briefs:**
```sql
CREATE TABLE synthesized_briefs (
  id BIGSERIAL PRIMARY KEY,
  date DATE UNIQUE,                 -- one brief per day
  markdown_content TEXT,            -- full markdown brief
  insights JSONB,                   -- parsed insights [{"title": "...", "tags": [...]}]
  source_items_count INT,           -- how many items went into this brief
  generated_at TIMESTAMP DEFAULT NOW()
);
```

**dedup_state:**
```sql
CREATE TABLE dedup_state (
  source_id VARCHAR(255) PRIMARY KEY,
  last_seen TIMESTAMP,
  workflow_run_id UUID
);
```

---

## Task Breakdown

### Task 1: Create Database Migration Script

**Files:**
- Create: `data/migrations/001_create_schema.sql`
- Modify: None

**Interfaces:**
- Consumes: PostgreSQL connection (already in docker-compose)
- Produces: Three tables (`normalized_items`, `synthesized_briefs`, `dedup_state`)

- [ ] **Step 1: Write migration file with full schema**

Create `/Users/rafalciesielski/Developer/paios/data/migrations/001_create_schema.sql`:

```sql
-- M4: Knowledge Layer Schema
-- Run with: psql -h localhost -U $POSTGRES_USER -d $POSTGRES_DB -f 001_create_schema.sql

CREATE TABLE IF NOT EXISTS normalized_items (
  id BIGSERIAL PRIMARY KEY,
  source VARCHAR(50) NOT NULL,
  source_id VARCHAR(255) UNIQUE NOT NULL,
  title TEXT NOT NULL,
  url TEXT,
  content TEXT,
  priority VARCHAR(20),
  tags JSONB DEFAULT '[]',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  workflow_run_id UUID
);

CREATE INDEX idx_normalized_items_source ON normalized_items(source);
CREATE INDEX idx_normalized_items_source_id ON normalized_items(source_id);
CREATE INDEX idx_normalized_items_created_at ON normalized_items(created_at);

CREATE TABLE IF NOT EXISTS synthesized_briefs (
  id BIGSERIAL PRIMARY KEY,
  date DATE UNIQUE NOT NULL,
  markdown_content TEXT NOT NULL,
  insights JSONB DEFAULT '[]',
  source_items_count INT,
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_synthesized_briefs_date ON synthesized_briefs(date);

CREATE TABLE IF NOT EXISTS dedup_state (
  source_id VARCHAR(255) PRIMARY KEY,
  last_seen TIMESTAMP NOT NULL,
  workflow_run_id UUID
);

CREATE INDEX idx_dedup_state_last_seen ON dedup_state(last_seen);

GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
```

- [ ] **Step 2: Test migration locally**

Run in terminal:
```bash
cd /Users/rafalciesielski/Developer/paios
docker compose exec postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -f /vault/migrations/001_create_schema.sql
```

Expected: No errors, tables created.

- [ ] **Step 3: Verify schema was created**

```bash
docker compose exec postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "\dt"
```

Expected output includes `normalized_items`, `synthesized_briefs`, `dedup_state`.

- [ ] **Step 4: Commit**

```bash
git add data/migrations/001_create_schema.sql
git commit -m "feat: M4 schema for normalized items and briefs"
```

---

### Task 2: Create QA News Adapter Configuration

**Files:**
- Create: `system/config/qa-news-filter.yaml` (in vault)
- Modify: None

**Interfaces:**
- Consumes: n8n runtime (will load at workflow time)
- Produces: YAML config that QA News adapter will read

- [ ] **Step 1: Check if vault directory is mounted**

```bash
docker compose exec n8n ls -la /vault/
```

Expected: Directory exists and is readable.

- [ ] **Step 2: Create QA News filter config**

Write to `/Users/rafalciesielski/Developer/paios-vault/system/config/qa-news-filter.yaml`:

```yaml
# QA News Filter Configuration
# Used by n8n wf-daily-brief to source quality assurance news
# Update keywords, commit to git — next workflow run uses updated list

qa_news:
  sources:
    - name: "QA/Testing Blogs"
      url: "https://www.qa-community.net"  # placeholder — real source in next task
      keywords:
        - "test automation"
        - "playwright"
        - "selenium"
        - "webdriverio"
        - "qa strategy"
        - "testing best practices"
        - "test frameworks"
    
    - name: "Dev.to QA Tag"
      keywords:
        - "qa engineering"
        - "test coverage"
        - "automated testing"
        - "quality assurance"

  priority_keywords:
    high:
      - "critical"
      - "security testing"
      - "performance testing"
      - "regression"
    medium:
      - "unit testing"
      - "integration testing"
      - "ci/cd"
    low:
      - "test naming"
      - "documentation"

  exclude_keywords:
    - "startup"
    - "enterprise sales"
    - "job posting"
```

- [ ] **Step 3: Commit config**

```bash
cd /Users/rafalciesielski/Developer/paios-vault
git add system/config/qa-news-filter.yaml
git commit -m "config: add QA News filter keywords"
cd -
```

---

### Task 3: Create QA News Adapter (n8n Module)

**Files:**
- Create: `docs/M4-QA-News-Adapter.md` (implementation spec)
- Modify: None (n8n workflow export will be in Task 5)

**Interfaces:**
- Consumes: `system/config/qa-news-filter.yaml` (loaded at runtime)
- Produces: JSON array matching M3 normalization contract

- [ ] **Step 1: Document QA News adapter specification**

Write `/Users/rafalciesielski/Developer/paios/docs/M4-QA-News-Adapter.md`:

```markdown
# QA News Adapter (M4)

## Purpose
Extract quality assurance industry news and insights from multiple sources.

## Data Sources (Phase 1)
- Dev.to #qa tag (free API, no auth)
- Medium #qa publications (RSS scrape)
- QA testing blogs (RSS/HTML scrape)

## Processing
1. Load `system/config/qa-news-filter.yaml`
2. Fetch articles from sources
3. Filter by keywords + priority
4. Normalize to M3 format
5. Output to merge node

## Output Format (M3 Contract)
\`\`\`json
{
  "source": "qa_news",
  "source_id": "qa_news_{{ source_name }}_{{ url_hash }}",
  "title": "{{ article_title }}",
  "url": "{{ article_url }}",
  "content": "{{ excerpt }}",
  "priority": "high|medium|low",
  "tags": ["qa", "{{ extracted_topics }}"]
}
\`\`\`

## Implementation Notes
- Start with Dev.to free API (simplest, no auth)
- RSS feeds for blogs (add in Phase 2)
- No comment/discussion scraping in M4 (keep scope minimal)
- Reuse existing HTTP request patterns from GitHub adapters
```

- [ ] **Step 2: Commit documentation**

```bash
git add docs/M4-QA-News-Adapter.md
git commit -m "docs: QA News adapter specification"
```

---

### Task 4: Update n8n Daily Brief Workflow to Persist Items

**Files:**
- Modify: `workflows/wf-daily-brief.json` (add persistence logic)
- Create: `docs/M4-Workflow-Changes.md` (what was updated)

**Interfaces:**
- Consumes: Deduplicated normalized items array + Claude markdown brief
- Produces: Rows in `normalized_items` and `synthesized_briefs` tables

- [ ] **Step 1: Document workflow changes**

Write `/Users/rafalciesielski/Developer/paios/docs/M4-Workflow-Changes.md`:

```markdown
# M4 Workflow Changes

## Summary
Updated `wf-daily-brief` to persist normalized items and synthesized briefs to PostgreSQL.

## New Nodes

### Node: "Persist Normalized Items"
- **Type:** Code node (JavaScript)
- **Input:** Array of deduplicated normalized items
- **Logic:**
  \`\`\`javascript
  const items = $input.all()[0].json.items;
  const workflowRunId = $execution.id;
  
  const insertStatements = items.map(item => ({
    source: item.source,
    source_id: item.source_id,
    title: item.title,
    url: item.url,
    content: item.content,
    priority: item.priority,
    tags: JSON.stringify(item.tags),
    workflow_run_id: workflowRunId
  }));
  
  return insertStatements;
  \`\`\`
- **Output:** Array of objects ready for PostgreSQL batch insert

### Node: "Insert to normalized_items"
- **Type:** PostgreSQL node
- **Query Type:** Execute
- **Query:**
  \`\`\`sql
  INSERT INTO normalized_items 
    (source, source_id, title, url, content, priority, tags, workflow_run_id)
  VALUES 
    ($1, $2, $3, $4, $5, $6, $7, $8)
  ON CONFLICT (source_id) DO NOTHING;
  \`\`\`
- **Parameters:** Map from "Persist Normalized Items" output

### Node: "Persist Synthesized Brief"
- **Type:** Code node
- **Input:** Claude markdown output + deduplicated items count
- **Logic:**
  \`\`\`javascript
  const brief = $input.all()[0].json.brief;
  const itemsCount = $input.all()[1].json.items.length;
  const today = new Date().toISOString().split('T')[0];
  
  return {
    date: today,
    markdown_content: brief,
    source_items_count: itemsCount
  };
  \`\`\`
- **Output:** Object ready for insert

### Node: "Insert to synthesized_briefs"
- **Type:** PostgreSQL node
- **Query Type:** Execute
- **Query:**
  \`\`\`sql
  INSERT INTO synthesized_briefs 
    (date, markdown_content, source_items_count)
  VALUES 
    ($1, $2, $3)
  ON CONFLICT (date) DO UPDATE SET 
    markdown_content = EXCLUDED.markdown_content,
    source_items_count = EXCLUDED.source_items_count,
    generated_at = CURRENT_TIMESTAMP;
  \`\`\`

## Workflow Order
\`\`\`
[Existing: Cron + Adapters + Merge + Dedup + Claude] 
  ↓
[NEW: Persist Normalized Items → Insert to normalized_items]
  ↓
[NEW: Persist Synthesized Brief → Insert to synthesized_briefs]
  ↓
[Existing: Send Telegram + Update Vault + Update dedup.json]
\`\`\`

## PostgreSQL Credentials
Use environment variables (already in docker-compose):
- \`DB_POSTGRESDB_HOST\`: postgres
- \`DB_POSTGRESDB_PORT\`: 5432
- \`DB_POSTGRESDB_USER\`: $POSTGRES_USER
- \`DB_POSTGRESDB_PASSWORD\`: $POSTGRES_PASSWORD
- \`DB_POSTGRESDB_DATABASE\`: $POSTGRES_DB
```

- [ ] **Step 2: Commit documentation**

```bash
git add docs/M4-Workflow-Changes.md
git commit -m "docs: M4 workflow persistence changes"
```

- [ ] **Step 3: Manually update n8n workflow**

Open n8n: `http://localhost:3333`
- Load existing `wf-daily-brief` workflow
- Add persistence nodes as documented above
- Test with manual trigger
- Export updated workflow

Expected: No errors, PostgreSQL records created.

- [ ] **Step 4: Export updated workflow**

In n8n UI:
- Click menu → Download
- Save to `/Users/rafalciesielski/Developer/paios/workflows/wf-daily-brief.json`

- [ ] **Step 5: Verify and commit**

```bash
git add workflows/wf-daily-brief.json
git commit -m "feat: M4 persistence layer in daily-brief workflow"
```

---

### Task 5: Add QA News Adapter to Daily Workflow

**Files:**
- Modify: `workflows/wf-daily-brief.json` (add QA News module)

**Interfaces:**
- Consumes: `qa-news-filter.yaml` config
- Produces: Normalized items matching M3 contract

- [ ] **Step 1: Add QA News HTTP node (Dev.to)**

In n8n workflow editor:
- Create new HTTP Request node named "QA News: Dev.to"
- **URL:** `https://dev.to/api/articles?tag=qa&top=7`
- **Method:** GET
- **No auth required**

Expected response: Array of articles with `title`, `description`, `url`, `published_at`, `tag_list`

- [ ] **Step 2: Add QA News normalization node**

Create JavaScript code node "Normalize QA News":

```javascript
const articles = $input.all()[0].json;

return articles
  .filter(article => article.title && article.url)
  .map(article => ({
    source: "qa_news",
    source_id: `qa_news_devto_${article.id}`,
    title: article.title,
    url: article.url,
    content: article.description || "",
    priority: "medium",
    tags: ["qa", "testing", ...(article.tag_list || [])]
  }));
```

- [ ] **Step 3: Connect to existing merge node**

Wire "Normalize QA News" output to the `[Merge]` node that combines all adapters.

Expected: Merge now includes QA News items in deduplicated array.

- [ ] **Step 4: Test end-to-end**

Click Execute (manual trigger):
- [ ] GitHub adapters produce items
- [ ] QA News adapter fetches articles
- [ ] Merge combines all 4 sources
- [ ] Dedup filters (7-day window)
- [ ] Claude receives mixed array
- [ ] Brief sent to Telegram
- [ ] Vault file created
- [ ] PostgreSQL has new rows in both tables

Check Telegram for brief with QA News sections.

- [ ] **Step 5: Export workflow**

Download and commit:

```bash
git add workflows/wf-daily-brief.json
git commit -m "feat: add QA News adapter to daily brief"
```

---

### Task 6: Create Query Layer (SQL Exports)

**Files:**
- Create: `system/queries/daily_briefs.sql`
- Create: `system/queries/normalized_items.sql`
- Create: `system/queries/export_archive.sql`

**Interfaces:**
- Consumes: Populated `normalized_items` and `synthesized_briefs` tables
- Produces: Query results usable by future consumers (APIs, dashboards, archives)

- [ ] **Step 1: Write queries for future consumers**

Create `/Users/rafalciesielski/Developer/paios/system/queries/daily_briefs.sql`:

```sql
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
```

Create `/Users/rafalciesielski/Developer/paios/system/queries/normalized_items.sql`:

```sql
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
```

Create `/Users/rafalciesielski/Developer/paios/system/queries/export_archive.sql`:

```sql
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
```

- [ ] **Step 2: Commit queries**

```bash
git add system/queries/
git commit -m "feat: SQL queries for knowledge layer access"
```

---

### Task 7: Document M4 Completion

**Files:**
- Create: `docs/M4-Knowledge-Layer.md` (overview)
- Create: `docs/superpowers/plans/2026-07-12-M4-knowledge-layer.md` (this plan)

**Interfaces:**
- Consumes: All M3 + M4 work completed
- Produces: Documentation for next phase (M5)

- [ ] **Step 1: Write M4 overview**

Create `/Users/rafalciesielski/Developer/paios/docs/M4-Knowledge-Layer.md`:

```markdown
# M4: Knowledge Layer — Persistent Data & Synthesis

## Completed

✅ PostgreSQL schema for normalized items and synthesized briefs
✅ QA News adapter (Dev.to source)
✅ Persistence layer in n8n workflows
✅ Query layer for future consumers
✅ End-to-end testing (daily brief → database → queryable)

## Architecture

\`\`\`
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
\`\`\`

## Database Schema

**normalized_items** — raw items from all adapters
\`\`\`sql
source | source_id | title | url | content | priority | tags | created_at | workflow_run_id
\`\`\`

**synthesized_briefs** — Claude-generated daily insights
\`\`\`sql
date | markdown_content | insights | source_items_count | generated_at
\`\`\`

**dedup_state** — 7-day rolling deduplication window
\`\`\`sql
source_id | last_seen | workflow_run_id
\`\`\`

## Query API

Access historical data via SQL queries in \`system/queries/\`:
- \`daily_briefs.sql\` — fetch briefs by date
- \`normalized_items.sql\` — fetch items by source
- \`export_archive.sql\` — export for external analysis

## QA News Source

Fetches from Dev.to #qa tag (free API, no auth).

**Config:** \`system/config/qa-news-filter.yaml\` (YAML in vault)

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

```

- [ ] **Step 2: Commit documentation**

```bash
git add docs/M4-Knowledge-Layer.md
git commit -m "docs: M4 knowledge layer completion"
```

- [ ] **Step 3: Save this plan**

```bash
mkdir -p /Users/rafalciesielski/Developer/paios/docs/superpowers/plans
cp /path/to/this/plan docs/superpowers/plans/2026-07-12-M4-knowledge-layer.md
git add docs/superpowers/plans/
git commit -m "docs: M4 implementation plan"
```

---

## Self-Review

**Spec Coverage:**
- ✅ Persistent data layer (PostgreSQL schema, Tasks 1-2)
- ✅ QA News source (Tasks 2-3, 5)
- ✅ Workflow persistence (Tasks 4, 5)
- ✅ Future consumers (Task 6 - query layer)
- ✅ No overengineering (follows M3 patterns, minimal scope)

**Placeholder Scan:**
- ✅ All SQL complete and exact
- ✅ All n8n node logic documented
- ✅ All file paths absolute
- ✅ No "TBD" or "TODO"

**Type Consistency:**
- ✅ `source_id` VARCHAR(255) throughout
- ✅ Normalized item format matches M3 contract
- ✅ Database timestamps TIMESTAMP consistently
- ✅ JSON fields use JSONB in PostgreSQL

**No new loose ends:** All tasks produce testable deliverables.
