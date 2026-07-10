# M3a: Tech Radar (Daily)

## Mission

Extend Daily Brief with Reddit + Hacker News to surface 3–5 actionable insights that improve Senior QA Automation Engineer knowledge and decision-making.

---

## Data Sources

### Reddit (Daily)

**QA Subreddits:**
- r/QualityAssurance
- r/softwaretesting
- r/playwright
- r/Selenium
- r/webdriverio
- r/Appium

**AI Subreddits:**
- r/ClaudeAI
- r/OpenAI
- r/ChatGPT
- r/LocalLLaMA

**Automation & Engineering:**
- r/n8n
- r/selfhosted
- r/devops
- r/programming

Fetch: Top 24-hour posts per subreddit. Deduplicate by post ID across 7-day window.

### Hacker News (Daily)

Fetch: Top 100 stories. Filter for QA/AI/Automation/DevOps keywords. Deduplicate by URL across 7-day window.

### GitHub (Daily)

Fetch: All user repos. Select the single repo with the most recent activity. Filter: commits, PRs, issues in last 24h.

---

## Deduplication

**File:** `paios/data/dedup.json`

**Format:**
```json
{
  "reddit_post_id_1": "2026-07-10T08:05:00Z",
  "reddit_post_id_2": "2026-07-10T08:05:00Z",
  "hacker_news_url_hash": "2026-07-10T08:05:00Z",
  "github_event_id": "2026-07-10T08:05:00Z"
}
```

**Rules:**
- Store: Source ID (not AI hash) → timestamp
- On each run: Remove entries older than 7 days
- Filter: Don't process items already in dedup file
- Add: New items to dedup file after processing

**Implementation in n8n:**
- Read dedup.json at start
- Filter new items
- Process only new items
- Write updated dedup.json at end

---

## Daily Brief Structure

```markdown
# Daily Brief — Fri 10.07

## 🔧 GitHub

[GitHub] OCDP: 3 new commits, 1 PR opened (awaiting review)

---

## 📡 Tech Radar

### QA & Automation
[r/playwright] Playwright 2.1 released — breaking changes in X, migration guide available
[r/softwaretesting] Discussion: flaky tests in CI, 12 strategies shared

### AI & Engineering
[r/ClaudeAI] Claude MCP protocol — new capability for agent workflows
[Hacker News] Why fast feedback loops are underrated in engineering teams

---

Generated: 2026-07-10 08:05
Sources: 6 QA subs, 4 AI subs, 4 Eng subs, GitHub, HN
Filtered: 142 posts → 4 insights
```

---

## Claude Prompt (Filtering)

**Goal:** Extract 3–5 actionable insights. Ignore noise.

**Filter Rules:**
```
Prioritize:
- Production experience
- Architecture discussions
- Engineering trade-offs
- Testing patterns
- Automation techniques
- Real implementations
- Performance improvements

Ignore:
- Beginner tutorials
- Clickbait
- Memes
- Hype
- Generic career advice
- Opinion-only discussions
- "AI will replace developers"
- Benchmarks
```

**Output Format:**
```
[source] Insight (1–2 sentences, actionable)
```

**Discipline:** If fewer than 3 high-quality insights exist, send 1–2. Do not pad with low-quality items.

---

## Workflow Implementation

### n8n Nodes

```
Cron (08:05 Mon-Fri)
    ↓
[1] Read dedup.json
    ↓
[2] GitHub: Get top 1 active repo
    ↓
[3] Reddit: Fetch top posts (6 QA + 4 AI subs)
    ↓
[4] Hacker News: Fetch top stories + filter
    ↓
[5] Dedup Filter: Remove items in dedup.json
    ↓
[6] Claude: Synthesize 3–5 insights
    ↓
[7] Send Telegram
    ↓
[8] Write to Vault (daily/YYYY-MM-DD.md)
    ↓
[9] Update dedup.json
```

### Node Details

**[1] Read dedup.json**
- Type: Read File
- Path: `paios/data/dedup.json`
- Fallback: `{}` if file doesn't exist

**[2] GitHub**
- Type: GitHub node
- Operation: Get repos
- Filter: Sort by `pushed_at`, take top 1
- Extract: commits/PRs/issues from last 24h

**[3] Reddit**
- Type: HTTP Request (Reddit API) or Script
- Subreddits: 10 total (6 QA + 4 AI)
- Fetch: Top 10 posts per sub, 24-hour window
- Extract: Post ID, title, URL, score, subreddit

**[4] Hacker News**
- Type: HTTP Request (HN API)
- Fetch: Top 100 stories
- Filter: Keywords = "QA", "testing", "Playwright", "AI", "automation", "DevOps", "architecture"
- Extract: URL, title, score, author

**[5] Dedup Filter**
- Type: Script or Function
- Input: Dedup data + new items
- Output: Only items NOT in dedup (by ID/URL)

**[6] Claude**
- Type: Claude node (Anthropic)
- Model: claude-3-5-sonnet-20241022
- Prompt: (see prompt section above)
- Output: Markdown with [source] tags, 3–5 insights

**[7] Send Telegram**
- Type: Telegram node
- Format: Markdown (source tags preserved)

**[8] Write to Vault**
- Type: Write File
- Path: `/Users/rafalciesielski/Developer/paios-vault/daily/{{ now().format('YYYY-MM-DD') }}.md`
- Append: If file exists

**[9] Update dedup.json**
- Type: Write File
- Clean: Remove entries older than 7 days
- Add: New items processed with current timestamp

---

## Testing

1. **Manual execution:**
   - Click Execute
   - Verify: All 3 sources fetched
   - Verify: Dedup filtering works
   - Verify: Claude output has [source] tags
   - Verify: Telegram receives brief
   - Verify: daily/YYYY-MM-DD.md created

2. **Dedup verification:**
   - Run twice same day
   - Verify: Second run produces no duplicate items (or fewer if new posts)
   - Check dedup.json: Should have entries from both runs

3. **7-day cleanup:**
   - Manually test by adding old entries to dedup.json
   - Run workflow
   - Verify: Old entries removed

---

## M3a Definition of Done

- ✅ Workflow imports to n8n without errors
- ✅ All 3 sources (GitHub, Reddit, HN) fetch successfully
- ✅ Dedup filtering prevents duplicates within 7 days
- ✅ Claude produces 3–5 [source]-tagged insights
- ✅ Brief sent to Telegram
- ✅ Brief saved to vault daily/YYYY-MM-DD.md
- ✅ dedup.json auto-cleaned and updated
- ✅ Cron triggers daily at 08:05 Mon-Fri (after testing with manual trigger)
- ✅ Workflow exported to `workflows/wf-daily-brief-v2.json` (or updated existing)

---

## Notes

- **Reddit API:** May require API credentials (free tier available)
- **HN API:** Free, no auth required
- **Dedup size:** 7 days × ~50 items/day = ~350 entries max (tiny)
- **No Git commits:** Dedup.json is data, not committed (add to .gitignore)
- **Backup:** Dedup.json included in M4 backup strategy

---

## Next: M3b (Future)

- Add: Product Hunt, Releases, Expo blog
- Add: Weekly workflow (wf-weekly-radar, Sunday 09:00)
- Add: Business/EV subs to weekly only
