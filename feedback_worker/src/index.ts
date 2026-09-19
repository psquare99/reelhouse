import { Env, FeedbackRequest } from './types';
import { validateFeedbackPayload } from './validator';
import { formatEmailSubject, formatEmailBody } from './formatter';

const CORS_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Idempotency-Key, X-Idempotency-Key',
  'Access-Control-Max-Age': '86400',
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
  extraHeaders: Record<string, string> = {}
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
      ...extraHeaders,
    },
  });
}

export async function handleFeedbackRequest(
  request: Request,
  env: Env,
  customFetch: typeof fetch = fetch
): Promise<Response> {
  const url = new URL(request.url);

  // Route matching: only /v1/feedback is supported
  if (url.pathname !== '/v1/feedback') {
    return jsonResponse({ error: 'Not found' }, 404);
  }

  // Handle CORS Preflight
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: CORS_HEADERS,
    });
  }

  // Only POST is allowed for /v1/feedback
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, {
      Allow: 'POST, OPTIONS',
    });
  }

  // Rate Limiting (if Cloudflare Rate Limiting binding is configured)
  if (env.RATE_LIMITER) {
    try {
      const clientIp = request.headers.get('cf-connecting-ip') || 'anonymous';
      const { success } = await env.RATE_LIMITER.limit({ key: clientIp });
      if (!success) {
        return jsonResponse(
          { error: 'Too many submissions. Please try again later.' },
          429
        );
      }
    } catch {
      // If rate limiter fails, fail open gracefully or log
    }
  }

  // Parse JSON Body
  let rawBody: unknown;
  try {
    rawBody = await request.json();
  } catch {
    return jsonResponse(
      { error: 'Invalid JSON body in request.' },
      400
    );
  }

  // Validate Payload
  const validation = validateFeedbackPayload(rawBody);
  if (!validation.valid || !validation.data) {
    return jsonResponse(
      { error: 'Invalid feedback request', details: validation.error },
      400
    );
  }

  const feedbackData: FeedbackRequest = validation.data;

  // Verify Resend API Key is present in Worker secrets
  const resendApiKey = env.RESEND_API_KEY;
  if (!resendApiKey) {
    return jsonResponse(
      { error: 'Feedback service temporarily unavailable' },
      503
    );
  }

  const toEmail = env.FEEDBACK_TO_EMAIL || 'feedback@reelhouse.app';
  const fromEmail =
    env.FEEDBACK_FROM_EMAIL || 'REELHOUSE Feedback <feedback@reelhouse.app>';

  const subject = formatEmailSubject(feedbackData);
  const bodyText = formatEmailBody(feedbackData);

  // Extract optional idempotency key
  const idempotencyKey =
    request.headers.get('Idempotency-Key') ||
    request.headers.get('X-Idempotency-Key');

  const resendHeaders: Record<string, string> = {
    'Authorization': `Bearer ${resendApiKey}`,
    'Content-Type': 'application/json',
  };

  if (idempotencyKey) {
    resendHeaders['Idempotency-Key'] = idempotencyKey;
    resendHeaders['X-Entity-Ref-ID'] = idempotencyKey;
  }

  try {
    const resendResponse = await customFetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: resendHeaders,
      body: JSON.stringify({
        from: fromEmail,
        to: [toEmail],
        subject,
        text: bodyText,
      }),
    });

    if (resendResponse.ok) {
      return jsonResponse({ ok: true }, 200);
    }

    // Upstream error mapping without leaking internal provider details
    if (resendResponse.status >= 400 && resendResponse.status < 500) {
      return jsonResponse(
        { error: 'Feedback service temporarily unavailable' },
        502
      );
    }

    return jsonResponse(
      { error: 'Feedback service temporarily unavailable' },
      500
    );
  } catch {
    return jsonResponse(
      { error: 'Feedback service temporarily unavailable' },
      500
    );
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    return handleFeedbackRequest(request, env);
  },
};
