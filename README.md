# Aari AI Designer

Premium AI-powered mobile app that lets women visualize Aari embroidery on a saree + blouse
before a single stitch is made — upload a design, a saree, and a blouse, and get a
photorealistic preview with AI-recommended bead colours and a ready-to-buy materials list.

## Architecture

Clean, modular, two-service architecture:

```
Aari-AI-Designer/
├── backend/                  FastAPI (Python) — REST API, AI orchestration, persistence
│   └── app/
│       ├── api/v1/endpoints/ Route handlers (auth, uploads, analysis, generation, designs, cart)
│       ├── core/             Config, Supabase JWT verification, logging
│       ├── db/                SQLAlchemy async engine/session, declarative base
│       ├── models/           SQLAlchemy ORM models (User, Design, CartItem)
│       ├── schemas/          Pydantic request/response contracts
│       ├── services/         Gemini (vision + image gen), Cloudinary, shopping list logic
│       └── utils/            Image helpers, domain exceptions
│
└── frontend/                 Flutter — luxury fashion UI, Riverpod state management
    └── lib/
        ├── core/              Theme, network client, router, constants
        ├── models/            Dart data classes (mirror backend schemas)
        ├── services/          Supabase auth, API client, media pickers
        ├── state/             Riverpod providers/controllers
        ├── screens/           Splash, Auth, Home, Design, Result, History, Settings, Cart
        └── widgets/           Reusable luxury UI components
```

## Feature → implementation map

| Feature | Where |
|---|---|
| Upload design / saree / blouse (camera, gallery, PDF, manual colour) | `frontend/lib/screens/design/design_screen.dart`, `backend/app/api/v1/endpoints/uploads.py` |
| AI colour analysis + bead recommendations with reasoning | `backend/app/services/gemini_service.py::analyze_colors` |
| Photorealistic AI preview generation | `backend/app/services/gemini_service.py::generate_preview_image` |
| Regenerate (Luxury/Traditional/Minimal/Bridal/Temple/Modern) | `backend/app/api/v1/endpoints/generation.py`, `frontend/lib/widgets/result/look_style_selector.dart` |
| Shopping list + estimated cost | `backend/app/services/shopping_list_service.py` |
| Buy Materials (one-click cart) | `backend/app/api/v1/endpoints/cart.py`, `frontend/lib/screens/settings/cart_screen.dart` |
| Save / Favourite / Download / Share | `frontend/lib/screens/result/result_screen.dart` |
| History | `backend/app/api/v1/endpoints/designs.py`, `frontend/lib/screens/history/history_screen.dart` |
| Settings (dark mode, language, notifications, profile) | `frontend/lib/screens/settings/settings_screen.dart` |

## Backend setup

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # fill in Supabase / Cloudinary / Gemini credentials
uvicorn app.main:app --reload
```

- **Database**: defaults to local SQLite (`aiosqlite`) and auto-creates tables on startup —
  there's no Alembic migration setup yet, so this same auto-create path runs in every
  environment, including production. Point `DATABASE_URL` at PostgreSQL for anything beyond
  local dev (SQLAlchemy's async engine supports both transparently via `asyncpg`).
- **Supabase Auth**: set `SUPABASE_URL` and `SUPABASE_JWT_SECRET` from your Supabase project's
  dashboard (Project Settings → API). The backend verifies access tokens locally by decoding
  the JWT with this secret — no network call to Supabase needed per-request.
- **Cloudinary**: set `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET`
  from your Cloudinary dashboard.
- **Gemini**: set `GEMINI_API_KEY` (billing required beyond the free tier's daily quota — see
  [aistudio.google.com](https://aistudio.google.com)). Used for the vision-analysis half of the
  pipeline: garment/colour analysis and QA-scoring generated visualizations.
- **OpenAI**: set `OPENAI_API_KEY` (billing required). Used for the actual image generation —
  `gpt-image-1`'s edit endpoint composes the final boutique visualization from the uploaded
  blouse, saree and embroidery reference photos. Gemini has no viable image-generation offering
  for this, so the two providers split the pipeline: Gemini sees and describes, OpenAI renders.

API docs are available at `http://localhost:8000/docs` once running. Run the test suite with
`pytest` from `backend/` (install `requirements-dev.txt` first) — it exercises the full
Supabase-JWT → local-user pipeline with a self-signed token, no real Supabase project required.

## Frontend setup

```bash
cd frontend
flutter pub get

flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
            --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

- **State management**: Riverpod (`flutter_riverpod`).
- **Routing**: `go_router`, defined in `lib/core/router/app_router.dart`.
- **Auth**: Supabase Authentication (email/password + Google Sign-In) via `supabase_flutter`;
  the backend verifies the Supabase access token on every request via
  `app/core/supabase_auth.py`. No `flutterfire configure` step, no Firebase CLI login — just
  a project URL and anon key, both safe to expose client-side.
- Enable the Email and Google providers under Supabase → Authentication → Sign-in methods.
- Point `API_BASE_URL` at your deployed backend for release builds.

## Setting up Supabase

1. Create a project at [supabase.com](https://supabase.com) (free tier is enough for dev).
2. **Project Settings → API**: copy the *Project URL* and *anon/public key* → these go into the
   frontend's `SUPABASE_URL` / `SUPABASE_ANON_KEY` dart-defines above.
3. Same page, further down: copy the *JWT Secret* → this goes into the backend's
   `SUPABASE_JWT_SECRET` in `.env`.
4. **Authentication → Providers**: enable *Email* and *Google*.

No CLI login or interactive setup wizard required — everything above is copy-paste from the
dashboard.

## Deploying to Railway

The two services (`backend/`, `frontend/`) each carry their own `railway.json`, so this repo
deploys as two separate Railway services pointed at the same GitHub repo with different root
directories. Railway's filesystem is ephemeral — **do not** run the backend against the default
SQLite file in production, it will be wiped on every redeploy/restart. Use Railway's Postgres
plugin instead; the backend already supports it via `DATABASE_URL` (`asyncpg` is in
`requirements.txt`), no code changes needed.

**1. Database**: In your Railway project, click *New → Database → Add PostgreSQL*. Railway
provisions it and exposes a `DATABASE_URL` — copy it (or reference it directly, see step 2).

**2. Backend service**: *New → GitHub Repo* → select this repo → in service *Settings*, set
**Root Directory** to `backend`. It builds via Nixpacks (auto-detects `requirements.txt`) and
starts via `backend/railway.json`'s `startCommand`. Under *Variables*, set everything from
`backend/.env.example` — most importantly:
- `DATABASE_URL` — the Postgres connection string from step 1, with the `postgresql://` prefix
  changed to `postgresql+asyncpg://` (SQLAlchemy's async driver needs the explicit dialect)
- `ENVIRONMENT=production`
- `SUPABASE_URL`, `SUPABASE_JWT_SECRET`, `CLOUDINARY_*`, `GEMINI_API_KEY`, `OPENAI_API_KEY` — the
  same real values from your local `backend/.env`
- `CORS_ORIGINS` — once the frontend service has a URL (step 3), set this to
  `["https://your-frontend-service.up.railway.app"]` instead of the permissive dev default

Once deployed, note the backend's public URL (Settings → Networking → Generate Domain if not
already assigned) — the frontend needs it next.

**3. Frontend service**: *New → GitHub Repo* → same repo again → **Root Directory** set to
`frontend`. It builds via the Dockerfile (multi-stage: compiles Flutter web, serves via nginx).
Flutter web bakes config in at *build* time, not runtime, so these three variables must be set
as **build-time variables** on this service (Railway's Dockerfile builds pass matching
`ARG`-declared variables through automatically — check your dashboard's Variables tab for a
build-time toggle if it isn't automatic):
- `API_BASE_URL` — the backend's public URL from step 2, plus `/api/v1`
- `SUPABASE_URL`, `SUPABASE_ANON_KEY` — same Supabase project as the backend

After both are deployed, go back to the backend's `CORS_ORIGINS` variable and set it to the
frontend's actual Railway URL, then redeploy the backend so browser requests aren't blocked.

## Tech stack

Flutter · FastAPI · SQLAlchemy (async) · SQLite (dev) / PostgreSQL (prod) · Supabase Auth ·
Cloudinary · Google Gemini (vision analysis + QA scoring) · OpenAI `gpt-image-1` (image
generation) · Riverpod · go_router
