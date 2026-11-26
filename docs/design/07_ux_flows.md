# 07 UX Flows

The five most important tasks from roadmap section 8, written as step by
step flows with edge cases. Screen numbers refer to the specs in
`05_screen_specs_user.md`.

---

## Flow 1: Write a journal entry

Goal: May finishes practice, writes what happened, and sees the entry
counted in Insights.

Steps:

1. Open Home Dashboard and tap New Entry.
2. Enter a title, for example "Rumba walk timing".
3. Write body text about the session.
4. Confirm the entry date. Default is today.
5. Select dance: Rumba.
6. Add an Instagram link if the session was posted online.
7. Link a drill, a video, or a figure if relevant. In the sample flow,
   link drill Rumba Walks, video Rumba routine run through, figure
   Alemana.
8. Read the category preview under the body text. On device AI suggests
   Challenge. Change it to Accomplishment if it is wrong.
9. Tap Save.
10. Journal Entry Detail opens. Confirm category, AI tags, linked items.
11. Go to the Progress tab and open Journal Insights to see the updated
    count.

Edge cases:

- Empty title: Save stays disabled. Helper text reads "Enter a title to
  save." No alert, no lost text.
- AI category wrong: the category control is editable on the form and on
  the detail screen. Changing it never changes the body text.
- No Instagram link: the field is optional. The detail screen hides the
  Instagram button when no link is set.
- No drill, video or figure to link: all three link rows are optional.
  The detail screen shows "None linked".
- Save fails, for example storage full: an inline banner reads "This
  entry could not be saved. Check storage and try again." The form keeps
  every field so nothing is retyped.
- Cancel mid form: returns with no changes saved. No confirmation, since
  nothing was saved yet. If text was entered, Cancel still discards it.
  This matches standard iOS form behaviour and is called out here so the
  team does not add a confirmation dialog.
- Very long body text: the editor grows, the form scrolls, the Save
  button stays reachable above the keyboard.

---

## Flow 2: Add a drill

Goal: May saves a drill she wants to practise again, then logs its first
use.

Steps:

1. Open Drill List and tap Add Drill.
2. Enter drill name, for example "Rumba Walks".
3. Select dance: Rumba.
4. Select focus area: Footwork.
5. Enter description: "Slow forward and back walks with full weight
   transfer on every count."
6. Enter target repetitions 20 and target duration 15 minutes.
7. Select difficulty: Intermediate.
8. Turn on the favourite toggle if this is a core drill.
9. Tap Save.
10. Drill Detail opens. Confirm all fields.
11. After the first use, tap Mark Practiced.

Edge cases:

- Name or dance missing: Save stays disabled. Helper text reads "Enter a
  name and pick a dance to save."
- Repetitions or duration left blank: both are optional at creation. The
  detail screen shows "Not set" for a blank target. Mark Practiced still
  works and logs the session with the values entered at that moment.
- Favourite off: the drill appears under its dance group, not in
  Favourites. Toggling favourite later in the detail screen moves it at
  once.
- Duplicate name: allowed. Two drills can share a name if they differ by
  dance or focus area. The list shows dance and focus area on every row
  so they stay distinguishable.
- Delete by mistake: Delete asks for confirmation first. Linked journal
  entries keep their text and lose only the drill link.
- Start Timer tapped before any practice: the timer starts at zero and
  counts up. It is a simple timer on the detail screen, not a separate
  screen.

---

## Flow 3: Upload a video

Goal: May uploads a practice video, tags it, and checks playback.

Steps:

1. Open Video Library and tap Add Video.
2. Choose Choose from Library or Record Video.
3. Select a video, or record a new video, and confirm the thumbnail.
4. Enter a title, for example "Rumba routine run through".
5. Confirm the recorded date. Default is today.
6. Select dance: Rumba. Select video type: Choreography.
7. Enter choreography name: Rumba routine. If type is Drill, pick the
   drill instead.
8. Add notes and an Instagram link if relevant.
9. Tap Save.
10. Video Detail opens. Confirm playback, date, dance, type.

Edge cases:

- No video picked: the form below the choice buttons stays disabled. The
  title field cannot be used before a video exists.
- Video over the size limit: an inline banner reads "This video is over
  the size limit. Pick a shorter video." The limit is set in Settings and
  defaults to 500 MB per video.
- Video with no sound: plays without error. The mute control stays
  available and does nothing harmful.
- Long video over 5 minutes: scrub bar seeks to start, middle and end.
  Thumbnail is generated from the first frame.
- Import fails: an inline banner reads "This video could not be
  imported. Try a shorter video or check storage." The choice buttons
  stay available to try again.
- Thumbnail still generating: the preview tile shows a spinner. Save
  stays disabled until the thumbnail is ready.
- Delete by mistake: Delete asks for confirmation first. Deleting a video
  removes the file from local storage and frees the space. Linked journal
  entries keep their text and lose only the video link.
- Offline: the whole flow works in Airplane Mode. No network message
  ever appears.

---

## Flow 4: Check the competition countdown

Goal: May checks how long until the next competition and reviews her
preparation.

Steps:

1. Open Home Dashboard and read the next competition countdown card:
   "Sample NDCA event, 42 days to go".
2. Tap the card to open Competition Detail.
3. Read days remaining, start date, end date, venue, registration
   deadline.
4. Review entry status and update it if it has changed, for example from
   Interested to Entered.
5. Review the checklist. Tick done items. Add any missing item with a due
   date.
6. Open Competition List to compare other NDCC and NDCA events by date.

Edge cases:

- No competitions saved: Home Dashboard shows no countdown card. In its
  place is a quiet empty card: "No competition yet. Add one to track its
  countdown." with an Add Competition button. Competition List shows its
  own empty state.
- Countdown reaches zero: the card reads "Starts today" and the detail
  screen shows the event as in progress until the end date passes. After
  the end date, the event moves to Past and the countdown reads
  "Completed".
- Registration deadline passes with status still Interested: the
  deadline label turns `warning` and reads "Registration deadline passed".
  The status is not changed automatically. May changes it.
- Checklist item with no due date: allowed. The row shows no due label.
- Competition deleted: the countdown card disappears from Home. If it
  was the only competition, the Home empty card appears.
- Sample data: the sample event is labelled "Sample data" on the card,
  the row, and the detail screen. Real values arrive with the client
  competition dates, due 16 Dec 2026. No real name, date, venue or price
  is invented in the meantime.

---

## Flow 5: Track a figure

Goal: May practises a figure, logs the session, and checks her totals.

Steps:

1. Open Figure Library Browse and select the dance tab: Rumba.
2. Search or filter by level to find the figure: Alemana.
3. Open Figure Detail to read steps, timing, practice summary.
4. Tap Log Practice.
5. Enter practice date, default today. Enter repetitions 8 and duration
   12 minutes. Pick confidence 4 of 5.
6. Add notes, for example "Turn felt steadier on the last set.", and link
   a video if one was recorded.
7. Tap Save.
8. Figure Detail opens with the updated practice summary.
9. Open Practice History to confirm the new session and the updated
   totals for that figure.

Edge cases:

- Figure has no practice yet: the detail screen shows practice count
  zero and "No practice yet. Log your first practice." Log Practice
  still works the same way.
- Repetitions or duration missing: Save stays disabled. Helper text reads
  "Enter repetitions and duration to save."
- Confidence not picked: allowed. The session saves with no confidence
  value, and the average confidence ignores it. The summary shows
  "Average confidence 4 of 5" only from sessions that have a value.
- No video to link: the link video control is optional. The session
  saves without it.
- Practice logged for the wrong figure: there is no edit for a practice
  session in Phase 1. The session is deleted from Practice History by
  swiping the row, then logged again on the right figure. This is a
  deliberate Phase 1 limit, listed in
  `08_decisions_and_open_questions.md`.
- Figure list is pending: until the client NDCA list arrives, every
  figure row carries "Pending the client NDCA list". The library still
  works end to end with the sample figures.
- Totals update: Practice History totals and the Figure Detail summary
  update at once after save. Both read the same store, so they cannot
  disagree.
