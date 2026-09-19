export type FeedbackCategory = 'bug' | 'suggestion' | 'general';

export interface Diagnostics {
  appVersion: string;
  platform: string;
}

export interface FeedbackRequest {
  category: FeedbackCategory;
  subject?: string;
  message: string;
  diagnostics?: Diagnostics | null;
}

export interface Env {
  RESEND_API_KEY?: string;
  FEEDBACK_TO_EMAIL?: string;
  FEEDBACK_FROM_EMAIL?: string;
  RATE_LIMITER?: {
    limit(options: { key: string }): Promise<{ success: boolean }>;
  };
}
