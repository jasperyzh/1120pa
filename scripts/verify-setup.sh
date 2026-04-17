#!/bin/bash
# ================================================
# OpenCondo - Supabase Verification Script
# ================================================

set -e

echo "============================================"
echo "  Supabase & Resend Verification"
echo "============================================"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found!"
    echo ""
    echo "Please create a .env file with your credentials:"
    echo "   cp .env.example .env"
    echo "   # Then edit .env with your actual values"
    exit 1
fi

echo "✓ .env file found"
echo ""

# Load environment variables
source .env 2>/dev/null || true

# Check required variables
echo "Checking configuration..."
echo ""

check_var() {
    local var_name=$1
    local var_value=$(eval echo \$$var_name)
    if [ -z "$var_value" ] || [ "$var_value" = "placeholder" ] || [ "$var_value" = "your-"* ]; then
        echo "❌ $var_name: NOT SET"
        return 1
    else
        echo "✓ $var_name: SET"
        return 0
    fi
}

MISSING=0

check_var "PUBLIC_SUPABASE_URL" || MISSING=1
check_var "PUBLIC_SUPABASE_ANON_KEY" || MISSING=1
check_var "SUPABASE_SERVICE_ROLE_KEY" || MISSING=1
check_var "RESEND_API_KEY" || MISSING=1

echo ""

if [ $MISSING -eq 1 ]; then
    echo "❌ Missing required environment variables"
    echo ""
    echo "Please update your .env file with:"
    echo "  PUBLIC_SUPABASE_URL=https://xxxx.supabase.co"
    echo "  PUBLIC_SUPABASE_ANON_KEY=eyJ..."
    echo "  SUPABASE_SERVICE_ROLE_KEY=eyJ..."
    echo "  RESEND_API_KEY=re_..."
    exit 1
fi

echo ""
echo "============================================"
echo "  Testing Connections"
echo "============================================"
echo ""

# Test Supabase connection
echo "1. Testing Supabase connection..."
SUPABASE_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "apikey: $PUBLIC_SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $PUBLIC_SUPABASE_ANON_KEY" \
    "$PUBLIC_SUPABASE_URL/rest/v1/?select=*&limit=1" 2>/dev/null || echo "000")

SUPABASE_STATUS=$(echo "$SUPABASE_RESPONSE" | tail -1)
SUPABASE_BODY=$(echo "$SUPABASE_RESPONSE" | head -1)

if [ "$SUPABASE_STATUS" = "200" ]; then
    echo "   ✓ Supabase REST API: Connected"
elif [ "$SUPABASE_STATUS" = "401" ]; then
    echo "   ⚠️  Supabase REST API: Connected but auth issue (check keys)"
elif [ "$SUPABASE_STATUS" = "000" ]; then
    echo "   ❌ Supabase REST API: Connection failed"
    echo "      Check your PUBLIC_SUPABASE_URL"
else
    echo "   ⚠️  Supabase REST API: Status $SUPABASE_STATUS"
fi

# Test Resend connection
echo ""
echo "2. Testing Resend API..."
RESEND_RESPONSE=$(curl -s -w "%{http_code}" \
    -H "Authorization: Bearer $RESEND_API_KEY" \
    "https://api.resend.com/domains" 2>/dev/null || echo "000")

RESEND_STATUS="${RESEND_RESPONSE: -3}"
RESEND_BODY="${RESEND_RESPONSE:0:${#RESEND_RESPONSE}-3}"

if [ "$RESEND_STATUS" = "200" ]; then
    echo "   ✓ Resend API: Connected"
elif [ "$RESEND_STATUS" = "401" ]; then
    echo "   ❌ Resend API: Invalid API key"
elif [ "$RESEND_STATUS" = "000" ]; then
    echo "   ❌ Resend API: Connection failed"
else
    echo "   ⚠️  Resend API: Status $RESEND_STATUS"
fi

echo ""
echo "============================================"
echo "  Database Schema Check"
echo "============================================"
echo ""

# Check if tables exist
echo "3. Checking database tables..."

TABLES=$(curl -s \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    "$PUBLIC_SUPABASE_URL/rest/v1/?select=tablename&schemaname=public&eq.tablename=profiles" 2>/dev/null || echo "")

if echo "$TABLES" | grep -q "profiles"; then
    echo "   ✓ Tables exist (already initialized)"
else
    echo "   ⚠️  Tables not found"
    echo "   → Run the SQL in supabase-schema.sql in Supabase SQL Editor"
fi

echo ""
echo "============================================"
echo "  Next Steps"
echo "============================================"
echo ""
echo "1. If tables don't exist, go to:"
echo "   https://app.supabase.com → SQL Editor"
echo "   → Paste contents of supabase-schema.sql"
echo "   → Click 'Run'"
echo ""
echo "2. Test the form at: /contact"
echo ""
echo "✓ Verification complete!"
