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

Additional fields: `months` (integer, 2–36, required for recurring, must be absent for one_time), `dedication_message` (optional text), `payment_intent_id` (reserved for payment provider), `currency` (string, default `"ILS"`), `exchange_rate` (decimal, default `1.0` — ILS per 1 unit of the chosen currency, snapshotted at create time).

Key methods:
- `display_name` — returns name per preference, "תורם אנונימי" for anonymous
- `total_committed_amount` — `amount × months` for recurring, `amount` for one_time

Validations: amount > 0; currency must be one of `ILS USD EUR GBP CAD`; exchange_rate > 0; donor_name required unless anonymous; months in 2..36 when present, must be absent for one_time donations.

DB indexes: `campaign_id` FK, composite `[campaign_id, status]` for aggregate queries, unique partial index on `payment_intent_id` for webhook lookup.

### Service Objects

`app/services/create_donation.rb` — `CreateDonation.new(campaign:, params:).call` returns a `Result` struct with `success?`, `donation`, and `errors`. Controller stays thin; all creation logic lives here. On each call, sets `exchange_rate` via `ExchangeRateService` before saving.

`app/services/exchange_rate_service.rb` — `ExchangeRateService.to_ils(currency)` fetches the live ILS rate from the [Frankfurter API](https://api.frankfurter.dev) over HTTPS. Rates are cached in Rails cache for 1 hour. Falls back to `1.0` (with a log warning) if the API is unreachable. `amount_raised` on Campaign uses `SUM(amount * exchange_rate)` so all donations are normalized to ILS regardless of original currency.

### Controllers

- `CampaignsController#index` — lists all campaigns, active before ended.
- `CampaignsController#show` — loads campaign + last 20 donations (memoized). 404 on missing campaign via `rescue_from ActiveRecord::RecordNotFound`.
- `DonationsController#create` — guards against ended campaigns; strong params; delegates to `CreateDonation`; redirects on success or re-renders with errors on failure.

### Views

- **Campaigns index** — card grid: cover image, title, org name, amount raised, thin progress bar, donors + % funded.
- **Hero section** — full-width cover image with title/subtitle overlaid (RTL).
- **Stats bar** — amount raised (pending + paid), % funded, donor count, primary goal, bonus goal (purple zone), "Donate" anchor CTA. Extracted to `campaigns/_stats.html.erb` partial so it can be re-rendered via Turbo Streams.
- **Progress bar** — LTR bar: green fill for raised amount, purple zone for bonus goal range, 🧡 heart marker at current progress position.
- **Tabs** — Stimulus `tabs_controller.js` switches panels client-side. "About the Project" and "Recent Donations" have real content; "Ambassador Board", "Groups", "Updates" are stubs.
- **Donation modal** — native `<dialog>` element opened by the "לתרומה" CTA; Stimulus `modal_controller.js` handles open/close/backdrop-click. Auto-opens on validation failure so errors are immediately visible. Frequency toggle (one-time / recurring), currency selector (ILS/USD/EUR/GBP/CAD), 5 preset amount cards (converted to selected currency client-side using server-embedded rates; labels change to `N × $X` for recurring), months selector (2–36, default 36) with live total, custom amount input, display preference radios, donor name field (hidden when anonymous), optional dedication message.
- **Real-time updates** — Action Cable + Turbo Streams push live updates to every connected browser tab when a donation is submitted. `turbo_stream_from @campaign` subscribes the page; `Donation#after_create_commit` broadcasts two streams: `broadcast_replace_to` replaces the stats bar with fresh numbers, and `broadcast_prepend_to` inserts the new donation card at the top of the Recent Donations grid — no page reload required on any client.

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
| Donation form | Native `<dialog>` modal | Browser-native modal API; no library needed; Stimulus controller is ~20 lines |
| Multi-currency | Snapshot exchange rate at create time | Rate stored on the donation record so `amount_raised` is always historically accurate; server-side Frankfurter fetch avoids browser CORS issues |
| `amount_raised` | Pending + paid | Assignment spec: "submitting the form should update campaign progress." Bar must move on submit. `status` column tracks paid vs pending for payment processing. |
| Database | SQLite | Zero infra for dev; Render supports it with persistent disk |
| Tabs | Client-side Stimulus | No page reload; stays "Rails way" without a full SPA |
| Preset amounts | Hardcoded on Campaign model | Avoids a separate DB table for a 4–6h scope; keyword detection on title/org name |
| CSS | Tailwind v4 | Fastest path to approximate Jgive's design; ships with Rails 8 |
| Real-time updates | Action Cable async adapter + Turbo Streams | No extra gem or Redis needed for a single-server demo; `after_create_commit` broadcasts stats bar replacement and donation card prepend to all subscribers |

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

### Backend

- **Payment provider integration** — wire Stripe or Cardcom: create a Payment Intent on form submit, store `payment_intent_id`, add a `POST /webhooks/payment` endpoint that verifies the signature and transitions `status` to `paid`
- **Recurring payment scheduling** — for `frequency: recurring`, create a Stripe Subscription (or Cardcom standing-order); store `subscription_id`; webhook handler marks each charge cycle as paid
- **`paid_at` timestamp** — add a `paid_at` datetime column to Donation; set it in the webhook handler; enables financial reporting by actual collection date vs. pledge date
- **Background jobs** — move webhook processing to ActiveJob (e.g. `ProcessPaymentWebhookJob`) so the webhook endpoint returns 200 immediately and processing happens async; use Solid Queue (ships with Rails 8)
- **Preset amounts as data** — move campaign presets out of hardcoded Ruby into a `preset_amounts` JSONB column on Campaign; allows admins to configure them without a deploy
- **Ambassador Board & Groups models** — `Ambassador` (belongs_to campaign, donor_name, amount_raised, rank) and `Group` (belongs_to campaign, name, member_count, total_raised); expose via existing tab stubs
- **Admin interface** — a minimal password-protected `/admin` for creating/editing campaigns, viewing all donations, and manually transitioning donation status; Rails' built-in `authenticate_or_request_with_http_basic` is enough for a demo
- **i18n backend** — extract all Hebrew strings to `config/locales/he.yml`; use `t()` helpers throughout; prepares for multi-language support
- **CI pipeline** — GitHub Actions: run `rails test` + Brakeman (security audit) + `bundle audit` (dependency CVEs) on every push and PR

### Frontend

- **Multi-step modal flow** — extend the current single-step dialog into amount → display preference → confirmation steps using Turbo Frames
- **Flash auto-dismiss** — Stimulus controller to fade out success/alert banners after 5 seconds
- **Proper cover images** — Active Storage (or Cloudinary) instead of bare URL strings; add drag-and-drop upload to admin
- **Pagination** — Recent Donations tab capped at 20; add Pagy with infinite scroll or "load more"
- **Responsive polish** — mobile layout for the stats bar and donation form (currently functional but not optimized for small screens)

---

## Test Suite

**50 tests · 107 assertions · 0 failures · 0 skips**

### Campaign model (15 tests)
| Test | Covers |
|------|--------|
| requires title | presence validation |
| requires organization_name | presence validation |
| requires goal_amount > 0 | numericality validation |
| amount_raised includes pending and paid | all donations counted toward progress |
| amount_raised updates immediately on new donation | memoization cleared on fresh load |
| percent_funded capped at 100 | overflow protection |
| donor_count includes pending and paid | all donations counted |
| active / ended enum values | integer backing (0/1) |
| progress_pct uses bonus_goal_amount as ceiling | dual-goal bar logic |
| progress_pct never above 100 | cap guard |
| goal_marker_pct returns nil with no bonus goal | single-goal campaigns |
| goal_marker_pct returns correct % with bonus goal | marker position math |
| preset_amounts → food presets for food campaign | keyword detection |
| preset_amounts → tree presets for non-food campaign | keyword detection |
| RECENT_DONATIONS_LIMIT constant is 20 | magic-number extracted |

### Donation model (23 tests)
| Test | Covers |
|------|--------|
| valid with all required attributes | happy path |
| amount must be > 0 / cannot be negative | numericality validation |
| donor_name required for full_name / first_name_only | conditional presence |
| donor_name not required when anonymous | anonymous bypass |
| status defaults to pending | enum default |
| frequency defaults to one_time | enum default |
| .paid / .pending scopes | enum-generated scopes |
| display_name: full name | enum predicate |
| display_name: first name only | split logic |
| display_name: anonymous label | fallback string |
| display_name: nil donor_name returns nil safely | safe navigation |
| enum values are correct integers | backing values |
| DEFAULT_MONTHS constant is 36 | magic-number extracted |
| recurring donation accepts months | valid range |
| months must be between 2 and DEFAULT_MONTHS | bounds validation |
| months can be nil for one-time donations | nil allowed |
| months must be absent for one_time donations | consistency enforcement |
| total_committed_amount: one_time = amount | formula |
| total_committed_amount: recurring = amount × months | formula |
| total_committed_amount: nil months defaults to 0 | nil safety |

### Integration — requests (12 tests)
| Test | Covers |
|------|--------|
| GET /campaigns → 200 | index route |
| GET /campaigns/:id → 200 | show route |
| GET /campaigns/99999 → 404 | rescue_from RecordNotFound |
| POST create valid params → redirect + pending status | happy path |
| POST create sets status to pending | status default |
| POST create missing amount → 422 | validation error |
| POST create missing donor_name → 422 | validation error |
| POST create anonymous → no donor_name required | anonymous bypass |
| POST create recurring → stores months | recurring logic |
| POST create invalid months (1) → 422 | months bounds |
| POST create to ended campaign → redirect + alert | ended-campaign guard |
| POST create to missing campaign → 404 | rescue_from RecordNotFound |

---

## Thought Process & AI Usage

### How I approached the problem

Started by reading the assignment requirements and inspecting the live Jgive campaign page to understand the exact layout, interactions, and data model. From there I wrote an implementation plan (schema, routes, service objects, Stimulus controllers) before writing any code, so the AI had a clear spec to work against rather than guessing at structure.

I used **Claude Code** (Anthropic's CLI) as the primary coding assistant throughout — for scaffolding, model/validation logic, Stimulus controllers, CSS, and debugging CI failures.

### Where AI helped

- **Bootstrapping speed** — generated the full model layer (enums, validations, scopes, memoized helpers), service object pattern, and controller guards in one pass with no structural errors.
- **Stimulus controllers** — `donation_form_controller.js` (~170 lines) was produced correctly end-to-end: preset selection, frequency toggle, months visibility, anonymous toggle, and live total calculation all worked on first run.
- **RTL layout quirks** — suggested `direction: ltr` isolation for the progress bar and numeric amounts, which is non-obvious and correct.
- **CI debugging** — correctly diagnosed that Windows doesn't preserve Unix executable bits (`git update-index --chmod=+x`) and that bin scripts had a `ruby.exe` shebang incompatible with Linux runners.
- **Multi-currency architecture** — proposed snapshotting the exchange rate at donation-create time (rather than re-fetching on read) so historical `amount_raised` values remain stable if exchange rates shift.
- **Real-time broadcast design** — correctly identified that `amount_raised` uses `||=` memoization, so the `after_create_commit` callback must call `Campaign.find(campaign_id)` to get a fresh instance rather than reusing the already-loaded `campaign` association (which would return the pre-donation cached value).

### Where AI needed correction or caused issues

- **RuboCop spacing** — generated `[x, 100]` (missing inner spaces) in several array literals, causing CI lint failures. Required a manual autocorrect pass.
- **Modal width** — initially used Tailwind `max-w-md` on the `<dialog>` element, which had no effect because the browser renders modals in the top layer where Tailwind utility classes aren't applied. Needed to switch to an explicit inline `max-width` style.
- **Frankfurter API redirect** — original service used `Net::HTTP.get_response` against `api.frankfurter.app`, which returns a 301 that `Net::HTTP` doesn't follow. The AI didn't catch that `get_response` doesn't handle redirects; found by testing the service directly and seeing the 301. Fixed by switching to `api.frankfurter.dev/v1` with an explicit `Net::HTTP` SSL connection.
- **`months` absence validation** — the `validates :months, absence: true, if: :one_time?` validation was triggered on form submit for one-time donations because the recurring months hidden field always submitted a value. The AI's initial fix was correct (clear the hidden field on frequency toggle) but needed to be identified first by reading the error message carefully.
- **Memoization in tests** — `@amount_raised ||=` memoization caused a test failure (`amount_raised_updates_immediately`) because the cached value on the already-loaded instance wasn't cleared. Fixed by reloading the record in the assertion; the AI suggested the fix but didn't anticipate the failure upfront.

---

## Tools Used

Built with [Claude Code](https://claude.ai/claude-code) as the primary coding assistant. The full conversation transcript is attached per assignment instructions.
