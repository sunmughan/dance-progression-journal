# 03 Accessibility

Accessibility is part of the design, not a checklist added at the end.
Every rule below is testable on device.

## Dynamic Type

- Every text style uses the iOS Dynamic Type styles in
  `01_design_tokens.md`. No fixed point size is set outside the token
  file.
- Layouts reflow at larger sizes. Rows grow in height. Buttons grow in
  height. Text wraps, never truncates, on titles, body copy and button
  labels. The only truncation allowed is a single metadata line in a list
  row, and only after the title has wrapped to two lines.
- At the largest accessibility sizes, the tab bar labels remain readable
  and the primary Save button stays reachable without scrolling past the
  form. Forms scroll. Nothing essential sits below the fold at large
  sizes without a scroll path to it.
- Test at the five sizes: default, large, extra large, accessibility
  medium, accessibility large.

## Contrast

- Body text contrast is at least 4.5 to 1 in light mode and dark mode.
  Measured values are in `01_design_tokens.md`.
- `textTertiary` in light mode measures 4.2 to 1. It is used for large
  text at 17 pt and above and for icons only. It is never used for
  footnote or caption sizes.
- The countdown numerals, category tags, checklist ticks and selected
  chips all pass 4.5 to 1 for their text.
- Contrast is checked in both modes on device, not only in the design
  file.

## Tap targets

- Minimum tap target 44 by 44 on every control. No exceptions.
- Buttons are 52 high. Chips are 32 high with 6 of extra tappable padding
  around them, bringing the target to 44. The confidence circles are
  44 by 44. Checklist tick boxes are 28 by 28 visually with 44 by 44
  tappable area. Tab bar items are 49 high with full width targets.
- Adjacent controls keep at least 8 of clear space between their tap
  targets.

## VoiceOver

- Every control that shows as an icon only carries a VoiceOver label:
  favourite star, clear search button, grid and list toggle, play and
  pause, full screen, mute, add item, delete row actions.
- Reading order matches visual order on every screen: title, metadata,
  actions.
- Category tags read as words: "Category, Accomplishment". The colour is
  never the information.
- The countdown reads as a sentence: "Sample NDCA event starts in 42
  days". The numerals are not read digit by digit.
- Images and video thumbnails carry labels with the video title and
  duration. Decorative icons are hidden from VoiceOver.

## Colour is never the only signal

- Categories pair colour with a written label.
- Favourites pair the star with the word Favourite in the detail screen.
- Entry status pairs the status word with a dot, never a dot alone.
- Form errors pair a red message with an icon and words, never colour
  alone.

## Reduce Motion

- When Reduce Motion is on, navigation transitions are instant, the
  countdown updates without animation, and chart bars appear without
  growth animation.
- No auto playing video. No parallax. No motion that is decorative.

## Keyboard and input

- Forms dismiss the keyboard with a Done button on the keyboard toolbar
  and by tapping outside the field.
- The Save button stays visible above the keyboard while a form is open.
- Focus moves in reading order: title, body, dance, date, links, Save.
