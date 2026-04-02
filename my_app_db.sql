-- 1. EXTENSIONS & CLEANUP
-- Ensure UUID support is available in the Postgres instance
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. USERS TABLE (Primary Dependency)
CREATE TABLE IF NOT EXISTS "users" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "password" VARCHAR(128) NOT NULL,
    "last_login" TIMESTAMP WITH TIME ZONE,
    "is_superuser" BOOLEAN NOT NULL DEFAULT FALSE,
    "username" VARCHAR(50) UNIQUE NOT NULL,
    "email" VARCHAR(254) UNIQUE NOT NULL,
    "first_name" VARCHAR(50) NOT NULL,
    "last_name" VARCHAR(50) NOT NULL,
    "avatar" VARCHAR(500) DEFAULT 'https://res.cloudinary.com/dbgpxmjln/image/upload/v1766143170/deafult-avatar_tyvazc.png',
    "is_active" BOOLEAN NOT NULL DEFAULT TRUE,
    "is_staff" BOOLEAN NOT NULL DEFAULT FALSE,
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. DOCUMENTS TABLE
CREATE TABLE IF NOT EXISTS "documents" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "title" VARCHAR(128) NOT NULL,
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "is_deleted" BOOLEAN NOT NULL DEFAULT FALSE,
    "created_by_id" UUID NOT NULL,
    CONSTRAINT "documents_created_by_fkey" FOREIGN KEY ("created_by_id") 
        REFERENCES "users" ("id") ON DELETE CASCADE
);

-- Partial Unique Index: Prevents duplicate titles ONLY for active (non-deleted) docs
CREATE UNIQUE INDEX IF NOT EXISTS "unique_user_active_title" 
ON "documents" ("created_by_id", "title") 
WHERE "is_deleted" = FALSE;

-- 4. VERSIONS TABLE (Self-referencing & Document Dependent)
CREATE TABLE IF NOT EXISTS "versions" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "version_number" INTEGER NOT NULL,
    "content" TEXT,
    "status" VARCHAR(20) NOT NULL DEFAULT 'draft', -- draft, pending_approval, approved, rejected
    "is_active" BOOLEAN NOT NULL DEFAULT FALSE,
    "file_path" VARCHAR(500) NOT NULL,
    "file_size" BIGINT NOT NULL,
    "checksum" VARCHAR(255) NOT NULL,
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "document_id" UUID NOT NULL,
    "created_by_id" UUID,
    "parent_version_id" UUID,
    CONSTRAINT "versions_document_fkey" FOREIGN KEY ("document_id") 
        REFERENCES "documents" ("id") ON DELETE CASCADE,
    CONSTRAINT "versions_creator_fkey" FOREIGN KEY ("created_by_id") 
        REFERENCES "users" ("id") ON DELETE SET NULL,
    CONSTRAINT "versions_parent_fkey" FOREIGN KEY ("parent_version_id") 
        REFERENCES "versions" ("id") ON DELETE SET NULL,
    UNIQUE ("document_id", "version_number")
);

-- 5. DOCUMENT PERMISSIONS TABLE
CREATE TABLE IF NOT EXISTS "document_permissions" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "permission_type" VARCHAR(16) NOT NULL DEFAULT 'READ', -- READ, WRITE, APPROVE, DELETE
    "granted_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "document_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    CONSTRAINT "permissions_doc_fkey" FOREIGN KEY ("document_id") 
        REFERENCES "documents" ("id") ON DELETE CASCADE,
    CONSTRAINT "permissions_user_fkey" FOREIGN KEY ("user_id") 
        REFERENCES "users" ("id") ON DELETE CASCADE,
    UNIQUE ("user_id", "document_id")
);

-- 6. REVIEWS TABLE
CREATE TABLE IF NOT EXISTS "reviews" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "review_status" VARCHAR(20) NOT NULL DEFAULT 'pending',
    "comments" TEXT,
    "reviewed_at" TIMESTAMP WITH TIME ZONE,
    "reviewer_id" UUID,
    "version_id" UUID NOT NULL,
    CONSTRAINT "reviews_reviewer_fkey" FOREIGN KEY ("reviewer_id") 
        REFERENCES "users" ("id") ON DELETE SET NULL,
    CONSTRAINT "reviews_version_fkey" FOREIGN KEY ("version_id") 
        REFERENCES "versions" ("id") ON DELETE CASCADE
);

-- 7. AUDIT LOG TABLE
CREATE TABLE IF NOT EXISTS "audit_log" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "action_type" VARCHAR(50) NOT NULL,
    "ip_address" VARCHAR(45),
    "timestamp" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "description" TEXT,
    "user_id" UUID,
    "document_id" UUID,
    "version_id" UUID,
    CONSTRAINT "audit_user_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE SET NULL,
    CONSTRAINT "audit_doc_fkey" FOREIGN KEY ("document_id") REFERENCES "documents" ("id") ON DELETE SET NULL,
    CONSTRAINT "audit_ver_fkey" FOREIGN KEY ("version_id") REFERENCES "versions" ("id") ON DELETE SET NULL
);

-- 8. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS "notifications" (
    "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "verb" VARCHAR(255) NOT NULL,
    "is_read" BOOLEAN NOT NULL DEFAULT FALSE,
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "recipient_id" UUID NOT NULL,
    "actor_id" UUID,
    "target_document_id" UUID,
    CONSTRAINT "notify_recipient_fkey" FOREIGN KEY ("recipient_id") REFERENCES "users" ("id") ON DELETE CASCADE,
    CONSTRAINT "notify_actor_fkey" FOREIGN KEY ("actor_id") REFERENCES "users" ("id") ON DELETE CASCADE,
    CONSTRAINT "notify_doc_fkey" FOREIGN KEY ("target_document_id") REFERENCES "documents" ("id") ON DELETE CASCADE
);

-- 9. OPTIMIZATION INDEXES
CREATE INDEX IF NOT EXISTS "idx_audit_log_timestamp" ON "audit_log" ("timestamp" DESC);
CREATE INDEX IF NOT EXISTS "idx_versions_document_active" ON "versions" ("document_id") WHERE "is_active" = TRUE;
CREATE INDEX IF NOT EXISTS "idx_notifications_unread" ON "notifications" ("recipient_id") WHERE "is_read" = FALSE;