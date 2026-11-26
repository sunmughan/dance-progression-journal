# 02 Components

Every component below is built once and reused on every screen. No screen
invents its own button, card or row. States are part of the component, not
an afterthought: normal, pressed, disabled, loading.

## Primary button

- Height 52. Full width inside forms and sheets, content width elsewhere.
  Radius 12. Background `accent`. Label white, Headline 17 semibold.
- Pressed: background darkens one step, no scale change.
- Disabled: background `backgroundSecondary`, label `textTertiary`, never
  tappable. A disabled Save always has a visible reason beside it, for
  example "Enter a title to save".
- Loading: label replaced by a spinner, button stays disabled.
- Minimum tap target 44 by 44. The 52 height already clears it.
- Examples: Save entry, Save practice, Save competition, Save drill,
  Save video, Continue.

## Secondary button

- Height 52. Radius 12. Transparent background, 1 pt `borderSubtle`
  border, label `accentText` in light mode and `accent` in dark mode.
- Examples: Cancel, Choose from Library, Record Video.

## Destructive button

- Text button style. Label `danger`, Headline 17. No background fill.
- Destructive actions always ask for confirmation first, in an alert.
- Examples: Delete entry, Delete video, Delete all data.

## Text button and links

- Label `accentText` in light mode, `accent` in dark mode, Headline 17.
- Instagram links use this style with an arrow icon. The label reads
  "View on Instagram". The raw URL is never shown as the label.

## Cards

Cards are for widgets, galleries and settings groups only. Lists of entries,
drills, videos and figures are rows, never cards.

- Radius 16. Background `surfaceCard`. Border 1 pt `borderSubtle`.
  Padding 16. No shadow.
- Card types in this app: countdown card, summary card, insight summary
  card, admin count card, storage card.
- A card holds one idea. A card never holds a whole screen.

## List rows

- Height minimum 64, grows with content. Full width, edge to edge, with a
  1 pt divider in `borderSubtle` between rows. Side padding 16.
- Row layout, left to right: optional thumbnail or icon, title in Headline
  17 semibold, one metadata line in Subheadline 15 `textSecondary`,
  disclosure chevron at the right in `textTertiary`.
- Pressed: background `backgroundSecondary`, no other change.
- Favourite rows carry a filled star icon in `accent` at the right, before
  the chevron.
- Row types: journal entry row, drill row, video row in list mode,
  competition row, figure row, practice session row, settings row.

## Filter chips

- Pill shape, height 32. Padding 8 horizontal, 4 vertical. Label
  Subheadline 15.
- Unselected: background `backgroundSecondary`, label `textPrimary`.
- Selected: background `accentSoft`, label `accentText` in light mode and
  `accent` in dark mode, with a 1 pt accent border.
- Chips sit in a single horizontal scroll row under the screen title.
  They never wrap to two lines.

## Category tags

- Pill shape, height 24. Label Caption 1, 12 medium uppercase.
- Challenge: text `challenge` on a tinted background at 12 percent of the
  challenge colour. Accomplishment: text `accomplishment` on its tint.
  Uncategorised: text `uncategorised` on `backgroundSecondary`.
- A tag always shows the written word. Colour is never the only signal.

## Search field

- Height 44. Radius 12. Background `backgroundSecondary`. Magnifier icon
  at the left, placeholder in `textSecondary`, clear button at the right
  when text is present.
- Placeholder text: "Search entries", "Search drills", "Search videos",
  "Search competitions", "Search figures". One per screen, matching the
  content.
- Search filters as text is typed. No search button.

## Form controls

- Text field: height 52, radius 12, background `backgroundSecondary`,
  padding 16, Body 17. Label above in Headline 17 semibold. Helper text
  below in Footnote 13 `textSecondary`.
- Text editor for journal body and notes: minimum height 160, same
  styling, grows with content, no fixed character count shown.
- Picker: native iOS picker in a sheet, or a segmented control for two to
  five options. Dance picker uses a segmented control where space allows
  and a sheet picker in forms.
- Date picker: native compact date picker, always in the same style.
  Defaults to today wherever the roadmap says so.
- Toggle: native switch, accent colour. Label at the left, switch at the
  right. Used for Favourite and for Reminders.
- Segmented control: native segmented control, used for Upcoming and Past,
  Videos and Figures and Drills, Insights and Practice History, and for
  video type Choreography or Drill.
- Stepper or number field for repetitions and duration: a plain number
  field with a stepper beside it, keyboard type number pad.
- Confidence selector: five tappable circles numbered 1 to 5, 44 by 44
  each, selected circle filled in `accent` with white numerals.
- Difficulty selector: three options, Beginner, Intermediate, Advanced,
  as a segmented control.
- Focus area picker: options Footwork, Timing, Posture, Partner
  Connection, Routine. Sheet picker in the drill form.
- Entry status selector: options Interested, Entered, Confirmed,
  Completed, Cancelled. Sheet picker on Competition Detail and in the
  competition form.

## Tab bar

- Four tabs: Journal, Library, Progress, Settings.
- Icons: Journal uses the journal icon, Library uses the stack icon,
  Progress uses the chart icon, Settings uses the gear icon. SF Symbols.
- Label Caption 2, 11 regular, under the icon. Selected tab icon and
  label in `accent`. Unselected in `textSecondary`.
- No badges in Phase 1. No tab carries a count.
- The tab bar is always visible on root screens. It hides on pushed detail
  and form screens, following standard iOS behaviour.

## Navigation bar

- Large Title on root screens: Home Dashboard, Journal List, Video
  Library, Journal Insights, Settings.
- Title 1, inline, on detail and form screens.
- Back button is the standard iOS back chevron with the previous screen
  title. No custom back control.
- Right side actions are text buttons: Edit, Save, Add. Icon only actions
  carry VoiceOver labels.

## Empty state

- Centred in the content area. Icon 28 pt in `textTertiary`. Title Title
  3, 20 semibold. One line of helper text in Callout 16 `textSecondary`.
- One primary action button below, for example "New Entry" or
  "Add Drill" or "Add Video" or "Browse figures".
- Empty states never show a list skeleton and never show an error.
- Exact copy per screen is in the screen specs.

## Error state

- A plain inline banner at the top of the content area, or an alert for
  destructive failures. Banner: background `dangerSoft`, text `danger`,
  Body 17, with a retry button where retry makes sense.
- Error copy is plain and specific: what failed, and what to do next.
  Example: "This video could not be saved. Check storage and try again."
- No error message about the network ever appears for local actions.
  Phase 1 works offline. A local save failing is a storage problem, and
  the copy says so.

## Loading state

- Local data loads instantly in practice. Where a load is visible, show a
  spinner centred in the content area with the label "Loading" in
  `textSecondary`. No skeleton rows, no shimmer.
- Video thumbnails generate on import. While a thumbnail is missing, show
  the video placeholder tile in `backgroundSecondary` with a play icon.

## Sheets and alerts

- Sheets: radius 20 top corners, drag indicator, Cancel at the left of
  the sheet header, Save or Done at the right. Used for pickers and for
  small forms where the roadmap calls for a sheet.
- Alerts: used for delete confirmation and for Delete all data only.
  Title in Headline 17 semibold, message in Body 17, Cancel and Delete
  buttons. Delete is styled destructive.
- Delete confirmation copy: "Delete this entry? This cannot be undone."
  The object word changes per screen: entry, drill, video, competition,
  figure practice session.

## Video player

- Native AVPlayer controls: play and pause, scrub bar, time labels,
  full screen button. Mute control in the player bar.
- Player background black in both modes. Controls white.
- Below the player: title in Title 3, metadata line in Subheadline 15,
  notes in Body 17, linked items as rows.
- Landscape is allowed for playback. Lists and forms stay portrait.

## Countdown display

- Large numerals in SF Pro Rounded, Title 1, 28 semibold, tabular
  figures. Unit label under each numeral in Caption 1 uppercase:
  Days, Hours, Minutes.
- One line under the numerals in Subheadline 15 `textSecondary` stating
  the target in words, for example "Sample NDCA event starts in 42 days".
  The sample event is labelled sample data on the card.
- No live seconds ticker. Days, hours and minutes only.

## Checklist rows

- Row height minimum 52. Tick box at the left, 28 by 28, radius 8,
  border 1 pt `borderSubtle`. Ticked: filled `accent` with a white check.
- Title in Body 17. Done items show the title in `textSecondary` with no
  strikethrough, so done text stays readable.
- Due date at the right in Footnote 13 `textSecondary`, written as a
  relative label in sample data, for example "in 28 days".
- Add item field at the bottom of the list: text field with an Add button.
  New items are unchecked with no due date until one is set.
- Checklist categories are Registration, Travel, Costume, Practice,
  Music, Paperwork. Category shows as a small tag on the row.
