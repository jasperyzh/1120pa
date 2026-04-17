# Agnostic Multi-Tenant Form Engine

A drop-in, reusable form microservice built to replace managed services like Formspree or Google Sheets. It is designed to handle forms for multiple clients (or multiple condo communities) from a single database.

## 1. Core Architecture (KISE)

1. **One Table to Rule Them All:** We do not create separate databases for different clients. Multi-tenancy is handled via a `client_id` foreign key.
2. **Dumb Frontend, Smart Backend:** HTML forms have zero complex logic. All validation happens on the server.
3. **Agnostic Framework (Hono):** The backend is written in [Hono](https://hono.dev/). This means the same code can run on Cloudflare Workers, AWS Lambda, Vercel Edge, or a standard Node.js VPS without modification.

## 2. The Tech Stack

- **Framework:** Hono (Portable Web Standard framework).
- **Compute:** Cloudflare Workers (or Astro SSR API routes).
- **Database:** Supabase PostgreSQL (`clients` and `submissions` tables).
- **Spam Protection:** Cloudflare Turnstile (Invisible reCAPTCHA alternative).
- **Email:** Resend API.

## 3. The Workflow

1. **Incoming Request:** User submits an HTML form containing `_client_id` and a hidden honeypot field.
2. **Security Checks:**
   - Honeypot check (Silent reject if filled).
   - Turnstile verification.
3. **Database Insertion:** The worker fetches the client config, logs the raw JSON payload to the `submissions` table (linked to `client_id`).
4. **Notification:** Worker constructs an HTML email and sends it via Resend using the client's verified domain.
5. **Redirect:** User is redirected to a standard "Thank You" page.

## 4. Supabase RLS (Multi-Tenancy Security)

To allow clients to log in and view *only* their leads, we use Supabase Auth linked to the `clients` table, enforced by RLS.

```sql
-- Link clients table to Supabase Auth
ALTER TABLE clients ADD COLUMN auth_user_id UUID REFERENCES auth.users(id);

-- Enforce multi-tenant security on submissions
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Clients can view own submissions"
ON submissions FOR SELECT
USING (
  client_id IN (
    SELECT id FROM clients 
    WHERE auth_user_id = auth.uid()
  )
);
```

## 5. Standard Frontend Template

This snippet can be dropped into *any* WordPress, Astro, or static HTML site.

```html
<form action="https://api.your-worker.com/submit" method="POST">
  <!-- Config -->
  <input type="hidden" name="_client_id" value="UUID_FROM_DB">
  <input type="hidden" name="_redirect" value="/thank-you">
  
  <!-- Honeypot -->
  <input type="text" name="_website" style="display:none" tabindex="-1" autocomplete="off">
  
  <!-- Content -->
  <input type="text" name="name" required>
  <input type="email" name="email" required>
  <textarea name="message" required></textarea>
  
  <!-- Spam Guard -->
  <div class="cf-turnstile" data-sitekey="YOUR_PUBLIC_KEY"></div>
  
  <button type="submit">Send</button>
</form>
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
```

## 6. Implementation Notes for "OpenCondo"
For the condo project, we can integrate this logic directly into an **Astro API Endpoint** (`src/pages/api/forms/submit.ts`) instead of a separate Cloudflare Worker, simplifying the deployment to a single Vercel/Netlify instance while maintaining the exact same Hono/Web-standard syntax.