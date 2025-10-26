# FamilyMeet — iOS Starter

An MVP iPhone app to help young families meet using Tinder-like swipe mechanics. This repo is structured to be easy to extend as you add auth, backend, and moderation.

## Overview
- Core flows: onboarding → profile → discovery (swipe) → match → chat → meet
- Safety-first: approximate location, block/report, photo moderation, adult-only (18+)
- Tech: SwiftUI app with a modular structure; backend-ready (Firebase suggested) but not required to build/run the MVP

## Quick Start
Prereqs: Xcode 15+ with iOS Simulator installed.

- Open in Xcode: `open FamilyMeet.xcodeproj`
- Select an iOS Simulator (e.g., iPhone 15 Pro) and press Run

CLI (optional):
- `chmod +x scripts/run-ios-sim.sh`
- `./scripts/run-ios-sim.sh`  # builds, installs, and launches on a simulator

If the script can’t find a simulator, open Xcode once and run from there to let Xcode set up devices.

## App Structure
- FamilyMeetApp.swift: SwiftUI entry point
- ContentView.swift: Root view with onboarding + swipe deck
- Assets.xcassets: app icon and accent color placeholders
- scripts/run-ios-sim.sh: helper to build and run on iOS Simulator
- AppState/: JSON testing configs packaged in Debug for seeding app state

Expected directories/files:
- `FamilyMeet.xcodeproj/` — Xcode project and scheme
- `FamilyMeet/` — source, assets, previews
- `scripts/` — developer utilities

## Swipe UI
The MVP uses a simple `SwipeCard` with `DragGesture` that animates cards off-screen when a threshold is reached. A `ZStack` arranges a short deck of profiles so the top card is draggable.

## Data Model (for backend later)
- users/{uid}: profile (names optional), kids age ranges, interests, city/region, geohash, photos, prefs, createdAt
- swipes/{uid}/outgoing/{otherUid}: { direction: "like" | "pass", ts }
- matches/{matchId}: { participants: [uid1, uid2], createdAt, lastMessage }
- matches/{matchId}/messages/{messageId}: { senderId, text, ts }

## Suggested Security Rules (Firestore)
- Users: allow write if `request.auth.uid == uid`
- Swipes: allow read/write if `request.auth.uid == uid`
- Matches: allow read/write if `request.auth.uid in resource.data.participants`
- Messages: allow read/create if `request.auth.uid in get(/databases/$(database)/documents/matches/$(matchId)).data.participants`

## Matching Logic (server-side)
- On right-swipe, write `swipes/{me}/outgoing/{them} = like`
- Cloud Function watches writes; if reciprocal like exists, create `matches/{id}` and send push

## Location (privacy-first)
- Request coarse location; store city/region + geohash (precision 5–6)
- Filter discovery by bounding box around user geohash; show distance ranges

## Onboarding
- Built-in local onboarding flow captures:
  - Adult confirmation (18+), names (optional), city/region, kids age ranges, interests
  - Data is stored locally in `UserDefaults` (no backend yet)
- Edit or reset: tap the gear icon in the top bar and choose “Reset Onboarding”
- Future: add Sign in with Apple, photos, and backend persistence

## Testing App State (JSON)
- Location: `FamilyMeet/AppState/`
  - `state.json` — combined example: partially completed onboarding (city empty) + 10 example families
  - `onboarding_partial.json` — onboarding-only sample
  - `families_10.json` — profiles-only sample
- Behavior: In Debug builds, the app automatically loads `AppState/state.json` on launch if present, setting onboarding values and the discovery profiles.
- Customize: Edit these files and re-run. To disable, remove or rename `state.json`.

## Safety & Compliance
- Adults only (18+); avoid collecting personal data about kids beyond coarse ranges
- Required: block/report, content moderation, account deletion in-app
- App Store keys: Camera, Photo Library, Location usage descriptions (already set in build settings)

## Extending This Project
- Add a `Services/` layer per feature (AuthService, DiscoveryService, MatchService)
- Introduce a `Models/` module for shared types
- Add a `Feature/` folder per screen (Discovery, Matches, Chat, Settings)
- Use environment objects or a simple DI container for services
- Add Firebase when ready (Auth, Firestore, Storage, Functions)
- Filtering
- Three or more way matching, when matched with one couple, unmatch with
- Allow Young couples who are thinking of having children to meet

## Roadmap (MVP → v1)
1) Auth + profile creation (Firebase Auth + Firestore)
2) Swipe feed + writes to Firestore
3) Cloud Function for mutual match + push notifications
4) Matches list + chat view (realtime updates)
5) Block/report + account deletion
6) TestFlight + iterations on onboarding and discovery

## Run Troubleshooting
- If build fails on CLI, open the project in Xcode once and run; Xcode will generate any missing derived data and simulators
- If the CLI script fails to find a device, pass a specific one: `./scripts/run-ios-sim.sh "iPhone 15 Pro"`
- No signing is required for iOS Simulator
- To reset onboarding from terminal: `defaults delete com.familymeet.app fm_hasOnboarded; defaults delete com.familymeet.app fm_profile`


## Marketing
- Young parents feel isolated
- Mums and Dads need to share their experiences
