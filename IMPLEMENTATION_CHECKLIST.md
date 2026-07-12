# PAIOS Multi-Repository Implementation Checklist

## Repositories to Create

- [ ] **`paios`** (PUBLIC)
  - [ ] Push existing code with new README.md
  - [ ] Update .env.example with all variables
  - [ ] Verify docker-compose.yml mounts vault at ../paios-vault
  - [ ] GitHub: Create public repo, push code

- [ ] **`paios-vault-template`** (PUBLIC)
  - [ ] Create repo structure: system/config, system/prompts, daily
  - [ ] Add README.md and CUSTOMIZATION.md
  - [ ] Create example YAML files (.example suffix)
  - [ ] Create example prompt files (.example suffix)
  - [ ] GitHub: Create public repo, push template

- [ ] **`paios-docs`** (PUBLIC)
  - [ ] Create README.md (documentation index)
  - [ ] Create QUICKSTART.md (5-minute setup)
  - [ ] Create ARCHITECTURE.md (system design)
  - [ ] Create CONFIGURATION.md (vault reference)
  - [ ] Create TROUBLESHOOTING.md (FAQ)
  - [ ] Create CONTRIBUTING.md (how to extend)
  - [ ] Create ROADMAP.md (M5+ plans)
  - [ ] GitHub: Create public repo, push docs

- [ ] **`paios-vault`** (PRIVATE)
  - [ ] Create your own private vault repo
  - [ ] Clone paios-vault-template as reference
  - [ ] Customize configs with your data
  - [ ] Update paios/.env to point to your vault
  - [ ] GitHub: Create private repo (or self-hosted)

## Testing Checklist

- [ ] Clone paios, follow QUICKSTART.md
- [ ] Verify docker-compose up works
- [ ] Check n8n at http://localhost:3333
- [ ] Run workflow manually (wf-daily-brief)
- [ ] Verify Telegram notification received
- [ ] Verify vault file created in daily/
- [ ] Verify database has new rows
- [ ] Customize a config, verify next run uses new config

## Documentation Verification

- [ ] All links in paios/README.md work
- [ ] All links in paios-docs/README.md work
- [ ] No broken markdown syntax
- [ ] Code examples are runnable
- [ ] API keys not exposed in examples

## Privacy Verification

- [ ] No API keys in public repos
- [ ] No personal data in paios-vault-template
- [ ] No real configs in paios-vault-template (only examples)
- [ ] paios-vault is private
- [ ] .gitignore excludes .env files

## Before Publishing

- [ ] All repos tested locally
- [ ] All documentation reviewed
- [ ] License files added (Apache 2.0)
- [ ] Contributing guidelines clear
- [ ] Roadmap is realistic and helpful
- [ ] No broken links or typos

## After Publishing

- [ ] Add topics to GitHub repos (paios, n8n, docker, ai, etc.)
- [ ] Add description to each repo
- [ ] Set up GitHub Issues and Discussions
- [ ] Pin QUICKSTART.md in paios README
- [ ] Share on appropriate forums (n8n, GitHub topics)
