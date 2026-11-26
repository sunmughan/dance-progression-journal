# Dance Progression Journal: Design System and Screen Specs

Client: May Nguyen. App: Dance Progression Journal, iOS only, Phase 1.
Build: native Swift, SwiftUI, SwiftData, local first. TestFlight delivery 7 Jan 2027.

## What this folder holds

This folder is the single source of truth for how the app looks and behaves.
Build from these files, not from memory and not from the earlier presentation
artifact. The artifact was a presentation of the same decisions. The words
below are the decisions.

| File | Contents |
| --- | --- |
| `01_design_tokens.md` | Colour, type, spacing, radius, shadow, motion. Light mode and dark mode. |
| `02_components.md` | Buttons, cards, list rows, chips, forms, tab bar, sheets, alerts, player, countdown, checklist. |
| `03_accessibility.md` | Dynamic Type, contrast, tap targets, VoiceOver, Reduce Motion. |
| `04_sample_data.md` | The one sample data set every screen uses. Nothing else. |
| `05_screen_specs_user.md` | Specs for the 20 user app screens, in roadmap order. |
| `06_screen_specs_admin.md` | Specs for the 6 admin content management screens. |
| `07_ux_flows.md` | The five most important tasks, step by step, with edge cases. |
| `08_decisions_and_open_questions.md` | Decisions made here, and what still needs the client. |

`DesignSystem/DesignTokens.swift` at the repo root carries the same tokens in
SwiftUI code. Docs and code must match. If they ever disagree, the docs in
this folder win and the Swift file is updated to match.

## Design language

Meta Astryx is the design language reference only. Astryx is not a code
dependency. The native build stays SwiftUI. What is borrowed from Astryx:

1. Semantic tokens, named by purpose, never by appearance. Code never
   carries a raw hex value outside `DesignTokens.swift`.
2. Frame first layout. Pick the shell, then place content. Dense data
   renders as rows with dividers, edge to edge.
3. Cards are for widgets, galleries and settings groups only. A list of
   entries, drills, videos or figures is rows, never a stack of cards.
4. Badges are for counts and enumerated states only. Status uses a written
   label plus a dot, never colour alone.
5. One clear hierarchy per screen. Generous white space. Nothing decorative.

## Quality rules, hard

1. Professional and very clean. No AI slop.
2. No lorem ipsum. Every string in a spec is real copy or it is marked as a
   placeholder that the client must supply.
3. No random gradients. No invented features. No stock style clutter.
4. Every element comes from the roadmap or the admin screen list.
5. One clear hierarchy per screen. Generous white space.
6. Sample data is consistent everywhere. It all comes from
   `04_sample_data.md`. Dancer May. International Latin only: cha cha,
   samba, rumba, paso doble, jive. Alemana and Fan figures are labelled
   pending the client NDCA list. The sample NDCA competition is shown only
   as a relative countdown labelled sample data. No real competition name,
   date, venue or price is invented anywhere.
7. No hyphens or em dashes in visible app text, except literal identifiers
   such as INV-2026-1122-01. This applies to every string in the specs.
   File names use underscores for the same reason.
8. No Devanagari in app text. App copy is English.

## Brand status

Brand preference is pending from May, due 2 Dec 2026. Until she answers,
the system uses the provisional palette in `01_design_tokens.md`, taken from
the Week 1 presentation: teal as the single accent, neutral greys, one
secondary purple used sparingly for the figure library. The accent token is
a single swap point. When May picks brand colours, change the accent token
values only. No screen layout changes.

## How to use these specs

1. Read `04_sample_data.md` first. Build the sample data set exactly as
   written, so every screen shot and every review shows the same journal,
   the same drills, the same videos, the same figures.
2. Build `DesignTokens.swift` first, then components, then screens.
3. Each screen spec follows the same template: purpose, layout, components,
   states, navigation, sample data. A screen is done when all four states
   are handled: normal, empty, error, loading.
4. Anything marked as an open question in
   `08_decisions_and_open_questions.md` is not to be guessed. Build the
   documented default and raise the question at the Week 1 review.

## Navigation map, at a glance

Four tabs: Journal, Library, Progress, Settings.

- Journal tab root is Home Dashboard. Home leads to Journal List, Journal
  Entry Detail, Create and Edit Journal Entry, and Competition Detail
  through the countdown card.
- Library tab root is Video Library, with a top segment that switches the
  list to Figure Library Browse or Drill List. Each keeps its own spec.
- Progress tab root is Journal Insights by Category, with a top segment
  that switches to Practice History.
- Settings tab root is Settings and Local Profile. Its Content Management
  section leads to Admin Dashboard, the hub for the six admin screens.

Full per screen navigation is in the screen specs.
