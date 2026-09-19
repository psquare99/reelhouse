import { FeedbackRequest } from './types';

export function formatEmailSubject(data: FeedbackRequest): string {
  const categoryTag =
    data.category === 'bug'
      ? '[Bug]'
      : data.category === 'suggestion'
      ? '[Suggestion]'
      : '[General]';

  const cleanSubject = data.subject?.trim();
  if (cleanSubject && cleanSubject.length > 0) {
    return `[REELHOUSE]${categoryTag} ${cleanSubject}`;
  }
  return `[REELHOUSE]${categoryTag} Feedback`;
}

export function formatEmailBody(data: FeedbackRequest): string {
  const categoryName =
    data.category === 'bug'
      ? 'Bug Report'
      : data.category === 'suggestion'
      ? 'Feature Suggestion'
      : 'General Feedback';

  const subjectLine = data.subject?.trim() || 'None';
  const cleanMessage = data.message.trim();

  let diagnosticsBlock = 'Diagnostics:\nNot included';
  if (data.diagnostics) {
    const version = data.diagnostics.appVersion.trim() || 'Unknown';
    const platform = data.diagnostics.platform.trim() || 'Unknown';
    diagnosticsBlock = `Diagnostics:\nREELHOUSE ${version}\nPlatform: ${platform}`;
  }

  return `REELHOUSE Feedback\n────────────────────────\n\nCategory:\n${categoryName}\n\nSubject:\n${subjectLine}\n\nMessage:\n${cleanMessage}\n\n────────────────────────\n\n${diagnosticsBlock}\n`;
}
