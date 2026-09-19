import { FeedbackCategory, FeedbackRequest, Diagnostics } from './types';

const ALLOWED_CATEGORIES: ReadonlySet<string> = new Set<FeedbackCategory>([
  'bug',
  'suggestion',
  'general',
]);

const ALLOWED_TOP_LEVEL_KEYS: ReadonlySet<string> = new Set([
  'category',
  'subject',
  'message',
  'diagnostics',
]);

const ALLOWED_DIAGNOSTIC_KEYS: ReadonlySet<string> = new Set([
  'appVersion',
  'platform',
]);

const MAX_SUBJECT_LENGTH = 200;
const MAX_MESSAGE_LENGTH = 5000;
const MAX_DIAGNOSTIC_FIELD_LENGTH = 50;

export interface ValidationResult {
  valid: boolean;
  error?: string;
  data?: FeedbackRequest;
}

export function validateFeedbackPayload(rawBody: unknown): ValidationResult {
  if (typeof rawBody !== 'object' || rawBody === null || Array.isArray(rawBody)) {
    return { valid: false, error: 'Request body must be a valid JSON object.' };
  }

  const obj = rawBody as Record<string, unknown>;

  // Check for forbidden / unexpected keys to prevent arbitrary metadata forwarding
  for (const key of Object.keys(obj)) {
    if (!ALLOWED_TOP_LEVEL_KEYS.has(key)) {
      return { valid: false, error: `Unrecognized field '${key}' in payload.` };
    }
  }

  // Validate category
  if (!obj.category || typeof obj.category !== 'string') {
    return { valid: false, error: "Missing or invalid 'category'. Must be 'bug', 'suggestion', or 'general'." };
  }
  if (!ALLOWED_CATEGORIES.has(obj.category)) {
    return { valid: false, error: "Invalid 'category'. Must be 'bug', 'suggestion', or 'general'." };
  }
  const category = obj.category as FeedbackCategory;

  // Validate subject (optional)
  let subject: string | undefined;
  if (obj.subject !== undefined && obj.subject !== null) {
    if (typeof obj.subject !== 'string') {
      return { valid: false, error: "'subject' must be a string if provided." };
    }
    if (obj.subject.length > MAX_SUBJECT_LENGTH) {
      return { valid: false, error: `'subject' exceeds maximum length of ${MAX_SUBJECT_LENGTH} characters.` };
    }
    subject = obj.subject;
  }

  // Validate message (required)
  if (obj.message === undefined || obj.message === null || typeof obj.message !== 'string') {
    return { valid: false, error: "Missing or invalid 'message'. It must be a non-empty string." };
  }
  const trimmedMessage = obj.message.trim();
  if (trimmedMessage.length === 0) {
    return { valid: false, error: "'message' cannot be empty." };
  }
  if (obj.message.length > MAX_MESSAGE_LENGTH) {
    return { valid: false, error: `'message' exceeds maximum length of ${MAX_MESSAGE_LENGTH} characters.` };
  }
  const message = obj.message;

  // Validate diagnostics (optional)
  let diagnostics: Diagnostics | null = null;
  if (obj.diagnostics !== undefined && obj.diagnostics !== null) {
    if (typeof obj.diagnostics !== 'object' || Array.isArray(obj.diagnostics)) {
      return { valid: false, error: "'diagnostics' must be an object or null." };
    }
    const diagObj = obj.diagnostics as Record<string, unknown>;
    for (const key of Object.keys(diagObj)) {
      if (!ALLOWED_DIAGNOSTIC_KEYS.has(key)) {
        return { valid: false, error: `Unrecognized diagnostic key '${key}'.` };
      }
    }
    if (typeof diagObj.appVersion !== 'string' || typeof diagObj.platform !== 'string') {
      return { valid: false, error: "'diagnostics' must include string fields 'appVersion' and 'platform'." };
    }
    if (diagObj.appVersion.length > MAX_DIAGNOSTIC_FIELD_LENGTH) {
      return { valid: false, error: `'appVersion' exceeds limit of ${MAX_DIAGNOSTIC_FIELD_LENGTH} characters.` };
    }
    if (diagObj.platform.length > MAX_DIAGNOSTIC_FIELD_LENGTH) {
      return { valid: false, error: `'platform' exceeds limit of ${MAX_DIAGNOSTIC_FIELD_LENGTH} characters.` };
    }
    diagnostics = {
      appVersion: diagObj.appVersion,
      platform: diagObj.platform,
    };
  }

  return {
    valid: true,
    data: {
      category,
      subject,
      message,
      diagnostics,
    },
  };
}
