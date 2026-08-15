# Aari AI Designer

**See your embroidery on the actual saree and blouse — before a single stitch is made.**

Upload a reference embroidery design, a saree, and a blouse. Aari AI Designer analyses the
colours, recommends bead palettes with real design reasoning, and generates a photorealistic
boutique product photograph of the finished outfit — worn on a display mannequin — faithful to
the exact embroidery you uploaded, not a reinterpretation of it. It closes with an itemised,
budget-aware materials shopping list ready to send a customer over WhatsApp.

[![Live Demo](https://img.shields.io/badge/Live%20Demo-aari--ai--designer-C9A24B?style=for-the-badge)](https://aari-ai-designer-frontend.onrender.com)
&nbsp;
![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Python-009688?logo=fastapi&logoColor=white)
![Gemini](https://img.shields.io/badge/Vision%20%2B%20QA-Gemini-4285F4?logo=googlegemini&logoColor=white)
![OpenAI](https://img.shields.io/badge/Image%20Generation-gpt--image--1-000000?logo=openai&logoColor=white)
![Supabase](https://img.shields.io/badge/Auth-Supabase-3ECF8E?logo=supabase&logoColor=white)
![Tests](https://img.shields.io/badge/backend%20tests-31%20passing-2E8B57)

---

## Contents

- [What it does](#what-it-does)
- [Architecture](#architecture)
- [Feature → implementation map](#feature--implementation-map)
- [Engineering notes](#engineering-notes)
- [Getting started](#prerequisites)
- [Deployment](#deployment)
- [Tech stack](#tech-stack)
- [License](#license)

## What it does

Aari embroidery — intricate hand-stitched beadwork on saree blouses — is traditionally sold on
faith: a customer picks a design from a photo of *someone else's* blouse and hopes it looks right
on their own fabric. Aari AI Designer replaces that guess with a real preview.

- **Upload** an embroidery reference (photo or PDF), a saree, and a blouse — by camera, gallery,
  or a manual colour swatch if a physical sample isn't on hand yet.
- **AI colour analysis** (Gemini) reads the actual fabrics and proposes three bead palettes —
  complementary, analogous, triadic — each with genuine colour-theory reasoning, not a generic
  guess.
- **Photorealistic generation** (OpenAI `gpt-image-1`) composes the chosen embroidery directly
  onto the uploaded blouse and saree as a styled boutique product photograph on a display
  mannequin. The reference photos are the source of truth throughout — the model is instructed
  to render *this* embroidery, not invent a similar-looking one.
- **AI quality scoring** (Gemini again, in a different role) scores each generated image against
  the original reference for fidelity; if the first attempt scores too low, the pipeline
  automatically retries once and keeps whichever attempt scored higher.
- **Shopping list**, sized to the blouse and budget, with per-material cost estimates and a
  ready-to-send WhatsApp message.
- **Look styles** (Luxury, Traditional, Minimal, Bridal, Temple, Modern) and **"View on
  Mannequin"** re-presentation are available on any completed design without redoing the whole
  pipeline.

## Architecture

Two independently deployable services:

```
Aari-AI-Designer/
├── backend/                       FastAPI (Python) — REST API, AI orchestration, persistence
│   └── app/
│       ├── api/v1/endpoints/      Route handlers (auth, uploads, analysis, generation, mannequin, designs, cart)
│       ├── core/                  Config, Supabase JWT verification, logging
│       ├── db/                    SQLAlchemy async engine/session, declarative base
│       ├── models/                SQLAlchemy ORM models (User, Design, CartItem)
│       ├── schemas/                Pydantic request/response contracts
│       ├── services/              Gemini (vision analysis + QA scoring), OpenAI (image generation),
│       │                          Cloudinary, shopping list logic, visualization pipeline
│       └── utils/                 Image helpers, domain exceptions
│
└── frontend/                      Flutter web — luxury fashion UI, Riverpod state management
    └── lib/
        ├── core/                  Theme, network client, router, constants
        ├── models/                Dart data classes (mirror backend schemas)
        ├── services/              Supabase auth, API client, media pickers, gallery download
        ├── state/                 Riverpod providers/controllers
        ├── screens/                Splash, Auth, Home, Design, Result, History, Settings, Cart
        └── widgets/                Reusable luxury UI components
```

The core visualization pipeline (`backend/app/services/openai_service.py` +
`visualization_pipeline.py`) uses two AI providers for different jobs: **Gemini** analyses the
uploaded garment and scores fidelity of the result, while **OpenAI**'s `gpt-image-1` does the
actual image generation — composing the final photo from the uploaded blouse, saree and
embroidery reference photos. Neither provider ever redesigns or reinterprets the embroidery;
the reference photos are the source of truth throughout. "View on Mannequin"
(`mannequin_service.py`) is a separate, optional post-processing step that re-presents an
already-completed visualization on a display mannequin.

## Feature → implementation map

| Feature | Where |
|---|---|
| Upload embroidery / saree / blouse (camera, gallery, PDF, manual colour) | `frontend/lib/screens/design/design_screen.dart`, `backend/app/api/v1/endpoints/uploads.py` |
| AI colour analysis + bead recommendations with reasoning | `backend/app/services/gemini_service.py::analyze_colors` |
| Boutique product photograph generation (blouse + saree + embroidery on a mannequin) | `backend/app/services/openai_service.py::generate_visualization`, `visualization_pipeline.py` |
| "View on Mannequin" (re-present a finished visualization) | `backend/app/services/mannequin_service.py`, `POST /generation/mannequin` |
| Regenerate (Luxury/Traditional/Minimal/Bridal/Temple/Modern) | `backend/app/api/v1/endpoints/generation.py`, `frontend/lib/widgets/result/look_style_selector.dart` |
| Shopping list + estimated cost | `backend/app/services/shopping_list_service.py` |
| Buy Materials | `frontend/lib/screens/result/result_screen.dart` (opens the external materials storefront) |
| Save / Favourite / Download / Share via WhatsApp | `frontend/lib/screens/result/result_screen.dart` |
| History | `backend/app/api/v1/endpoints/designs.py`, `frontend/lib/screens/history/history_screen.dart` |
| Settings (dark mode, language, notifications, profile) | `frontend/lib/screens/settings/settings_screen.dart` |

## Engineering notes

A few decisions worth calling out, since they weren't obvious going in:

- **The generation pipeline runs as a background task, not a synchronous request.** A full
  visualization — background removal, garment analysis, image generation, QA scoring, and up to
  one automatic retry — can take 1–5 minutes end to end, which reliably exceeds most hosting
  platforms' reverse-proxy timeouts if held open on a single request. `POST /generation/visualize`
  returns immediately with a `processing` status; the frontend polls `GET /designs/{id}` until
  it resolves.
- **Reference-image fidelity over generative freedom.** Early iterations let the model "interpret"
  the embroidery from a text description, which drifted from the actual uploaded design. The
  pipeline now sends the real reference photos directly to `gpt-image-1`'s edit endpoint with
  explicit instructions to preserve pattern, colour, and bead placement — Gemini's role is
  analysis and scoring, never generation.
- **Blocking work is kept off the event loop.** Background removal is genuine CPU-bound ML
  inference; running it directly inside an `async def` request handler blocks the entire
  single-worker process for its full duration, freezing every other in-flight request — including
  the same job's own status-polling calls. It runs via a thread-pool offload instead.
- **No Alembic migrations yet** — `create_all()` provisions schema in every environment on
  startup, and a small additive-only startup step backfills any column a model has gained (or
  widened) since a table was first created. It only ever adds or widens, never narrows or drops;
  a real migration tool is the obvious next step once schema changes get more involved than that.

## Prerequisites

- Python 3.12 (pinned in `backend/runtime.txt` / `backend/.python-version`)
- Flutter SDK (stable channel) with web support enabled
- Accounts/API keys for: [Supabase](https://supabase.com), [Cloudinary](https://cloudinary.com),
  [Google AI Studio](https://aistudio.google.com) (Gemini), [OpenAI](https://platform.openai.com)
  — all have the setup steps below

## Clone

```bash
git clone https://github.com/ani14006/Aari-AI-Designer.git
cd Aari-AI-Designer
```

## Backend — install, configure, run

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # then fill in the real values, see below
uvicorn app.main:app --reload
```

API docs are served at `http://localhost:8000/docs` once running, and a health check at
`http://localhost:8000/health`.

Run the test suite (31 tests, no real external services required — Supabase JWT verification is
exercised with a self-signed token, and OpenAI/Gemini/Cloudinary calls are mocked):

```bash
pip install -r requirements-dev.txt
pytest
```

### Backend environment variables

Every variable is listed with real placeholder shapes in `backend/.env.example`. The required
ones (no working default):

| Variable | Where to get it |
|---|---|
| `SUPABASE_URL`, `SUPABASE_JWT_SECRET` | Supabase dashboard → Project Settings → API |
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Cloudinary dashboard |
| `GEMINI_API_KEY` | [aistudio.google.com](https://aistudio.google.com) — billing required beyond the free tier's daily quota |
| `OPENAI_API_KEY` | [platform.openai.com](https://platform.openai.com/api-keys) — billing required |

Everything else in `.env.example` (`DATABASE_URL`, `CORS_ORIGINS`, `OPENAI_EDIT_QUALITY`,
`VISUALIZATION_QA_ACCEPT_THRESHOLD`, etc.) has a working default and only needs overriding
intentionally.

- **Database**: defaults to local SQLite (`aiosqlite`) and auto-creates tables on startup —
  there's no Alembic migration setup, so this same auto-create path runs in every environment,
  including production. Point `DATABASE_URL` at PostgreSQL for anything beyond local dev
  (SQLAlchemy's async engine supports both transparently via `asyncpg`; use the
  `postgresql+asyncpg://` prefix, not plain `postgresql://`).
- **Supabase Auth**: the backend verifies access tokens locally by decoding the JWT with
  `SUPABASE_JWT_SECRET` — no network call to Supabase needed per-request.
- **Gemini**: vision-analysis half of the pipeline only — garment/colour analysis and
  QA-scoring generated visualizations. Never generates images.
- **OpenAI**: the actual image generation. `gpt-image-1`'s edit endpoint composes the final
  boutique visualization from the uploaded blouse, saree and embroidery reference photos.
  Gemini has no viable image-generation offering for this, so the two providers split the
  pipeline: Gemini sees and describes, OpenAI renders.

## Frontend — install, configure, run

```bash
cd frontend
flutter pub get

flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Production build (what `frontend/Dockerfile` runs):

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://your-deployed-backend/api/v1 \
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Output is a static site in `frontend/build/web/` — servable by any static host or the included
nginx-based Dockerfile.

### Frontend environment variables

Flutter web has no runtime `.env` loading — these are **build-time** `--dart-define` flags, not
a file the app reads at startup. `frontend/.env.example` documents the same three values for
reference:

| Variable | Meaning |
|---|---|
| `API_BASE_URL` | Your backend's public URL, with the `/api/v1` prefix |
| `SUPABASE_URL` | Same Supabase project as the backend |
| `SUPABASE_ANON_KEY` | Supabase's public anon key (safe to expose client-side) |

- **State management**: Riverpod (`flutter_riverpod`).
- **Routing**: `go_router`, defined in `lib/core/router/app_router.dart`.
- **Auth**: Supabase Authentication (email/password + Google Sign-In) via `supabase_flutter`;
  the backend verifies the Supabase access token on every request via
  `app/core/supabase_auth.py`. No Firebase CLI, no `flutterfire configure` — just a project URL
  and anon key.

## Setting up Supabase

1. Create a project at [supabase.com](https://supabase.com) (free tier is enough for dev).
2. **Project Settings → API**: copy the *Project URL* and *anon/public key* → these go into the
   frontend's `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
3. Same page, further down: copy the *JWT Secret* → this goes into the backend's
   `SUPABASE_JWT_SECRET`.
4. **Authentication → Providers**: enable *Email* and *Google*.

No CLI login or interactive setup wizard required — everything above is copy-paste from the
dashboard.

## Deployment

Both `render.yaml` (repo root) and `backend/railway.json` + `frontend/railway.json` are checked
in — pick whichever platform you prefer. Either way, the shape is the same: two services (one
Python, one Docker) plus a managed Postgres database, since **the platform's filesystem is
ephemeral** — do not run the backend against the default SQLite file in production, it will be
wiped on every redeploy/restart.

### Render (one-click via Blueprint)

1. In the Render dashboard: **New → Blueprint**, point it at this repo. Render reads
   `render.yaml` and provisions the backend web service, the frontend Docker service, and a
   managed Postgres database in one go.
2. Fill in the secrets Render leaves blank (`sync: false` in `render.yaml`): `DATABASE_URL`
   (take Render's Postgres "Internal Connection String" and change its `postgresql://` prefix
   to `postgresql+asyncpg://`), `SUPABASE_URL`, `SUPABASE_JWT_SECRET`, `CLOUDINARY_*`,
   `GEMINI_API_KEY`, `OPENAI_API_KEY` on the backend service, and `API_BASE_URL`,
   `SUPABASE_URL`, `SUPABASE_ANON_KEY` on the frontend service (as **build-time** variables —
   Flutter web bakes these in at build, not runtime).
3. Once both services have URLs, set the backend's `CORS_ORIGINS` to the frontend's actual URL
   and redeploy the backend.
4. Pick an instance size deliberately, not just "free vs paid" — this pipeline runs real ML
   inference (background removal) alongside multiple in-memory image buffers per request. 512MB
   RAM tiers (including Render's "Starter") are tight for this workload under real usage; 2GB
   ("Standard") is a more realistic floor for production traffic.

### Railway

1. **New → Database → Add PostgreSQL** in your Railway project.
2. **New → GitHub Repo** → this repo → service *Settings* → **Root Directory**: `backend`. It
   builds via Nixpacks (auto-detects `requirements.txt`) and starts via `backend/railway.json`.
   Set the same variables as the Render backend service above under *Variables*.
3. **New → GitHub Repo** → this repo again → **Root Directory**: `frontend`. It builds via
   `frontend/Dockerfile` (multi-stage: compiles Flutter web, serves via nginx listening on
   Railway's dynamic `$PORT`). Set `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` as
   **build-time** variables (check your dashboard's Variables tab for a build-time toggle if
   Railway doesn't pass matching `ARG`s through automatically).
4. Once both are deployed, set the backend's `CORS_ORIGINS` to the frontend's actual Railway URL
   and redeploy the backend.

### Fly.io / DigitalOcean App Platform / other standard hosts

The same two-service shape applies: run the backend with `backend/Procfile`'s command
(`uvicorn app.main:app --host 0.0.0.0 --port $PORT`) against a Postgres `DATABASE_URL`, and
build/serve the frontend via `frontend/Dockerfile`. Both are platform-agnostic — nothing here is
Render- or Railway-specific beyond the two `railway.json` files and `render.yaml`, which
unrelated platforms simply ignore.

## Tech stack

**Frontend** — Flutter (web), Riverpod, go_router, nginx (production container)
**Backend** — FastAPI, SQLAlchemy (async), Pydantic, Uvicorn
**Data** — PostgreSQL (production) / SQLite (dev), Supabase (auth), Cloudinary (media storage)
**AI** — Google Gemini (vision analysis + QA scoring), OpenAI `gpt-image-1` (image generation)

## License

© 2026 Anish Karthick. All rights reserved.

This repository is public for portfolio and demonstration purposes. No license is granted to
use, copy, modify, or distribute this code, in whole or in part, without explicit written
permission.
