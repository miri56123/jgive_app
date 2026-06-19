# Jgive Campaign Donation Page

A Ruby on Rails application that replicates the [Jgive campaign donation page](https://www.jgive.com/new/he/ils/donation-targets/159183) — the complete donor-facing flow from campaign discovery through form submission.

> **Note:** This is a backend-focused project. The UI is functional and reasonably close to the reference, but pixel-perfect visual fidelity was not the goal — backend architecture, data modeling, service design, and test coverage were.

**Live:** https://jgive-app.onrender.com

---

## Getting Started

**Requirements:** Ruby 4.0+, Node not required (importmap)

```bash
git clone <repo-url>
cd jgive_app
bundle install
rails db:setup        # create database, run migrations, seed sample data
bin/dev               # start Rails server + Tailwind watcher
```

Visit `http://localhost:3000` to browse campaigns.

**Tests:**
```bash
rails test
```

**Background worker** (exchange rate refresh, Solid Queue):
```bash
bin/jobs
```

---

## Architecture

Rails 8.1 MVC with service objects, background jobs, and WebSocket real-time updates.

**Stack:** Ruby 4.0.5 · Rails 8.1.3 · SQLite · Solid Cache · Solid Queue · Action Cable · Tailwind CSS v4 · Hotwire (Turbo + Stimulus) · Importmap · Render.com

**Request lifecycle:**
```
Browser (Stimulus + Turbo)
  │  HTTP requests        → CampaignsController / DonationsController
  │  WebSocket /cable     → Action Cable → Turbo Streams → DOM updates
  └──────────────────────────────────────────────────────────────────
Controllers delegate business logic → CreateDonation / ExchangeRateService
Solid Queue runs recurring → ExchangeRateRefreshJob (every 55 min)
Rack::Attack sits at middleware boundary → rate limiting per IP
```

---

## Data Model

### Campaign

| Column | Type | Notes |
|--------|------|-------|
| `title`, `subtitle`, `organization_name` | string | |
| `description` | text | sanitized HTML |
| `cover_image_url` | string | |
| `goal_amount` | decimal(12,2) | primary goal in ILS |
| `bonus_goal_amount` | decimal(12,2) | optional stretch goal |
| `status` | integer enum | `active(0)` \| `ended(1)` |

### Donation

| Column | Type | Notes |
|--------|------|-------|
| `campaign_id` | integer | indexed FK |
| `amount` | decimal(12,2) | |
| `currency` | string | ILS / USD / EUR / GBP / CAD |
| `exchange_rate` | decimal(10,6) | ILS rate snapshotted at create time |
| `status` | integer enum | `pending(0)` \| `paid(1)` |
| `frequency` | integer enum | `one_time(0)` \| `recurring(1)` |
| `months` | integer | 2–36; required for recurring, must be absent for one-time |
| `display_preference` | integer enum | `full_name(0)` \| `first_name_only(1)` \| `anonymous(2)` |
| `donor_name` | string | nullable; required unless anonymous |
| `dedication_message` | text | optional |
| `payment_intent_id` | string | reserved for payment provider integration |

**Indexes:** `campaign_id` · composite `(campaign_id, status)` for aggregate queries · unique partial on `payment_intent_id WHERE NOT NULL` for fast webhook lookup.

---

## Key Components

### Models

**`Campaign`**
- `amount_raised` — `SUM(amount * exchange_rate)` in SQL; includes pending and paid; memoized per request instance
- `percent_funded` — capped at 100%; `progress_pct` uses bonus goal as ceiling when present
- `goal_marker_pct` — CSS `left: X%` position of the primary-goal marker on the bonus bar
- `preset_amounts` — five themed presets derived from title/org keywords (food basket vs. tree-planting)

**`Donation`**
- Three integer enums generate predicates (`anonymous?`), scopes (`.paid`), and bang methods (`paid!`) automatically
- `after_create_commit` broadcasts two Turbo Streams to all connected clients: replaces the stats bar with fresh totals, prepends the new donation card to the Recent Donations grid
- `display_name` — returns full name, first name, or "תורם אנונימי" based on `display_preference`
- `total_committed_amount` — `amount × months` for recurring, `amount` for one-time

### Service Objects

**`CreateDonation`** (`app/services/create_donation.rb`)
Encapsulates donation creation: builds the record, fetches and snapshots the exchange rate, saves, and returns a `Result` struct (`success?`, `donation`, `errors`). Keeps the controller to HTTP concerns only.

**`ExchangeRateService`** (`app/services/exchange_rate_service.rb`)
Fetches live ILS rates from the [Frankfurter API](https://api.frankfurter.dev) over HTTPS with 5-second timeouts. Rates are cached via Rails cache (Solid Cache) for one hour and fall back to `1.0` with a log warning on API failure. Accepts `force: true` to bypass the cache — used by the background refresh job.

### Background Jobs

**`ExchangeRateRefreshJob`** (`app/jobs/exchange_rate_refresh_job.rb`)
Calls `ExchangeRateService.to_ils(currency, force: true)` for each non-ILS currency, proactively re-warming the cache before it expires. Scheduled every 55 minutes via Solid Queue recurring jobs (`config/recurring.yml`), ensuring the cache is always warm within the one-hour TTL window.

### Controllers

- **`CampaignsController#index`** — lists campaigns, active before ended
- **`CampaignsController#show`** — loads campaign + last 20 donations + empty donation object; `rescue_from ActiveRecord::RecordNotFound` returns 404
- **`DonationsController#create`** — `before_action` guard for ended campaigns; delegates to `CreateDonation`; redirects on success, re-renders with errors on failure (422)

### Views & Frontend

- **Campaigns index** — card grid with cover image, progress bar, amount raised, donor count
- **Hero section** — full-width cover image with title/subtitle overlay (RTL)
- **Stats bar** (`campaigns/_stats.html.erb`) — amount raised, % funded, donor count, goal markers; extracted as a partial so Turbo Streams can replace it in-place
- **Progress bar** — layered absolute-position divs: gray base, purple bonus zone, green fill, 🧡 marker at current position
- **Tabs** — Stimulus `tabs_controller.js` switches panels client-side; "About" and "Recent Donations" have real content; Ambassador Board, Groups, Updates are stubs
- **Donation modal** — native `<dialog>` element managed by `modal_controller.js`; auto-opens on validation failure; frequency toggle, currency selector, preset cards, months selector with live total, display preference, anonymous mode
- **Real-time updates** — `turbo_stream_from @campaign` subscribes each page load to the campaign's Action Cable channel; on donation create, `after_create_commit` broadcasts a stats bar replacement and a donation card prepend to all subscribers simultaneously

### Security

| Measure | Implementation |
|---------|---------------|
| Idempotency | UUID generated per form render, stored as `idempotency_key` (nullable, unique partial index); duplicate submit returns existing donation silently |
| Rate limiting | `Rack::Attack`: 5 donation POSTs/min per IP · 300 general requests/5 min per IP · assets + `/cable` + `/up` safelisted · 429 on throttle |
| XSS | `sanitize` with allowlisted tags on campaign description |
| Mass assignment | Strong parameters in `DonationsController` |
| CSRF | Rails default `authenticity_token` |
| Ended campaigns | `before_action :require_active_campaign` blocks POST to closed campaigns |

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Hebrew + RTL | `dir="rtl"` on `<html>`, `direction: ltr` on numbers | Matches reference site |
| Donation modal | Native `<dialog>` + Stimulus | Browser top-layer API; no library; focus trap and Escape key built in |
| Multi-currency | Exchange rate snapshotted at create time | `amount_raised` remains historically accurate regardless of rate fluctuations; server-side fetch avoids CORS |
| `amount_raised` scope | Pending + paid | Assignment requires the progress bar to update on form submit; `status` column exists for payment processing |
| Real-time | Action Cable async adapter + Turbo Streams | No Redis or additional infrastructure required for a single-server deployment |
| Rate limiting | Rack::Attack + Solid Cache | Fits naturally into the existing cache layer; no nginx config required on Render |
| Database | SQLite | Sufficient for a single-server demo; Render supports it with a persistent disk |
| Asset pipeline | Importmap + Propshaft | Eliminates Node.js/webpack dependency entirely |

---

## Assumptions

- Progress toward goal includes both **pending and paid** donations. The spec states "submitting the form should update campaign progress," so the bar must move on submission. The `status` column tracks payment state separately — only `paid` donations would trigger disbursement in a real integration.
- Preset amount labels are derived from campaign title/org keywords. A production system would store these in a database column.
- Recurring donations capture `frequency`, `months`, and `amount` but do not schedule actual charges — those values are passed to the payment provider at checkout.
- Ambassador Board, Groups, and Updates tabs are stubs; the reference site has content there but it is out of scope.

---

## Payment Provider Integration

To advance a donation from `pending → paid`:

1. **On submit** — call the provider (Stripe, Tranzila, or Cardcom) to create a Payment Intent; store `payment_intent_id` on the donation record (column already exists); redirect to the hosted payment page.

2. **Webhook** — add `POST /webhooks/payment` (exempted from CSRF). Verify the provider signature, look up the donation by `payment_intent_id` (partial index ensures fast lookup), call `donation.paid!`.

3. **Recurring** — use Stripe Subscriptions or Cardcom standing orders; store `subscription_id`; webhook marks each charge cycle. `total_committed_amount` (`amount × months`) represents the full pledge value.

`Donation#status` is the single source of truth — only the webhook handler should transition to `paid`.

---

## Future Improvements

### Backend
- Payment provider integration (Stripe / Cardcom) with webhook handler and `paid_at` timestamp
- `ProcessPaymentWebhookJob` — return 200 immediately from the webhook endpoint, process async via Solid Queue
- Admin interface (HTTP Basic Auth) for campaign management and donation status transitions
- Move preset amounts to a `preset_amounts` JSONB column on Campaign
- i18n: extract Hebrew strings to `config/locales/he.yml`

### Frontend
- Multi-step donation modal (amount → display preference → confirmation) using Turbo Frames
- Flash auto-dismiss via Stimulus
- Pagination on Recent Donations (Pagy + infinite scroll)
- Active Storage / Cloudinary for campaign cover images
- Mobile-optimised layout for the stats bar and donation form

---

## Test Suite

**54 tests · 120 assertions · 0 failures · 0 skips**

### Campaign model — 15 tests
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

### Donation model — 25 tests
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
| idempotency_key allows nil on multiple donations | nullable uniqueness |
| idempotency_key must be unique when present | duplicate prevention |

### Request integration — 14 tests
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
| POST create stores idempotency_key on donation | key persisted |
| POST create with duplicate idempotency_key is idempotent | no duplicate record, redirects |

---

## Thought Process & AI Usage

### Approach

The implementation began with a detailed review of the assignment requirements and a live inspection of the reference campaign page using **Claude for Chrome** to capture layout structure, interaction patterns, and the data the page exposes. From that, a complete implementation plan was drafted — schema, routes, service objects, and Stimulus controllers — before any code was written.

**Claude Code** (Anthropic's CLI) was used as the primary coding assistant throughout: model and validation scaffolding, Stimulus controller logic, CSS layout, CI pipeline debugging, and architectural decisions.

### Where AI accelerated development

- **Model layer** — generated enums, validations, scopes, and memoized helpers correctly in a single pass
- **Stimulus controllers** — `donation_form_controller.js` (~170 lines covering preset selection, currency conversion, frequency toggle, live total, and anonymous mode) worked on first run
- **RTL layout** — identified the need for `direction: ltr` isolation on numeric elements, which is non-obvious
- **Multi-currency architecture** — proposed snapshotting `exchange_rate` at create time so `amount_raised` remains historically stable; identified that server-side rate embedding avoids browser CORS issues
- **Real-time broadcast** — identified that `amount_raised` uses `||=` memoization, requiring `Campaign.find(campaign_id)` in `after_create_commit` rather than the already-loaded association

### Where AI required correction

- **RuboCop spacing** — generated `[x, 100]` without inner spaces in several array literals, causing CI lint failures; required an autocorrect pass
- **Modal sizing** — applied Tailwind `max-w-md` to the `<dialog>` element, which has no effect in the browser's top layer; corrected to explicit inline `max-width` style
- **Frankfurter API redirect** — used `Net::HTTP.get_response` against `api.frankfurter.app`, which returns a 301 that `Net::HTTP` does not follow automatically; fixed by switching to `api.frankfurter.dev/v1` with an explicit SSL connection
- **`months` validation** — `validates :months, absence: true, if: :one_time?` fired on one-time submissions because the hidden months field always submitted a value; fix required reading the error carefully and clearing the field on frequency toggle
- **Memoization in tests** — `@amount_raised ||=` caused a test failure when asserting an immediate update; fixed by reloading the record in the assertion

---

## Tools

- [Claude Code](https://claude.ai/claude-code) — primary coding assistant
- [Claude for Chrome](https://claude.ai) — browser-based UI inspection of the reference page

The full AI session transcript (raw conversation between developer and Claude Code, including decisions, corrections, and rationale) is available in [`AI_TRANSCRIPT.md`](./AI_TRANSCRIPT.md).
