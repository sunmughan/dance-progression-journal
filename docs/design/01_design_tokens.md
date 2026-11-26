# 01 Design Tokens

Tokens are semantic. Names describe purpose, never appearance. No screen
and no component uses a raw hex value. The only place a hex value lives is
this file and `DesignTokens.swift`.

Provisional palette note: brand preference is pending from May, due 2 Dec
2026. The accent below is provisional, taken from the Week 1 presentation.
When May picks brand colours, change the accent token values only.

## Colour, light mode

| Token | Value | Use | Contrast on its surface |
| --- | --- | --- | --- |
| `backgroundPrimary` | #FFFFFF | Screen background | n/a |
| `backgroundSecondary` | #F4F6F8 | Grouped background, input fill | n/a |
| `surfaceCard` | #FFFFFF | Card surface, with a 1 pt border | n/a |
| `borderSubtle` | #E3E8EE | Card borders, row dividers | n/a |
| `textPrimary` | #14181D | Headings, body text, row titles | 17.8 to 1 on white |
| `textSecondary` | #606770 | Dates, metadata, helper text | 5.7 to 1 on white |
| `textTertiary` | #757C86 | Large text and icons only, never small text | 4.2 to 1 on white |
| `accent` | #0E7A5F | Primary buttons, links, selected states, tab selection | 5.3 to 1 on white, white text on accent 5.3 to 1 |
| `accentText` | #0A5C48 | Accent coloured text on light surfaces | 8.0 to 1 on white |
| `accentSoft` | #E2F2E7 | Accent tinted background for selected chips and tags | n/a |
| `library` | #7A4FD0 | Figure library accents only, used sparingly | 5.5 to 1 on white |
| `libraryText` | #5B32B8 | Figure library text on light surfaces | 8.1 to 1 on white |
| `challenge` | #B3540A | Challenge category | 5.0 to 1 on white |
| `accomplishment` | #217A3C | Accomplishment category | 5.4 to 1 on white |
| `uncategorised` | #606770 | Uncategorised category, same as secondary text | 5.7 to 1 on white |
| `warning` | #9A6206 | Warning text, storage warnings | 5.1 to 1 on white |
| `danger` | #C0281B | Delete actions, error text | 5.9 to 1 on white |
| `dangerSoft` | #FBE9E7 | Danger tinted background for delete confirmation | n/a |

Category colour is never the only signal. Every category tag pairs its
colour with a written label: Challenge, Accomplishment, Uncategorised.

Dances have no colour. A dance is always named in words: cha cha, samba,
rumba, paso doble, jive. Colour per dance would add clutter and would mean
nothing to VoiceOver.

## Colour, dark mode

| Token | Value | Use | Contrast on its surface |
| --- | --- | --- | --- |
| `backgroundPrimary` | #121214 | Screen background | n/a |
| `backgroundSecondary` | #1C1E21 | Grouped background, input fill | n/a |
| `surfaceCard` | #1E2023 | Card surface, with a 1 pt border | n/a |
| `borderSubtle` | #2E3136 | Card borders, row dividers | n/a |
| `textPrimary` | #F5F5F7 | Headings, body text, row titles | 17.2 to 1 on dark background, 15.0 to 1 on dark card |
| `textSecondary` | #A8A8AD | Dates, metadata, helper text | 7.9 to 1 on dark background, 6.9 to 1 on dark card |
| `textTertiary` | #9BA0A8 | Tertiary text, all sizes in dark mode | 7.1 to 1 on dark background |
| `accent` | #5EC8AC | Primary buttons, links, selected states, tab selection | 9.2 to 1 on dark background, 8.0 to 1 on dark card |
| `accentText` | #5EC8AC | Accent coloured text on dark surfaces | 9.2 to 1 on dark background |
| `accentSoft` | #16352C | Accent tinted background for selected chips and tags | n/a |
| `library` | #B79CFF | Figure library accents only | 8.2 to 1 on dark background |
| `libraryText` | #B79CFF | Figure library text on dark surfaces | 8.2 to 1 on dark background |
| `challenge` | #F2A35C | Challenge category | 9.1 to 1 on dark background |
| `accomplishment` | #7BC8A4 | Accomplishment category | 9.5 to 1 on dark background |
| `uncategorised` | #A8A8AD | Uncategorised category | 7.9 to 1 on dark background |
| `warning` | #F0B95A | Warning text | 10.5 to 1 on dark background |
| `danger` | #FF7A6E | Delete actions, error text | 7.4 to 1 on dark background |
| `dangerSoft` | #3A1D1A | Danger tinted background for delete confirmation | n/a |

All text pairs pass WCAG AA at 4.5 to 1 or better, in both modes, except
`textTertiary` in light mode at 4.2 to 1, which is restricted to large text
at 17 pt and above and to icons. It is never used for footnote or caption
sizes.

## Type scale

System font SF Pro. Display face SF Pro Rounded for large titles and for
countdown numerals only. Everything else is SF Pro. Dynamic Type is
supported on every style. Layouts reflow at larger sizes, never truncate
essential text.

| Style | Size | Weight | Use |
| --- | --- | --- | --- |
| Large Title | 34 | Semibold, Rounded | Screen title on Home Dashboard and section roots |
| Title 1 | 28 | Semibold, Rounded | Screen title on detail screens |
| Title 2 | 22 | Semibold | Section titles inside a screen |
| Title 3 | 20 | Semibold | Card titles |
| Headline | 17 | Semibold | Row titles, button labels, form labels |
| Body | 17 | Regular | Journal text, notes, descriptions |
| Callout | 16 | Regular | Secondary body copy |
| Subheadline | 15 | Regular | Metadata lines under a row title |
| Footnote | 13 | Regular | Helper text, timestamps, storage lines |
| Caption 1 | 12 | Medium, uppercase | Eyebrow labels, section headers, dance labels |
| Caption 2 | 11 | Regular | Small print, version line |

Rules:

- One title per screen. Screen titles are Title 1 or Large Title, never
  larger.
- Eyebrow labels are Caption 1, uppercase, with 0.5 pt tracking.
- Body text line spacing is 22 pt on a 17 pt body, 20 pt on a 16 pt callout.
- Journal body text never goes below Body 17. It is the content the app
  exists to read.
- Numbers that matter, the countdown and practice totals, use tabular
  figures so digits do not shift as they change.

## Spacing, 8 point grid

Base unit 8. A 4 point half step is allowed inside chips and tight rows
only. Nothing else uses a value off the grid.

| Token | Value | Use |
| --- | --- | --- |
| `space1` | 4 | Inside chips, tag padding, tight row gaps |
| `space2` | 8 | Gaps between a label and its value, icon to text |
| `space3` | 16 | Screen side margin, card padding, row gaps |
| `space4` | 24 | Gaps between sections inside a screen |
| `space5` | 32 | Major breaks between groups, top of a detail screen |
| `space6` | 48 | Breathing room on empty states, bottom of long forms |

Screen side margin is 16 on standard phones and 20 on large phones.
Content never touches the screen edge. The safe area is always respected.

## Corner radius

| Token | Value | Use |
| --- | --- | --- |
| `radiusSmall` | 8 | Thumbnails, tags, small media |
| `radiusMedium` | 12 | Buttons, text fields, pickers |
| `radiusLarge` | 16 | Cards |
| `radiusSheet` | 20 | Top corners of sheets |
| `radiusPill` | Full | Filter chips, category tags, toggle pills |

## Shadow and borders

Cards use a 1 pt `borderSubtle` border and no shadow. The app is flat and
clean. Shadow is reserved for floating layers only:

| Token | Light mode | Dark mode | Use |
| --- | --- | --- | --- |
| `shadowSheet` | y 8, blur 24, black 12 percent | y 8, blur 24, black 40 percent | Sheets, action sheets |
| `shadowFloating` | y 4, blur 12, black 10 percent | y 4, blur 12, black 35 percent | Video player controls, floating buttons |

## Motion

| Token | Value | Use |
| --- | --- | --- |
| `durationFast` | 150 ms | Toggles, chip selection, press states |
| `durationStandard` | 250 ms | Navigation pushes, sheet presentation |
| `durationSlow` | 350 ms | Countdown changes, chart updates |
| `easeStandard` | Ease in out | All motion |

Motion respects the Reduce Motion setting. When it is on, transitions are
instant and the countdown updates without animation.

## Iconography

SF Symbols only. No custom icon set in Phase 1. Icon sizes: 20 pt in rows,
24 pt in the tab bar, 28 pt in empty states. Icons always sit beside a
written label, except the tab bar and the video player transport controls,
which carry VoiceOver labels. Icon colour is `textSecondary` by default and
`accent` when selected.
