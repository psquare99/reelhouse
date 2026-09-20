# REELHOUSE Feedback Worker

Minimal, privacy-preserving Cloudflare Worker endpoint for user-initiated feedback and bug report submissions in REELHOUSE.

## Architecture

```
REELHOUSE Flutter App
        ↓ HTTPS POST /v1/feedback
Cloudflare Worker (Stateless, Rate-Limited)
        ↓ Resend API (Bearer Secret)
REELHOUSE Developer Feedback Inbox
```

- **Stateless**: The worker does not store feedback messages, user data, or identifiers.
- **Privacy-Guaranteed**: Only allowlisted feedback payloads (`category`, `subject`, `message`, non-sensitive `diagnostics`) are accepted. No library data, media files, TMDB credentials, or profile photos can be forwarded.
- **Abuse Protected**: Cloudflare Workers Rate Limiting binding limiting feedback submissions to 10 per 60 seconds per IP.

---

## 1. Local Development Setup

### Install Dependencies
```bash
cd feedback_worker
npm install
```

### Configure Local Secrets
Copy `.dev.vars.example` to `.dev.vars` (gitignored):
```ini
RESEND_API_KEY=re_your_resend_api_key_here
FEEDBACK_TO_EMAIL=feedback@reelhouse.app
FEEDBACK_FROM_EMAIL=REELHOUSE Feedback <feedback@reelhouse.app>
```

### Run Locally
```bash
npm run dev
```

### Run Tests & Typecheck
```bash
npm test
npm run typecheck
```

---

## 2. Production Deployment & Configuration

### Prerequisites

- A Cloudflare account with the Worker configured as a custom domain (see Step 3).

### Step 1: Set Worker Secrets

Create the `RESEND_API_KEY` secret (do not commit secrets to source control):
```bash
npx wrangler secret put RESEND_API_KEY
```
You will be prompted to enter the value. The secret is scoped to your Cloudflare account, not stored in this repository.

### Step 2: Configure Production Env Vars

If the production email recipients differ from the local defaults, set them as Worker environment variables:
```bash
npx wrangler secret put FEEDBACK_TO_EMAIL
npx wrangler secret put FEEDBACK_FROM_EMAIL
```

### Step 3: Deploy Worker

> **Important**: The **production** endpoint is `https://feedback.thelongwayhome.dev/v1/feedback` and is wired to a Custom Domain. The `*.workers.dev` subdomain is provided by Cloudflare as a secondary convenience URL only and should not be used as the primary production URL.

The `wrangler.jsonc` configuration already declares the Custom Domain route:

```jsonc
{
  "routes": [
    { "pattern": "feedback.thelongwayhome.dev", "custom_domain": true }
  ]
}
```

Deploy the Worker (this requires your Cloudflare account login):
```bash
npx wrangler deploy
```

After deploying, confirm in the Cloudflare dashboard that the Custom Domain `feedback.thelongwayhome.dev` is attached to this Worker and that Cloudflare is managing the DNS/certificate for it.

### Step 4: Configure REELHOUSE Flutter Application

The Flutter app defaults to the production endpoint `https://feedback.thelongwayhome.dev/v1/feedback`. This is the only endpoint used by the app, so no additional configuration is required. If you need to point a test build elsewhere, pass a `--dart-define` at build time:

```bash
flutter run --dart-define=FEEDBACK_ENDPOINT_URL=https://feedback.thelongwayhome.dev/v1/feedback
```

---

## Implemented-in-Code Status

| Component | Status | Description |
|-----------|--------|-------------|
| **Worker Routing & JSON API** | Implemented in Code | `POST /v1/feedback`, `OPTIONS /v1/feedback`, 405/404 handling |
| **Strict Payload Validation & Filtering** | Implemented in Code | Schema enforcement, character limits, allowlist only |
| **Email Body & Subject Formatting** | Implemented in Code | Formats developer-friendly clean email with diagnostic block |
| **Idempotency Header Propagation** | Implemented in Code | Supports `Idempotency-Key` / `X-Entity-Ref-ID` to Resend |
| **CORS Configuration** | Implemented in Code | Preflight and headers for web/desktop/mobile targets |
| **Rate Limiter Binding** | Implemented in Code | 10 submissions / 60 s / IP in `wrangler.jsonc` (`RATE_LIMITER`) |
| **Flutter In-App Submission Client** | Implemented in Code | HTTP POST, timeout handling, error mapping, state management |
| **Flutter In-App Feedback UI** | Implemented in Code | Loading indicator, success confirmation, error notifications |
| **Cloudflare Worker Secret Provisioning** | Manual Action Required | `npx wrangler secret put RESEND_API_KEY` in user's Cloudflare account |
| **Resend Sender Domain Verification** | Manual Action Required | Verify DNS records for your sender domain in Resend dashboard |
| **Wrangler Production Deployment** | Manual Action Required | `npx wrangler deploy` plus Custom Domain `feedback.thelongwayhome.dev` in user's Cloudflare account |