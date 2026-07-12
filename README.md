# PAIOS: Personal AI Operating System

A lightweight, self-hosted framework for synthesizing daily insights and making better decisions. PAIOS integrates news sources, calendars, and repositories into unified daily briefs delivered to your preferred channel. Built with n8n workflows, PostgreSQL, and Claude AI.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Data Sources: GitHub, Reddit, News APIs, Google Calendar   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  n8n Orchestration Platform    │
        │  (M1-M4 Workflows)             │
        │  • Filter & Rank (Claude)      │
        │  • Synthesize & Summarize      │
        │  • Generate Recommendations    │
        └────────────────┬───────────────┘
                         │
        ┌────────────────┴──────────────────┐
        │                                   │
        ▼                                   ▼
    ┌─────────────┐           ┌──────────────────────┐
    │  PostgreSQL │           │  Vault (Git-backed)  │
    │  Database   │           │  • Configs           │
    │  • History  │           │  • Prompts           │
    │  • State    │           │  • Knowledge Graph   │
    └─────────────┘           └──────────────────────┘
        │                                   │
        └────────────────┬──────────────────┘
                         │
        ┌────────────────┴──────────────────┐
        │                                   │
        ▼                                   ▼
    ┌──────────────┐          ┌──────────────────┐
    │  Telegram    │          │  Obsidian Vault  │
    │  Notification│          │  Archive & Notes │
    └──────────────┘          └──────────────────┘
```

## Features (M1-M4)

- **M1: Telegram Integration** — Send notifications to Telegram bot; subscribe to daily briefs
- **M2: Daily Brief MVP** — Synthesize GitHub activity, news, and calendar into concise daily summaries
- **M3: Tech Radar** — Monitor tech trends, Reddit discussions, Hacker News; rank by relevance
- **M4: Knowledge Layer** — Git-backed configuration, prompt management, and historical context

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/your-github-username/paios.git
cd paios
```

### 2. Configure Environment Variables
```bash
cp .env.example .env
# Edit .env with your API credentials (Telegram bot token, Claude API key, etc.)
nano .env
```

### 3. Mount Your Private Vault (Optional but Recommended)
```bash
# Clone your private paios-vault repository (or create one)
cd ..
git clone git@github.com:your-github-username/paios-vault.git  # or your private repo
# Update docker-compose.yml to reference your vault location
```

### 4. Start the Services
```bash
cd paios
docker compose up -d
```

### 5. Verify Setup
```bash
# Check that n8n is running
curl http://localhost:3333
# Access n8n UI in browser: http://localhost:3333
```

## Configuration

### Environment Variables
All configuration is controlled via `.env`. See `.env.example` for all available options.

### Private Vault Setup
To use custom configurations and prompts:

1. Create a private `paios-vault` repository (see [paios-vault-template](https://github.com/your-github-username/paios-vault-template) for structure)
2. Mount it in `docker-compose.yml`:
   ```yaml
   volumes:
     - /path/to/paios-vault:/vault:ro
   ```
3. Update `.env` with `VAULT_PATH=/vault`

### Workflow Customization
Edit workflow files in `workflows/` directory or use the n8n UI to customize filters, prompts, and outputs.

## Repository Structure

| Directory | Purpose |
|-----------|---------|
| `docker-compose.yml` | Infrastructure orchestration (n8n, PostgreSQL) |
| `.env.example` | Environment variable template |
| `workflows/` | n8n workflow exports (M1-M4 features) |
| `data/` | Persistent storage (PostgreSQL, n8n data) |
| `data/migrations/` | Database schema and initialization scripts |
| `system/queries/` | SQL query templates used by workflows |
| `docker/` | Dockerfile definitions |
| `scripts/` | Operational and deployment scripts |
| `docs/` | Detailed documentation and guides |

## Documentation

See [paios-docs](https://github.com/your-github-username/paios-docs) for complete guides:

- **[QUICKSTART](https://github.com/your-github-username/paios-docs/blob/main/QUICKSTART.md)** — 5-minute setup
- **[ARCHITECTURE](https://github.com/your-github-username/paios-docs/blob/main/ARCHITECTURE.md)** — System design
- **[CONFIGURATION](https://github.com/your-github-username/paios-docs/blob/main/CONFIGURATION.md)** — Vault setup
- **[TROUBLESHOOTING](https://github.com/your-github-username/paios-docs/blob/main/TROUBLESHOOTING.md)** — FAQ & fixes
- **[CONTRIBUTING](https://github.com/your-github-username/paios-docs/blob/main/CONTRIBUTING.md)** — Extend PAIOS

## System Requirements

- Docker & Docker Compose (v1.29+)
- 2GB RAM minimum (4GB+ recommended)
- Disk space: 10GB for PostgreSQL and n8n data
- Network: Outbound access to GitHub, Reddit, news APIs

## API Keys Required

- **Telegram:** Bot token (get from [BotFather](https://t.me/botfather))
- **Claude:** API key from [Anthropic Console](https://console.anthropic.com)
- **Optional:** GitHub token (personal access token), Reddit API credentials, HackerNews access

## Troubleshooting

### n8n not accessible
```bash
# Check if services are running
docker compose ps

# View logs
docker compose logs n8n
```

### Database connection errors
```bash
# Verify PostgreSQL is running
docker compose logs postgres

# Reset database (caution: destroys data)
rm -rf data/postgres && docker compose up -d postgres
```

### Vault not loading
Ensure `VAULT_PATH` in `.env` matches the mounted path, and the vault directory is readable.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Submit a pull request with a clear description

See [CONTRIBUTING.md](https://github.com/rciesielski3/paios-docs/blob/main/CONTRIBUTING.md) for detailed guidelines.

## License

PAIOS is released under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Roadmap

- **M5:** GitHub Intelligence (detailed repository analysis)
- **M6:** Weekly Review (aggregated weekly summary)
- **M7:** Project Intelligence (cross-repository insights)
- **M8:** VPS Migration (cloud deployment guide)

## Related Repositories

- [paios-vault-template](https://github.com/your-github-username/paios-vault-template) — Configuration templates and examples
- [paios-docs](https://github.com/your-github-username/paios-docs) — Extended documentation and guides

## Support

For issues, questions, or feature requests, please open an [issue on GitHub](https://github.com/your-github-username/paios/issues).

---

**Last Updated:** 2026-07-12
