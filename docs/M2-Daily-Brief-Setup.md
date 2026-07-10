# M2: Daily Brief MVP

## Overview

Every weekday at 07:30, you get a Telegram message with what matters today:
- Your GitHub activity (PRs to review, CI status, recent commits)
- Synthesized into a brief by Claude
- Archived to vault for history

## Components

### 1. Get API Keys

**Claude API Key:**
- Go to https://console.anthropic.com/
- Create/view API key
- Add to .env: `CLAUDE_API_KEY=sk-...`

**GitHub Personal Access Token:**
- Go to https://github.com/settings/tokens
- Create new token → "Tokens (classic)"
- Scopes: `repo`, `read:user`
- Add to .env: `GITHUB_TOKEN=ghp_...`

### 2. Workflow Structure

```
Manual Trigger (for testing)
    ↓
GitHub Node: Get user repos + recent activity
    ↓
GitHub Node: Check CI status
    ↓
Claude Node: Synthesize into brief
    ↓
Telegram Node: Send brief
    ↓
Vault Node: Save to daily/YYYY-MM-DD.md
```

**For scheduling:** After M2 is working, add Cron trigger for 07:30 weekdays.

### 3. Prompts

**System Prompt** (in `system/prompts/daily-brief.md`):
- Keep to <500 tokens
- Format as 5-min read
- Focus on actionable items

**Format Expected:**
```
📋 Brief — Fri 10.07

⚡ ACTION (0–3 items)
• PR #42 (OCDP) awaiting your review
• CI red on main — last build failed 2h ago

📌 CHANGED
• Unpeeky: 3 new commits

👀 WORTH ATTENTION (≤2)
• GitHub release: Playwright 2.1 released

🗑 IGNORED: 15 commits, 8 issues, 3 releases (filtered)
```

## Testing

1. Create workflow in n8n
2. Configure GitHub and Claude credentials
3. Click "Execute Workflow"
4. Verify:
   - Telegram receives brief
   - Vault note created with brief + your daily notes
5. Export JSON to `workflows/wf-daily-brief.json`

## Automation (After Testing)

Add Cron trigger:
- Time: 07:30
- Days: Mon-Fri
- Timezone: Your timezone

## Next Milestones

- M3: Reddit Radar (adds reddit filtering)
- M4: Vault setup (obsidian-git, backups)
- M5: GitHub Intelligence (dependency watching)
