# 05 Screen Specs: User App

All 20 screens, in roadmap order. Every screen follows the same template:
purpose, layout, components used, states, navigation, sample data. Sample
data comes from `04_sample_data.md` and is repeated here per screen so a
builder never has to look elsewhere.

Tab map reminder: Journal tab root is Home Dashboard. Library tab root is
Video Library with a top segment for Figures and Drills. Progress tab root
is Journal Insights with a top segment for Practice History. Settings tab
root is Settings and Local Profile.

---

## Screen 1: Welcome and Setup

Purpose: Introduce the app and set the local dancer profile and preferred
dances on first launch only. This screen never appears again after setup.

Layout: Single scrolling column. Top: app name in Large Title 34 Rounded,
tagline under it. Middle: intro text, name field, dance selection list,
experience level selector. Bottom: Continue primary button, Skip text
button under it, privacy note at the very bottom. Generous spacing, 24
between groups, 48 above the Continue button.

Components used: Large Title, Body intro text, text field, dance selection
list with check marks, segmented experience selector, primary button,
text button, footnote privacy note.

States:

- Normal: all fields visible. Name field empty. No dance selected yet.
  Continue disabled until a name is entered and at least one dance is
  selected.
- Empty state: not applicable, this is a first launch form.
- Error state: name field shows inline helper text in `danger` when
  Continue is tapped with no name: "Enter your name to continue."
- Loading state: none. Everything is local.

Navigation: Comes from app launch on first run only. Continue or Skip
goes to Home Dashboard. Skip keeps the default profile: name "May" is not
assumed. Skip leaves the name blank and selects all five dances. The
profile can be completed later in Settings.

Sample data and copy:

- App name: Dance Progression Journal
- Tagline: Train, reflect, progress
- Intro: "A journal built for International Latin practice, built around
  your dances and your goals."
- Name field label: "Your name". Placeholder: "May"
- Dance list: cha cha, samba, rumba, paso doble, jive, each with a
  check mark when selected
- Experience level selector: Beginner, Intermediate, Advanced,
  Competition dancer. Sample selection: Competition dancer
- Privacy note: "Your data stays on this device. No account. No sign in.
  Journal text, videos and notes live on this iPhone only."
- Buttons: Continue, Skip

---

## Screen 2: Home Dashboard

Purpose: Today at a glance. Next competition countdown, recent journal
entries, next drill, recent videos, and quick actions. This is the first
screen inside the Journal tab.

Layout: Scrolling column. Top: greeting in Large Title, date line under it
in Subheadline. Next: countdown card. Next: quick actions row with three
equal buttons: New Entry, Add Drill, Add Video. Then three sections, each
with a Title 3 heading and a See all text button at the right: Recent
entries, Next drill, Recent videos. Section gap 24. Screen side margin 16.

Components used: Large Title, countdown card, three secondary buttons in a
row, section headings, journal entry rows, drill row, video thumbnail
rows, See all text buttons.

States:

- Normal: countdown card, three recent entries, one next drill, two
  recent videos, all visible.
- Empty state: no entries yet shows a friendly empty card in the Recent
  entries section with the text "No entries yet. Write your first entry
  after practice." and a New Entry button. Same pattern per section when
  that section alone is empty.
- Error state: none for local reads. A failed video thumbnail shows the
  placeholder tile, never an error banner.
- Loading state: spinner only on first launch while the store opens.

Navigation: Comes from Welcome and Setup on first launch, and from the
Journal tab at any time. Countdown card taps to Competition Detail.
Recent entries See all goes to Journal List. A recent entry row goes to
Journal Entry Detail. Next drill row goes to Drill Detail. A recent video
row goes to Video Detail and Player. New Entry goes to Create Journal
Entry. Add Drill goes to Create Drill. Add Video goes to Add Video.

Sample data:

- Greeting: "Good evening, May" with the date line under it
- Countdown card: "Sample NDCA event", "42 days to go", label
  "Sample data"
- Recent entries, newest first: Samba bounce finally clicked, Rumba walk
  timing, Cha cha lock step footwork
- Next drill: Rumba Walks, Rumba, Footwork, 20 repetitions
- Recent videos: Rumba routine run through, 2:10; Samba basic practice,
  1:24

---

## Screen 3: Journal List

Purpose: All journal entries in date order, with search and filters.

Layout: Large Title "Journal". Search field under the title. Filter chip
row under the search field, horizontal scroll: All, Challenges,
Accomplishments, then a dance filter chip that opens a sheet with the five
dances. Sort control at the right of the chip row: Newest first or Oldest
first. Entry rows below, edge to edge with dividers. New Entry primary
button pinned above the tab bar.

Components used: Large Title, search field, filter chips, sort control,
journal entry rows, primary button.

States:

- Normal: three sample entries, newest first, each row showing title,
  category tag, dance, date.
- Empty state: no entries shows the icon, title "No entries yet", helper
  "Write your first entry after practice.", and a New Entry button.
- Empty state after filter: no match shows "No entries match this filter."
  with a "Clear filters" text button.
- Error state: none for local reads.
- Loading state: spinner on first open only.

Navigation: Comes from Home Dashboard See all and from the Journal tab.
A row goes to Journal Entry Detail. New Entry goes to Create Journal
Entry.

Sample data: the three entries from `04_sample_data.md`, newest first.
Category tags read Challenge or Accomplishment. Dance shown as plain
text: Samba, Rumba, Cha cha.

---

## Screen 4: Journal Entry Detail

Purpose: One full entry with text, category, dance, date, linked video,
linked drill, linked figure, Instagram link.

Layout: Scrolling column. Top: title in Title 1, metadata line under it:
dance, date, category tag. Next: body text in Body 17. Next: "Suggested by
the app" line with AI tags. Next: Linked items section with rows for
video, drill, figure. Next: Instagram link button. Top right bar actions:
Edit text button, Delete text button in `danger`. Share button at the
bottom for local export.

Components used: Title 1, category tag, body text, linked item rows,
video thumbnail row, text buttons, destructive button, share button.

States:

- Normal: all sections visible with the sample links.
- Empty state: no linked items shows "None linked" in `textSecondary`
  under the Linked items heading, with an Edit button to add links.
- Error state: none. Delete asks for confirmation first: "Delete this
  entry? This cannot be undone."
- Loading state: none.

Navigation: Comes from Journal List, from Home Dashboard recent entries,
from Insights entry rows, from Drill Detail linked entries, from Video
Detail linked entries. Edit goes to Create and Edit Journal Entry
prefilled. Delete returns to Journal List after confirmation. A linked
video row goes to Video Detail. A linked drill row goes to Drill Detail.
A linked figure row goes to Figure Detail. Instagram button opens the
link in the browser.

Sample data: entry "Rumba walk timing", Rumba, Challenge, Yesterday.
Body text as in `04_sample_data.md`. AI tags: timing, weight transfer.
Linked video: Rumba routine run through, 2:10. Linked drill:
Rumba Walks. Linked figure: Alemana. Instagram: "View on Instagram"
button.

---

## Screen 5: Create and Edit Journal Entry

Purpose: Write or change an entry. On device AI categorises it as a
challenge or an accomplishment. The category is editable on every entry.

Layout: Scrolling form. Top bar: Cancel at the left, Save at the right.
Fields in order: title field, body editor, dance picker, date picker,
Instagram link field, Link drill row, Link video row, Link figure row.
Category preview appears under the body editor after text is entered:
"Category: Challenge" with an Edit control to change it. Save is a
primary button in the top bar.

Components used: text field, text editor, dance picker, date picker,
text field for Instagram link, link rows with chevrons, category preview
with edit control, primary Save, secondary Cancel.

States:

- Normal, create: blank fields, date defaults to today, Save disabled.
- Normal, edit: prefilled with the sample entry values.
- Empty title: Save stays disabled until a title is entered. Helper text
  under the title field: "Enter a title to save."
- Error state: a save failure shows an inline banner: "This entry could
  not be saved. Check storage and try again."
- Loading state: Save shows a spinner while writing, then navigates.

Navigation: Comes from Journal List New Entry, Home Dashboard New Entry,
and Journal Entry Detail Edit. Save goes to Journal Entry Detail.
Cancel returns to where it came from with no changes saved.

Sample data, edit mode: title "Rumba walk timing", body text as in
`04_sample_data.md`, dance Rumba, date Yesterday, Instagram link empty,
linked drill Rumba Walks, linked video Rumba routine run through,
linked figure Alemana, category Challenge.

---

## Screen 6: Journal Insights by Category

Purpose: Counts and trends for challenges and accomplishments by dance
and by month. This is the root of the Progress tab.

Layout: Large Title "Progress". Segmented control under the title:
Insights, Practice History. Month selector under the segment: previous
and next chevrons around the month name. Next: two summary cards side by
side, Accomplishments and Challenges, each with a large numeral. Next:
dance filter chips. Next: trend chart, bars per month. Next: entry list
for the selected month.

Components used: Large Title, segmented control, month selector, summary
cards, filter chips, trend chart, entry rows.

States:

- Normal: counts and chart visible for December 2026.
- Empty state: a month with no entries shows zero counts and the chart
  message "No entries in this month yet." The entry list shows "No
  entries in this month yet." with no button.
- Error state: none for local reads.
- Loading state: spinner on first open only.

Navigation: Comes from the Progress tab. An entry row goes to Journal
Entry Detail. The Practice History segment switches to Screen 19.
Practice History is reached from here and from Figure Detail.

Sample data: month December 2026. Accomplishments 2, Challenges 1,
total 3. By dance: Samba 1, Rumba 1, Cha cha 1, Paso doble 0, Jive 0.
Entry list shows the three sample entries.

---

## Screen 7: Drill List

Purpose: All saved drills grouped by dance, with favourites at the top.

Layout: Title "Drills", reached through the Library tab segment. Search
field under the title. Filter row: dance filter chip, focus area filter
chip, both opening sheets. Favourites toggle at the right of the filter
row. Groups below: Favourites group first, then one group per dance with
a Caption 1 group heading. Drill rows inside each group. Add Drill
primary button pinned above the tab bar.

Components used: search field, filter chips, favourite toggle, group
headings, drill rows, primary button.

States:

- Normal: Favourites group with Rumba Walks and Cha Cha Lock Steps,
  then By dance groups.
- Empty state: no drills shows the icon, title "No drills yet", helper
  "Save a drill to practise it again.", and an Add Drill button.
- Empty state after filter: "No drills match this filter." with a
  "Clear filters" text button.
- Error state: none for local reads.
- Loading state: spinner on first open only.

Navigation: Comes from the Library tab segment and from Home Dashboard
Add Drill. A row goes to Drill Detail. Add Drill goes to Create and Edit
Drill.

Sample data: Rumba Walks, Samba Bounce Basics, Cha Cha Lock Steps, as in
`04_sample_data.md`. Row metadata reads "Rumba, Footwork, 20
repetitions". Favourite rows carry a filled star.

---

## Screen 8: Drill Detail

Purpose: One drill with description, focus area, target repetitions,
target duration, practice history, linked videos and linked journal
entries.

Layout: Scrolling column. Top: name in Title 1, metadata line under it:
dance, focus area, difficulty. Next: description in Body 17. Next: two
target cards side by side: Target repetitions 20, Target minutes 15.
Next: primary button Mark Practiced, secondary button Start Timer. Next:
Practice history section with session rows. Next: Linked videos section.
Next: Linked entries section. Top right bar actions: Edit, Delete.

Components used: Title 1, target cards, primary button, secondary
button, session rows, linked video rows, linked entry rows, destructive
Delete.

States:

- Normal: all sections visible with the sample data.
- Empty state: no practice yet shows "No practice logged yet. Tap Mark
  Practiced after your first set." No linked videos shows "None linked".
- Error state: Delete asks for confirmation first: "Delete this drill?
  This cannot be undone."
- Loading state: none.

Navigation: Comes from Drill List, Home Dashboard Next drill, Journal
Entry Detail linked drill, Video Detail linked drill. Edit goes to Create
and Edit Drill prefilled. Mark Practiced logs a session with today date
and the drill targets, then shows a confirmation and updates the history
list. Start Timer opens the timer, which is a simple count up timer on
this screen, not a separate screen. Linked video goes to Video Detail.
Linked entry goes to Journal Entry Detail.

Sample data: Rumba Walks. Description "Slow forward and back walks with
full weight transfer on every count." Target repetitions 20, target
minutes 15, difficulty Intermediate, favourite on, last practiced
Yesterday. Practice history: Yesterday, 2 days ago, 4 days ago. Linked
video: Rumba routine run through. Linked entry: Rumba walk timing.

---

## Screen 9: Create and Edit Drill

Purpose: Add or change a drill for a selected dance.

Layout: Scrolling form. Top bar: Cancel at the left, Save at the right.
Fields in order: name field, dance picker, focus area picker, description
field, repetitions field, duration field, difficulty selector, favourite
toggle. Save is a primary button in the top bar.

Components used: text field, pickers, text editor, number fields with
steppers, segmented difficulty selector, toggle, primary Save, secondary
Cancel.

States:

- Normal, create: blank fields. Save disabled until name and dance are
  set. Helper text: "Enter a name and pick a dance to save."
- Normal, edit: prefilled with the Rumba Walks values.
- Error state: a save failure shows an inline banner: "This drill could
  not be saved. Check storage and try again."
- Loading state: Save shows a spinner while writing.

Navigation: Comes from Drill List Add Drill, Home Dashboard Add Drill,
and Drill Detail Edit. Save goes to Drill Detail. Cancel returns with no
changes saved.

Sample data, edit mode: name Rumba Walks, dance Rumba, focus area
Footwork, description "Slow forward and back walks with full weight
transfer on every count.", repetitions 20, duration 15 minutes,
difficulty Intermediate, favourite on.

---

## Screen 10: Video Library

Purpose: All uploaded videos in date order, with filters by dance and by
type. This is the root of the Library tab.

Layout: Large Title "Library". Segmented control under the title:
Videos, Figures, Drills. Search field under the segment. Filter row:
dance filter chip, type filter chip for Choreography or Drill. Grid and
list toggle at the right of the filter row. Grid mode shows two columns
of thumbnails with title and duration under each. List mode shows video
rows. Add Video primary button pinned above the tab bar.

Components used: Large Title, segmented control, search field, filter
chips, grid and list toggle, video thumbnail tiles, video rows, primary
button.

States:

- Normal: two sample videos in grid mode by default, newest first.
- Empty state: no videos shows the icon, title "No videos yet", helper
  "Upload a practice video to watch it back.", and an Add Video button.
- Empty state after filter: "No videos match this filter." with a
  "Clear filters" text button.
- Error state: a thumbnail that fails to generate shows the placeholder
  tile, never an error banner.
- Loading state: spinner on first open only.

Navigation: Comes from the Library tab. A thumbnail or row goes to Video
Detail and Player. Add Video goes to Add Video and Upload Video. The
Figures segment switches to Figure Library Browse. The Drills segment
switches to Drill List.

Sample data: Rumba routine run through, Rumba, Choreography, 2:10,
Today. Samba basic practice, Samba, Drill, 1:24, Yesterday.

---

## Screen 11: Video Detail and Player

Purpose: Play one video and show date, dance, choreography or drill type,
notes, linked entries.

Layout: Video player at the top, 16 by 9, black background in both modes.
Player controls below the video: play and pause, scrub bar, time labels,
mute, full screen. Next: title in Title 3, metadata line under it: date,
dance, type. Next: notes in Body 17. Next: Linked journal entry row.
Next: Linked drill row. Next: Instagram link button. Top right bar
actions: Edit, Delete.

Components used: video player with native controls, Title 3, metadata
line, notes text, linked item rows, text button, destructive Delete.

States:

- Normal: video plays, notes and links visible.
- Empty state: notes field shows "Add a note" as placeholder text when
  empty. No linked entry shows "None linked".
- Error state: a video that cannot play shows an inline message: "This
  video could not be played. The file may be missing." Delete asks for
  confirmation first: "Delete this video? This cannot be undone."
- Loading state: player shows a spinner while the video prepares.

Navigation: Comes from Video Library, Home Dashboard recent videos,
Journal Entry Detail linked video, Drill Detail linked video, Figure
Detail linked video. Edit goes to Add Video and Upload Video prefilled.
Delete returns to Video Library after confirmation. Linked entry goes to
Journal Entry Detail. Linked drill goes to Drill Detail. Instagram button
opens the link in the browser.

Sample data: Rumba routine run through, Rumba, Choreography, 2:10,
Today. Choreography name: Rumba routine. Notes: "Full run through,
timing held after the turn." Linked entry: Rumba walk timing. Linked
drill: Rumba Walks. Linked figure: Alemana. Instagram: "View on
Instagram" button.

---

## Screen 12: Add Video and Upload Video

Purpose: Import from the device library or record a new video, and tag it
with date and type.

Layout: Scrolling form. Top: two large choice buttons side by side:
Choose from Library, Record Video. After a video is picked, a thumbnail
preview appears with duration. Fields in order: title field, date picker,
dance picker, type selector for Choreography or Drill, choreography name
field shown only when type is Choreography, drill picker shown only when
type is Drill, notes field, Instagram link field. Save is a primary button
in the top bar with Cancel at the left.

Components used: secondary choice buttons, thumbnail preview, text
fields, date picker, dance picker, segmented type selector, conditional
fields, text editor for notes, primary Save, secondary Cancel.

States:

- Normal, create: no video picked yet. The form below the choice buttons
  is disabled until a video is picked. Date defaults to today.
- After pick: thumbnail preview visible, form enabled, Save disabled
  until a title is entered.
- Normal, edit: prefilled with the Rumba routine values.
- Error state: a video that cannot be imported shows an inline banner:
  "This video could not be imported. Try a shorter video or check
  storage." A video over the size limit shows: "This video is over the
  size limit. Pick a shorter video."
- Loading state: thumbnail generation shows a spinner on the preview
  tile. Save shows a spinner while writing.

Navigation: Comes from Video Library Add Video, Home Dashboard Add
Video, and Video Detail Edit. Save goes to Video Detail and Player.
Cancel returns with no changes saved.

Sample data, edit mode: title Rumba routine run through, date Today,
dance Rumba, type Choreography, choreography name Rumba routine, notes
"Full run through, timing held after the turn.", Instagram link empty.

---

## Screen 13: Competition List

Purpose: All saved competitions from NDCC and NDCA in date order, with
countdown status.

Layout: Large Title "Competitions". Search field under the title. Filter
row: source filter chip for NDCC or NDCA, upcoming and past toggle as a
segmented control. Competition rows below, each showing name, source tag,
start date in words, days remaining. Add Competition primary button
pinned above the tab bar.

Components used: Large Title, search field, filter chips, segmented
upcoming and past control, competition rows, primary button.

States:

- Normal: one sample competition, upcoming, NDCA.
- Empty state: no competitions shows the icon, title "No competitions
  yet", helper "Add a competition to track its countdown and checklist.",
  and an Add Competition button.
- Empty state after filter: "No competitions match this filter." with a
  "Clear filters" text button.
- Error state: none for local reads.
- Loading state: spinner on first open only.

Navigation: Comes from Home Dashboard through the countdown card flow and
from Competition Detail back navigation. A row goes to Competition Detail
with Countdown and Checklist. Add Competition goes to Create and Edit
Competition.

Sample data: one row. Name "Sample NDCA event", source tag NDCA, "Starts
in 42 days", entry status Interested, label "Sample data" on the row.

---

## Screen 14: Competition Detail with Countdown and Checklist

Purpose: One competition with live countdown, event details, and
preparation checklist.

Layout: Scrolling column. Top: name in Title 1 with a "Sample data"
label beside it. Next: countdown card with large numerals and the line
"Sample NDCA event starts in 42 days". Next: details card with date,
venue, location, registration deadline, entry status selector. Next:
Checklist section with rows and an add item field at the bottom. Top
right bar actions: Edit, Delete.

Components used: Title 1, countdown card, details card, entry status
selector, checklist rows, add item field, destructive Delete.

States:

- Normal: countdown, details, five checklist items visible.
- Empty state: no checklist items shows "No checklist items yet. Add the
  first item below." with the add item field visible.
- Error state: Delete asks for confirmation first: "Delete this
  competition? This cannot be undone."
- Loading state: none.

Navigation: Comes from Competition List and from the Home Dashboard
countdown card. Edit goes to Create and Edit Competition prefilled.
Delete returns to Competition List after confirmation.

Sample data: as in `04_sample_data.md`. Countdown 42 days to go.
Registration deadline in 28 days. Entry status Interested. Location
"Sample location, client to supply". Venue "Sample venue, client to
supply". Checklist: Confirm entry done, Book travel, Costume fitting,
Music check, Practice plan, all with relative due labels.

---

## Screen 15: Create and Edit Competition

Purpose: Add or change a competition and set the countdown target date.

Layout: Scrolling form. Top bar: Cancel at the left, Save at the right.
Fields in order: name field, source selector for NDCC or NDCA, location
field, venue field, start date picker, end date picker, registration
deadline picker, entry status selector, notes field. Save is a primary
button in the top bar.

Components used: text fields, segmented source selector, date pickers,
entry status picker, text editor for notes, primary Save, secondary
Cancel.

States:

- Normal, create: blank fields. Save disabled until name, source and
  start date are set. Helper text: "Enter a name, pick a source and set a
  start date to save."
- Normal, edit: prefilled with the sample event values.
- Error state: a save failure shows an inline banner: "This competition
  could not be saved. Check storage and try again."
- Loading state: Save shows a spinner while writing.

Navigation: Comes from Competition List Add Competition and from
Competition Detail Edit. Save goes to Competition Detail. Cancel returns
with no changes saved.

Sample data, edit mode: name "Sample NDCA event", source NDCA, location
"Sample location", venue "Sample venue", start date in 42 days, end date
in 44 days, registration deadline in 28 days, entry status Interested,
notes "Sample notes, client to supply".

---

## Screen 16: Figure Library Browse

Purpose: Browse the NDCA figure library by dance and by level.

Layout: Title "Figures", reached through the Library tab segment. Dance
tabs under the title: cha cha, samba, rumba, paso doble, jive, as a
horizontal scroll row of chips, with All at the left. Filter row under
the tabs: level filter chip, favourites filter toggle, search field.
Figure rows below, each showing figure name, dance, level tag, practice
count. A note bar sits under the filter row: "Figure library sample data
is pending the client NDCA list."

Components used: dance tab chips, level filter chip, favourites toggle,
search field, figure rows, note bar.

States:

- Normal: six sample figures, filtered by the selected dance tab.
- Empty state: a dance with no figures shows "No figures for this dance
  yet." A favourites filter with no favourites shows "No favourite
  figures yet. Tap the star on a figure to save it here."
- Empty state after search: "No figures found." with a "Clear search"
  text button.
- Error state: none for local reads.
- Loading state: spinner on first open only.

Navigation: Comes from the Library tab segment. A row goes to Figure
Detail.

Sample data: the six figures from `04_sample_data.md`. Alemana and Fan
are Rumba, Bronze. The note bar is always visible until the client NDCA
list arrives.

---

## Screen 17: Figure Detail

Purpose: One NDCA figure with steps, timing, level, practice summary.

Layout: Scrolling column. Top: figure name in Title 1, metadata line
under it: dance, level tag, note "Pending the client NDCA list".
Next: description in Body 17. Next: steps list, numbered, one step per
row. Next: timing line in Callout 16. Next: practice summary card with
practice count, total repetitions, total minutes, average confidence.
Next: Log Practice primary button. Next: linked videos list. Top right:
favourite star toggle.

Components used: Title 1, level tag, numbered steps list, timing line,
practice summary card, primary button, linked video rows, favourite
toggle.

States:

- Normal: Alemana with six practice sessions and one linked video.
- Empty state: no practice yet shows practice count zero and the message
  "No practice yet. Log your first practice." with the Log Practice
  button below it. No linked videos shows "None linked".
- Error state: none.
- Loading state: none.

Navigation: Comes from Figure Library Browse, Journal Entry Detail
linked figure, Video Detail linked figure, Practice History session
rows. Log Practice goes to Log Figure Practice. A linked video goes to
Video Detail. The favourite star toggles the figure as a favourite and
updates the Favourites filter in the library.

Sample data: Alemana, Rumba, Bronze. Description: "Open turn to the
right with a forward walk into the turn." Steps: Forward walk into the
turn; Turn under the raised arm; Close and settle the weight; Step out
to finish. Timing: "Counts 2 3 4 1 across the figure at rumba tempo."
Practice count 6, total 48 repetitions, 72 minutes, average confidence
4 of 5. Linked video: Rumba routine run through.

---

## Screen 18: Log Figure Practice

Purpose: Record one practice session for a figure with date, repetitions,
duration, confidence.

Layout: Scrolling form. Top: figure label in Title 3 with dance under it.
Fields in order: date picker, repetitions field, duration field,
confidence selector from 1 to 5, notes field, link video control. Save is
a primary button in the top bar with Cancel at the left.

Components used: figure label, date picker, number fields with steppers,
confidence selector, text editor for notes, link video row, primary
Save, secondary Cancel.

States:

- Normal: figure label Alemana, dance Rumba, date defaults to today,
  confidence unselected.
- Save disabled until repetitions and duration are entered. Helper text:
  "Enter repetitions and duration to save."
- Error state: a save failure shows an inline banner: "This practice
  could not be saved. Check storage and try again."
- Loading state: Save shows a spinner while writing.

Navigation: Comes from Figure Detail Log Practice button. Save goes to
Figure Detail, which shows the updated practice summary. Practice History
confirms the new session and the updated totals.

Sample data: figure Alemana, Rumba. Date today. Repetitions 8. Duration
12 minutes. Confidence 4. Notes "Turn felt steadier on the last set."
No video linked.

---

## Screen 19: Practice History

Purpose: All figure practice sessions in date order, with totals by dance
and by figure.

Layout: Title "Practice", reached through the Progress tab segment.
Totals card at the top: total sessions, total repetitions, total minutes.
Filter row under the card: date filter chip, dance filter chip, figure
filter chip. Session rows below, grouped by date, each showing figure
name, dance, repetitions, minutes, confidence as stars or numerals.

Components used: totals card, filter chips, session rows grouped by
date.

States:

- Normal: eight sessions, newest first, with the totals card.
- Empty state: no sessions shows the icon, title "No practice logged
  yet", helper "Log practice from a figure to see it here.", and a
  "Browse figures" button that goes to Figure Library Browse.
- Empty state after filter: "No sessions match this filter." with a
  "Clear filters" text button.
- Error state: none for local reads.
- Loading state: spinner on first open only.

Navigation: Comes from the Progress tab segment and from Log Figure
Practice after save, through Figure Detail. A session row goes to Figure
Detail for that figure.

Sample data: totals 8 sessions, 58 repetitions, 92 minutes. Alemana
sessions as in `04_sample_data.md`: 6 sessions, 48 repetitions,
72 minutes, average confidence 4 of 5. Fan sessions: 2 sessions,
10 repetitions, 20 minutes, average confidence 3 of 5.

---

## Screen 20: Settings and Local Profile

Purpose: Manage local profile, preferred dances, data storage, app
information. No account.

Layout: Scrolling grouped list. Sections in order: Local profile, with
name field, experience level selector, preferred dances selector; Storage
on this device, with a storage card and per video size limit; Video
settings, with video quality default 1080p or 720p; Data, with Export
data button and Delete all data button; About, with version label and
privacy note; Content Management, with rows leading to Admin Dashboard.

Components used: grouped list sections, text field, selectors, storage
card, buttons, destructive button, version label, privacy note,
navigation rows.

States:

- Normal: all sections visible with the sample values.
- Empty state: not applicable.
- Error state: Delete all data asks for confirmation in an alert:
  "Delete all data? This removes every entry, drill, video and practice
  record from this iPhone. This cannot be undone." Export failing shows
  an inline banner: "Export could not be created. Check storage and try
  again."
- Loading state: export shows a spinner on the button while the file is
  created.

Navigation: Comes from the Settings tab. This is a leaf screen inside the
Settings tab, except for the Content Management section, which leads to
Admin Dashboard.

Sample data: name May, experience Competition dancer, preferred dances
all five, storage "2 videos, 184 MB", video quality 1080p, per video size
limit 500 MB, reminders off, version "Version 1.0.0 Build 1", bundle ID
"com.codeair.danceprogressionjournal", privacy note "Your data stays on
this device. No account. No sign in. Journal text, videos and notes live
on this iPhone only."
