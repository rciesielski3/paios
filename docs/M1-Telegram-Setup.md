# M1: Telegram Integration Setup

## Prerequisites

- n8n running at http://localhost:3333
- Telegram bot token (from @BotFather)
- Your Telegram Chat ID (from @userinfobot)

## Import Workflow

### Option 1: Import JSON (Recommended)

1. Open n8n at http://localhost:3333
2. Click **+** (New Workflow)
3. Click the **...** menu → **Import from File**
4. Select `workflows/wf-alive.json`
5. Click **Import**

### Option 2: Manual Setup

If import doesn't work, build manually:

1. **Create new workflow:** Click **+** → Name it "PAIOS Alive"

2. **Add Manual Trigger:**
   - Click **+** to add a node
   - Search for "Manual Trigger"
   - Add it (no configuration needed)

3. **Add Send Telegram Message:**
   - Click **+** to add a node
   - Search for "Telegram"
   - Select "Send a message"
   - Connect it after Manual Trigger

4. **Configure Telegram node:**
   - **Authentication:** Select "Bot Token"
   - **Bot Token:** Paste your token or reference env: `{{ $processEnv.TELEGRAM_BOT_TOKEN }}`
   - **Chat ID:** Your chat ID or reference env: `{{ $processEnv.TELEGRAM_CHAT_ID }}`
   - **Text:** 
     ```
     ✅ PAIOS is alive!
     
     System is running and ready to process workflows.
     ```
   - **Parse Mode:** Markdown

## Test the Workflow

1. Click **Execute Workflow** or **Manual Trigger**
2. Check your Telegram — you should receive the message immediately
3. If it works, click **Save** and then **Activate**

## Troubleshooting

**Message not received:**
- Verify bot token is correct
- Verify chat ID is correct (must be your private chat, not a group)
- Check n8n logs: `docker compose logs n8n`

**Token error:**
- Make sure .env variables are loaded
- Restart n8n: `docker compose restart n8n`

## Next Steps

Once this workflow works, M1 is complete. The "PAIOS Alive" workflow proves:
- ✅ n8n is running
- ✅ Telegram integration works
- ✅ Environment variables are accessible

Commit and proceed to M2 (Daily Brief MVP).
