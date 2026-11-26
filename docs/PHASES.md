# Dance Progression Journal, phased execution plan

Client: May Nguyen. App: native Swift iOS, Phase 1 local data only, no
accounts, no backend. TestFlight delivery 7 Jan 2027. Source of truth
for scope and dates is the roadmap in the main workspace,
`dance_progression_journal_roadmap_2026_11_26.md`. This file is the
working plan: every phase states its exact scope, its deliverables,
what is done, what is next, and what is blocked on the client.

Definition of done for every phase: the phase work is merged to main,
GitHub Actions CI on the macOS runner is green for that commit, and
the phase milestone in the roadmap is met on a simulator build. No
phase is called done on a local claim alone. CI is the proof.

## Scope change, user order 26 Nov 2026 21:27 IST, hard

The client is an IIT team. Deadline pressure is IIT team level.
TestFlight delivery 7 Jan 2027 stands. This order changes the scope
of the complete build:

1. ALL features promised in the roadmap and in this plan must be
   there. Every feature. No feature dropped, no placeholder.
2. NO hardcoded anything in the shipped app. No hardcoded data, no
   hardcoded content, no fake sample data standing in for real data.
   The app launches empty and the dancer creates real content. The
   five International Latin dances are the fixed real taxonomy, not
   sample data. Figures come only from the real NDCA list (client,
   due 9 Dec 2026) or from admin entry. Nothing is invented. The
   SeedData set in the repo is test fixtures only from this order on:
   it seeds the unit test store, never the shipped app. The
   seedIfNeeded path in the app is removed.
3. Firebase is IN the complete build, not Phase 6 after sign off.
   Firebase for BOTH the user app and the admin app, both fully
   connected. User app: Crashlytics, Analytics, Sign in with Apple,
   Firestore text sync, optional Firebase Storage video backup off
   by default. Admin app: the six Content Management screens from
   docs/design/06_screen_specs_admin.md as a second app target in
   this repo, bundle ID
   com.codeair.danceprogressionjournal.admin, sharing the same
   Firebase project, reading and writing the same Firestore
   collections the user app reads. Local SwiftData stays the source
   of truth offline in the user app. Repository protocols are the
   seam.
4. BLOCKED on the client for the Firebase connection itself, and
   nothing else in the build stops for it: no Firebase project
   exists yet, no GoogleService-Info.plist exists for either app,
   no console access exists. The build wires everything so that
   dropping in the two plist files connects both apps. The app
   configures Firebase only when its plist is present, and runs
   local only without it, so CI stays green with no credentials.
   Exact unblock steps, in order: (a) May Nguyen creates one
   Firebase project named Dance Progression Journal and stays
   project owner; (b) she registers the user iOS app with bundle
   ID com.codeair.danceprogressionjournal and downloads its plist;
   (c) she registers the admin iOS app with bundle ID
   com.codeair.danceprogressionjournal.admin and downloads its
   plist; (d) she grants Codeair editor access to the project;
   (e) Codeair drops both plist files into the repo targets,
   enables Apple under Authentication, creates the Firestore
   database in production mode, creates the default Storage bucket,
   applies the owner only security rules, and verifies Crashlytics,
   Analytics, sign in and phone to iPad sync in a TestFlight
   build. Video backup stays off by default and the Blaze plan is
   enabled only after she approves the cost.
5. No nonsense, no shortcuts, no excuses. Every phase below is
   still delivered with CI green at each step.

## Phase 1, foundation, DONE, Week 1, 26 Nov to 2 Dec 2026

Scope: Xcode project, SwiftData model, tab navigation shell, design
tokens, seed data, journal create and edit flow. Milestone 2 Dec 2026:
working journal flow on a test device.

Deliverables, all on main:

1. Design commit 75062a9: full design system, 26 screen specs, UX
   flows, sample data set, accessibility rules.
2. Engineering commit 22023e1: Xcode project, all 10 SwiftData
   entities, 4 tabs Journal Library Progress Settings, typed routes,
   repository protocols plus SwiftData implementations, VideoFileService,
   local rules categorisation service, seed data, 16 unit tests.
3. QA docs in docs/qa: QA plan and Week 1 verification report. QA
   verdict at the time was FAIL against the then empty repo. A fresh
   QA rerun against the foundation commit is still owed.

Done:

1. All 20 screens exist as SwiftUI views with navigation in place.
2. Journal create, edit, delete, search, filter, sort, detail with
   linked items, local share.
3. Checklist ticking, Mark Practiced, Insights counts from the real
   store, Practice History totals.
4. Settings editing and Delete all data.
5. Seed data: dancer May, 5 International Latin dances, 3 journal
   entries, 3 drills, 2 video metadata rows only with no video bytes,
   6 figures, 8 practice sessions, sample NDCA competition as a
   relative countdown only.

Not done, by design:

1. Video upload, recording and playback. That is Phase 3.
2. Drill create and edit forms. That is Phase 2.
3. Figure Log Practice form. That is Phase 3.
4. Competition create and edit forms and checklist add item. That is
   Phase 3.
5. Firebase Crashlytics and Analytics. Not wired yet. That is Phase 4.
6. Real app icon artwork. Placeholder icon set only. Real icon arrives
   with the client brand choice.

Open items from Phase 1:

1. The app has never compiled. First compile runs on GitHub Actions
   CI, macOS runner with Xcode, because this Linux VM has no Xcode.
   Likely first suspects, from BUILD-NOTES.md: SwiftData relationship
   declarations, `@Bindable` locals in form views, `ShareLink`
   initializer arguments, `#Predicate` captures in `@Query`
   initializers.
2. Two DesignTokens.swift files exist, one at repo root from the
   design team and one in the app target. All 18 colour hex values
   match, but the API shapes differ. Reconcile them in the Week 1
   review: either the root file becomes the target member, or the app
   file replaces it. Do not let them drift.
3. QA fresh rerun on the foundation commit, the gate for calling
   Week 1 done.

Blocked on the client:

1. Apple ID email plus iPhone model and iOS version, due 26 Nov 2026,
   not received.
2. Apple Developer enrolment, due 30 Nov 2026, not started.
3. Brand preference, due 2 Dec 2026, blocks only the final accent
   token and the app icon.

## Phase 2, all 20 screens plus navigation plus seed data working, Week 2, 3 Dec to 9 Dec 2026

Scope: journal intelligence and drills. International Latin journaling
complete, on device AI categorisation of challenges and
accomplishments, drill list with create, edit and complete, search and
filter. Milestone 9 Dec 2026: journal and drill list fully usable.

Deliverables:

1. Drill create and edit forms, wired to the real store, with
   favourite toggle, difficulty, target repetitions and duration.
2. On device categorisation verified against real journal samples,
   category editable on every entry.
3. All 20 screens reachable through the 4 tabs with no dead end,
   every button either works or says plainly that its feature arrives
   in a later phase.
4. Seed data verified on a simulator launch: Welcome and Setup, then
   Home Dashboard with seeded sample data.
5. CI green on every commit in this phase. Unit tests extended for
   drill create and edit and for categorisation rules.

Done: nothing yet. This phase starts after Phase 1 CI is green.

Next: fix the first compile, run the 16 unit tests in CI, then build
the drill forms.

Blocked on the client:

1. NDCA figure list source, due 9 Dec 2026. Official list or PDF or
   link for International Latin figures to load into the library.
2. Sample videos, due 9 Dec 2026. 3 to 5 sample videos with date and
   choreography or drill type for upload testing.
3. Brand preference, due 2 Dec 2026, if not received in Phase 1.

## Phase 3, video plus figures plus competitions, Weeks 3 and 4, 10 Dec to 23 Dec 2026

Scope: video uploads with date and choreography or drill type, local
playback, Instagram links, NDCA figure library data and detail
screens, figure practice tracking, competition countdown, checklist
with create, edit and complete, NDCC and NDCA competition list.
Milestone 16 Dec 2026: video upload and figure library working.
Milestone 23 Dec 2026: competition screens fully working.

Deliverables:

1. Video import from Photos and in app recording, thumbnail
   generation, local playback with AVPlayer, per video size limit in
   Settings.
2. Figure Library browse by dance and by level, Figure Detail with
   steps and timing, Log Figure Practice form with confidence rating,
   Practice History totals.
3. Competition create and edit forms, countdown display, checklist
   add item and ticking, NDCC and NDCA lists entered manually from
   public lists.
4. Video file handling verified: large video over 500 MB saves without
   crash, delete removes the file and frees space, offline playback
   works in Airplane Mode.
5. CI green on every commit in this phase. Unit tests extended for
   video metadata, figure practice totals, competition countdown.

Done: nothing yet.

Next: Phase 2 must be done first. Video bytes live in Application
Support in a Videos folder, one file per asset, UUID plus extension
filename, SwiftData stores the relative path only.

Blocked on the client:

1. NDCA figure list source, due 9 Dec 2026, if not received in
   Phase 2.
2. Sample videos, due 9 Dec 2026, if not received in Phase 2.
3. Instagram handle, due 10 Dec 2026. Exact handle and confirmation
   of link format to use.
4. Competition dates, due 16 Dec 2026. Next 2 competitions with
   dates, locations and checklist items for countdown and checklist
   setup.
5. Figures Alemana and Fan stay labelled pending the client NDCA list
   until the list arrives. No figure data is invented.

## Phase 4, polish plus internal TestFlight build, Week 5, 24 Dec to 30 Dec 2026

Scope: full app polish, local data checks, layout checks on all
screen sizes, Firebase Crashlytics and Analytics wired, internal
TestFlight build, bug fix round 1. Note 25 Dec 2026 is a holiday with
reduced capacity. Milestone 30 Dec 2026: internal TestFlight build
ready for client review.

Deliverables:

1. Layout checks on iPhone SE 3rd generation, iPhone 13, iPhone 14,
   iPhone 15, iPhone 16, in Light Mode and Dark Mode, with large text
   sizes.
2. Firebase Crashlytics and Analytics added through Swift Package
   Manager, anonymous only, no journal text, no video, no name, no
   email leaves the device.
3. Airplane Mode test: create, edit, delete, play video, view
   progression, search and filter all work offline.
4. Data persistence verified across app restart, device restart and
   TestFlight build update.
5. Internal TestFlight build 1, installed on internal devices, smoke
   tested, crash free for 3 days of use.
6. App launches in under 3 seconds on iPhone 13 and newer.

Done: nothing yet.

Next: Phase 3 must be done first. Signing setup happens here: set the
development team for signing in the app target, confirm bundle ID
`com.codeair.danceprogressionjournal` is free in App Store Connect.

Blocked on the client:

1. Apple Developer enrolment, due 30 Nov 2026. Without it no
   TestFlight build can be uploaded.
2. TestFlight invite acceptance and first build install, due 2 Jan
   2027, after the 30 Dec 2026 internal build.
3. Brand preference, due 2 Dec 2026, if not received earlier.

## Phase 5, final fixes and delivery, Week 6, 31 Dec 2026 to 7 Jan 2027

Scope: final bug fix round, TestFlight submission, client
walkthrough, final checks, balance payment on delivery. Note 1 Jan
2027 is a holiday with reduced capacity. TestFlight delivery date
7 Jan 2027.

Deliverables:

1. External tester group named May Nguyen Testers, May added by email,
   build submitted for Beta App Review with review notes stating local
   data only, no accounts, no backend, no login, test account not
   needed.
2. May installs from TestFlight on her own iPhone, first test pass on
   journal and video with feedback by 4 Jan 2027.
3. Every feedback item logged, fixed, and shipped as a new build with
   a higher build number.
4. Written sign off from May, or a list of remaining blockers, by
   7 Jan 2027.
5. Balance $295 on delivery.

Done: nothing yet.

Next: Phase 4 internal build must be ready first.

Blocked on the client:

1. First test pass with feedback, due 4 Jan 2027.
2. Written sign off, due 7 Jan 2027.

## Phase 6, Firebase sync and backup, IN the complete build

Scope per the 26 Nov 2026 21:27 IST order: Firebase is no longer
after sign off. Sign in with Apple, Firestore text backup and sync
across phone and iPad, optional Firebase Storage video backup off by
default, practice reminders, streaks, weekly totals, PDF export,
coach sharing by link, advanced AI insights, full text search.
American Rhythm expansion: swing, bolero, mambo, American style cha
cha and rumba. Plus the admin app target with its six Content
Management screens, fully connected to the same Firebase project.

Deliverables: per roadmap section 9. Local SwiftData stays the source
of truth offline. Repository protocols are the seam, UI and ViewModels
do not change when sync is added.

Blocked on the client: Firebase project ownership by May, editor
access for Codeair, approval of video backup cost before the Blaze
plan is enabled. Video backup stays off by default. Exact unblock
steps are in the scope change section at the top of this file.

## Phase 7, accounts and growth, later

Scope: American Smooth dances, International Standard dances,
accounts and studio mode with multiple dancer profiles and coach
accounts, competition registration integration, social community,
video analysis with AI pose and timing feedback, Apple Watch
companion, in app purchase for premium AI insights and premium figure
packs.

No dates. No work starts without a separate quote and a separate
timeline.

## Client items tracker

1. Apple ID email plus iPhone model and iOS version, due 26 Nov 2026,
   not received.
2. Apple Developer enrolment, due 30 Nov 2026, not started.
3. Brand preference, due 2 Dec 2026, not received.
4. NDCA figure list source, due 9 Dec 2026, not received.
5. Sample videos, 3 to 5, due 9 Dec 2026, not received.
6. Instagram handle, due 10 Dec 2026, not received.
7. Competition dates, next 2, due 16 Dec 2026, not received.
8. TestFlight invite acceptance and first build install, due 2 Jan
   2027.
9. First test pass with feedback, due 4 Jan 2027.
10. Written sign off, due 7 Jan 2027.

## Honesty rules for every phase

1. No fake sample data in the shipped app. The app launches empty.
   SeedData is test fixtures only. The five International Latin
   dances are the fixed real taxonomy.
2. Alemana and Fan figures are labelled pending the client NDCA list.
3. No competition name, date, venue or price is invented.
4. No Apple ID, no prices, no competition dates invented.
5. Astryx is the design language reference only. The native build
   stays SwiftUI.
6. No phase is called done until CI is green for its commits.
7. Firebase is configured only when the real plist file is present.
   No placeholder plist, no hardcoded key, no fake Firebase config.
