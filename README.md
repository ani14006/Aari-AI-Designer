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

- **Database**: defaults to local SQLite (`aiosqlite`) and auto-creates tables on startup in
  dev. For production, point `DATABASE_URL` at PostgreSQL and run migrations via Alembic
  instead of the dev auto-create path.
- **Supabase Auth**: set `SUPABASE_URL` and `SUPABASE_JWT_SECRET` from your Supabase project's
  dashboard (Project Settings → API). The backend verifies access tokens locally by decoding
  the JWT with this secret — no network call to Supabase needed per-request.
- **Cloudinary**: set `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET`
  from your Cloudinary dashboard.
- **Gemini**: set `GEMINI_API_KEY` (free tier available at [aistudio.google.com](https://aistudio.google.com)).
  A single provider covers both halves of the AI pipeline: `gemini-2.5-flash` for colour/style
  vision analysis, and `gemini-2.5-flash-image` for photorealistic preview generation — unlike
  Claude, which has no image-generation capability and could only cover the analysis half.

API docs are available at `http://localhost:8000/docs` once running. Run the test suite with
`pytest` from `backend/` (install `requirements-dev.txt` first) — it exercises the full
Supabase-JWT → local-user pipeline with a self-signed token, no real Supabase project required.

## Frontend setup

The Dart source (`lib/`) and `pubspec.yaml` are complete; native platform folders
(`android/`, `ios/`, `web/`) aren't checked in and must be generated locally:

```bash
cd frontend
flutter create . --org com.aariaidesigner --project-name aari_ai_designer
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

## Tech stack

Flutter · FastAPI · SQLAlchemy (async) · SQLite (dev) / PostgreSQL (prod) · Supabase Auth ·
Cloudinary · Google Gemini (2.5 Flash vision + 2.5 Flash Image generation) · Riverpod · go_router
