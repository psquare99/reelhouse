// RC.5B — Static legal pages served by the feedback worker.
// Content derived exclusively from RC.5A verified facts.

export const PRIVACY_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>REELHOUSE — Privacy Policy</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.7; color: #e0e0e0; background: #0d0d0d; margin: 0; padding: 0; }
    .container { max-width: 720px; margin: 0 auto; padding: 40px 24px 80px; }
    h1 { font-size: 1.6rem; color: #ffffff; margin-bottom: 4px; }
    .updated { color: #888; font-size: 0.85rem; margin-bottom: 32px; }
    h2 { font-size: 1.15rem; color: #ffffff; margin-top: 32px; margin-bottom: 8px; }
    p, li { font-size: 0.95rem; color: #ccc; }
    ul { padding-left: 20px; }
    li { margin-bottom: 6px; }
    .brand { color: #c8a961; font-weight: 600; }
    a { color: #c8a961; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Privacy Policy</h1>
    <p class="updated">Last updated: September 2026</p>

    <h2>1. What REELHOUSE Is</h2>
    <p><span class="brand">REELHOUSE</span> is a personal digital cinema application for organising and discovering your movie and TV collection. It runs entirely on your local device.</p>

    <h2>2. Data Stored on Your Device</h2>
    <p>REELHOUSE stores the following data locally on your device only:</p>
    <ul>
      <li>Movie and TV show metadata (titles, descriptions, ratings, artwork URLs)</li>
      <li>Your media library structure (files, folders, storage associations)</li>
      <li>Collections you create</li>
      <li>Playback and resume-position state</li>
      <li>Your local profile (name, bio, photo) and application preferences</li>
      <li>Your TMDB API key (stored locally, used only for metadata requests you initiate)</li>
    </ul>
    <p>This data never leaves your device except as described in the sections below.</p>

    <h2>3. External Metadata Services</h2>
    <p>When you choose to look up or refresh metadata for your media, REELHOUSE sends search queries to:</p>
    <ul>
      <li><strong>TMDB (api.themoviedb.org)</strong> — primary metadata source</li>
      <li><strong>TVMaze (api.tvmaze.com)</strong> — fallback metadata source</li>
      <li><strong>OMDb (www.omdbapi.com)</strong> — fallback metadata source</li>
    </ul>
    <p>These requests include only the search query (e.g. a movie title) and your TMDB API key. No personal data, media files, or library contents are transmitted to these services.</p>

    <h2>4. Feedback</h2>
    <p>When you submit feedback, REELHOUSE sends only the following to our feedback endpoint:</p>
    <ul>
      <li>Feedback category (bug, suggestion, or general)</li>
      <li>Subject and message you type</li>
      <li>App version and platform (e.g. "1.0.0+1 / Windows")</li>
    </ul>
    <p>No media files, personal files, library contents, API credentials, or device-identifying information is included with feedback submissions.</p>

    <h2>5. What REELHOUSE Does Not Do</h2>
    <ul>
      <li>REELHOUSE does not collect analytics, telemetry, or crash reports.</li>
      <li>REELHOUSE does not use tracking cookies or fingerprinting.</li>
      <li>REELHOUSE does not require user accounts or online authentication.</li>
      <li>REELHOUSE does not sync your library to any cloud service.</li>
      <li>REELHOUSE does not upload, stream, or share your media files.</li>
    </ul>

    <h2>6. Backups</h2>
    <p>Library backups created by REELHOUSE exclude your TMDB API key and other credentials. Backups may contain relative file paths to your media, but these paths are only useful on your own devices.</p>

    <h2>7. Children's Privacy</h2>
    <p>REELHOUSE is not directed at children under 13. It does not knowingly collect information from children.</p>

    <h2>8. Changes to This Policy</h2>
    <p>If this privacy policy changes, the updated version will be available at this URL. The app will link to the current version from the About section.</p>

    <h2>9. Contact</h2>
    <p>For privacy-related questions, contact us at <a href="mailto:feedback@thelongwayhome.dev">feedback@thelongwayhome.dev</a>.</p>
  </div>
</body>
</html>`;

export const MEDIA_RESPONSIBILITY_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>REELHOUSE — Media, Copyright &amp; User Responsibility</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.7; color: #e0e0e0; background: #0d0d0d; margin: 0; padding: 0; }
    .container { max-width: 720px; margin: 0 auto; padding: 40px 24px 80px; }
    h1 { font-size: 1.6rem; color: #ffffff; margin-bottom: 4px; }
    .updated { color: #888; font-size: 0.85rem; margin-bottom: 32px; }
    h2 { font-size: 1.15rem; color: #ffffff; margin-top: 32px; margin-bottom: 8px; }
    p, li { font-size: 0.95rem; color: #ccc; }
    ul { padding-left: 20px; }
    li { margin-bottom: 6px; }
    .brand { color: #c8a961; font-weight: 600; }
    a { color: #c8a961; }
    .notice { background: #1a1a1a; border: 1px solid #333; border-radius: 8px; padding: 16px; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Media, Copyright &amp; User Responsibility</h1>
    <p class="updated">Last updated: September 2026</p>

    <h2>1. What REELHOUSE Is</h2>
    <p><span class="brand">REELHOUSE</span> is a personal media library organiser. It helps you catalogue, browse, and manage the movies and TV shows you already own on your local devices and storage.</p>

    <div class="notice">
      <strong>REELHOUSE does not provide, sell, host, stream, or distribute any media content.</strong> All media in your REELHOUSE library comes from your own local storage.
    </div>

    <h2>2. Your Media Is Your Responsibility</h2>
    <p>You are solely responsible for the media files you add to your REELHOUSE library. This includes:</p>
    <ul>
      <li>Ensuring you have the legal right to possess and view each media file</li>
      <li>Complying with all applicable copyright and intellectual-property laws in your jurisdiction</li>
      <li>Understanding that REELHOUSE is a management tool — it does not grant any rights to media content</li>
    </ul>

    <h2>3. No Piracy Facilitation</h2>
    <p>REELHOUSE is designed exclusively for managing media you legally own or have the right to access. It does not facilitate, encourage, or enable piracy or copyright infringement. REELHOUSE does not search for, download, or provide access to unlicensed media content.</p>

    <h2>4. Metadata and Third-Party Content</h2>
    <p>REELHOUSE retrieves metadata (titles, descriptions, ratings, artwork) from The Movie Database (TMDB) and related services. This metadata is used solely to enrich your library catalogue. All artwork and metadata remain the property of their respective owners and are used under the terms of each service.</p>

    <h2>5. TMDB Attribution</h2>
    <p>This product uses the TMDB API but is not endorsed or certified by TMDB. TMDB metadata and artwork are used in accordance with the TMDB API terms of use.</p>

    <h2>6. No Warranty</h2>
    <p>REELHOUSE is provided as-is for personal library management. The developers make no claims about the legality of any specific use of the application and are not responsible for how users choose to use it.</p>

    <h2>7. Contact</h2>
    <p>For questions about this notice, contact us at <a href="mailto:feedback@thelongwayhome.dev">feedback@thelongwayhome.dev</a>.</p>
  </div>
</body>
</html>`;
