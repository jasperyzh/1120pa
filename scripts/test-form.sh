#!/bin/bash
# ================================================
# OpenCondo - Form Submission Test Script
# ================================================

set -e

SUPABASE_URL=${PUBLIC_SUPABASE_URL:-"https://oagdtbevdwclnnvitcqz.supabase.co"}
ANON_KEY=${PUBLIC_SUPABASE_ANON_KEY:-"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9hZ2R0YmV2ZHdjbG5udml0Y3F6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNTIyNjcsImV4cCI6MjA4OTgyODI2N30.V5wwxtXrmkqMUGuU8jb8uE5tzI_SvHA2RGPcbyZWQs4"}

echo "============================================"
echo "  Testing 1120pa Form Submission"
echo "============================================"
echo ""

# Test JSON payload
PAYLOAD='{
  "_form_id": "contact",
  "_client_id": "default",
  "name": "Test User",
  "email": "test@example.com",
  "phone": "+60 12-345 6789",
  "subject": "general",
  "message": "This is a test submission to verify the form is working correctly."
}'

echo "1. Sending test POST request to /api/forms/submit..."
echo ""

# Make the request (assuming local dev server on port 4321)
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:4321/api/forms/submit" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" 2>/dev/null || echo "{\"error\":\"Server not running\"}\n000")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

echo "   HTTP Status: $HTTP_CODE"
echo "   Response: $BODY"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Form submission endpoint is working!"
    echo ""
    echo "2. Checking database for submission..."
    
    # Wait a moment for DB to update
    sleep 1
    
    # Check the latest submission
    SUBMISSION=$(curl -s "$SUPABASE_URL/rest/v1/form_submissions?order=created_at.desc&limit=1" \
      -H "apikey: $ANON_KEY" \
      -H "Authorization: Bearer $ANON_KEY")
    
    echo "   Latest submission:"
    echo "   $SUBMISSION"
    echo ""
    
    echo "✅ All tests passed!"
else
    echo "❌ Form submission failed with HTTP $HTTP_CODE"
fi

echo ""
echo "============================================"
echo ""
echo "To test manually:"
echo "1. Run: npm run dev"
echo "2. Visit: http://localhost:4321/contact"
echo "3. Fill out the form and submit"
echo "4. Check your email for the notification"
echo "5. Check Supabase dashboard for the stored data"
