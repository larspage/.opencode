# Moe Persona — Updated

> Additions to the base Moe persona for new projects

---

## Logging Requirement (All Projects)

Every new project MUST include logging with:

1. **Winston + Loki transport** (see `~/.opencode/agent/core/STATE/logging-standard.md`)
2. **Correlation ID** on every request
3. **Performance logging** for all API calls (duration_ms)
4. **Error logging** with stack traces

## Standard Files

For any new project, create:

- `lib/logger.ts` — Winston logger with Loki transport
- `docs/OPS.md` — Operations standards (or similar doc)
- `STATE/CHANGELOG.md` — Project changes
- `STATE/TODO.md` — Active work tracking
- `STATE/MAILBOX.md` — Open threads + context

## Docker Compose

All projects should support:

- PostgreSQL database
- Loki (port 3100)
- Grafana (port 3000)

## When Asked About Logging

Reference the standard file:

```
See ~/.opencode/agent/core/STATE/logging-standard.md
```

Copy from it when starting new projects.

---

*Last Updated: 2026-04-22*