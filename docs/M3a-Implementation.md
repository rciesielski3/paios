# M3a: Tech Radar Implementation Guide

## Goal

Update existing `wf-daily-brief` workflow to include GitHub Releases + Hacker News.

**Output:** One consolidated Daily Brief with 3–5 engineering insights.

---

## Workflow Structure

```
Cron (08:05 Mon-Fri)
    ↓
[Parallel] Execute all source adapters
├─ Adapter: GitHub Activity
├─ Adapter: GitHub Releases
└─ Adapter: Hacker News
    ↓
[Merge] Combine all normalized items
    ↓
[Dedup] Load dedup.json → Filter duplicates
    ↓
[Claude] Synthesize 3–5 insights
    ↓
[Output] Telegram + Vault (daily/YYYY-MM-DD.md)
    ↓
[Cleanup] Update dedup.json (remove 7-day-old, add new)
```

---

## Source Adapters

### Adapter: GitHub Activity

**Purpose:** Top 1 most active repository.

**Output (Normalized JSON):**
```json
{
  "source": "github_activity",
  "source_id": "github_activity_{{ repo_name }}",
  "title": "{{ repo_name }}: {{ activity_summary }}",
  "url": "https://github.com/{{ owner }}/{{ repo }}",
  "content": "{{ commits + prs + issues in last 24h }}",
  "priority": "high",
  "tags": ["github", "repository"]
}
```

**Keep current implementation.** Very simple.

---

### Adapter: GitHub Releases

**Purpose:** Latest releases from monitored repositories.

**Data Source:**
```
system/config/watched-repositories.yaml
→ github_releases.priority_1
→ [microsoft/playwright, n8n-io/n8n, webdriverio/webdriverio, appium/appium, microsoft/typescript]
```

**Processing:**
1. Load `watched-repositories.yaml` from vault
2. For each Priority 1 repository:
   - Fetch latest release
   - Skip if patch release (unless security/critical tag)
   - Extract: title, tag, release notes URL, breaking changes
3. Normalize each to JSON

**Output (Normalized JSON):**
```json
{
  "source": "github_releases",
  "source_id": "github_release_{{ repo }}_{{ version_tag }}",
  "title": "{{ repo }} {{ version }} released",
  "url": "{{ release_url }}",
  "content": "{{ release_notes_excerpt }}. Breaking changes: {{ list if any }}",
  "priority": "high",
  "tags": ["release", "{{ repo_name }}"]
}
```

**Do not interpret** release notes. Pass raw information to Claude.

---

### Adapter: Hacker News

**Purpose:** Top stories matching engineering interests.

**Data Source:**
```
system/config/hacker-news-filter.yaml
→ keywords
→ [qa, testing, automation, playwright, ai, llm, agent, architecture, devops, ci/cd, docker, postgres, n8n, ...]
```

**Processing:**
1. Load `hacker-news-filter.yaml` from vault
2. Fetch HN top 100 stories (free API, no auth)
3. Filter: Keep stories matching any keyword
4. Normalize each to JSON

**Output (Normalized JSON):**
```json
{
  "source": "hacker_news",
  "source_id": "hacker_news_{{ url_hash }}",
  "title": "{{ story_title }}",
  "url": "{{ story_url }}",
  "content": "{{ title + score }}",
  "priority": "medium",
  "tags": ["hacker_news", "{{ extracted_topic }}"]
}
```

**Do not fetch comments** during M3a. Comments can be added later.

---

## Normalization Contract

Every adapter must output this JSON structure:

```json
{
  "source": "string (github_activity | github_releases | hacker_news | reddit)",
  "source_id": "string (unique per source, never duplicates)",
  "title": "string (human readable title)",
  "url": "string (link to original)",
  "content": "string (summary or raw content)",
  "priority": "string (high | medium | low)",
  "tags": ["array", "of", "strings"]
}
```

**This contract is stable and never changes.**

---

## Merge Step

Combine all normalized items from all adapters into single array:

```json
[
  { "source": "github_activity", ... },
  { "source": "github_releases", ... },
  { "source": "hacker_news", ... },
  { "source": "hacker_news", ... }
]
```

Pass this single array to dedup filter.

---

## Deduplication

**Workflow:**
1. Load `paios/data/dedup.json`
2. For each item in merged array:
   - If `source_id` in dedup: discard (already processed)
   - If not in dedup: keep
3. Remove entries in dedup older than 7 days
4. Pass filtered array to Claude
5. After Claude: Add all processed `source_id` to dedup with current timestamp
6. Save updated dedup.json

**Storage:** `paios/data/dedup.json`

**Format:**
```json
{
  "github_activity_repo-name": "2026-07-10T08:05:00Z",
  "github_release_playwright_v2.1.0": "2026-07-10T08:05:00Z",
  "hacker_news_abc123": "2026-07-10T08:05:00Z"
}
```

---

## Claude Synthesis

**Input:** Deduplicated normalized JSON array (3–10 items)

**Task:**
- Read `system/prompts/tech-radar-daily.md` for filtering rules
- Synthesize into 3–5 actionable engineering insights
- Include [source] tags (e.g., [GitHub Release], [Hacker News])
- Explain why each insight matters

**Output (Markdown):**
```markdown
# Daily Brief — Fri 10.07

## 🔧 GitHub

[GitHub Activity] repo-name: activity summary

---

## 📡 Tech Radar

### QA & Automation
[GitHub Release] Playwright 2.1 released — breaking changes in X. Why it matters: ...

### AI & Engineering
[Hacker News] Discussion on test automation patterns. Why it matters: ...

---

Generated: 2026-07-10 08:05
```

---

## Output

**Telegram:**
- Send formatted markdown brief

**Vault:**
- Write to: `paios-vault/daily/YYYY-MM-DD.md`
- Append if file exists (for manual notes)

---

## Configuration Files

**Already created:**
- `system/config/watched-repositories.yaml` — GitHub repos (Priority 1)
- `system/config/hacker-news-filter.yaml` — Keywords
- `system/prompts/tech-radar-daily.md` — Claude prompt

**To update them later:** Edit, commit to git. Next run uses updated config automatically.

---

## n8n Implementation Steps

### Step 1: Prepare
- [ ] Open existing `wf-daily-brief` workflow
- [ ] Rename last node to clarify flow (optional)
- [ ] Note: Keep Manual Trigger for testing

### Step 2: Add GitHub Releases Adapter
- [ ] Add HTTP Request node (GitHub API)
- [ ] Load watched-repositories.yaml from vault mount
- [ ] Fetch latest release from each Priority 1 repo
- [ ] Normalize output to JSON
- [ ] Connect to Merge node

### Step 3: Add Hacker News Adapter
- [ ] Add HTTP Request node (Hacker News API)
- [ ] Load hacker-news-filter.yaml from vault mount
- [ ] Fetch top 100 stories + filter by keywords
- [ ] Normalize output to JSON
- [ ] Connect to Merge node

### Step 4: Add Merge Node
- [ ] Combine all adapter outputs into single array
- [ ] Verify structure (all items have required fields)
- [ ] Pass to Dedup node

### Step 5: Add Dedup Node
- [ ] Read dedup.json
- [ ] Filter: Remove items already in dedup
- [ ] Remove 7-day-old entries
- [ ] Pass filtered array to Claude

### Step 6: Update Claude Node
- [ ] Input: Filtered normalized array
- [ ] Prompt: Load from system/prompts/tech-radar-daily.md
- [ ] Output: Markdown brief with [source] tags

### Step 7: Add Cleanup Node
- [ ] After output (Telegram + Vault)
- [ ] Update dedup.json
- [ ] Add processed source_ids with timestamp
- [ ] Save file

### Step 8: Test & Export
- [ ] Click Execute Workflow (manual trigger)
- [ ] Verify: All adapters work
- [ ] Verify: Dedup prevents duplicates (run twice)
- [ ] Verify: Claude output has [source] tags
- [ ] Verify: Telegram receives brief
- [ ] Verify: Vault file created
- [ ] Verify: dedup.json updated
- [ ] Export workflow JSON
- [ ] Replace existing `wf-daily-brief.json`

---

## Acceptance Criteria

- ✅ Workflow updates existing `wf-daily-brief` (no new files)
- ✅ GitHub Activity adapter outputs normalized JSON
- ✅ GitHub Releases adapter loads config, fetches releases, outputs JSON
- ✅ Hacker News adapter loads config, filters keywords, outputs JSON
- ✅ All items merge into single array
- ✅ Dedup prevents duplicates (7-day window)
- ✅ Claude receives deduplicated array
- ✅ Claude outputs 3–5 [source]-tagged insights
- ✅ Telegram receives formatted brief
- ✅ Vault saves to daily/YYYY-MM-DD.md
- ✅ dedup.json created/updated
- ✅ Cron ready (after testing with manual trigger)
- ✅ Workflow exported to `workflows/wf-daily-brief.json`

---

## Key Principles to Remember

1. **Independent adapters:** Each source is standalone
2. **Stable contract:** Normalized JSON never changes
3. **Configuration as code:** All lists/keywords in vault YAML
4. **One synthesis:** Claude receives single payload
5. **No complexity:** Don't interpret; pass raw to Claude
6. **Quality over quantity:** 3–5 insights max
7. **Decision support:** Not a news aggregator
