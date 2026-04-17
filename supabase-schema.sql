-- =====================================================
-- OpenCondo / 1120pa Database Schema
-- Run this in Supabase SQL Editor to set up the database
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- CORE TABLES
-- =====================================================

-- Profiles table (extends Supabase Auth users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    unit_no TEXT,
    role TEXT DEFAULT 'resident' CHECK (role IN ('admin', 'resident')),
    phone TEXT,
    display_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Announcements table (Official notices)
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    body TEXT,
    is_urgent BOOLEAN DEFAULT FALSE,
    is_pinned BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tickets table (Issue reporting / Feedback)
CREATE TABLE IF NOT EXISTS public.tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id),
    category TEXT NOT NULL CHECK (category IN ('feedback', 'incident', 'maintenance', 'inquiry')),
    subject TEXT NOT NULL,
    details TEXT,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Marketplace items table
CREATE TABLE IF NOT EXISTS public.market_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    seller_id UUID REFERENCES public.profiles(id),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('sell', 'buy', 'trade', 'request', 'giveaway')),
    price DECIMAL(10, 2),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'sold', 'expired', 'removed')),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '14 days'),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- AGENCY FORM ENGINE TABLES (Multi-tenant)
-- =====================================================

-- Clients table (for agency form engine)
CREATE TABLE IF NOT EXISTS public.form_clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    domain TEXT,
    notification_email TEXT NOT NULL,
    auth_user_id UUID REFERENCES auth.users(id),
    allowed_origins TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Form submissions table
CREATE TABLE IF NOT EXISTS public.form_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES public.form_clients(id),
    form_id TEXT NOT NULL,
    payload JSONB NOT NULL,
    file_url TEXT,
    ip_address TEXT,
    user_agent TEXT,
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'read', 'archived', 'spam')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON public.announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON public.tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON public.tickets(status);
CREATE INDEX IF NOT EXISTS idx_market_items_status ON public.market_items(status);
CREATE INDEX IF NOT EXISTS idx_market_items_expires_at ON public.market_items(expires_at);
CREATE INDEX IF NOT EXISTS idx_form_submissions_client_id ON public.form_submissions(client_id);
CREATE INDEX IF NOT EXISTS idx_form_submissions_created_at ON public.form_submissions(created_at DESC);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_submissions ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read all, update own
CREATE POLICY "Profiles are viewable by authenticated users"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);

-- Announcements: Everyone can read, only admins can write
CREATE POLICY "Announcements are viewable by everyone"
    ON public.announcements FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Only admins can insert announcements"
    ON public.announcements FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Tickets: Users see own, admins see all
CREATE POLICY "Users can view own tickets"
    ON public.tickets FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all tickets"
    ON public.tickets FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Authenticated users can create tickets"
    ON public.tickets FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tickets"
    ON public.tickets FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

-- Market items: Active items visible to all authenticated, users manage own
CREATE POLICY "Active marketplace items are viewable by authenticated users"
    ON public.market_items FOR SELECT
    TO authenticated
    USING (
        status = 'active' AND expires_at > NOW()
        OR seller_id = auth.uid()
    );

CREATE POLICY "Authenticated users can create marketplace items"
    ON public.market_items FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "Users can update own marketplace items"
    ON public.market_items FOR UPDATE
    TO authenticated
    USING (auth.uid() = seller_id);

-- Form clients: Users see own
CREATE POLICY "Users can view own client record"
    ON public.form_clients FOR SELECT
    TO authenticated
    USING (auth_user_id = auth.uid());

-- Form submissions: Clients see own submissions
CREATE POLICY "Clients can view own submissions"
    ON public.form_submissions FOR SELECT
    TO authenticated
    USING (
        client_id IN (
            SELECT id FROM public.form_clients
            WHERE auth_user_id = auth.uid()
        )
    );

-- Allow public insert for forms (honeypot + rate limiting handled in API)
CREATE POLICY "Public can submit forms"
    ON public.form_submissions FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON public.announcements
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON public.tickets
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_market_items_updated_at BEFORE UPDATE ON public.market_items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_form_clients_updated_at BEFORE UPDATE ON public.form_clients
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =====================================================
-- VIEWS (Auto-Janitor Pattern)
-- =====================================================

-- View for active marketplace items (Zero-Janitoring)
CREATE OR REPLACE VIEW public.active_listings AS
SELECT 
    m.*,
    p.display_name as seller_name,
    p.unit_no as seller_unit
FROM public.market_items m
LEFT JOIN public.profiles p ON m.seller_id = p.id
WHERE m.status = 'active' AND m.expires_at > NOW()
ORDER BY m.created_at DESC;

-- View for unread form submissions count (for dashboard)
CREATE OR REPLACE VIEW public.unread_submissions AS
SELECT 
    client_id,
    COUNT(*) as unread_count
FROM public.form_submissions
WHERE status = 'new'
GROUP BY client_id;
