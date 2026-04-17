# Architecture & Security Strategy

## 1. Database Schema (Supabase)

The core database uses a multi-tenant structure to support different clients or condos in the future. 

### Core Tables

| Table | Columns | Purpose | RLS Policy |
|-------|---------|---------|------------|
| `clients` | `id`, `name`, `domain`, `notification_email`, `auth_user_id` | Configuration for different condos/agencies | Strict Admin access |
| `profiles` | `id` (auth.uid), `unit_no`, `role` (admin/resident), `phone` | User identities | Users edit own; Everyone reads names/units |
| `announcements` | `id`, `title`, `body`, `created_at`, `is_urgent` | Official condo notices | Admins write; Everyone reads |
| `tickets` | `id`, `user_id`, `category`, `status`, `details` | Issue reporting | User writes/reads own; Admin reads all |
| `market_items` | `id`, `seller_id`, `title`, `price`, `status`, `expires_at` | Marketplace listings | Auth users write; Auth users read active |
| `submissions` | `id`, `client_id`, `payload` (JSONB), `file_url`, `created_at`| Agnostic Form Data | User inserts; Client views only their own |

## 2. Security Fundamentals (Defense in Depth)

We utilize database-level security to prevent data leaks, rather than relying solely on the application layer.

- **Row Level Security (RLS):** Enabled on all tables. Acts as a firewall for individual rows.
- **SECURITY INVOKER vs DEFINER:** 
  - Always use `SECURITY INVOKER` (Default) for Views and Functions. This ensures the query respects the caller's RLS policies.
  - **Never** use `SECURITY DEFINER` unless strictly for an isolated admin task, as it bypasses RLS.
- **Supabase Roles:**
  - `anon`: Public, unlogged-in users (Minimal access).
  - `authenticated`: Logged-in residents (uses `auth.uid()`).
  - `service_role`: "God Mode" - ONLY for backend server execution. NEVER expose to the frontend.

## 3. The "Auto-Janitor" Pattern

To adhere to the **Zero-Janitoring** philosophy, we do not use Cron jobs to delete old posts. Instead, we use a PostgreSQL View or RLS policy.

**Using a View:**
```sql
CREATE VIEW active_listings AS
SELECT * FROM marketplace_posts
WHERE created_at > (NOW() - INTERVAL '30 days') AND status = 'active';
```

**Using an RLS Policy:**
Add an `expires_at` column (Default: `now() + 30 days`).
Update the SELECT policy: `WHERE expires_at > now()`.

## 4. Admin Lite (Handover Strategy)

The primary reason condo apps fail is the inability to hand them over to non-technical property managers. We solve this by avoiding a full CMS.

Build a protected `/admin` route with **just 3 features**:
1. **Pin/Unpin Announcement:** A boolean toggle for the homepage banner.
2. **Approve User:** A toggle for `is_verified` to gatekeep the community.
3. **Delete Post:** A simple table to manually nuke a marketplace post if it violates rules.

## 5. PWA Implementation (Astro)

We use `@vite-pwa/astro` to generate the `manifest.json` and Service Workers automatically. This provides:
- Add to Homescreen capabilities.
- Offline caching for FAQs and Directories.
- A foundation for iOS/Android Push Notifications in the future.