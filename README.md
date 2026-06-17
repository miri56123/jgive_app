# Jgive Campaign Donation Page — Home Assignment

A Ruby on Rails app that reproduces the [Jgive campaign donation page](https://www.jgive.com/new/he/ils/donation-targets/159183) for "הגן הכתום" (The Orange Garden).

## Live URL

https://jgive-app.onrender.com

---

## Running Locally

**Requirements:** Ruby 4.0+, Rails 8.1+, Node not required (importmap)

```bash
git clone <repo-url>
cd jgive_app
bundle install
rails db:setup        # creates DB, runs migrations, seeds data
bin/dev               # starts Rails + Tailwind watcher
```

Visit `http://localhost:3000` — shows the campaigns index; click any campaign to open its page.

**Run tests:**
```bash
rails test
```

---

## What Was Built

### Models

**Campaign** — title, subtitle, description (sanitized HTML), organization name, cover image URL, goal amount, bonus goal, status enum (active/ended).

**Donation** — belongs to a campaign. Three integer enums:
- `status`: `pending (0)` | `paid (1)` — default pending
- `frequency`: `one_time (0)` | `recurring (1)` — default one_time
- `display_preference`: `full_name (0)` | `first_name_only (1)` | `anonymous (2)` — default full_name

`donor_name` is required unless `anonymous`. Amounts must be `> 0`.

DB indexes: `campaign_id` (via FK reference), composite `[campaign_id, status]` for the paid-sum query.

### Service Object

`app/services/create_donation.rb` — `CreateDonation.new(campaign:, params:).call` returns a `Result` struct (`success?`, `donation`, `errors`). Controller stays thin; all business logic lives here.

### Controllers

- `CampaignsController#show` — loads campaign + last 20 donations (pending + paid; memoized to avoid repeated DB hits). 404 on missing campaign via `rescue_from ActiveRecord::RecordNotFound`.
- `DonationsController#create` — strong params, delegates to `CreateDonation`, redirects on success or re-renders on failure.

### Views

- **Hero section** — full-width cover image, title, subtitle overlaid at bottom-right (RTL)
- **Stats bar** — amount raised (paid only), % funded, donor count, goal, bonus goal, "Donate" anchor
- **Tabs** — Stimulus `tabs_controller.js` switches panels client-side. "About" and "Recent Donations" have real content; "Ambassador Board", "Groups", "Updates" are stubs.
- **Donation form** — frequency toggle, 5 preset amount cards, custom amount input, display preference radios, donor name field (hidden when anonymous), optional dedication message.

### Security

- `sanitize` helper with allowlisted tags on campaign description (prevents XSS from admin-entered HTML)
- Strong parameters in `DonationsController`
- CSRF protection via Rails default

---

## Key Decisions & Tradeoffs

| Decision | Choice | Reasoning |
|----------|--------|-----------|
| Language | Hebrew + RTL | Matches original; `dir="rtl"` on `<html>`, CSS `direction: rtl` |
| Donation form | Inline section (not modal) | Modal adds ~1h of Stimulus/CSS work for little demo value; noted in form copy |
| `amount_raised` | Pending + paid | Assignment spec: "submitting the form should update the campaign's progress." Progress must move on submit. In production, only paid count toward actual fund disbursement — tracked via `status` column. |
| Database | SQLite | Zero infra for dev; Render supports it with persistent disk |
| Tabs | Client-side Stimulus | No page reload needed, stays "Rails way" without a full SPA |
| Preset amounts | Hardcoded on Campaign model | Avoids a separate DB table for a 4–6h scope; easily extracted later |
| CSS | Tailwind v4 | Fastest path to approximate Jgive's design; ships with Rails 8 |

---

## Assumptions

- "Progress toward goal" includes **both pending and paid** donations. The assignment explicitly states "submitting the form should update the campaign's progress," which requires the bar to move on form submit. The `status` column distinguishes pending from paid for payment processing purposes — only paid donations trigger fund disbursement in a real integration.
- The preset amount labels ("נטיעת עץ", etc.) are campaign-specific and hardcoded in `Campaign#preset_amounts`. In a real multi-campaign system these would be a separate `preset_amounts` JSON column or child table.
- Recurring donations are stored with `frequency: recurring` but no actual recurring payment is scheduled (that requires a payment provider). The distinction is passed along to the payment provider at checkout time.
- The "Ambassador Board" and "Groups" tabs are stubs — the reference site has real data there but it's out of scope for 4–6 hours.

---

## Payment Provider Integration

To move a donation from `pending → paid`:

1. **On form submit** — before saving, call the payment provider (e.g. **Stripe**, **Tranzila**, or **Cardcom** for Israeli ISPs) to create a Payment Intent. Store the returned `payment_intent_id` on the donation record (column already exists in schema). Redirect user to hosted payment page or complete with JS SDK.

2. **Webhook endpoint** — add `POST /webhooks/payment` (excluded from CSRF protection via `protect_from_forgery except: :payment`). On receipt:
   - Verify the provider's signature
   - Find the donation by `payment_intent_id`
   - Transition `status` to `paid` (and `paid_at` timestamp if added)
   - `amount_raised` automatically reflects it on next page load

3. **Recurring donations** — for `frequency: recurring`, use Stripe Subscriptions or Cardcom's standing-order API. Store a `subscription_id` alongside `payment_intent_id`. Webhook handler updates `status` on each successful charge cycle.

The `Donation#status` enum is the single source of truth — no other code path should set `paid` except the webhook.

---

## What I'd Do With More Time

- **Proper cover images** — use Active Storage (or Cloudinary) instead of bare URL strings
- **Turbo Stream progress update** — after donation create, push a stream to update the stats bar inline without a full page reload
- **Modal donation flow** — match the original site's multi-step modal UX with Turbo Frames
- **i18n** — extract all Hebrew strings to `config/locales/he.yml`
- **Flash auto-dismiss** — add a Stimulus controller to fade out the success banner after 5s
- **Pagination** — Recent Donations tab is limited to 20; add Pagy for more
- **Ambassador Board & Groups** — real data models and views
- **CI** — wire GitHub Actions to run `rails test` + Brakeman on each push

---

## Tools Used

Built with [Claude Code](https://claude.ai/claude-code) as the primary coding assistant, with the transcript attached per assignment instructions.
