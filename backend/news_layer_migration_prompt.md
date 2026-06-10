# Agent Prompt: Migrate News Layer from sam_backend to implement Branch (based on prod v1)

## Your Mission
Migrate the **News Layer** feature from the `sam_backend` branch into the **`implement` branch** of this FastAPI backend project.

**Important**: `implement` is a new branch whose HEAD is exactly `v1` (production) HEAD. You will make changes on `implement`, not on `v1`, to avoid accidental branch confusion and to keep prod clean.

The goal is to add news functionality while **preserving v1's existing podcast implementation** (which is architecturally superior to sam_backend's).

---

## Critical Context

### Branch Structure
- **v1 (production)**: Has well-structured podcast with FeedItem, preferences, service layer
- **implement (work branch)**: Starts from `v1` HEAD; this is where you apply the migration changes
- **sam_backend**: Has News feature + Admin Panel + other features, BUT deleted v1's good podcast code

### DO NOT CONFUSE THESE TERMS
- **`v1` branch**: the production Git branch name (source of truth for podcast implementation).
- **`/v1` route prefix**: the API URL prefix used by FastAPI routers (e.g. `/v1/news/*`). This is not a Git branch.

### What You're Migrating
The **News Layer** consists of these files on `sam_backend`:

| sam_backend File | Purpose |
|------------------|---------|
| `app/models/news.py` | SQLAlchemy models: NewsTopic, UserTopicPreference, NewsItem, TopicRefreshJob |
| `app/models/user_topic_feedback.py` | UserTopicFeedback model |
| `app/schemas/news.py` | Pydantic schemas for news API |
| `app/services/news.py` | Business logic: topic CRUD, AI-powered news refresh |
| `app/api/v1/news.py` | FastAPI router with /news/* endpoints |
| `app/worker/news_tasks.py` | Celery tasks for background news refreshes |

### Important Technical Notes
1. **No Alembic**: User creates database tables manually. You must provide the SQL CREATE TABLE statements.
2. **Celery Queue**: sam_backend uses queue name `"news"` - check if this should be changed
3. **Dependencies**: News service uses `google-genai` with Google Search grounding for AI-powered news fetching
4. **User model**: May need to add relationships to the existing User model

---

## Step-by-Step Instructions

### Step 0 (Guardrail): You must be on the correct Git branch
Before doing anything else, confirm what branch you are on:

```powershell
cd c:\Users\nojan\Desktop\dorna-project\backend
git branch --show-current
git status
```

Expected:
- You should be on **`implement`**.
- Working tree should be clean (or you should explicitly note what is uncommitted).

If you are not on `implement`, stop and switch to it.

### Step 1: Switch to implement and Verify State (implement == v1 HEAD)
```powershell
cd c:\Users\nojan\Desktop\dorna-project\backend
git stash  # If needed
git checkout implement
git status  # Should be clean and on implement
```

### Step 2: Extract Source Files from sam_backend
For each file below, run `git show <sam_backend_ref>:<path>` to get the exact content.

Notes:
- If `sam_backend` exists locally, use `sam_backend:<path>`.
- If it’s only on the remote, use `origin/sam_backend:<path>` (run `git fetch --all` first).

```powershell
# Models
git show sam_backend:app/models/news.py
git show sam_backend:app/models/user_topic_feedback.py

# Schemas  
git show sam_backend:app/schemas/news.py

# Service
git show sam_backend:app/services/news.py

# API Router
git show sam_backend:app/api/v1/news.py

# Worker Tasks
git show sam_backend:app/worker/news_tasks.py
```

### Step 3: Analyze Dependencies
Before copying, check what each file imports and verify those exist on `implement` (which mirrors `v1` at start):

**news.py (service)** imports:
- `from app.core.config import settings` → Verify GEMINI_API_KEY, PODCAST_GENERATE_MODEL exist
- `from google import genai` / `from google.genai import types` → Verify google-genai is installed
- Models it uses

**news_tasks.py** imports:
- `from app.core.config import settings` → Verify DB_URL
- Celery shared_task
- Models: TopicRefreshJob, NewsTopic

### Step 4: Create Files on implement
Create each new file on **`implement`** with the content from Step 2. Adjust imports if needed.

> ⚠️ Guardrail: This migration must be **additive**. Do not refactor or “clean up” unrelated code as part of the migration.

### Step 5: Update Integration Points

**Modify** `app/models/__init__.py`:
```python
# Add these imports
from .news import NewsTopic, UserTopicPreference, NewsItem, TopicRefreshJob
from .user_topic_feedback import UserTopicFeedback
```

**Modify** `app/api/v1/__init__.py`:
```python
# Add import
from app.api.v1 import news

# Add router registration
api_router.include_router(news.router, prefix='/news', tags=["news"])
```

**Modify** `app/main.py` (FastAPI app wiring):
- Ensure `app.include_router(v1_router, prefix='/v1')` remains intact.
- Do **not** mount Admin here as part of the News migration unless explicitly requested.

**Modify** `app/worker/celery_app.py` (Celery wiring is required for refresh jobs):
- Add `app.worker.news_tasks` to `include=[...]`
- Add routing so `app.worker.news_tasks.*` goes to the `"news"` queue
- If the repo uses additional queues, document them; but don’t change unrelated routing.

### Step 6: Generate SQL for Manual Table Creation
Based on the SQLAlchemy models, provide CREATE TABLE statements for:
- `news_topics`
- `user_topic_preferences` 
- `news_items`
- `topic_refresh_jobs`
- `user_topic_feedback`

User will run these manually in PostgreSQL.

**SQL DDL requirements (do not skip):**
- Include primary keys, foreign keys, `ON DELETE` behavior, and uniqueness constraints.
- Include indexes that match expected query patterns (e.g. topic feed lookup, content_hash dedupe).
- Be explicit about JSON storage (`JSONB` vs `TEXT`) to match how the ORM stores `raw_json`.

### Step 7: Verify
1. Check imports work: `python -c "from app.models.news import NewsTopic; print('OK')"`
2. Start server and check `/docs` for new `/v1/news/*` endpoints
3. Test `GET /v1/news/topics` returns empty list

---

## Expected Deliverables

You are in **plan mode**: produce an **implementation plan only** (no code changes). Your plan should include:

1. **Pre-flight Checklist**
   - [ ] On `implement` branch (work branch)
   - [ ] Confirm `implement` is based on `v1` HEAD (e.g. `git merge-base implement v1`)
   - [ ] Docker services running
   - [ ] No uncommitted changes

2. **File-by-File Implementation**
   - Exact file paths
   - For each file: what you will add/change and why (high-level; no full source code in plan mode)
   - Exact integration points (which routers/modules get updated)

3. **SQL Table Definitions**
   - CREATE TABLE statements matching the SQLAlchemy models
   - Any constraints, indexes, foreign keys

4. **Verification Steps**
   - Commands to test each component
   - Expected responses

5. **Known Integration Points**
   - What config values are needed in .env
   - Any Celery worker configuration changes

---

## Reference: v1 Branch Current Structure

```
app/
├── api/v1/
│   ├── __init__.py      # Router aggregator
│   ├── assistant.py     # Grammar/tone endpoints
│   ├── auth.py          # Authentication
│   ├── podcast.py       # Podcast feed/preferences (KEEP THIS)
│   ├── track.py         # Analytics tracking
│   ├── tts.py           # Text-to-speech
│   └── users.py         # User management
├── models/
│   ├── __init__.py      # Model exports
│   ├── feed_item.py     # Podcast feed items (KEEP)
│   ├── podcast_job.py   # Background podcast jobs
│   ├── podcast_preferences.py  # User preferences (KEEP)
│   ├── user.py          # User model
│   └── ...other models
├── services/
│   ├── podcast.py       # Podcast business logic (KEEP - sam_backend deleted this!)
│   └── ...other services
├── worker/
│   ├── celery_app.py    # Celery configuration
│   ├── podcast_tasks.py # Podcast background tasks
│   └── tts_tasks.py     # TTS tasks
└── schemas/
    └── podcast.py       # Podcast Pydantic schemas
```

---

## Warnings

> ⚠️ **DO NOT** overwrite or modify `app/services/podcast.py`, `app/models/feed_item.py`, or `app/models/podcast_preferences.py` - these are v1's superior implementations that we want to keep.

> ⚠️ **DO NOT** copy sam_backend's `app/api/v1/podcast.py` wholesale - it has a different architecture. Only the `/news/podcast` endpoint (lines 272-397) could be added later as an enhancement.

> ⚠️ Check if `UserTopicPreference` in news.py conflicts with any existing preference model naming.

> ⚠️ Hard guardrail: For this migration, treat Podcast as **read-only**. Do not change Podcast routers/services/models at all. News must be implemented as a separate router/service/models and wired into the API via `app/api/v1/__init__.py`.
