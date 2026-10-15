# StudyFlow 📚

**Smart Student Productivity System** — built with React + Vite + Supabase.

## Features

- 🔐 **Auth** — email sign-up / sign-in, session persistence, protected routes
- 📋 **Tasks** — full CRUD with priority, status, subject, due-date filtering and inline complete toggle
- 📅 **Study Planner** — schedule sessions by date/time/duration, grouped calendar view
- 📊 **Analytics** — Recharts graphs (study hours trend, task status, hours by subject, priority breakdown)
- ⚙️ **Settings** — profile update, account info
- 📱 **Responsive** — sidebar collapses to mobile drawer on small screens

## Tech Stack

| Layer     | Technology                        |
|-----------|-----------------------------------|
| Frontend  | React 18 + Vite                   |
| Routing   | react-router-dom v6               |
| Backend   | Supabase (Auth + PostgreSQL)      |
| Charts    | Recharts                          |
| Icons     | lucide-react                      |
| Dates     | date-fns                          |

---

## 1 · Supabase Setup (required — one-time)

1. Open your Supabase project → **SQL Editor** → **New query**
2. Paste the contents of [`supabase/migrations/001_studyflow_setup.sql`](./supabase/migrations/001_studyflow_setup.sql)
3. Click **Run**

This creates the `profiles`, `tasks`, and `study_sessions` tables, enables **Row Level Security** with per-user policies, sets up `updated_at` triggers, and grants the right privileges.

> ⚠️ Never disable RLS. All policies use `auth.uid() = user_id` to ensure users can only access their own data.

---

## 2 · Local Development

```bash
# Clone / open the project
cd "full stack web"

# Install dependencies
npm install

# Copy env example and fill in your values
cp .env.example .env.local
# Then edit .env.local — your values are already populated

# Start dev server
npm run dev
```

Open [http://localhost:5173](http://localhost:5173).

---

## 3 · Environment Variables

| Variable                         | Description                         |
|----------------------------------|-------------------------------------|
| `VITE_SUPABASE_URL`              | Your Supabase project URL           |
| `VITE_SUPABASE_PUBLISHABLE_KEY`  | Publishable (anon) key — safe for frontend |

> `.env.local` is git-ignored. **Never** commit secrets.

---

## 4 · Production Build

```bash
npm run build
# Output in dist/
```

Deploy the `dist/` folder to any static host (Netlify, Vercel, Cloudflare Pages, etc.).  
Set the same env vars in your hosting provider's dashboard.

### Vercel (one command)
```bash
npx vercel --prod
```

### Netlify
```bash
npx netlify deploy --prod --dir=dist
```

---

## Project Structure

```
src/
├── contexts/
│   └── AuthContext.jsx      # Auth state, sign-in/up/out, profile
├── lib/
│   └── supabase.js          # Supabase client (env vars only)
├── components/
│   ├── Layout/
│   │   ├── Layout.jsx
│   │   ├── Sidebar.jsx
│   │   └── Sidebar.css
│   └── ui/
│       └── LoadingScreen.jsx
├── pages/
│   ├── AuthPage.jsx / .css
│   ├── Dashboard.jsx
│   ├── Tasks.jsx
│   ├── StudyPlanner.jsx
│   ├── Analytics.jsx
│   └── Settings.jsx
├── index.css                # Global design tokens + utilities
└── main.jsx
supabase/
└── migrations/
    └── 001_studyflow_setup.sql
```

---

## Security Notes

- All tables have RLS enabled — users can only read/write their own rows
- `user_id` is always set from `auth.uid()` via RLS, never from client input
- No service-role keys are used anywhere in the frontend
- `.env.local` is in `.gitignore`
