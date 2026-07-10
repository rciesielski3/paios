# M2: Monthly Summary Generation

## Overview

After daily briefs accumulate for a month, synthesize them into a **Monthly Brief** that captures:
- Key themes
- Patterns (what got blocked, what shipped, what stayed constant)
- One-liner recommendations for next month

**Trigger:** First day of month at 08:00 (after daily brief at 07:30)

**Output:** 
- `monthly/YYYY-MM-summary.md` (3–5 min read)
- Saved to vault for review during Weekly Review (M6)

---

## Workflow: wf-monthly-summary

**Trigger:** Cron 08:00 on 1st of month (only)

**Steps:**
1. **Collect:** Read all `daily/YYYY-MM-*.md` files from previous month
2. **Parse:** Extract ACTION + CHANGED + WORTH ATTENTION sections
3. **Claude:** Synthesize into themes (what moved, what's blocked, patterns)
4. **Save:** Write to `monthly/YYYY-MM-summary.md`
5. **Vault:** Commit to vault repo

**Cron:** `0 8 1 * *` (08:00 on 1st of every month)

---

## Monthly Summary Format

```markdown
# Month Summary — July 2026

## 🎯 Key Themes

- **Blocked:** What didn't move and why (2–3 bullets)
- **Shipped:** What completed (2–3 bullets)
- **Pattern:** Repeating signal (e.g., "CI flaky on Mondays", "Redis timeouts before 10am")

## 📊 By the Numbers

- Total briefs: 22 (22 weekdays)
- Key repos with activity: 3–5 (list)
- Most-mentioned issue: X (brief description)

## 🔮 Next Month Signals

- Watch out for: X (based on trends)
- Opportunity: Y (based on patterns)
- Unblock: Z (specific action)

---

**Generated:** 2026-08-01 08:00  
**Based on:** daily/2026-07-*.md (22 briefs)
```

---

## Implementation

### Node Structure

```
Cron (1st month, 08:00)
  ↓
Script: Collect all daily files from previous month
  ↓
Read Files: Load each daily/YYYY-MM-*.md
  ↓
Claude: Synthesize themes + patterns
  ↓
Write File: Save to monthly/YYYY-MM-summary.md
  ↓
Git Commit: Commit to vault
  ↓
Telegram: Notify (optional: "Monthly summary ready")
```

### Cron Expression

```
0 8 1 * *
```

(08:00 UTC on the 1st day of every month)

---

## Notes

- **No deletion:** Keep all daily briefs in git. They're part of audit trail.
- **Summary is standalone:** Review during M6 (Weekly Review) or read manually.
- **Monthly pattern detection:** First few months will be sparse. By month 3+, real themes emerge.

---

## Timeline

- **After M2 is stable:** Implement monthly summary (can be part of M2 or separate M2.5)
- **Test:** Run manually first, then schedule cron

---

## Future: Archive Strategy (M10+)

Once vault has 6+ months of briefs:
- Compress old months (gzip `monthly/YYYY-MM-summary.md`)
- Keep daily briefs indexed by month
- Search by date range in Obsidian Dataview

For now: keep everything, organize by month.
