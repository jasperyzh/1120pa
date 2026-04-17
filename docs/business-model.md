# The "Open Source SaaS" Business Strategy

We are building the "Obsidian for Living Communities." A local-first, privacy-focused, modular system that is free for those with the skills, but paid for those who want convenience.

## 1. The Market Problem

- **Existing Competitors:** BuildingLink, ConciergePlus (Expensive, look like software from 2005, feature-bloated).
- **Free Alternatives:** Facebook Groups (Terrible privacy, algorithm-controlled), WhatsApp Groups (Noisy, phone numbers exposed to everyone, impossible to moderate).

## 2. Technical Sustainability (Zero Cost to Operate)

If we are offering this open-source, the architecture must be able to run for $0.

- **Image Resizing:** Do not resize on the server. Use `browser-image-compression` on the frontend before upload. This uses zero server CPU and tiny storage space.
- **Auto-Expire:** Do not write cron jobs. Use PostgreSQL Views or Row Level Security (RLS) to hide items older than 30 days.
- **Compute:** Deploy to Vercel or Netlify (Free Tier).
- **Database:** Supabase (Free Tier handles up to 500MB database and 50,000 monthly active users).

## 3. The "Obsidian Model" Monetization

This is the **"Open Core"** business model.

### Tier 1: The "Hacker" (Free)
- **Who:** A tech-savvy resident or a frugal Condo Board member.
- **Offer:** Open Source Code (MIT License).
- **The Catch:** They have to create their own Supabase account, set up the `.env` variables, manage their own domain, and fix it if it breaks.
- **Value:** These users become testers, bug fixers, and evangelists.

### Tier 2: The "Managed Cloud" ($29 - $49/mo per condo)
- **Who:** The Property Manager who has no idea what a "Git Repo" is.
- **Offer:** "We set it up for you."
- **Value Proposition:**
  - Custom Domain (`portal.sunriseresidences.com`).
  - Email Support & Daily Backups.
  - Pre-configured Email (We handle Resend API keys so they don't have to verify DNS records).
- **Our Cost:** ~$0 (They fit in the free tiers).
- **Our Profit:** ~100%.

### Tier 3: The "Enterprise" (Upsells)
- SMS/WhatsApp Notifications (Integration with Twilio/WhatsApp API).
- Amenity Booking Systems.
- Payment Gateways (Stripe integration for maintenance fees).

## 4. Why This Works

1. **Low Churn:** Once a condo board adopts software and gets residents to sign up, they rarely leave.
2. **Viral Growth:** Property Managers often manage 10-20 buildings. Winning one building can lead to 19 more.
3. **Portfolio Piece:** A fully functional, open-source SaaS on GitHub is an incredible asset for a developer.

## 5. Services Directory Monetization

The local services directory opens up additional revenue streams:

### Provider Tiers

| Tier | Price | Features |
|------|-------|----------|
| **Basic** | Free | Profile listing, up to 4 portfolio images, auto-expire after 30 days |
| **Premium** | $5/mo | No expire, unlimited images, "Verified" badge, priority placement |
| **Featured** | $10/mo | Homepage spotlight, "Recommended" badge, basic analytics |

### Why Providers Will Pay
- **Direct Access:** Reach 200-500 households in one condo
- **Trusted Network:** Residents prefer known neighbors over random contractors
- **No Commission:** Unlike TaskRabbit or蚂蜂窝, we don't take a cut of their earnings
- **Local SEO:** Get discovered by neighbors searching for "plumber near me"

### Implementation
- Payment via Stripe Connect (providers get paid directly, we take a small fee)
- OR: Simple subscription model (monthly/yearly billing)
- Free tier always available (no lock-in, demonstrates value first)