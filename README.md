# OpenCondo (1120pa Community Hub)

A long-term, low-maintenance, privacy-first Progressive Web App (PWA) designed for condo communities. Built to replace noisy WhatsApp groups, neglected physical notice boards, and expensive legacy property management software.

**Live Project Instance:** `1120pa.rakyaaat.com`



260415 - security system? what are the patrol system like? our sec-ops; or at least start with our digital system. lets do pen test on them.


## 🌟 Project Vision & Philosophies

This project is built on the **KISE (Keep It Simple, Essential)** principle. It is designed to be an **"Open Source SaaS"** (The Obsidian Model) that can be self-hosted by tech-savvy residents for free, or managed as a service for property managers.

- **Zero-Janitoring:** No cron jobs or manual deletion. Posts auto-expire via Database Views/RLS.
- **The "No-Chat" Rule:** No in-app messaging. Marketplace items and services link directly to WhatsApp (`wa.me`). This completely removes liability and moderation headaches.
- **Dumb Frontend, Smart Backend:** Forms have zero complex logic. Validation, routing, and database inserts happen on a centralized serverless backend.
- **Multi-Tenant Ready:** The underlying form and database engine can support unlimited clients (or condos) from a single database, keeping costs at $0.

## 🛠 Tech Stack ("The Free Tier Hero")

The stack is designed to be completely **free** to operate at small-to-medium scale, while remaining highly portable.

- **Frontend:** Astro.js (SSR Mode) + Tailwind CSS + DaisyUI
- **Backend APIs / Form Engine:** Hono (Deployed on Cloudflare Workers or Node.js)
- **Database:** Supabase (PostgreSQL, Auth, RLS, Storage)
- **Emails:** Resend (Easily swappable to SES/Mailgun)
- **App Experience:** `@vite-pwa/astro` for installable PWA and offline support.

## 🗺 Implementation Roadmap

### Phase 1: The Foundation & "Notice Board" ✅ (Complete)
- [x] PWA Setup (Installable, Service Workers, Offline capabilities).
- [x] Setup Supabase connection and core utilities.
- [x] Implement the **Agnostic Form Framework** (API route + reusable component).
- [x] Static Content & Wiki: Visitor Guide, Renovation Guide, Moving Guide.
- [x] "Notice Board" for Management Announcements.

### Phase 2: The "Help Desk" (Communication)
- [ ] Resident Feedback & Ticketing System via the Form Engine.
- [ ] Integration with Email Notifications (Resend).
- [ ] Status tracking for tickets (Submitted -> In Progress -> Fixed).
- [ ] Admin Approval workflow for new user accounts.

### Phase 3: The Community Hub & Marketplace
- [ ] Hyperlocal Services Directory (Technicians, Plumbers, Electricians).
- [ ] Marketplace (Buy/Sell/Giveaway).
- [ ] "Auto-Expire" functionality via PostgreSQL views (30-day limit).
- [ ] Client-side image compression (`browser-image-compression`) to save server costs).

### Phase 4: Simple Booking System (Amenities)
- [ ] Court/Field Booking System (Badminton, Ping Pong).
- [ ] Integration with existing Picktime or custom solution.
- [ ] Availability API for external calendars.

## 📖 Documentation Directory

For deeper technical dives and content structures, refer to the `docs/` folder:

1. [Architecture & Security](docs/architecture-and-security.md)
2. [Agnostic Form Engine](docs/form-engine.md)
3. [Business Model & Strategy](docs/business-model.md)
4. [1120pa Specific Content](docs/1120pa-content.md)
5. [Booking System MVP](docs/booking-system-mvp.md)

---

## 🎯 Phase 3 Extended: Hyperlocal "Jobs & Services" Marketplace

Beyond the standard "buy/sell used furniture" marketplace, Phase 3 will also serve as a **local services directory** for the condo community.

### Target Users

| User Type | Example | Purpose |
|-----------|---------|---------|
| **Solopreneurs** | Home bakers, craft sellers, consultants | Sell products/services to neighbors |
| **Technicians** | Plumbers, electricians, AC repair | Offer services within the condo |
| **Solo Devs** | Web developers, designers | Freelance work for neighbors |
| **Car Owners** | Car wash, detailing, mechanic | Mobile car services |
| **Service Providers** | Cleaners, movers, tutors | Recurring or one-time services |

### Marketplace Categories

#### 1. 🛠 Services (Local Technicians)
- **Home Repair:** Plumbers, electricians, handymen
- **AC Service:** Installation, repair, maintenance
- **Cleaning:** House cleaning, window cleaning
- **Automotive:** Mobile car wash, basic repairs
- **Tutors/Classes:** Academic tutoring, music lessons, fitness

#### 2. 🍰 Home Businesses (Solopreneurs)
- **Food:** Home bakers, cooked meals, dietary specialties
- **Crafts:** Handmade goods, custom gifts
- **Consulting:** Financial, legal, business advice
- **Creative:** Photography, design, writing

#### 3. 🏠 Property Services
- **Renovation:** Contractors, interior designers
- **Landscaping:** Garden maintenance
- **Pest Control:** Termite, pest treatment

### Key Features

| Feature | Description |
|---------|-------------|
| **Service Cards** | Profile with photo, description, services offered, pricing (if public) |
| **WhatsApp Integration** | Direct chat via `wa.me` link - no in-app messaging |
| **Portfolio/Gallery** | Up to 4 images to showcase work |
| **Availability Toggle** | Mark as "Available" or "Fully Booked" |
| **Reviews (Simple)** | Star rating only, no comment threads |
| **Auto-Expire Listings** | Active listings expire after 30 days unless renewed |

### "No-Chat" Philosophy for Services

- **No In-App Messaging:** All communication goes to WhatsApp
- **Public Contact Only:** Phone number/WhatsApp visible on profile
- **Booking Outside App:** Service provider manages their own bookings (via Picktime, WhatsApp, or their own system)
- **No Payments In-App:** Use Stripe Payment Links or bank transfers

### Database Schema Extension

```sql
-- Service provider profiles
CREATE TABLE IF NOT EXISTS public.service_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    business_name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    phone TEXT,
    whatsapp TEXT,
    hourly_rate DECIMAL(10, 2),
    is_available BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Service portfolio images
CREATE TABLE IF NOT EXISTS public.service_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID REFERENCES public.service_providers(id),
    image_url TEXT NOT NULL,
    caption TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Monetization Options (Future)

| Tier | Price | Features |
|------|-------|----------|
| **Free** | $0 | Basic listing, up to 4 images, auto-expire |
| **Premium** | $5/mo | Priority placement, unlimited images, no expire |
| **Featured** | $10/mo | Homepage spotlight, badge, analytics |

---

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your Supabase and Resend keys

# Run database schema in Supabase SQL Editor
# Copy contents of supabase-schema.sql

# Start development
npm run dev
```

## 📁 Project Structure

```
1120pa/
├── src/
│   ├── pages/
│   │   ├── api/forms/        # Form submission API
│   │   ├── guides/           # Wiki pages
│   │   ├── announcements/    # Notice board
│   │   ├── contact.astro     # Contact form
│   │   └── index.astro       # Homepage
│   ├── components/
│   │   └── FormAgnostic.astro
│   └── lib/
│       └── supabase.ts
├── supabase-schema.sql
├── docs/
└── scripts/
```