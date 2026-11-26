# Dance Progression Journal, Firebase setup runbook

One Firebase project serves both iOS apps. The app code already
configures Firebase only when a real `GoogleService-Info.plist` is
in the bundle (`Services/FirebaseService.swift`, `configureIfPresent`).
No plist means the apps run fully offline; no placeholder plist, no
hardcoded key, no fake config anywhere in this repo.

## Status

- Firebase CLI installed on this machine:
  `~/workspace/tools/firebase-tools/node_modules/.bin/firebase`
  (version 15.37.0). Login is still owed: the CLI needs an interactive
  Google sign in (`firebase login`), which cannot run from this VM.
- Rules in this folder are ready to deploy once the project exists.

## 1. Create the project (Firebase console, signed-in browser)

1. Open https://console.firebase.google.com, signed in as
   sunmughan@gmail.com.
2. Add project, name it exactly `Dance Progression Journal`.
3. Enable Google Analytics when asked (the app uses Analytics and
   Crashlytics). Wait for creation to finish.
4. Note the project ID shown in Project settings.

## 2. Register both iOS apps (same project)

In Project settings, Your apps, add an iOS app twice:

| App | Bundle ID | Plist goes to |
| --- | --- | --- |
| User app | com.codeair.danceprogressionjournal | `DanceProgressionJournal/GoogleService-Info.plist` |
| Admin app | com.codeair.danceprogressionjournal.admin | `DanceProgressionJournalAdmin/GoogleService-Info.plist` |

Each plist is a different file (different app ID and bundle ID).
After each file lands, add it to that target in Xcode so it ships
in the bundle (a file dropped in the folder alone is not bundled).
`.gitignore` does not exclude the plist, so both files commit to
main like any other target file.

## 3. Authentication, Sign in with Apple

Build, Authentication, Sign-in method, Apple, Enable, Save.
The apps already carry the Sign in with Apple capability in both
targets (`DanceProgressionJournal.entitlements`,
`DanceProgressionJournalAdmin.entitlements`).

## 4. Firestore, production mode, owner only rules

1. Build, Firestore Database, Create database.
2. Start in production mode. Location: `asia-south1` (Mumbai,
   closest to the users; a location cannot be changed later).
3. Deploy the rules in this folder. From this folder, after
   `firebase login`:
   `firebase deploy --only firestore:rules --project <project-id>`
   Or paste `firestore.rules` into the console Rules tab and
   Publish. The rules allow read and write only under
   `users/{uid}/...` for the signed-in owner of that uid.

## 5. Storage, default bucket, owner only rules

1. Build, Storage, Get started, production mode, default bucket.
2. Deploy the rules in this folder. From this folder, after
   `firebase login`:
   `firebase deploy --only storage --project <project-id>`
   Or paste `storage.rules` into the console Rules tab and Publish.
   The rules allow read and write only under
   `users/{uid}/videos/...` for the signed-in owner of that uid.
   Video backup stays off by default in the app; Blaze plan only
   if May approves the cost.

## 6. Verify

1. Run both apps. `FirebaseService.isConfigured` must be true.
2. Sign in with Apple, then sync once: records must appear under
   `users/{uid}/` in Firestore, never anywhere else.
3. Run the CI workflow on main; the build and test job must stay
   green with the plist files present.

## What May still owes (non Firebase)

Apple ID email plus iPhone model and iOS version, Apple Developer
enrolment due 30 Nov 2026, brand preference due 2 Dec, NDCA figure
list plus sample videos due 9 Dec, Instagram handle due 10 Dec,
next 2 competition dates due 16 Dec, TestFlight install by
2 Jan 2027, first feedback by 4 Jan, written sign off and balance
$295 by 7 Jan 2027.
