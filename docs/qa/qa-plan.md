# Dance Progression Journal QA Plan

Client: May Nguyen
App: Dance Progression Journal, iOS only, Phase 1
Source of truth: the roadmap file `dance_progression_journal_roadmap_2026_11_26.md`, sections 1 to 16
QA role: independent verification of design and engineering deliveries against the roadmap
Plan version: 1.0, dated 26 Nov 2026
Author: QA Lead

## 1. Purpose

This plan states how QA verifies the Dance Progression Journal build. QA checks what the design team and the engineering team deliver. QA does not rewrite their work. When QA finds a defect, QA lists it precisely with file and line, with severity, and hands it back to the owning team to fix. A fix is verified by QA in a fresh run, never by assumption.

## 2. Authority and boundaries

1. The roadmap is the only source of truth for scope, screens, data model, tech stack, testing and acceptance.
2. The roadmap plus the 6 admin screens is the full authorised scope. Anything outside that list is an invented feature until the client approves it in writing.
3. QA verifies. QA does not edit design files, code, tokens or seed data, except typos in QA own docs.
4. Every verdict is evidence based. A check that QA could not run is recorded as NOT RUN, never as passed.
5. No verdict is given on a claim. Only on proof QA has seen: a file, a log, a test result, a screenshot of a running build, a TestFlight build number.

## 3. Week 1 foundation checklist

Week 1 is 26 Nov to 2 Dec 2026. Milestone 2 Dec 2026: working journal flow on a test device. Week 1 passes only when every item below passes.

### 3.1 Project opens in Xcode 26.1

Pass criteria:

1. An Xcode project exists in the repo at the agreed path, with the app target and test targets.
2. The project opens in Xcode 26.1 with no error and no missing file reference.
3. Deployment target is iOS 17.0, iPhone only, Swift 6.2, Swift 6 language mode, strict concurrency on.
4. Bundle ID is `com.codeair.danceprogressionjournal`.
5. The project builds with zero errors and zero warnings for a release build, since warnings are treated as errors for release builds.
6. No third party dependency is present in Phase 1 except the Firebase SDK for Crashlytics and Analytics, added through Swift Package Manager.

### 3.2 ModelContainer launches

Pass criteria:

1. One ModelContainer is created at launch, with a versioned schema from day one.
2. The app launches to the first screen with an empty store and shows the empty state, with no crash.
3. The app launches with a populated store and shows stored data, with no crash.
4. Force quit during a save does not corrupt the store on next launch.

### 3.3 All 10 SwiftData entities present with correct fields and relationships

Pass criteria:

1. All 10 entities from roadmap section 7 exist as SwiftData models: Dance, JournalEntry, Drill, Video, Competition, ChecklistItem, Figure, FigurePracticeLog, LocalProfile, AppSettings.
2. Every field listed in roadmap section 7 exists on the matching model, with the correct type.
3. Every relationship listed in roadmap section 7 item 11 exists, with the correct direction and cardinality.
4. Enum values match the roadmap exactly: JournalEntry category is challenge, accomplishment or uncategorised; Video type is choreography or drill; Competition source is NDCC or NDCA; Competition entry status is interested, entered, confirmed, completed or cancelled; ChecklistItem category is registration, travel, costume, practice, music or paperwork; Figure level is Bronze, Silver, Gold or Gold Star; FigurePracticeLog confidence rating is 1 to 5.
5. Dance style is International Latin in Phase 1. Dance names are cha cha, samba, rumba, paso doble, jive.
6. Video bytes live in the app sandbox under Application Support in a Videos folder, one file per asset, file name is a UUID plus extension. SwiftData stores the relative path only, never the bytes and never an absolute path.

### 3.4 Tab shell navigates

Pass criteria:

1. The four tabs exist: Journal, Library, Progress, Settings.
2. Home Dashboard is the first screen inside the Journal tab.
3. Every tab opens its first screen with no blank screen and no crash.
4. Back navigation returns to the previous screen without loss of data where the roadmap defines it.
5. Typed routes per tab are used. No string based routes exist anywhere in navigation code.
6. Portrait is used for lists and entry work. Landscape is allowed for video playback only.

### 3.5 Design tokens exist and match the design system

Pass criteria:

1. A design token source exists in the repo, in code or in a token file, covering colours, type sizes, spacing, corner radii and any other token the design system defines.
2. Every token referenced in code exists in the token source. No missing token, no hardcoded colour or size that duplicates a token.
3. Token values match the design system document exactly. Any mismatch is a defect with the token name and both values listed.
4. The design system document itself exists under `docs/design/` and states the source for every token value.

### 3.6 Seed data is consistent sample data

Pass criteria:

1. Seed data exists and loads on first launch or on demand, as the design defines it.
2. The dancer in sample data is May, and only May.
3. Dances in sample data are International Latin only: cha cha, samba, rumba, paso doble, jive.
4. Alemana and Fan are labelled pending client NDCA list. They are never presented as confirmed NDCA figures.
5. Any sample competition is a relative countdown only, with no real competition name, date, venue or price.
6. No lorem ipsum appears anywhere in seed data or in any visible string.
7. No real person, real competition, real venue, real date or real price is invented anywhere.

## 4. Entity traceability matrix

QA checks each roadmap entity against the matching model file. Status is Present, Partial or Missing.

1. Dance. Fields: id, name, style, display order, is active. Relationships: has many JournalEntry, Drill, Video, Figure. Model file: to be filled at verification.
2. JournalEntry. Fields: id, title, body text, entry date, created date, updated date, dance id, category, AI confidence, AI tags, Instagram link, linked video ids, linked drill ids, linked figure ids, is favourite. Relationships: belongs to one Dance; links to many Video, Drill, Figure. Model file: to be filled at verification.
3. Drill. Fields: id, name, dance id, focus area, description, target repetitions, target duration in minutes, difficulty level, is favourite, last practiced date, created date, updated date. Relationships: belongs to one Dance; links to many Video and JournalEntry. Model file: to be filled at verification.
4. Video. Fields: id, title, file name, local file path, thumbnail path, duration in seconds, recorded date, created date, dance id, video type, choreography name, drill id, notes, Instagram link, linked journal entry id, linked figure id. Relationships: belongs to one Dance; links to one JournalEntry, one Drill, one Figure, all optional. Model file: to be filled at verification.
5. Competition. Fields: id, name, source, location, venue, start date, end date, registration deadline, entry status, notes, website link, created date, updated date. Relationships: has many ChecklistItem. Model file: to be filled at verification.
6. ChecklistItem. Fields: id, competition id, title, due date, category, is done, done date, created date, sort order. Relationships: belongs to one Competition. Model file: to be filled at verification.
7. Figure. Fields: id, name, dance id, level, category, description, steps text, timing, beat count, is favourite, NDCA reference code, created date. Relationships: belongs to one Dance; has many FigurePracticeLog. Model file: to be filled at verification.
8. FigurePracticeLog. Fields: id, figure id, dance id, practice date, repetitions, duration in minutes, confidence rating, notes, linked video id, created date. Relationships: belongs to one Figure and one Dance; links to one Video. Model file: to be filled at verification.
9. LocalProfile. Fields: id, dancer name, experience level, preferred dance ids, home studio, coach name, created date, updated date. Relationships: has many preferred Dance records; has one AppSettings record. Model file: to be filled at verification.
10. AppSettings. Fields: id, default dance id, default video type, reminders enabled, preferred date format, storage limit warning, last backup date. Relationships: belongs to one LocalProfile. Model file: to be filled at verification.

## 5. Screen traceability matrix

QA checks each of the 20 roadmap screens against its design spec under `docs/design/` and its implemented view. Status is Spec Present, Spec Missing, Implemented, or Not Implemented.

1. Welcome and Setup. Design spec: to be filled at verification. View: to be filled at verification.
2. Home Dashboard. Design spec: to be filled at verification. View: to be filled at verification.
3. Journal List. Design spec: to be filled at verification. View: to be filled at verification.
4. Journal Entry Detail. Design spec: to be filled at verification. View: to be filled at verification.
5. Create and Edit Journal Entry. Design spec: to be filled at verification. View: to be filled at verification.
6. Journal Insights by Category. Design spec: to be filled at verification. View: to be filled at verification.
7. Drill List. Design spec: to be filled at verification. View: to be filled at verification.
8. Drill Detail. Design spec: to be filled at verification. View: to be filled at verification.
9. Create and Edit Drill. Design spec: to be filled at verification. View: to be filled at verification.
10. Video Library. Design spec: to be filled at verification. View: to be filled at verification.
11. Video Detail and Player. Design spec: to be filled at verification. View: to be filled at verification.
12. Add Video and Upload Video. Design spec: to be filled at verification. View: to be filled at verification.
13. Competition List. Design spec: to be filled at verification. View: to be filled at verification.
14. Competition Detail with Countdown and Checklist. Design spec: to be filled at verification. View: to be filled at verification.
15. Create and Edit Competition. Design spec: to be filled at verification. View: to be filled at verification.
16. Figure Library Browse. Design spec: to be filled at verification. View: to be filled at verification.
17. Figure Detail. Design spec: to be filled at verification. View: to be filled at verification.
18. Log Figure Practice. Design spec: to be filled at verification. View: to be filled at verification.
19. Practice History. Design spec: to be filled at verification. View: to be filled at verification.
20. Settings and Local Profile. Design spec: to be filled at verification. View: to be filled at verification.

The 6 admin screens are authorised scope in addition to the 20 screens above. QA checks each admin screen against the admin spec the design team cites. If no admin spec is on file, each admin screen is recorded as Spec Missing.

## 6. Full Phase 1 test plan, from roadmap section 10

### 6.1 Unit tests

1. Journal entry create with valid title, date, notes and rating saves correctly.
2. Entry edit updates only changed fields and keeps the video link intact.
3. Entry delete removes the entry and the linked video reference from the local store.
4. Empty title is rejected or handled as defined in design.
5. Very long notes save and load without truncation.
6. Date sorting newest first and oldest first works.
7. Filter by dance style returns only matching entries.
8. Search by text matches title and notes and ignores case.
9. Progression calculation counts entries per style and per week correctly.
10. Rating average updates when entries are added, edited or deleted.
11. Video metadata duration, file size and creation date are stored correctly.
12. Local persistence encode and decode round trip preserves all fields.
13. App launch with an empty store shows the empty state and no crash.
14. App launch with a corrupt local file falls back safely and does not crash.
15. AI categorisation assigns challenge or accomplishment per the local rules, and the user can edit the category on every entry.

### 6.2 UI tests

1. App launches to the journal list and shows no blank screen.
2. Create entry flow completes with keyboard, date picker and save button.
3. Edit entry flow opens a prefilled form and saves changes.
4. Delete entry shows confirmation and removes the row after confirm.
5. Cancel delete keeps the entry in the list.
6. Video picker opens Photos and returns the selected video.
7. Video playback controls play, pause, seek and mute respond to tap.
8. Filter control updates the list immediately after selection.
9. Search field filters the list as text is typed.
10. Progression view loads a chart or summary and updates after a new entry.
11. Rotation from portrait to landscape keeps content visible and usable.
12. Dark Mode and Light Mode render text with readable contrast.
13. Large text accessibility size keeps buttons reachable and labels readable.
14. Back navigation returns to the previous screen without loss of data where defined.

### 6.3 Manual test cases for every Phase 1 feature

1. Create, edit, delete and view journal entries.
2. Add a new dance style and select it in a new entry, within International Latin only.
3. Add notes with long text, special characters and line breaks.
4. Set rating from lowest to highest and verify it saves.
5. Attach video from Photos to an entry.
6. Record video in app and attach it to an entry.
7. Play attached video with sound and without sound.
8. Remove video from an entry and verify the entry remains.
9. View progression summary by dance style and by week.
10. View progression after adding entries on different dates.
11. Search journal by title word and by notes word.
12. Filter journal by dance style and clear the filter to show all entries.
13. Sort journal by newest date and by oldest date.
14. Close the app and reopen to verify all entries and videos remain.
15. Restart the device and reopen the app to verify all entries and videos remain.
16. Check the empty state when no entries exist and after deleting all entries.
17. Check app behaviour with a very long journal list and fast scrolling.
18. Complete each of the five user flows in roadmap section 8 from start to finish: write a journal entry, add a drill, upload a video, check the competition countdown, track a figure.

### 6.4 Device and iOS coverage

1. iPhone SE 3rd generation on iOS 17.
2. iPhone 13 on iOS 18.
3. iPhone 14 on iOS 18.
4. iPhone 15 on iOS 26.
5. iPhone 16 on iOS 26.
6. iPhone 17 on iOS 26 if available.
7. Small screen check for text truncation and button reach.
8. Large screen check for layout stretch and safe area.
9. Check on a device with low storage and on a device with ample storage.
10. iPad is out of scope in Phase 1 and is not tested as a target.

### 6.5 Video upload and playback checks

1. Record video in app and attach it without error.
2. Pick MOV, MP4 and HEVC video from Photos and attach each.
3. Large video over 500 MB saves to the local store without crash or freeze.
4. Short video under 5 seconds plays fully.
5. Long video over 5 minutes seeks correctly to start, middle and end.
6. Thumbnail appears for each video entry.
7. Play, pause, seek forward, seek back, mute and unmute work.
8. Full screen playback and exit full screen work.
9. Video keeps playing correctly after rotation.
10. Video with no sound plays without error.
11. Delete video removes the file from local storage and frees space.
12. Low storage warning appears when device storage is low.
13. Video recorded in low light remains viewable with audio in sync.
14. Default video quality is 1080p with a 720p option. Per video size limit is set in Settings.

### 6.6 Offline checks

1. Airplane Mode on: create, edit, delete, play video and view progression all work.
2. WiFi off and cellular off: the same checks pass.
3. No error message about network appears for local actions.
4. App launch offline shows the journal list from the local store.
5. Video playback offline works for locally stored videos.
6. Search and filter offline work with the same results as online.
7. The app remains usable after a long offline period with no data loss.
8. Airplane Mode test runs before each TestFlight build.

### 6.7 Data checks

1. Phase 1 is a rebuild from zero, so no data migration from a prior version exists.
2. Fresh install on a clean device creates an empty local store correctly.
3. Install again after delete starts clean with no leftover entries.
4. Update from TestFlight build 1 to build 2 keeps all entries, videos and settings.
5. Update from build 2 to build 3 keeps data intact after a video feature change.
6. Force quit during save does not corrupt the local store on next launch.
7. Update with the app in background keeps data intact on next open.

### 6.8 Acceptance criteria for Phase 1 sign off

1. All unit tests pass in Xcode with zero failures.
2. All UI tests pass on iPhone 15 on iOS 26 and iPhone 13 on iOS 18.
3. All manual test cases pass with no critical or major bug open.
4. Video upload and playback checks pass on all covered devices.
5. Offline checks pass with full function in Airplane Mode.
6. Data persists across app restart, device restart and TestFlight build update.
7. No crash in TestFlight crash reports for 3 days of client use.
8. App launches in under 3 seconds on iPhone 13 and newer.
9. No login screen, no account prompt, no network error on launch.
10. May Nguyen confirms in writing that journal, video, progression, search and filter meet her expectation.
11. Final build is installed from TestFlight and verified by May Nguyen on her own iPhone.

## 7. Honesty rules checks

QA runs these checks on every verification run, over every visible string, every seed record and every design spec.

1. Sample dancer is May, and only May. Any other dancer name in sample data is a defect.
2. Dances are International Latin only. American Rhythm, Smooth or Standard in Phase 1 content is a defect, unless it is clearly labelled as a later phase note with no data behind it.
3. Alemana and Fan are labelled pending client NDCA list wherever they appear. Any presentation of them as confirmed NDCA figures is a defect.
4. A sample competition is a relative countdown only. Any real competition name, date, venue or price in sample data, specs or screens is a defect.
5. No real competition name, date, venue or price is invented anywhere, in any file.
6. No lorem ipsum appears anywhere.
7. No invented feature appears beyond the roadmap plus the 6 admin screens.
8. No placeholder text that pretends to be real content appears in any user visible string.
9. All prices, dates and counts in docs match the roadmap: 500 dollars plus 18 percent GST, total 590 dollars, invoice INV-2026-1122-01, paid 295 dollars, balance 295 dollars, delivery 7 Jan 2027.

## 8. Forbidden content checks

QA greps the repo on every run for the following. Any hit in a user visible string or in sample data is a defect. Hits in QA own docs that quote the forbidden term as an example are noted as quoted, not as defects.

1. Lorem ipsum, in any casing.
2. Hyphens or em dashes in visible text, except literal identifiers such as INV-2026-1122-01, bundle IDs, file names and version strings. Visible text means any string the user can see in the app, plus headings and body text in design docs and user facing docs. Code identifiers and file paths are not visible text.
3. Devanagari script anywhere in user visible text or docs.
4. Real competition names, venues or dates presented as sample data.
5. TODO, FIXME or XXX markers left in shipped code or in design specs at sign off.
6. Hardcoded secrets, API keys or tokens in any file.

## 9. Design token verification method

1. QA reads the design system document under `docs/design/` and records every token name and value.
2. QA greps all Swift and asset files for token references and for hardcoded colour, font size and spacing literals.
3. Every token referenced in code must exist in the token source. Every hardcoded literal that duplicates a token is a defect.
4. Every token value in code must equal the design system value. QA lists token name, design value and code value for any mismatch.
5. If no design system document exists, section 3.5 fails as a blocker and token checks are recorded as NOT RUN.

## 10. Defect severity definitions

1. Blocker: the milestone cannot be called done. Examples: project does not open or build, ModelContainer does not launch, an entity or a required field is missing, a tab does not navigate, no design system exists, seed data contradicts the honesty rules, a real competition detail is invented, a crash on launch.
2. Major: a feature does not work as the roadmap defines it, but the app still launches. Examples: a filter returns wrong results, a video does not play, a relationship is wrong, a token value mismatches the design system, a manual test case fails.
3. Minor: a cosmetic or documentation gap that does not change behaviour. Examples: a label is unclear, a doc typo, a missing README note, an unused asset.

## 11. Verdict rules

1. PASS: every Week 1 checklist item passes, or every Phase 1 acceptance criterion passes for a full Phase 1 run, with zero blockers and zero majors open. Notes may list minors.
2. PASS with notes: as PASS, with minors listed for the owning team to fix in the next round.
3. FAIL: any blocker open, or any major open, or any checklist item NOT RUN where the owning team claimed it done. The verdict carries a numbered defect list with severity, file and line for each defect.
4. A retest after fixes is a fresh run. The old report is kept, and the new report records what changed.

## 12. Limits: what QA cannot run on this Linux VM

QA is honest about what the Linux VM cannot do. These limits apply to every verification run until a Mac with Xcode is available.

1. No Xcode exists on this VM, so the project cannot be opened, built or run here.
2. No iOS simulator exists on this VM, so no UI flow can be executed here.
3. No iPhone test device is attached to this VM, so no device check can run here.
4. No TestFlight build can be installed or checked from this VM.
5. No Firebase console access is used from this VM for Crashlytics or Analytics checks.
6. App launch time, crash reports, video playback, rotation, Dark Mode rendering and accessibility sizes cannot be measured from this VM.

What QA can run on this VM, and does run on every verification:

1. File presence and repo structure, by listing the repo tree.
2. Swift syntax sanity by reading code, plus brace and import balance checks by script.
3. Model count and field count against roadmap section 7.
4. Screen to spec traceability, by matching every roadmap screen to a design spec file.
5. Token reference checks, by grepping code for token names and hardcoded literals.
6. Forbidden content greps, per section 8.
7. Honesty rule checks, per section 7.
8. Git history checks: what landed, when, and on which branch.

## 13. Evidence and reporting

1. Each verification run produces a dated report under `docs/qa/`, named `weekN-report-YYYY-MM-DD.md`, with the commands run, their outputs, a check table, a defect list and a verdict.
2. Reports record what was verified, what could not be verified, and what must happen before the milestone can be called done.
3. QA commits QA docs under `docs/qa/` and pushes to main. QA never touches other teams files.
