# Database Documentation

> Version Control App — Database Layer

---

## Overview

This project uses **PostgreSQL** (hosted on [Neon.db](https://neon.tech)) as its primary database. The schema is managed via **Django ORM** with explicit table name mappings. A raw SQL dump of the full schema is available at `db/my_app_db.sql`.

The database is made up of **7 tables** that together handle users, documents, versioning, permissions, reviews, audit trails, and notifications.

---

## Requirements

- PostgreSQL (with `uuid-ossp` extension — auto-enabled on first run)
- Python 3.x + Django
- `dj-database-url` for connection parsing
- A `DATABASE_URL` environment variable pointing to your Postgres instance

> **For tests only:** SQLite (in-memory) is used automatically when running `python manage.py test`. No extra setup needed.

---

## Connection Setup

In `settings.py`, the database is configured using the `DATABASE_URL` environment variable:

```python
DATABASES = {
    "default": dj_database_url.parse(
        os.getenv("DATABASE_URL"), conn_max_age=600, ssl_require=True
    )
}
```

Create a `.env` file in the root of the backend:

```env
DATABASE_URL=postgres://user:password@host/dbname
SECRET_KEY=your-secret-key
```

---

## Schema

### Entity Relationship Overview

```
users
 ├── documents          (created_by → users)
 │    ├── versions      (document → documents, created_by → users, parent_version → versions)
 │    │    └── reviews  (version → versions, reviewer → users)
 │    └── document_permissions  (document → documents, user → users)
 └── audit_log          (user, document, version — all nullable FKs)
 └── notifications      (recipient, actor → users, target_document → documents)
```

---

### `users`

The central table. All other tables reference it.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID (PK) | Auto-generated |
| `username` | VARCHAR(50) | Unique |
| `email` | VARCHAR(254) | Unique, used for login |
| `password` | VARCHAR(128) | Hashed |
| `first_name` / `last_name` | VARCHAR(50) | — |
| `avatar` | VARCHAR(500) | URL, has a default avatar |
| `is_active` | BOOLEAN | `true` by default |
| `is_staff` / `is_superuser` | BOOLEAN | Admin flags |
| `last_login` | TIMESTAMP TZ | — |
| `created_at` / `updated_at` | TIMESTAMP TZ | Auto-managed |

> Login is by **email**, not username. Emails are normalized to lowercase on save.

---

### `documents`

Represents a document managed in the system. Supports **soft delete** — rows are never actually removed, just flagged.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID (PK) | Auto-generated |
| `title` | VARCHAR(128) | — |
| `created_by_id` | UUID (FK → users) | On delete: CASCADE |
| `is_deleted` | BOOLEAN | `false` by default — soft delete flag |
| `created_at` / `updated_at` | TIMESTAMP TZ | Auto-managed |

**Constraint:** A user cannot have two active (non-deleted) documents with the same title. This is enforced via a **partial unique index**:

```sql
CREATE UNIQUE INDEX unique_user_active_title
ON documents (created_by_id, title)
WHERE is_deleted = FALSE;
```

**Note on creation:** When a document is created, the owner is automatically granted `DELETE` permission via a database transaction — ensuring the document and its permission always exist together or not at all.

---

### `versions`

Each document can have many versions. Versions form a **linked list** via `parent_version_id`, allowing full history traversal. Only one version per document can be active at a time.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID (PK) | Auto-generated |
| `document_id` | UUID (FK → documents) | On delete: CASCADE |
| `created_by_id` | UUID (FK → users) | On delete: SET NULL |
| `parent_version_id` | UUID (FK → versions) | Self-referential, nullable |
| `version_number` | INTEGER | Auto-incremented per document |
| `status` | VARCHAR(20) | `draft` / `pending_approval` / `approved` / `rejected` |
| `is_active` | BOOLEAN | Only one active version per document |
| `file_path` | VARCHAR(500) | Cloudinary URL |
| `file_size` | BIGINT | In bytes |
| `checksum` | VARCHAR(255) | For file integrity verification |
| `content` | TEXT | Optional extracted text content |
| `created_at` | TIMESTAMP TZ | Auto-managed |

**Constraints:**
- `(document_id, version_number)` is **unique** — no duplicate version numbers per document.
- A version can only be set to `is_active = true` if its `status` is `approved`. This is enforced at the model level.
- Setting a version as active automatically sets all other versions of the same document to inactive (within a single transaction).

**File storage path format:**
```
documents/{owner_id}/{document_id}/v{version_number}
```

---

### `document_permissions`

Controls who can do what with each document. Each user gets **one permission level per document**.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID (PK) | Auto-generated |
| `user_id` | UUID (FK → users) | On delete: CASCADE |
| `document_id` | UUID (FK → documents) | On delete: CASCADE |
| `permission_type` | VARCHAR(16) | `READ` / `WRITE` / `APPROVE` / `DELETE` |
| `granted_at` / `created_at` / `updated_at` | TIMESTAMP TZ | Auto-managed |

**Permission levels:**

| Level | What it allows |
|---|---|
| `READ` | View the document and its versions |
| `WRITE` | Upload new versions |
| `APPROVE` | Review and approve/reject versions |
| `DELETE` | Full ownership — can delete the document |

**Constraint:** `(user_id, document_id)` is **unique** — a user can only hold one permission level per document at a time.

---

### `reviews`

Tracks the approval/rejection of specific versions. Created when a version is submitted for review.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID (PK) | Auto-generated |
| `version_id` | UUID (FK → versions) | On delete: CASCADE |
| `reviewer_id` | UUID (FK → users) | On delete: SET NULL |
| `review_status` | VARCHAR(20) | `pending` / `approved` / `rejected` |
| `comments` | TEXT | Optional reviewer feedback |
| `reviewed_at` | TIMESTAMP TZ | Nullable — set when review is completed |

> `reviewer_id` is SET NULL on user deletion so that the review history is preserved even if the reviewer's account is removed.

---

### `audit_log`

Immutable record of every significant action in the system. Used for security monitoring and compliance.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID (PK) | Auto-generated |
| `user_id` | UUID (FK → users) | On delete: SET NULL |
| `document_id` | UUID (FK → documents) | On delete: SET NULL |
| `version_id` | UUID (FK → versions) | On delete: SET NULL |
| `action_type` | VARCHAR(50) | e.g. `LOGIN`, `UPLOAD`, `APPROVE` |
| `ip_address` | VARCHAR(45) | Supports IPv6 |
| `timestamp` | TIMESTAMP TZ | Auto-set, indexed DESC |
| `description` | TEXT | Optional extra context |

> All foreign keys use `SET NULL` so that audit records are **never deleted** even if the referenced user, document, or version is removed.

**Index:**
```sql
CREATE INDEX idx_audit_log_timestamp ON audit_log (timestamp DESC);
```

---

### `notifications`

In-app alerts sent to users when relevant actions occur (e.g. a document is shared with them, a version is approved).

| Column | Type | Notes |
|---|---|---|
| `id` | UUID (PK) | Auto-generated |
| `recipient_id` | UUID (FK → users) | Who receives the alert — CASCADE |
| `actor_id` | UUID (FK → users) | Who triggered it — nullable, CASCADE |
| `target_document_id` | UUID (FK → documents) | Related document — nullable, CASCADE |
| `verb` | VARCHAR(255) | Human-readable action, e.g. `"shared a document with you"` |
| `is_read` | BOOLEAN | `false` by default |
| `created_at` | TIMESTAMP TZ | Auto-managed |

**Index:**
```sql
CREATE INDEX idx_notifications_unread ON notifications (recipient_id) WHERE is_read = FALSE;
```

---

## Indexes Summary

| Index | Table | Purpose |
|---|---|---|
| `unique_user_active_title` | `documents` | Prevents duplicate titles for active docs per user |
| `idx_audit_log_timestamp` | `audit_log` | Fast descending time-ordered queries |
| `idx_versions_document_active` | `versions` | Fast lookup of the single active version per document |
| `idx_notifications_unread` | `notifications` | Fast unread notification counts per user |

---

## Running Migrations

```bash
# Apply all migrations
python manage.py migrate

# Or apply the raw SQL schema directly
psql $DATABASE_URL -f db/my_app_db.sql
```
