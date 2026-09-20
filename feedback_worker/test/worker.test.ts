import { describe, it, expect, vi } from 'vitest';
import { handleFeedbackRequest } from '../src/index';
import { Env } from '../src/types';
import { formatEmailSubject, formatEmailBody } from '../src/formatter';
import { validateFeedbackPayload } from '../src/validator';

describe('Worker Formatter', () => {
  it('formats bug subject and body correctly', () => {
    const subject = formatEmailSubject({
      category: 'bug',
      subject: "Artwork doesn't load",
      message: 'Posters are blank on the movies tab.',
      diagnostics: { appVersion: '1.0.0', platform: 'Windows' },
    });
    expect(subject).toBe("[MATINEE][Bug] Artwork doesn't load");

    const body = formatEmailBody({
      category: 'bug',
      subject: "Artwork doesn't load",
      message: 'Posters are blank on the movies tab.',
      diagnostics: { appVersion: '1.0.0', platform: 'Windows' },
    });
    expect(body).toContain('Category:\nBug Report');
    expect(body).toContain("Subject:\nArtwork doesn't load");
    expect(body).toContain('Message:\nPosters are blank on the movies tab.');
    expect(body).toContain('Diagnostics:\nMATINEE 1.0.0\nPlatform: Windows');
  });

  it('formats suggestion subject and body correctly', () => {
    const subject = formatEmailSubject({
      category: 'suggestion',
      subject: 'Add watched filter',
      message: 'Would love to filter only unwatched movies.',
      diagnostics: null,
    });
    expect(subject).toBe('[MATINEE][Suggestion] Add watched filter');

    const body = formatEmailBody({
      category: 'suggestion',
      subject: 'Add watched filter',
      message: 'Would love to filter only unwatched movies.',
      diagnostics: null,
    });
    expect(body).toContain('Category:\nFeature Suggestion');
    expect(body).toContain('Diagnostics:\nNot included');
  });

  it('formats general feedback with fallback subject', () => {
    const subject = formatEmailSubject({
      category: 'general',
      message: 'Love the app!',
    });
    expect(subject).toBe('[MATINEE][General] Feedback');
  });
});

describe('Worker Validator', () => {
  it('accepts valid payload with diagnostics', () => {
    const res = validateFeedbackPayload({
      category: 'bug',
      subject: 'Crash on launch',
      message: 'Details here',
      diagnostics: { appVersion: '1.0.0', platform: 'Windows' },
    });
    expect(res.valid).toBe(true);
    expect(res.data?.category).toBe('bug');
  });

  it('accepts valid payload without subject or diagnostics', () => {
    const res = validateFeedbackPayload({
      category: 'general',
      message: 'Great job',
    });
    expect(res.valid).toBe(true);
    expect(res.data?.category).toBe('general');
  });

  it('rejects invalid category', () => {
    const res = validateFeedbackPayload({
      category: 'invalid_cat',
      message: 'test',
    });
    expect(res.valid).toBe(false);
    expect(res.error).toContain('Invalid');
  });

  it('rejects empty message', () => {
    const res = validateFeedbackPayload({
      category: 'bug',
      message: '   ',
    });
    expect(res.valid).toBe(false);
    expect(res.error).toContain('empty');
  });

  it('rejects oversized subject', () => {
    const res = validateFeedbackPayload({
      category: 'bug',
      subject: 'a'.repeat(201),
      message: 'valid message',
    });
    expect(res.valid).toBe(false);
    expect(res.error).toContain('exceeds maximum length');
  });

  it('rejects oversized message', () => {
    const res = validateFeedbackPayload({
      category: 'bug',
      message: 'a'.repeat(5001),
    });
    expect(res.valid).toBe(false);
    expect(res.error).toContain('exceeds maximum length');
  });

  it('rejects unallowed top-level keys (e.g. sensitive fields)', () => {
    const res = validateFeedbackPayload({
      category: 'bug',
      message: 'testing unallowed keys',
      tmdbApiKey: 'secret_key',
      library: ['movie1'],
    });
    expect(res.valid).toBe(false);
    expect(res.error).toContain("Unrecognized field 'tmdbApiKey'");
  });

  it('rejects unallowed diagnostic fields', () => {
    const res = validateFeedbackPayload({
      category: 'bug',
      message: 'testing unallowed diagnostic fields',
      diagnostics: {
        appVersion: '1.0.0',
        platform: 'Windows',
        deviceIp: '192.168.1.1',
      },
    });
    expect(res.valid).toBe(false);
    expect(res.error).toContain("Unrecognized diagnostic key 'deviceIp'");
  });
});

describe('Worker HTTP Handler', () => {
  const defaultEnv: Env = {
    RESEND_API_KEY: 're_test_key_123',
    FEEDBACK_TO_EMAIL: 'dev@reelhouse.app',
    FEEDBACK_FROM_EMAIL: 'MATINEE <feedback@thelongwayhome.dev>',
  };

  it('handles CORS OPTIONS preflight', async () => {
    const req = new Request('https://worker.local/v1/feedback', {
      method: 'OPTIONS',
    });
    const res = await handleFeedbackRequest(req, defaultEnv);
    expect(res.status).toBe(204);
    expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
    expect(res.headers.get('Access-Control-Allow-Methods')).toContain('POST');
  });

  it('rejects non-existent routes with 404', async () => {
    const req = new Request('https://worker.local/v1/unknown', {
      method: 'POST',
      body: JSON.stringify({ category: 'bug', message: 'test' }),
    });
    const res = await handleFeedbackRequest(req, defaultEnv);
    expect(res.status).toBe(404);
  });

  it('rejects unsupported HTTP methods with 405', async () => {
    const req = new Request('https://worker.local/v1/feedback', {
      method: 'GET',
    });
    const res = await handleFeedbackRequest(req, defaultEnv);
    expect(res.status).toBe(405);
    const json = (await res.json()) as Record<string, unknown>;
    expect(json.error).toBe('Method not allowed');
  });

  it('rejects malformed JSON with 400', async () => {
    const req = new Request('https://worker.local/v1/feedback', {
      method: 'POST',
      body: 'this is not json',
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await handleFeedbackRequest(req, defaultEnv);
    expect(res.status).toBe(400);
  });

  it('successfully forwards valid feedback to Resend API and returns ok:true', async () => {
    let capturedUrl = '';
    let capturedHeaders: HeadersInit | undefined;
    let capturedBody: any;

    const mockFetch = vi.fn().mockImplementation(async (url, init) => {
      capturedUrl = url.toString();
      capturedHeaders = init?.headers;
      capturedBody = JSON.parse(init?.body as string);
      return new Response(JSON.stringify({ id: 'msg_123' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    });

    const req = new Request('https://worker.local/v1/feedback', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Idempotency-Key': 'req-idemp-12345',
      },
      body: JSON.stringify({
        category: 'bug',
        subject: 'Player freeze',
        message: 'Freezes on play',
        diagnostics: {
          appVersion: '1.0.0',
          platform: 'Windows',
        },
      }),
    });

    const res = await handleFeedbackRequest(req, defaultEnv, mockFetch as any);
    expect(res.status).toBe(200);
    const json = (await res.json()) as Record<string, unknown>;
    expect(json.ok).toBe(true);

    expect(capturedUrl).toBe('https://api.resend.com/emails');
    expect(capturedHeaders).toEqual({
      Authorization: 'Bearer re_test_key_123',
      'Content-Type': 'application/json',
      'Idempotency-Key': 'req-idemp-12345',
      'X-Entity-Ref-ID': 'req-idemp-12345',
    });
    expect(capturedBody.subject).toBe('[MATINEE][Bug] Player freeze');
    expect(capturedBody.text).toContain('Freezes on play');
    expect(capturedBody.to).toEqual(['dev@reelhouse.app']);
  });

  it('handles rate limiting when RATE_LIMITER binding rejects request', async () => {
    const envWithRateLimiter: Env = {
      ...defaultEnv,
      RATE_LIMITER: {
        limit: async () => ({ success: false }),
      },
    };

    const req = new Request('https://worker.local/v1/feedback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ category: 'general', message: 'Rate limit test' }),
    });

    const res = await handleFeedbackRequest(req, envWithRateLimiter);
    expect(res.status).toBe(429);
    const json = (await res.json()) as Record<string, unknown>;
    expect(json.error).toBe('Too many submissions. Please try again later.');
  });

  it('handles upstream Resend provider failure without leaking secrets', async () => {
    const mockFetch = vi.fn().mockImplementation(async () => {
      return new Response(JSON.stringify({ error: { message: 'Invalid domain' } }), {
        status: 422,
        headers: { 'Content-Type': 'application/json' },
      });
    });

    const req = new Request('https://worker.local/v1/feedback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ category: 'suggestion', message: 'Test suggestion' }),
    });

    const res = await handleFeedbackRequest(req, defaultEnv, mockFetch as any);
    expect(res.status).toBe(502);
    const json = (await res.json()) as Record<string, unknown>;
    expect(json.error).toBe('Feedback service temporarily unavailable');
    // Ensure no provider secrets or internals in response
    expect(JSON.stringify(json)).not.toContain('re_test_key');
    expect(JSON.stringify(json)).not.toContain('Invalid domain');
  });

  it('returns 503 if RESEND_API_KEY secret is not configured in Worker', async () => {
    const req = new Request('https://worker.local/v1/feedback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ category: 'bug', message: 'test' }),
    });

    const res = await handleFeedbackRequest(req, {});
    expect(res.status).toBe(503);
    const json = (await res.json()) as Record<string, unknown>;
    expect(json.error).toBe('Feedback service temporarily unavailable');
  });
});

describe('RC.5B — Legal Pages', () => {
  const defaultEnv: Env = {
    RESEND_API_KEY: 're_test_key_123',
    FEEDBACK_TO_EMAIL: 'dev@reelhouse.app',
    FEEDBACK_FROM_EMAIL: 'MATINEE <feedback@thelongwayhome.dev>',
  };

  it('serves Privacy Policy HTML at GET /privacy', async () => {
    const req = new Request('https://worker.local/privacy', {
      method: 'GET',
    });
    const res = await handleFeedbackRequest(req, defaultEnv);
    expect(res.status).toBe(200);
    expect(res.headers.get('Content-Type')).toContain('text/html');
    const html = await res.text();
    expect(html).toContain('Privacy Policy');
    expect(html).toContain('MATINEE');
    expect(html).toContain('TMDB');
    expect(html).toContain('feedback@thelongwayhome.dev');
  });

  it('serves Media Responsibility HTML at GET /media-responsibility', async () => {
    const req = new Request('https://worker.local/media-responsibility', {
      method: 'GET',
    });
    const res = await handleFeedbackRequest(req, defaultEnv);
    expect(res.status).toBe(200);
    expect(res.headers.get('Content-Type')).toContain('text/html');
    const html = await res.text();
    expect(html).toContain('Media, Copyright');
    expect(html).toContain('MATINEE');
    expect(html).toContain('feedback@thelongwayhome.dev');
  });

  it('returns 404 for unknown GET routes', async () => {
    const req = new Request('https://worker.local/unknown-page', {
      method: 'GET',
    });
    const res = await handleFeedbackRequest(req, defaultEnv);
    expect(res.status).toBe(404);
  });

  it('returns 404 for POST to legal page routes (GET only)', async () => {
    const req = new Request('https://worker.local/privacy', {
      method: 'POST',
      body: '{}',
    });
    const res = await handleFeedbackRequest(req, defaultEnv);
    expect(res.status).toBe(404);
  });
});
