#!/bin/bash

# ================================================
# OpenCondo / 1120pa - Supabase Setup Script
# ================================================

set -e

echo "============================================"
echo "  OpenCondo Supabase Setup"
echo "============================================"
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Installing..."
    export PATH="$HOME/.local/bin:$PATH"
    curl -fsSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar xz
    mkdir -p ~/.local/bin
    mv supabase ~/.local/bin/
fi

export PATH="$HOME/.local/bin:$PATH"

echo "✓ Supabase CLI installed: $(supabase --version)"
echo ""

# Check if linked to a project
if [ -f ".supabase/config.json" ]; then
    echo "⚠️  Already linked to a Supabase project"
    read -p "Do you want to re-link? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing link."
    else
        echo "Run 'supabase link' to reconnect."
    fi
else
    echo ""
    echo "📋 Next steps to complete setup:"
    echo ""
    echo "1. Create a Supabase project at: https://app.supabase.com"
    echo ""
    echo "2. Link your local project to Supabase:"
    echo "   supabase link --project-ref YOUR_PROJECT_REF"
    echo ""
    echo "3. Push the database schema:"
    echo "   supabase db push"
    echo ""
    echo "   OR copy the contents of 'supabase-schema.sql' and run it"
    echo "   in the Supabase SQL Editor at:"
    echo "   https://app.supabase.com/project/YOUR_PROJECT/sql"
    echo ""
    echo "4. Get your API keys from:"
    echo "   https://app.supabase.com/project/YOUR_PROJECT/settings/api"
    echo ""
    echo "   Copy them to your .env file:"
    echo "   PUBLIC_SUPABASE_URL=https://your-project.supabase.co"
    echo "   PUBLIC_SUPABASE_ANON_KEY=your-anon-key"
    echo "   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key"
    echo ""
fi

echo ""
echo "============================================"
echo "  Manual Setup Steps"
echo "============================================"
echo ""

echo "Step 1: Create Supabase Project"
echo "   → https://app.supabase.com"
echo "   → Click 'New Project'"
echo "   → Name: '1120pa' or 'opencondo'"
echo "   → Set a strong database password (save it!)"
echo "   → Region: Choose closest to you"
echo ""

echo "Step 2: Run Database Schema"
echo "   → Go to: SQL Editor in your Supabase dashboard"
echo "   → Copy & paste the contents of: supabase-schema.sql"
echo "   → Click 'Run'"
echo ""

echo "Step 3: Get API Keys"
echo "   → Go to: Project Settings → API"
echo "   → Copy 'Project URL' → PUBLIC_SUPABASE_URL"
echo "   → Copy 'anon public' → PUBLIC_SUPABASE_ANON_KEY"
echo "   → Copy 'service_role secret' → SUPABASE_SERVICE_ROLE_KEY"
echo ""

echo "Step 4: Create .env file"
echo "   → cp .env.example .env"
echo "   → Edit .env and add your Supabase keys"
echo ""

echo "Step 5: (Optional) Enable Email Auth"
echo "   → Go to: Authentication → Providers → Email"
echo "   → Enable 'Confirm email'"
echo "   → Add your domain to 'Authorized domains'"
echo ""

echo "Step 6: (Optional) Setup Resend for Emails"
echo "   → Sign up at: https://resend.com"
echo "   → Add and verify your domain"
echo "   → Create an API key"
echo "   → Add to .env: RESEND_API_KEY=re_xxxxx"
echo ""

echo "============================================"
echo "  Useful Commands"
echo "============================================"
echo ""
echo "  supabase link --project-ref YOUR_REF    Link project"
echo "  supabase db push                        Push schema changes"
echo "  supabase db reset                        Reset database (dangerous!)"
echo "  supabase studio                          Open local studio"
echo "  supabase migration new NAME               Create new migration"
echo ""

echo "✓ Setup guide complete!"
