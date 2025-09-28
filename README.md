# AI for Science — Full‑Stack Template (FastAPI + Next.js + Docker)

A production‑ready template for building AI‑powered research/education tools. It pairs **FastAPI** (Python) with **Next.js 15 (React 18)**, ships with **Docker Compose**, and is engineered to sit cleanly behind a reverse proxy (e.g., **Plesk/nginx**, Caddy, Traefik).

---

## ✨ Highlights

- **FastAPI** backend with sensible defaults (timeouts, JSON errors, Redis)
- **Next.js 15** frontend, basePath‑aware to run under a subpath (e.g. `/ai-for-science`)
- **Docker Compose** with a clean **base** and **override** split (portable + host‑specific)
- Loopback‑only ports (`127.0.0.1`) → safe by default; reverse proxy terminates TLS
- Path‑based routing for both UI and API
- Flexible `deploy.sh` helper for CLI‑first ops
- Ready for CI (Actions), Dependabot, and docs

---

## 📦 Repository Layout

```
ai-for-science-template/
├─ backend/                     # FastAPI service
│  ├─ app/                      # your API code
│  ├─ tests/                    # pytest tests (optional)
│  └─ requirements.txt
├─ frontend/                    # Next.js 15 + React 18
│  ├─ next.config.ts            # basePath via env
│  └─ Dockerfile                # multi-stage, Node 20
├─ docker-compose.yml           # base compose (no public ports)
├─ docker-compose.override.yml  # loopback ports for reverse proxy
├─ deploy.sh                    # flexible CLI helper
├─ .env.example                 # sample env
├─ docs/                        # deployment & operations guides
└─ README.md
```

---

## 🧭 Naming & Initialization

This repo ships as **`ai-for-science-template`**. After you create your own repo from it, we recommend renaming the folder to **`ai-for-science`** for clarity.

```bash
# from the parent directory
mv ai-for-science-template ai-for-science
cd ai-for-science
```

Alternatively, if you keep the template folder name, you can still ensure stable Compose names by pinning the project name in `.env`:

```env
COMPOSE_PROJECT_NAME=ai-for-science
```

> Why: Docker Compose defaults the project name to the folder name. Pinning it keeps container/volume names stable across renames.

---

## 🔧 Requirements

- Docker Engine + Docker Compose plugin (v2+)
- Node.js 20 (for local non‑Docker builds) — optional
- Python 3.11+ (for local non‑Docker runs) — optional

---

## ⚙️ Configuration

Copy the sample env and edit the values:

```bash
cp .env.example .env
```

`.env` keys (used by Compose and builds):

```env
# Public domain (no scheme)
DOMAIN=yourdomain.tld

# Subpath where the app is served (UI + API under this prefix)
BASE_PATH=/ai-for-science

# Public API URL baked into the frontend at build time
NEXT_PUBLIC_API_URL=https://api.${DOMAIN}${BASE_PATH}

# Optional but recommended for stable Compose names
COMPOSE_PROJECT_NAME=ai-for-science
```

> The backend also reads `API_ROOT_PATH` from Compose (set to `${BASE_PATH}`) so API routes live under the same subpath.

---

## 🐳 Compose Files (Why two?)

- **`docker-compose.yml`** — Portable **base**: services, networks, volumes, env. **No host ports** exposed.
- **`docker-compose.override.yml`** — Host‑specific **override**: loopback port bindings for reverse proxy.

This split keeps the base safe and reusable across environments; the override captures only machine‑specific tweaks.

To run with both (recommended):

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d --build
```

To generate a flattened snapshot:

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml config > docker-compose.final.yml
```

---

## 🚀 Quick Start

```bash
# 1) Clone your newly created repo from this template
git clone git@github.com:<your-org>/<your-repo>.git
cd <your-repo>

# 2) Configure env
cp .env.example .env
# edit .env with your DOMAIN / BASE_PATH

# 3) Start stack (base + override)
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d --build

# 4) Status & logs
docker compose -f docker-compose.yml -f docker-compose.override.yml ps
docker compose -f docker-compose.yml -f docker-compose.override.yml logs -f backend
docker compose -f docker-compose.yml -f docker-compose.override.yml logs -f frontend
```

### Health Checks

Local (bypass proxy):
```bash
curl -sS http://127.0.0.1:8001/api/v1/healthz
curl -I  http://127.0.0.1:3001${BASE_PATH}/
```

Public (through your reverse proxy/TLS):
```bash
curl -sS https://api.${DOMAIN}${BASE_PATH}/api/v1/healthz
curl -I  https://${DOMAIN}${BASE_PATH}/
```

---

## 🧩 Reverse Proxy Examples (nginx / Plesk)

**UI on `https://<domain>/<base_path>/`**

```nginx
location = /<base_path> { return 301 /<base_path>/; }
location ^~ /<base_path>/ {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

**API on `https://api.<domain>/<base_path>`**

```nginx
location ^~ /<base_path>/ {
    proxy_pass http://127.0.0.1:8001;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

> Issue TLS certificates (e.g., Let’s Encrypt) for both domains. Ensure container ports are **loopback‑only** (as in the override) so nothing is publicly exposed.

---

## 🛠️ `deploy.sh` — Flexible CLI Helper

A small wrapper to simplify common operations. Examples:

```bash
./deploy.sh up --build                    # start or redeploy all
./deploy.sh build --no-cache frontend     # rebuild frontend image from scratch
./deploy.sh up frontend                   # restart only frontend
./deploy.sh logs -f backend               # follow backend logs
./deploy.sh check all                     # local + public health checks
./deploy.sh prune images                  # safe cleanup of unused images
```

Use `./deploy.sh -h` for all commands & flags.

---

## 🧪 Testing & CI

- **Backend**: add `pytest` tests under `backend/tests/`, run in CI.
- **Linters/Typecheck**: recommended `ruff` + `mypy` for Python, ESLint + TS for frontend.
- **GitHub Actions**: see `.github/workflows/ci.yml` example to build/test on PRs.

---

## 🔒 Security Defaults

- No public container ports; nginx/Caddy/Traefik terminates TLS and proxies to loopback.
- Add rate limiting/auth before exposing write endpoints.
- Prefer managed databases for production (swap SQLite for Postgres/Azure SQL).

---

## 🧱 Architecture (at a glance)

```
[ Browser ]
    │
    │  HTTPS
    ▼
[ Reverse Proxy (nginx/Plesk) ]
    ├─ /<base_path>/           → 127.0.0.1:3001 (frontend)
    └─ api.<domain>/<base_path>→ 127.0.0.1:8001 (backend)
                                     │
                                     └─ redis://redis:6379/0
```

---

## 🩺 Troubleshooting

- **404 at `/<base_path>`** → Rebuild frontend with the correct `BASE_PATH`:
  ```bash
  docker compose -f docker-compose.yml -f docker-compose.override.yml build --no-cache frontend
  docker compose -f docker-compose.yml -f docker-compose.override.yml up -d frontend
  ```
- **Loop between `/<base_path>` and `/<base_path>/`** → Add nginx exact redirect (no‑slash → slash) **or** set `trailingSlash: true` in `next.config.ts` and rebuild.
- **Public API 404/502** → Check proxy rule on `api.<domain>` points to `127.0.0.1:8001` under `/<base_path>/`.
- **Frontend using wrong API URL** → `NEXT_PUBLIC_API_URL` must be correct at **build time**; rebuild frontend.

---

## 📜 License

Choose a license that fits your goals:
- **MIT** — simple & permissive
- **Apache‑2.0** — includes explicit patent license

Add `LICENSE` accordingly.

---

## 🤝 Contributing

Issues and PRs are welcome. Please keep the template focused: small, production‑minded primitives that are easy to extend.

---

_Last updated: 2025-09-28_
