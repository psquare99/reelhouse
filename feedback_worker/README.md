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
- **Abuse Protected**: Cloudflare Workers Rate Limiting binding (5 submissions / min / IP).

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
1. A [Cloudflare](https://dash.cloudflare.com/) account with Cloudflare Workers enabled.
2. A [Resend](https://resend.com/) account with a verified domain (or `onboarding@resend.dev` for testing).

### Step 1: Set Worker Secrets
Run Wrangler in the `feedback_worker` directory:
```bash
npx wrangler secret put RESEND_API_KEY
# Enter your live Resend API key when prompted
```

### Step 2: Configure Production Environment Variables
Edit `wrangler.jsonc` (or pass via Cloudflare dashboard):
- `FEEDBACK_TO_EMAIL`: The destination developer mailbox (default: `feedback@reelhouse.app`).
- `FEEDBACK_FROM_EMAIL`: The verified sender address in Resend (e.g., `REELHOUSE Feedback <feedback@yourdomain.com>`).

### Step 3: Deploy Worker
```bash
npx wrangler deploy
```

Upon completion, Wrangler will output your live production URL:
```
Published reelhouse-feedback-worker (https://reelhouse-feedback-worker.<your-subdomain>.workers.dev)
```

### Step 4: Configure REELHOUSE Flutter Application
By default, REELHOUSE connects to `https://feedback.reelhouse.app` (or custom endpoint).
To override the endpoint URL at build/run time:
```bash
flutter run --dart-define=FEEDBACK_ENDPOINT_URL=https://reelhouse-feedback-worker.<your-subdomain>.workers.dev
```
Or pass the custom endpoint directly into `FeedbackServiceImpl(endpointUrl: '...')`.

---

## 3. Implemented in Code vs. Manual Configuration Required

| Component | Status | Description |
|-----------|--------|-------------|
| **Worker Routing & JSON API** | Implemented in Code | `POST /v1/feedback`, `OPTIONS /v1/feedback`, 405/404 handling |
| **Strict Payload Validation & Filtering** | Implemented in Code | Schema enforcement, character limits, allowlist only |
| **Email Body & Subject Formatting** | Implemented in Code | Formats developer-friendly clean email with diagnostic block |
| **Idempotency Header Propagation** | Implemented in Code | Supports `Idempotency-Key` / `X-Entity-Ref-ID` to Resend |
| **CORS Configuration** | Implemented in Code | Preflight and headers for web/desktop/mobile targets |
| **Rate Limiter Binding** | Implemented in Code | Configured in `wrangler.jsonc` (`RATE_LIMITER`) |
| **Flutter In-App Submission Client** | Implemented in Code | HTTP POST, timeout handling, error mapping, state management |
| **Flutter In-App Feedback UI** | Implemented in Code | Loading indicator, success confirmation, error notifications |
| **Cloudflare Worker Secret Provisioning** | Manual Action Required | `npx wrangler secret put RESEND_API_KEY` in user's Cloudflare account |
| **Resend Sender Domain Verification** | Manual Action Required | Verify DNS records for your sender domain in Resend dashboard |
| **Wrangler Production Deployment** | Manual Action Required | `npx wrangler deploy` with user Cloudflare account login |
