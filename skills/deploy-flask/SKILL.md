---
name: deploy-flask
description: Deploy Python Flask applications to the mrbrooks.biz DigitalOcean droplet (167.71.96.57). Covers rsync, venv setup, PM2 with Gunicorn, nginx reverse proxy, and Certbot SSL.
version: 1.0.0
author: moe
type: skill
category: deploy
tags:
  - deploy
  - flask
  - python
  - digitalocean
  - mrbrooks
  - nginx
  - pm2
  - gunicorn
  - certbot
---

# Deploy Flask App to DigitalOcean (mrbrooks.biz)

> **Purpose**: Deploy a Python Flask web application to the DigitalOcean droplet at `167.71.96.57` behind nginx with SSL on a `*.mrbrooks.biz` subdomain.

---

## Prerequisites

- SSH key at `~/.ssh/id_ed25519` authorized for `root@167.71.96.57`
- Target subdomain DNS A record pointing to `167.71.96.57` (add via DigitalOcean control panel → Networking → mrbrooks.biz)
- An unused port on the droplet (check existing: 3000, 3001, 3002, 3003, 5081)
- Flask app must have `pyproject.toml` or `requirements.txt` with `flask` and `gunicorn` declared

---

## Deploy Steps (6 steps total)

### Step 1: Prep the app locally

Ensure Flask and gunicorn are in dependencies:

```toml
# pyproject.toml
dependencies = [
    "flask>=2.3.0",
    "werkzeug>=2.3.0",
    "gunicorn>=21.2.0",
]
```

Or in `requirements.txt`:
```
flask>=2.3.0
werkzeug>=2.3.0
gunicorn>=21.2.0
```

### Step 2: Deploy files to server

```bash
rsync -av \
  --exclude='venv/' --exclude='.git/' --exclude='__pycache__/' \
  --exclude='.pytest_cache/' --exclude='*.pyc' \
  -e "ssh -i ~/.ssh/id_ed25519" \
  /path/to/project/ root@167.71.96.57:/var/www/<app-name>/
```

### Step 3: Set up venv and install deps

```bash
ssh -i ~/.ssh/id_ed25519 root@167.71.96.57 << 'CMDS'
  cd /var/www/<app-name>
  python3 -m venv venv
  source venv/bin/activate
  pip install -e .       # if using pyproject.toml
  pip install gunicorn   # if not in deps
CMDS
```

**Gotcha:** Ubuntu droplets may need `apt-get install -y python3.12-venv` first if `python3 -m venv` fails.

### Step 4: Start with PM2

Create a wrapper script on the server (PM2 doesn't handle venv Python paths well directly):

```bash
ssh -i ~/.ssh/id_ed25519 root@167.71.96.57 << 'CMDS'
  cat > /var/www/<app-name>/start.sh << 'SCRIPT'
#!/bin/bash
source /var/www/<app-name>/venv/bin/activate
exec gunicorn -w 1 --threads 2 -b 0.0.0.0:<PORT> <module>:app
SCRIPT
  chmod +x /var/www/<app-name>/start.sh
  pm2 start /var/www/<app-name>/start.sh --name <app-name>
  pm2 save
CMDS
```

**Key details:**
- Use `-w 1 --threads 2` for Flask apps with in-memory state (avoids shared-nothing between workers)
- PORT must be unused (check with `ss -tlnp`)
- Replace `<module>:app` with your Flask app's import path (e.g., `database_dependency_analyzer.web.app:app`)

### Step 5: Configure nginx

Create a local nginx config file:

```nginx
# analysistable.nginx.conf
server {
    server_name <subdomain>.mrbrooks.biz;
    location / {
        proxy_pass http://localhost:<PORT>;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# rsync to server and enable
rsync -av -e "ssh -i ~/.ssh/id_ed25519" \
  ./<config>.nginx.conf \
  root@167.71.96.57:/etc/nginx/sites-available/<subdomain>.mrbrooks.biz

ssh -i ~/.ssh/id_ed25519 root@167.71.96.57 \
  "ln -sf /etc/nginx/sites-available/<subdomain>.mrbrooks.biz /etc/nginx/sites-enabled/ && nginx -t && systemctl reload nginx"
```

### Step 6: Get SSL certificate

```bash
ssh -i ~/.ssh/id_ed25519 root@167.71.96.57 \
  "certbot --nginx -d <subdomain>.mrbrooks.biz --non-interactive --agree-tos --email <your-email>"
```

Certbot will:
- Modify the nginx config to add SSL listen directives
- Set up auto-renewal via systemd timer
- Add HTTP → HTTPS redirect

---

## Verification

```bash
# Check health endpoint (if available)
curl -s https://<subdomain>.mrbrooks.biz/health

# Check PM2 status
ssh -i ~/.ssh/id_ed25519 root@167.71.96.57 "pm2 list"

# Check nginx config
ssh -i ~/.ssh/id_ed25519 root@167.71.96.57 "nginx -t"
```

---

## Rollback

```bash
ssh -i ~/.ssh/id_ed25519 root@167.71.96.57 \
  "pm2 delete <app-name> && \
   rm -f /etc/nginx/sites-enabled/<subdomain>.mrbrooks.biz && \
   rm -f /etc/nginx/sites-available/<subdomain>.mrbrooks.biz && \
   systemctl reload nginx && \
   rm -rf /var/www/<app-name>"
```

---

## Troubleshooting

### PM2 runs with Node.js instead of Python
PM2 defaults to Node.js interpreter. Always use a shell wrapper script (`start.sh`) that `source`s the venv and `exec`s into the app. Point PM2 at the `.sh` file.

### ModuleNotFoundError for flask/gunicorn
The package must be installed inside the venv. Run `source venv/bin/activate && pip install -e .` or `pip install flask gunicorn`.

### Certbot fails: DNS problem
Must add an A record in DigitalOcean DNS first: `analysistable → 167.71.96.57`. Wait a minute for propagation.

### Port already in use
Run `ss -tlnp` to list listening ports. Pick the next available in the 3000+ range or a high port like 5081+.
