# Dorna Admin Panel

A comprehensive admin panel for managing the Dorna AI SaaS platform.

## 📁 Structure

```
apps/admin/
├── __init__.py              # Package init
├── router.py                # Main API router
├── static_server.py         # Static file serving
│
├── api/                     # API Endpoints
│   ├── __init__.py
│   ├── deps.py             # Auth dependencies
│   ├── auth.py             # Admin authentication
│   ├── users.py            # User management
│   ├── topics.py           # Topic/content management
│   ├── analytics.py        # Dashboard & analytics
│   └── audit.py            # Audit log viewing
│
├── models/                  # Database Models
│   ├── __init__.py
│   ├── admin_user.py       # Admin user model with RBAC
│   ├── audit_log.py        # Immutable audit trail
│   └── admin_note.py       # Internal notes about users
│
├── schemas/                 # Pydantic Schemas
│   ├── __init__.py
│   ├── auth.py             # Auth request/response
│   ├── users.py            # User management schemas
│   ├── topics.py           # Topic management schemas
│   ├── analytics.py        # Analytics schemas
│   └── audit.py            # Audit log schemas
│
├── services/                # Business Logic
│   ├── __init__.py
│   ├── user_service.py     # User management operations
│   ├── topic_service.py    # Topic CRUD operations
│   ├── analytics_service.py # Analytics queries
│   └── audit_service.py    # Audit logging
│
├── static/                  # Frontend Assets
│   ├── index.html          # Main HTML
│   ├── styles.css          # CSS with dark mode
│   └── app.js              # JavaScript application
│
└── tests/                   # Unit Tests
    ├── __init__.py
    ├── conftest.py         # Test fixtures
    ├── test_user_service.py
    ├── test_topic_service.py
    ├── test_analytics_service.py
    ├── test_audit_service.py
    └── test_schemas.py
```

## 🚀 Features

### 1. User Management
- List, search, and filter users
- View detailed user profiles
- Lock/unlock accounts
- Soft delete users
- Force logout from all devices
- Flag users for review
- Add internal admin notes

### 2. Topic/Content Management
- CRUD operations for news topics
- Activate/deactivate topics
- Filter by geo code, language, category
- View news item counts

### 3. Analytics Dashboard
- User growth metrics
- Active users (daily/weekly/monthly)
- Feature usage breakdown
- Aggregated language learning insights
- CLB distribution

### 4. Audit Logging
- Complete trail of all admin actions
- Filter by admin, action type, resource
- View detailed action history per user

### 5. Security
- Separate admin authentication
- Role-based access control (RBAC)
- Permission-based authorization
- MFA support (placeholder)
- Session management

## 🔐 Roles

| Role | Description |
|------|-------------|
| `super_admin` | Full access to everything |
| `admin` | Full access except admin management |
| `moderator` | User management & content moderation |
| `analyst` | Read-only access to analytics |
| `support` | Limited user viewing & notes |

## 📡 API Endpoints

### Authentication
- `POST /admin/auth/login` - Admin login
- `POST /admin/auth/refresh` - Refresh tokens
- `GET /admin/auth/me` - Get current admin profile
- `POST /admin/auth/logout` - Logout
- `POST /admin/auth/change-password` - Change password

### Users
- `GET /admin/users` - List users
- `GET /admin/users/{id}` - Get user profile
- `PATCH /admin/users/{id}` - Update user
- `POST /admin/users/{id}/lock` - Lock user
- `POST /admin/users/{id}/unlock` - Unlock user
- `POST /admin/users/{id}/force-logout` - Force logout
- `DELETE /admin/users/{id}` - Soft delete
- `POST /admin/users/{id}/flag` - Flag for review
- `GET /admin/users/{id}/notes` - Get admin notes
- `POST /admin/users/{id}/notes` - Add note
- `GET /admin/users/{id}/activity` - Get activity stats
- `GET /admin/users/{id}/learning-insights` - Get insights

### Topics
- `GET /admin/topics` - List topics
- `GET /admin/topics/reference-data` - Get tags, geo codes
- `GET /admin/topics/{id}` - Get topic details
- `POST /admin/topics` - Create topic
- `PATCH /admin/topics/{id}` - Update topic
- `DELETE /admin/topics/{id}` - Delete topic
- `POST /admin/topics/{id}/activate` - Activate
- `POST /admin/topics/{id}/deactivate` - Deactivate

### Analytics
- `GET /admin/analytics/dashboard` - Dashboard overview
- `GET /admin/analytics/user-growth` - User growth data
- `GET /admin/analytics/feature-usage` - Feature usage
- `GET /admin/analytics/language-insights` - Aggregated insights

### Audit
- `GET /admin/audit` - List audit logs
- `GET /admin/audit/{id}` - Get log details
- `GET /admin/audit/user/{id}` - User action history

## 🌐 Frontend

Access the admin panel at: `/admin/panel`

Features:
- Modern, minimal UI design
- Dark mode support (auto-detects)
- Responsive layout
- Real-time data loading

## 🧪 Running Tests

```bash
cd backend
pytest apps/admin/tests/ -v
```

## 📋 Database Migrations

The admin panel adds these tables:
- `admin_users` - Admin accounts
- `admin_audit_logs` - Action audit trail
- `admin_notes` - Internal notes about users

Run migrations to create these tables.

## 🔧 Configuration

Add to `.env`:
```
# Admin panel uses same JWT_SECRET as main app
```

## 📝 Privacy

- Raw user content is NEVER exposed to admins
- Only aggregated insights are shown
- All admin actions are logged
- Audit logs are immutable
