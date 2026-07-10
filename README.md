# PAIOS — Personal AI Operating System

A minimal, Docker-based decision-support assistant. Delivers daily briefs and monitors critical signals.

## Mission

By 08:00 every weekday, receive a brief (<5 min) that tells you:
- What deserves attention
- What can be ignored  
- What you should do today

## Architecture

```
GitHub ─┐
Reddit ─┤   n8n (orchestration)    ┌─► Telegram (decisions)
GCal  ─┼─► fetch→filter→rank ──────┤
       │   Claude + Gemini          └─► Obsidian Vault (archive)
Vault ◄─┘   state: n8n static data
```

## Quick Start

```bash
# Copy .env
cp .env.example .env
# Edit .env with actual credentials

# Start services
docker compose up -d

# Access n8n
open http://localhost:3333
```

## Structure

```
paios/
├── docker-compose.yml       # Infrastructure definition
├── .env.example            # Environment template (grows per milestone)
├── docker/                 # Dockerfiles
├── scripts/                # Operational scripts
├── workflows/              # n8n workflow exports
├── docs/                   # Documentation
├── data/                   # Persistent storage (postgres, n8n)
└── backups/                # Daily backups
```

## Milestones

- **M0**: Bootstrap (repos, docker-compose)
- **M1**: Telegram connectivity
- **M2**: Daily Brief MVP
- **M3**: Reddit Radar
- **M4**: Vault + Git + Backup
- **M5**: GitHub Intelligence
- **M6**: Weekly Review
- **M7**: Project Intelligence
- **M8**: VPS Migration Test

## Dependencies

- Docker + Docker Compose
- Telegram bot token
- Claude API key (M2+)
- GitHub token (M5+)

## Documentation

See `docs/` for detailed guides on setup, architecture, and operations.
