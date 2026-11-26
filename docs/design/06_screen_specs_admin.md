# 06 Screen Specs: Admin Content Management

Six screens. These manage the content the dancer sees in the user app.
Phase 1 is local only, so admin edits change the on device library data
directly. There is no server, no sync, no account. Admin is reached from
Settings and Local Profile, through the Content Management section, which
opens Admin Dashboard. Admin Dashboard is the hub. The other five screens
are reached from it.

Admin screens use the same tokens and components as the user app. Same
buttons, same rows, same empty states. The only visual difference is the
screen title prefix "Manage" where the roadmap calls for it, and the admin
count cards on the dashboard.

---

## Admin A: Admin Dashboard

Purpose: Content at a glance, with counts and manage actions for each
content area.

Layout: Title "Content Management". Six count cards in a two column grid:
Journal entries, Drills, Videos, Figures, Competitions, Practice
sessions. Each card shows a large numeral, the area name, and a Manage
text button. Below the grid: a "Content by area" list with one row per
area, showing the count and a chevron.

Components used: count cards, navigation rows, Title 1.

States:

- Normal: counts from the sample data set.
- Empty state: an area with no content shows a zero count and the Manage
  button still works, opening an empty management screen with an add
  action.
- Error state: none for local reads.
- Loading state: spinner on first open only.

Navigation: Comes from Settings, Content Management section. Each card
and each row goes to its management screen. Back returns to Settings.

Sample data: Journal entries 3, Drills 3, Videos 2, Figures 6,
Competitions 1, Practice sessions 8. Counts use the same sample data as
the user app. Nothing here is a live server total.

---

## Admin B: Figure Library Management

Purpose: Add, edit and remove figures, and assign each figure its level
and dance.

Layout: Title "Manage Figures". Search field under the title. Dance filter
chips under the search field. Figure rows below, each with Edit and Remove
actions at the right. Add Figure primary button pinned at the bottom.
Tapping Add or Edit opens a form sheet with name field, dance picker,
level picker, description field, steps editor, timing field, NDCA
reference code field.

Components used: search field, filter chips, figure rows with Edit and
Remove, primary button, form sheet.

States:

- Normal: six sample figures.
- Empty state: no figures shows "No figures yet." with an Add Figure
  button.
- Empty state after search: "No figures found." with a "Clear search"
  text button.
- Error state: Remove asks for confirmation: "Remove this figure? It
  will no longer appear in the Figure Library. Practice history for it
  stays." A save failure shows an inline banner in the sheet.
- Loading state: Save shows a spinner while writing.

Navigation: Comes from Admin Dashboard. Back returns to Admin Dashboard.
Saved figures appear in the user app Figure Library Browse.

Sample data: the six figures from `04_sample_data.md`. Edit sample uses
Alemana: name Alemana, dance Rumba, level Bronze, description "Open turn
to the right with a forward walk into the turn.", steps "Forward walk
into the turn, turn under the raised arm, close and settle the weight,
step out to finish", timing "Counts 2 3 4 1 across the figure at rumba
tempo.", NDCA reference code empty, pending the client NDCA list.

---

## Admin C: Competition Management

Purpose: Add and edit competitions, set their dates, and manage their
preparation checklists.

Layout: Title "Manage Competitions". Competition rows below, each showing
name, source tag, start date in words, countdown. Add Competition primary
button pinned at the bottom. Tapping Add or Edit opens the same form as
user Screen 15, Create and Edit Competition, with the same fields.

Components used: competition rows, primary button, competition form.

States:

- Normal: one sample competition.
- Empty state: no competitions shows "No competitions yet." with an Add
  Competition button.
- Error state: Remove asks for confirmation: "Remove this competition?
  Its checklist goes with it. This cannot be undone."
- Loading state: Save shows a spinner while writing.

Navigation: Comes from Admin Dashboard. Back returns to Admin Dashboard.
Saved competitions appear in the user app Competition List and on the
Home Dashboard countdown card.

Sample data: "Sample NDCA event", NDCA, countdown 42 days to go, entry
status Interested, labelled "Sample data". Checklist items as in
`04_sample_data.md`.

---

## Admin D: Drill Library Management

Purpose: Add, edit and remove drills, and see the focus areas in use.

Layout: Title "Manage Drills". Focus area chips at the top, showing the
focus areas in use: Footwork, Timing. Search field under the chips. Drill
rows below, each with Edit and Remove actions. Add Drill primary button
pinned at the bottom. Tapping Add or Edit opens the same form as user
Screen 9, Create and Edit Drill.

Components used: focus area chips, search field, drill rows with Edit and
Remove, primary button, drill form.

States:

- Normal: three sample drills.
- Empty state: no drills shows "No drills yet." with an Add Drill
  button.
- Empty state after search: "No drills found." with a "Clear search"
  text button.
- Error state: Remove asks for confirmation: "Remove this drill? Linked
  journal entries keep their text, the drill link is removed."
- Loading state: Save shows a spinner while writing.

Navigation: Comes from Admin Dashboard. Back returns to Admin Dashboard.
Saved drills appear in the user app Drill List.

Sample data: the three drills from `04_sample_data.md`. These are the
same three drills the dancer sees in the user app Drill List.

---

## Admin E: Content and Categories Management

Purpose: Manage the lists the user app offers: journal categories and
dances, drill focus areas, checklist categories.

Layout: Title "Content and Categories". Three sections, each a grouped
list. Section 1, Journal categories and dances: category rows Challenge,
Accomplishment, Uncategorised, then dance rows cha cha, samba, rumba,
paso doble, jive, each with a show or hide toggle. Section 2, Drill focus
areas: rows Footwork, Timing, Posture, Partner Connection, Routine, each
with Edit and Remove, plus an Add focus area field at the bottom.
Section 3, Checklist categories: rows Registration, Travel, Costume,
Practice, Music, Paperwork, each with Edit and Remove, plus an Add
category field at the bottom.

Components used: grouped list sections, toggle rows, rows with Edit and
Remove, add item fields.

States:

- Normal: all lists populated as above.
- Empty state: not applicable. These lists come from the roadmap and start
  populated. A list that is emptied by removals shows "No items. Add one
  below."
- Error state: removing a category that entries still use shows an alert:
  "This category is in use. Entries using it keep their category until
  you change them." Removal is blocked, not forced.
- Loading state: none.

Navigation: Comes from Admin Dashboard. Back returns to Admin Dashboard.
Changes here appear in the user app pickers and filters.

Sample data: journal categories Challenge, Accomplishment,
Uncategorised. Dances cha cha, samba, rumba, paso doble, jive. Drill
focus areas Footwork, Timing, Posture, Partner Connection, Routine.
Checklist categories Registration, Travel, Costume, Practice, Music,
Paperwork.

---

## Admin F: App Settings Management

Purpose: Manage the defaults for the user app and the app information.

Layout: Title "App Settings". Scrolling form in grouped sections.
Section 1, Defaults for the user app: default dance picker, default
video type selector for Choreography or Drill, reminders toggle,
preferred date format picker, per video size limit field. Section 2,
Video: video quality default 1080p or 720p. Section 3, Version and
build: version label, build label, bundle ID label, all read only.
Section 4, Privacy position: the privacy note text, read only. Save
settings primary button pinned at the bottom.

Components used: grouped form sections, pickers, toggle, number field,
read only labels, primary button.

States:

- Normal: every field starts with the roadmap default.
- Empty state: not applicable.
- Error state: an invalid size limit shows inline helper text in
  `danger`: "Enter a size between 50 MB and 2000 MB."
- Loading state: Save shows a spinner while writing.

Navigation: Comes from Admin Dashboard. Back returns to Admin Dashboard.
Saved settings apply in the user app at once.

Sample data: default dance Rumba, default video type Choreography,
reminders off, preferred date format system default, per video size limit
500 MB, video quality 1080p. Version 1.0.0 Build 1. Bundle ID
com.codeair.danceprogressionjournal. Privacy position: "Your data stays
on this device. No account. No sign in. Journal text, videos and notes
live on this iPhone only."
