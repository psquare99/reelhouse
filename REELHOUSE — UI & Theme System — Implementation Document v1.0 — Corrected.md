# REELHOUSE
## UI & Theme System — Implementation Document
### v1.0

---

## 1. Purpose

REELHOUSE currently has two visual modes — **Screening Room** (dark) and **Gallery Linen** (light) — but only one of them is implemented correctly. The dark mode reads as intentional and cinematic. The light mode has text that is functionally invisible (TMDB API key field, "Appearance & Theme" heading, and likely other labels not yet audited).

This is not a "pick better colors" problem. It is an architecture problem: colors are being hardcoded as literal values tuned for one background, then reused verbatim against a different background. This document defines a token-based color and type system so that every surface in the app is either correct in both themes or physically cannot compile with a hardcoded color.

This document governs the same UI surfaces covered by Section 2.6 of the main Implementation Design Document ("The application should feel designed") and extends it with concrete, implementable values.

---

## 2. Root Cause

Observed failure: on Gallery Linen, secondary/label text renders in a muted gray (~`#9C9A93`) that was calibrated for legibility against a near-black background (`#0B0C0E`). Against the Gallery Linen background (`#F3EEE3`), the same literal value has almost no contrast.

This happens when a color is written as a literal (`Color(0xFF9C9A93)`) at the call site instead of being resolved from a theme object at render time. A literal color has no way to know which theme is active.

**Rule going forward: no UI/presentation widget in REELHOUSE may reference a raw `Color(0xFF...)` literal or named `Colors.*` for text, icon, border, or surface color.** Every such color reference resolves through the token system in Section 4. This is a lint-enforceable rule, not merely a style guideline — see Section 9. Theme-definition code, generated/framework code, tests, and non-UI infrastructure are not governed by this presentation-layer rule.

---

## 3. Design Principles for This System

1. **Two themes, one set of role names.** "Text secondary," "surface card," "border" are slots. Each theme fills the slot with a different value. No screen should ever need to know which theme is active — it just asks for `textSecondary` and gets the right pixel.
2. **Warm, not neutral.** Both themes lean warm (off-black with warm undertone / linen cream, not pure gray) to match the existing amber/orange brand identity and avoid the generic-SaaS look Section 2.6 of the main doc explicitly warns against.
3. **Contrast is a requirement, not a preference.** Every text/background pairing in this document has been chosen to clear WCAG AA (4.5:1 for body text, 3:1 for large text/icons). Do not substitute a color without checking contrast against every surface it can appear on.
4. **State color is semantic, not decorative.** Availability states (Play / Play Offline / Connect Disk / Downloading) get their own token names, not "green" or "orange." This keeps the state logic in Section 9 of the Query/Discovery spec cleanly separated from the color values in Section 5 below — a future retheme should never require touching availability logic.

---

## 4. Token Architecture

Three layers, resolved in this order:

```
Layer 1 — Palette
  Raw hex values. Never referenced directly outside this file.

Layer 2 — Theme
  Screening Room and Gallery Linen each map every Layer-3 role
  to a Layer-1 value.

Layer 3 — Role (what every widget actually reads)
  background, surface1, surface2, border, borderStrong,
  textPrimary, textSecondary, textMuted, accent, onAccent,
  stateAvailable, stateOffline, stateUnavailable, stateProgress
```

A widget requests `theme.textSecondary` — never `#9C9A93`, never `Colors.grey`. If a role doesn't exist yet for what you're building, add the role to Layer 3 first, then define it in both Layer 2 themes. Never invent a one-off literal to avoid adding a role.

---

## 5. Color System

### 5.1 Screening Room (dark)

| Role | Value | Used for |
|---|---|---|
| `background` | `#0B0C0E` | Page background |
| `surface1` | `#16181C` | Cards, poster tiles |
| `surface2` | `#1E2126` | Inputs, elevated panels, modals |
| `border` | `#2A2D33` | Hairline dividers, card outlines |
| `borderStrong` | `#3A3E45` | Input focus ring, emphasized divider |
| `textPrimary` | `#F2F0EC` | Titles, primary labels |
| `textSecondary` | `#A8A6A0` | Supporting text, field values |
| `textMuted` | `#6E6C68` | Placeholders, timestamps, hint text |
| `accent` | `#E2703A` | Brand actions, active nav, selected states |
| `onAccent` | `#1A0D06` | Text/icons on top of an accent-filled surface |

### 5.2 Gallery Linen (light)

| Role | Value | Used for |
|---|---|---|
| `background` | `#F3EEE3` | Page background |
| `surface1` | `#FBF9F4` | Cards, poster tiles |
| `surface2` | `#FFFFFF` | Inputs, elevated panels, modals |
| `border` | `#E1DAC9` | Hairline dividers, card outlines |
| `borderStrong` | `#C9BFA6` | Input focus ring, emphasized divider |
| `textPrimary` | `#241F19` | Titles, primary labels |
| `textSecondary` | `#5C564C` | Supporting text, field values |
| `textMuted` | `#8B8579` | Placeholders, timestamps, hint text |
| `accent` | `#C24E28` | Brand actions, active nav, selected states |
| `onAccent` | `#FFFFFF` | Text/icons on top of an accent-filled surface |

Note: `accent` is deliberately a different hex in each theme (darkened for light mode). The same orange that reads correctly on near-black is too light-value to hold contrast on cream — this is intentional, not a mismatch to fix later.

### 5.3 Semantic state colors

These map directly to the availability states defined in Section 18 of the main Implementation Design Document. Both themes share the same *role names*; values differ per theme the same way the roles above do.

| Role | Maps to | Screening Room | Gallery Linen |
|---|---|---|---|
| `stateAvailable` | `PLAY`, `AVAILABLE ON DISK` | `accent` (`#E2703A`) | `accent` (`#C24E28`) |
| `stateOffline` | `PLAY OFFLINE`, `✓ AVAILABLE OFFLINE` | `#5DCAA5` | `#0F6E56` |
| `stateUnavailable` | `CONNECT DISK` | `textMuted` | `textMuted` |
| `stateProgress` | `DOWNLOADING NN%` | `#EF9F27` | `#854F0B` |

Do not introduce a fifth ad-hoc color for a new state without adding a row here first.

---

## 6. Typography

### 6.1 Pairing

Two families, matching Principle 2.6 ("feel like a personal cinema," not a generic dashboard):

- **Display / editorial** — used for movie and show titles on detail pages, the Home hero, and onboarding screens. A serif with cinematic/poster character (e.g. Fraunces, Libre Caslon Text). This is the one place REELHOUSE should feel like a title card, not an app.
- **UI / sans** — used for everything else: nav, buttons, labels, body copy, metadata. Whatever sans is already in use across the catalogue grids is fine; keep it consistent rather than introducing a third family.

Eyebrow labels (`RECENTLY ADDED`, `TMDB METADATA CONFIGURATION`) stay in the UI sans, uppercase, tracked out (~0.06em letter-spacing), colored `accent` — this is already working in the current build and should be treated as the established pattern, not redesigned.

### 6.2 Scale

| Style | Size | Weight | Family | Used for |
|---|---|---|---|---|
| Display | 32 / 40px | 500 | Display serif | Movie/show title on detail page |
| Heading | 20 / 24px | 500 | UI sans | Section headers ("Movies", "Settings") |
| Eyebrow | 11px | 500, uppercase, tracked | UI sans | Category labels |
| Body | 14 / 16px | 400 | UI sans | Card titles, descriptions |
| Label | 13px | 400 | UI sans | Field labels, metadata |
| Caption | 11 / 12px | 400 | UI sans | Timestamps, fine print |

Two weights only across the UI sans — 400 and 500. Do not introduce 600/700; it reads heavy against the flat surfaces this app uses.

---

## 7. Spacing, Radius, Elevation

- **Radius**: `8px` for inputs/buttons/badges, `12px` for cards and posters. Keep this binary — don't introduce a third radius value.
- **Spacing scale**: `4 / 8 / 12 / 16 / 24 / 32px`. Poster grid gutters stay at the already-established `28–32px` from M4.1.
- **Elevation**: this app does not use drop shadows (flat, per Principle 2.6). Elevation is communicated purely through the `surface1` → `surface2` step and a hairline `border`. Never add a `box-shadow` to imply depth.

---

## 8. Component Rules

- **Cards** (poster tiles, settings rows): `surface1` background, `border` outline (`0.5–1px`), `12px` radius. Never bare — always give a card an explicit border in both themes, since Gallery Linen's surface1/background contrast is subtle enough that borders are doing real work (see the before/after comparison already shared).
- **Inputs** (API key field, search): `surface2` background, `border` at rest, `borderStrong` on focus, `textPrimary` for entered value, `textMuted` for placeholder. This is the field that was broken — apply this row exactly.
- **Buttons — primary** (Play, Save): `accent` fill, `onAccent` text/icon. One primary-accent button per screen at most; secondary actions use an outlined `border` button with `textPrimary` label.
- **Buttons — state actions** (Connect Disk, Download to Device): use the matching `state*` token from Section 5.3, not `accent`. `CONNECT DISK` should visually read as "not currently possible," not as a call to action — `textMuted`/outline, not filled.
- **Badges** (availability corner badge on posters): background is the `state*` color at ~15% opacity over `surface1`, text/icon is the full-strength `state*` color. Once the badge copy itself is corrected (tracked separately — not a theme issue), keep the badge's *color* wired to the state token so a copy fix doesn't require a color fix too.
- **Nav rail**: active item uses `accent` (icon + label), inactive items use `textSecondary`, background is `background` (not `surface1`) so the rail recedes behind content.

---

## 9. Implementation Rule & Enforcement

Add a lint rule (or a pre-commit grep, at minimum) that flags any `Color(0xFF...)` literal or named `Colors.*` used in **UI/presentation code** outside the theme definition file. Every other UI/presentation file should only ever read from the theme object. This rule applies to presentation-layer UI colors, not to every color literal in the repository. This is the actual fix for the bug that started this document — without an enforcement mechanism, the same class of bug (a value correct in one theme, silently wrong in the other) will recur the next time someone adds a screen.

Suggested minimum check before merging any new screen: render it once in Screening Room, once in Gallery Linen, and confirm every text element is legible without zooming in. This is cheap and would have caught the TMDB settings bug before it shipped.

---

## 10. QA / Acceptance Criteria

- [ ] No `Color(0xFF...)` or `Colors.*` literal is used for UI/presentation colors outside the theme definition.
- [ ] Every screen in Section 3 of the main Implementation Design Document's UX scope (Home, Movies, TV Shows, Search, Movie Detail, TV Detail, Settings, Onboarding) has been visually checked in both themes.
- [ ] TMDB API key field: entered value and placeholder both legible in Gallery Linen.
- [ ] All Settings section headers ("Appearance & Theme," "Playback Handoff," etc.) legible in Gallery Linen.
- [ ] Availability badges use `state*` tokens, not ad-hoc colors, in both themes.
- [ ] No decorative box-shadow or decorative gradient anywhere in the app. Functional media-legibility overlays/scrims, such as the Home hero backdrop scrim, are permitted and must be implemented as a named theme/component treatment rather than an ad-hoc visual effect.
- [ ] Display serif is used only for movie/show titles — not leaking into buttons, nav, or body text.

---

## 11. Non-Goals

This document does not introduce:

- A third theme or "auto" blending mode beyond system-default switching (already supported).
- Per-user custom accent colors / theming as a feature.
- Motion/animation tokens (separate concern, covered under M6 polish in the main roadmap).
- Any change to availability *logic* — this document only fixes how existing states are colored and labeled visually, not when they trigger.
