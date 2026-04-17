# Simple Booking System MVP

A lightweight, low-maintenance appointment booking system built as an extension of the OpenCondo/Form Engine architecture.

## 1. The Problem

Existing booking plugins (Bookly, Amelia) are feature-bloated and expensive. Most small businesses only need:
- Pick a date & time slot
- Submit a simple form
- Receive confirmation email

## 2. MVP Feature Set

### Frontend (Website Visitor)
- Clean calendar UI to pick a date
- Available time slots for that date
- Simple form (Name, Email, Phone, Notes)
- Success confirmation message

### Backend (Admin)
- Availability settings (working hours, block dates)
- Booking dashboard (view, approve, cancel)
- Email notifications (admin + customer)

### WordPress Integration
- Shortcode: `[my_simple_booking]`
- Or: Basic Gutenberg Block

## 3. Architecture Options

### Option A: Native WP Plugin (Recommended)
Build as a WordPress plugin with React frontend + WP REST API + custom database tables.

**Pros:**
- All data on user's server
- Zero monthly server costs for you
- No API maintenance

**Tech Stack:**
- React (calendar UI)
- PHP/MySQL (WP database)
- WP REST API

### Option B: Micro-SaaS Embed
Standalone app with WordPress connector/iframe.

**Pros:**
- You control the environment
- Scales automatically
- $0/month until high usage

**Tech Stack:**
- Astro/Next.js (frontend)
- Supabase (database)
- Resend (emails)

## 4. Implementation Checklist

- [ ] Database: `bookings` and `availability` tables
- [ ] API: CRUD endpoints for bookings
- [ ] Calendar Widget: Use `react-calendar` or `fullcalendar`
- [ ] Admin Dashboard: Settings + booking management
- [ ] Email: ICS calendar invite attachment
- [ ] WordPress Connector: Shortcode or iframe snippet

## 5. What to Exclude (MVP)

To keep maintenance low, **do NOT include in MVP:**
1. **Payment Gateways** - Use Stripe Payment Link on success page instead
2. **Google Calendar Sync** - Send `.ics` attachment in email instead
3. **Multi-staff/Multi-vendor** - One calendar per website

## 6. Database Schema (Supabase)

```sql
-- Availability settings
CREATE TABLE IF NOT EXISTS public.availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    day_of_week INTEGER, -- 0=Sunday, 1=Monday, etc.
    start_time TIME,
    end_time TIME,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Blocked dates (holidays, etc.)
CREATE TABLE IF NOT EXISTS public.blocked_dates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_name TEXT NOT NULL,
    client_email TEXT NOT NULL,
    client_phone TEXT,
    notes TEXT,
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocked_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Public can read availability and create bookings
CREATE POLICY "Anyone can read availability" ON public.availability FOR SELECT TO anon USING (true);
CREATE POLICY "Anyone can read blocked dates" ON public.blocked_dates FOR SELECT TO anon USING (true);
CREATE POLICY "Anyone can create bookings" ON public.bookings FOR INSERT TO anon WITH CHECK (true);

-- Admins can manage all
CREATE POLICY "Admins can manage bookings" ON public.bookings FOR ALL TO authenticated
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
```

## 7. Effort & Timeline

**For a single developer: 3-5 weeks**

| Week | Task |
|------|------|
| 1 | Database & API (backend) |
| 2 | Calendar Widget UI |
| 3 | Admin Dashboard |
| 4 | Polish & Timezone handling |

## 8. Monetization

**Recommended Pricing Model:**
- One-time fee: $49-$99 lifetime
- OR: $29/year for updates & support

**Why it works:** Subscription fatigue is real. A simple, beautifully designed tool at a reasonable one-time price will win customers from bloated plugins.
