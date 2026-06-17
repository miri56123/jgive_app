# Jgive Campaign Donation Page — Home Assignment

A Ruby on Rails app that reproduces the [Jgive campaign donation page](https://www.jgive.com/new/he/ils/donation-targets/159183). Includes two seeded campaigns, a campaigns index, and a full donation flow.

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

**Campaign** — title, subtitle, description (sanitized HTML), organization name, cover image URL, goal amount, optional bonus goal, status enum (`active` / `ended`).

Key methods:
- `amount_raised` — sum of all donations (pending + paid), memoized per request
- `donor_count` — total donation count, memoized
- `percent_funded` — % of primary goal reached, capped at 100
- `progress_pct` — bar fill % (uses bonus goal as ceiling when present)
- `goal_marker_pct` — position of the primary-goal marker on the bonus bar
- `preset_amounts` — 5 themed presets (food basket or tree-planting, detected from title/org name)

**Donation** — belongs to a campaign. Three integer enums:
- `status`: `pending (0)` | `paid (1)` — default pending
- `frequency`: `one_time (0)` | `recurring (1)` — default one_time
- `display_preference`: `full_name (0)` | `first_name_only (1)` | `anonymous (2)` — default full_name

Additional fields: `months` (integer, 2–36, required for recurring, must be absent for one_time), `dedication_message` (optional text), `payment_intent_id` (reserved for payment provider).

Key methods:
- `display_name` — returns name per preference, "תורם אנונימי" for anonymous
- `total_committed_amount` — `amount × months` for recurring, `amount` for one_time

Validations: amount > 0; donor_name required unless anonymous; months in 2..36 when present, must be absent for one_time donations.

DB indexes: `campaign_id` FK, composite `[campaign_id, status]` for aggregate queries, unique partial index on `payment_intent_id` for webhook lookup.

### Service Object

`app/services/create_donation.rb` — `CreateDonation.new(campaign:, params:).call` returns a `Result` struct with `success?`, `donation`, and `errors`. Controller stays thin; all creation logic lives here.

### Controllers

- `CampaignsController#index` — lists all campaigns, active before ended.
- `CampaignsController#show` — loads campaign + last 20 donations (memoized). 404 on missing campaign via `rescue_from ActiveRecord::RecordNotFound`.
- `DonationsController#create` — guards against ended campaigns; strong params; delegates to `CreateDonation`; redirects on success or re-renders with errors on failure.

### Views

- **Campaigns index** — card grid: cover image, title, org name, amount raised, thin progress bar, donors + % funded.
- **Hero section** — full-width cover image with title/subtitle overlaid (RTL).
- **Stats bar** — amount raised (pending + paid), % funded, donor count, primary goal, bonus goal (purple zone), "Donate" anchor CTA.
- **Progress bar** — LTR bar: green fill for raised amount, purple zone for bonus goal range, 🧡 heart marker at current progress position.
- **Tabs** — Stimulus `tabs_controller.js` switches panels client-side. "About the Project" and "Recent Donations" have real content; "Ambassador Board", "Groups", "Updates" are stubs.
- **Donation form** — frequency toggle (one-time / recurring), 5 preset amount cards (labels change to `N × ₪X` for recurring), months selector (2–36, default 36) with live total, custom amount input, display preference radios, donor name field (hidden when anonymous), optional dedication message.

### Security

- `sanitize` helper with allowlisted tags on campaign description (prevents XSS from admin-entered HTML)
- Strong parameters in `DonationsController`
- CSRF protection via Rails default
- Ended-campaign guard rejects donations via `before_action`

---

## Key Decisions & Tradeoffs

| Decision | Choice | Reasoning |
|----------|--------|-----------|
| Language | Hebrew + RTL | Matches original; `dir="rtl"` on `<html>`, `direction: ltr` on numbers |
| Donation form | Inline section (not modal) | Modal adds ~1h of Stimulus/CSS work for little demo value |
| `amount_raised` | Pending + paid | Assignment spec: "submitting the form should update campaign progress." Bar must move on submit. `status` column tracks paid vs pending for payment processing. |
| Database | SQLite | Zero infra for dev; Render supports it with persistent disk |
| Tabs | Client-side Stimulus | No page reload; stays "Rails way" without a full SPA |
| Preset amounts | Hardcoded on Campaign model | Avoids a separate DB table for a 4–6h scope; keyword detection on title/org name |
| CSS | Tailwind v4 | Fastest path to approximate Jgive's design; ships with Rails 8 |

---

## Assumptions

- "Progress toward goal" includes **both pending and paid** donations. The assignment explicitly states "submitting the form should update the campaign's progress," which requires the bar to move on form submit. The `status` column distinguishes pending from paid for payment processing — only paid donations trigger fund disbursement in a real integration.
- The preset amount labels ("נטיעת עץ", "סל מזון", etc.) are campaign-specific and derived from keywords in the title/organization name. In a real multi-campaign system these would live in a DB column or child table.
- Recurring donations store `frequency: recurring` and `months` but no actual recurring payment is scheduled (that requires a payment provider). The values are passed along to the provider at checkout time.
- The "Ambassador Board" and "Groups" tabs are stubs — the reference site has real data there but implementing them is out of scope for 4–6 hours.

---

## Payment Provider Integration

To move a donation from `pending → paid`:

1. **On form submit** — call the payment provider (e.g. **Stripe**, **Tranzila**, or **Cardcom** for Israeli ISPs) to create a Payment Intent. Store the returned `payment_intent_id` on the donation record (column already exists in schema). Redirect user to hosted payment page or complete with JS SDK.

2. **Webhook endpoint** — add `POST /webhooks/payment` (excluded from CSRF via `protect_from_forgery except: :payment`). On receipt:
   - Verify the provider's signature
   - Find the donation by `payment_intent_id` (indexed for fast lookup)
   - Transition `status` to `paid`
   - `amount_raised` automatically reflects it on next page load

3. **Recurring donations** — use Stripe Subscriptions or Cardcom's standing-order API. Store a `subscription_id` alongside `payment_intent_id`. Webhook handler updates `status` on each successful charge cycle. The `months` and `amount` fields define the commitment; `total_committed_amount` computes the total.

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
