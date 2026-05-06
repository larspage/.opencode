# Logging Standard — Quick Reference

> Winston + Loki + Grafana setup for all projects

---

## Install

```bash
npm install winston winston-loki
```

## Core File (`lib/logger.ts`)

```typescript
import winston from 'winston'
import Loki from 'winston-loki'

const lokiUrl = process.env.LOKI_URL || 'http://localhost:3100'
const logLevel = process.env.LOG_LEVEL || 'info'

export const logger = winston.createLogger({
  level: logLevel,
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'my-app', environment: process.env.NODE_ENV },
  transports: [
    new winston.transports.Console({ format: winston.format.colorize() }),
    new Loki({ host: lokiUrl, labels: { service: 'my-app' }, json: true, frequency: 5000 }),
  ],
})

export function logPerformance({ endpoint, method, duration_ms, correlationId }) {
  logger.info(`${method} ${endpoint} completed`, { endpoint, method, duration_ms, correlationId })
}

export function logError(msg, meta) { logger.error(msg, meta) }

export function createLogger(context: Record<string, unknown>) {
  return logger.child(context)
}
```

## Docker Compose

```yaml
services:
  my-app:
    build: .
    environment:
      - LOKI_URL=http://loki:3100
      - LOG_LEVEL=info
    depends_on: [loki]

  loki:
    image: grafana/loki:3.2
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml

  grafana:
    image: grafana/grafana:11
    ports:
      - "3000:3000"
    environment:
      - GF_AUTH_ANONYMOUS_ENABLED=true
    depends_on: [loki]
```

## Usage in API Routes

```typescript
import { logger, logPerformance } from './lib/logger'

// Start of request
router.use((req, res, next) => {
  req.correlationId = req.headers['x-correlation-id'] as string || crypto.randomUUID()
  next()
})

// After request
router.get('/api/users', async (req, res) => {
  const start = Date.now()
  try {
    const users = await getUsers()
    logPerformance({ endpoint: '/api/users', method: 'GET', duration_ms: Date.now() - start, correlationId: req.correlationId })
    res.json(users)
  } catch (err) {
    logger.error('Failed to get users', { error: err.message, correlationId: req.correlationId })
    res.status(500).json({ error: 'Internal error' })
  }
})
```

## Log Levels

| Level | When |
|-------|------|
| debug | Detailed flow (dev only) |
| info | Operations, performance |
| warn | Rate limits, retries |
| error | Exceptions, failures |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| LOKI_URL | http://localhost:3100 | Loki server URL |
| LOG_LEVEL | info | Log level (debug, info, warn, error) |

## Grafana Dashboard

- URL: http://localhost:3000
- Query logs: `{service="my-app"}`
- Alert thresholds:
  - Warning: > 1000ms response
  - Error: > 5000ms response

## Best Practices

1. **Always log:** correlationId, duration_ms, endpoint, method
2. **JSON format:** Enables Grafana parsing
3. **Both transports:** Console (dev) + Loki (prod)
4. **Set alerts:** Response time thresholds
5. **Track correlation ID:** Pass through all requests

---

*Last Updated: 2026-04-22*
*Standard for all projects under larspage*