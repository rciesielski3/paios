# M2: Adding Vault Integration & Scheduling

## Overview

Current workflow (working):
```
Manual Trigger → GitHub → Claude → Telegram ✅
```

Now add:
```
Manual Trigger → GitHub → Claude → Telegram → Write to Vault → Git Commit
```

And replace Manual Trigger with Cron for 07:30 weekdays.

---

## Step 1: Add Write to File Node

In n8n workflow editor:

1. **After "Send Telegram: Brief"** node, click **+** to add new node
2. Search for **"Write to File"**
3. Configure:
   - **File Path:** `=/Users/rafalciesielski/Developer/paios-vault/daily/{{ now().format('YYYY-MM-DD') }}.md`
   - **File Content:** 
     ```
     # {{ now().format('dddd, MMMM D, YYYY') }}

     ## 📋 Brief

     {{ $('Send Telegram: Brief').text }}

     ---

     ## 📝 Notes

     (Add your notes here)

     ---

     ## 🎯 Decisions

     (Record decisions here)
     ```

4. **Click "Execute Workflow"** to test

---

## Step 2: Add Git Commit (Optional but Recommended)

After Write to File:

1. Click **+** to add node
2. Search for **"Execute Command"**
3. Configure:
   ```bash
   cd /Users/rafalciesielski/Developer/paios-vault && \
   git add daily/{{ now().format('YYYY-MM-DD') }}.md && \
   git commit -m "Daily brief: {{ now().format('YYYY-MM-DD') }}"
   ```

4. Test by clicking Execute

---

## Step 3: Replace Manual Trigger with Cron

1. Click on **Manual Trigger** node
2. In right panel, click the trigger type dropdown
3. Change to **"Cron"**
4. Configure:
   - **Cron Expression:** `0 7 * * 1-5` (07:30 Monday-Friday)
   - Or use the cron builder UI to set: 7:30 AM, Mon-Fri

---

## Step 4: Test & Export

1. **Keep Manual Trigger active** for testing (don't delete it yet)
2. Click **Execute Workflow** manually
3. Verify:
   - ✅ Brief sent to Telegram
   - ✅ File created at `paios-vault/daily/YYYY-MM-DD.md`
   - ✅ Git commit created (check: `git log` in vault)

4. Once working, download workflow:
   - Click **...** → **Download**
   - Replace `paios/workflows/wf-daily-brief.json`

5. **Then activate the Cron trigger** (switch Manual Trigger off once you're confident)

---

## Notes

- **Timezone:** Adjust cron time if not UTC. Check n8n settings for timezone.
- **Vault auto-commit:** obsidian-git plugin will also auto-commit every 30 min, so manual git commits are redundant but don't hurt.
- **File overwrite:** If brief runs twice same day, it overwrites. That's fine — latest brief is what matters.

---

## Troubleshooting

**Git commit fails:**
- Make sure git is installed: `which git`
- Vault repo is initialized: `cd paios-vault && git status`

**File not created:**
- Check path is correct and directory exists
- Verify write permissions: `ls -la paios-vault/daily/`

**Cron not firing:**
- n8n server must be running 24/7
- Check n8n logs for errors: `docker compose logs n8n`

---

Once complete, M2 is fully done. Reply when exported!
