# M3: Modular Tech Radar Architecture

## Goal

Build a flexible, modular system where sources are independent and can be added/removed without architectural changes.

**Single output:** Concise, consolidated Daily Brief synthesized by Claude.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│ Source Modules (Independent)                             │
├─────────────────────────────────────────────────────────┤
│ • GitHub Activity (Module)                               │
│ • GitHub Releases (Module)                               │
│ • GitHub Trending (Module)                               │
│ • Hacker News (Module)                                   │
│ • Reddit (Module — Future)                               │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ Normalization Layer                                      │
│ Convert all sources to common format                     │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ Deduplication Layer                                      │
│ Track source IDs (7-day rolling window)                  │
│ Remove already-seen items                                │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ Synthesis Layer                                          │
│ Claude: Merge sources → 3–5 consolidated insights        │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ Output Layer                                             │
│ • Telegram                                               │
│ • Vault (daily/YYYY-MM-DD.md)                            │
└─────────────────────────────────────────────────────────┘
```

---

## Normalized Item Format

Every source must be converted to this format:

```json
{
  "source": "github|github_releases|github_trending|hacker_news|reddit",
  "source_id": "unique-per-source",
  "title": "Human readable title",
  "url": "https://...",
  "content": "Raw content or summary",
  "timestamp": "2026-07-10T08:00:00Z",
  "priority": "high|medium|low",
  "tags": ["qa", "automation", "testing"]
}
```

**Source ID examples:**
- GitHub: `github_commit_abc123` or `github_pr_456`
- GitHub Releases: `github_release_repo-name_v1.0.0`
- GitHub Trending: `github_trending_repo-owner/repo`
- Hacker News: `hacker_news_url_hash` (SHA256 of URL)
- Reddit: `reddit_post_id` (once implemented)

---

## Module Specifications

### Module 1: GitHub Activity

**Purpose:** Most important repository activity today.

**Input:**
- All user repositories

**Processing:**
- Sort by `pushed_at` (most recent first)
- Take top 1
- Extract: commits, PRs, issues from last 24h
- Assess priority (high/medium/low)

**Output:**
```json
{
  "source": "github",
  "source_id": "github_activity_{{ repo_name }}",
  "title": "{{ repo_name }}: {{ summary }}",
  "url": "https://github.com/{{ owner }}/{{ repo }}",
  "content": "{{ commits + PRs + issues }}",
  "priority": "high",
  "tags": ["github", "repository"]
}
```

---

### Module 2: GitHub Releases

**Purpose:** New releases from watched repositories.

**Input:**
- Configuration: `system/config/watched-repositories.yaml` (loaded at runtime)
- Priority 1 repos: Playwright, n8n, WebdriverIO, Appium, TypeScript
- Priority 2 repos: React Native, Expo, Flutter

**Processing:**
- Fetch releases from last 24h (or last poll)
- Filter: Major + Minor versions (ignore patches unless security/critical)
- Check: Any breaking changes or migration guides?
- Assess priority (high if breaking, medium otherwise)

**Configuration Changes:**
- Edit `system/config/watched-repositories.yaml` in vault
- Commit to git
- Next workflow run automatically uses updated list
- **No workflow refactoring needed**

**Output:**
```json
{
  "source": "github_releases",
  "source_id": "github_release_{{ repo }}_{{ version }}",
  "title": "{{ repo }} {{ version }} released",
  "url": "{{ release_url }}",
  "content": "Release notes excerpt. Breaking changes: {{ list }}",
  "priority": "high|medium",
  "tags": ["release", "{{ repo }}"]
}
```

---

### Module 3: GitHub Trending

**Purpose:** Interesting new repos matching your interests.

**Input:**
- GitHub Trending API or web scraping
- Filter keywords: QA, testing, Playwright, automation, AI, DevOps, architecture

**Processing:**
- Fetch trending repos from last day
- Filter by keywords
- Assess relevance (high/medium/low)
- Check if already in dedup

**Output:**
```json
{
  "source": "github_trending",
  "source_id": "github_trending_{{ repo_owner }}/{{ repo }}",
  "title": "Trending: {{ repo }} — {{ description }}",
  "url": "https://github.com/{{ repo_owner }}/{{ repo }}",
  "content": "Stars: {{ stars }}. Language: {{ lang }}. Description: {{ desc }}",
  "priority": "medium|low",
  "tags": ["trending", "{{ repo_owner }}/{{ repo }}"]
}
```

---

### Module 4: Hacker News

**Purpose:** Engineering discussions, architecture, tooling.

**Input:**
- Hacker News top stories
- Configuration: `system/config/hacker-news-filter.yaml` (loaded at runtime)
- Filter keywords: QA, testing, automation, AI, DevOps, architecture, etc.

**Processing:**
- Fetch top 100 stories
- Filter by keywords from config
- Score by relevance (high/medium/low)
- Extract top comments (not just headline)
- Ignore startup/business/news unless directly engineering-relevant

**Configuration Changes:**
- Edit `system/config/hacker-news-filter.yaml` in vault
- Add/remove keywords as needed
- Commit to git
- Next workflow run automatically uses updated keywords
- **No workflow refactoring needed**

**Output:**
```json
{
  "source": "hacker_news",
  "source_id": "hacker_news_{{ url_hash }}",
  "title": "{{ story_title }}",
  "url": "{{ story_url or hn_link }}",
  "content": "{{ headline + top_comment_summary }}",
  "priority": "high|medium|low",
  "tags": ["hacker_news", "{{ extracted_topics }}"]
}
```

---

### Module 5: Reddit (Future)

Once API approved:

```json
{
  "source": "reddit",
  "source_id": "reddit_{{ post_id }}",
  "title": "{{ post_title }}",
  "url": "{{ post_url or reddit_link }}",
  "content": "{{ post_content + top_comment_summary }}",
  "priority": "high|medium|low",
  "tags": ["reddit", "{{ subreddit }}", "{{ extracted_topics }}"]
}
```

---

## Deduplication Rules

**Storage:** `paios/data/dedup.json`

**Format:**
```json
{
  "github_activity_repo-name": "2026-07-10T08:05:00Z",
  "github_release_playwright_v2.1.0": "2026-07-10T08:05:00Z",
  "hacker_news_abc123def456": "2026-07-10T08:05:00Z"
}
```

**On each run:**
1. Read dedup.json
2. Remove entries older than 7 days
3. Filter: Keep only items where `source_id not in dedup`
4. Process new items
5. Add new items to dedup with current timestamp
6. Write updated dedup.json

**Never deduplicate Claude output.**

---

## Claude Synthesis Prompt

**Input:** Array of normalized items (3–15 items)

**Task:**
- Merge into single coherent briefing
- Identify themes across sources
- Prioritize actionable insights
- Ignore noise (memes, benchmarks, opinion-only)
- Extract 3–5 high-value insights with [source] tags

**Output:** Markdown with structure:
```markdown
# Daily Brief — Fri 10.07

## 🔧 GitHub

[GitHub Activity] ...

---

## 📡 Tech Radar

### QA & Automation
[source_tag] Insight

### AI & Engineering  
[source_tag] Insight

### Architecture
[source_tag] Insight

---

Generated: {{ timestamp }}
```

---

## n8n Workflow Structure

```
Cron (08:05 Mon-Fri)
    ↓
[Parallel] Run all modules
    ├─ GitHub Activity Module
    ├─ GitHub Releases Module
    ├─ GitHub Trending Module
    └─ Hacker News Module
    ↓
[Merge] Combine outputs into single array
    ↓
[Normalize] Ensure all items match format
    ↓
[Dedup] Filter by source_id (7-day window)
    ↓
[Claude] Synthesize → 3–5 insights
    ↓
[Send] Telegram + Vault (daily/YYYY-MM-DD.md)
    ↓
[Update] dedup.json (cleanup + add new)
```

---

## Configuration as Code

All configurable aspects live in `system/config/` (in vault, git-backed).

**Pattern:**
1. Create YAML/JSON config file
2. n8n workflow loads config at runtime
3. Update config → no workflow changes needed
4. All changes auditable in git

**Current configs:**
- `watched-repositories.yaml` — GitHub Releases to monitor
- `hacker-news-filter.yaml` — HN keyword filter

**Future configs:**
- `subreddits.yaml` — Reddit subs (when approved)
- `google-calendar-config.yaml` — Calendar rules
- `notification-rules.yaml` — Alert thresholds

---

## Adding a New Source

To add Reddit (or any future source):

1. **Create config file:** `system/config/subreddits.yaml` (in vault)
2. **Create module:** Fetch Reddit posts, normalize to format
3. **Add to parallel step:** Include in `[Parallel] Run all modules`
4. **Update dedup:** Add Reddit source_id format
5. **No architecture changes required**

Users can update `subreddits.yaml` without touching the workflow.

---

## Implementation Order

**Phase 1 (This week):**
- GitHub Activity (already working in M2)
- GitHub Releases
- Hacker News
- Normalization layer
- Dedup layer
- Claude synthesis
- Test end-to-end

**Phase 2 (Next week):**
- GitHub Trending
- Refine filtering

**Phase 3 (Later):**
- Reddit (when approved)
- Weekly radar (separate workflow)

---

## Success Criteria

- ✅ All modules produce normalized items
- ✅ Dedup prevents duplicates (7-day window)
- ✅ Claude merges 4–5 sources into 3–5 insights
- ✅ Brief sent to Telegram
- ✅ Brief saved to vault
- ✅ Adding/removing source requires no architecture refactoring
- ✅ Workflow runs daily at 08:05 Mon-Fri
