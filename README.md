# Sportify

A Flutter app for sports partners, local games, community venues and chat. The interface adapts to phones and desktop browsers, with blue and teal accents, soft cards, compact desktop profile actions and Android-safe navigation spacing. System-bar icons explicitly use dark colors for the app's light surfaces.

## Run

Use Flutter 3.32.6 / Dart 3.8.1 or compatible versions.

```sh
flutter pub get
flutter run -d chrome
flutter run -d <android-device-id>
```

The existing Android and web Firebase app configurations are retained. Enable email/password and Google sign-in in the Firebase console, authorize your web domain, and register Android SHA fingerprints as required by [Firebase Google sign-in documentation](https://firebase.google.com/docs/auth/flutter/federated-auth).

## Implemented flows

- Firebase email registration/login, Google sign-in and password reset.
- Authentication gates all main app routes. Only missing/incomplete profiles enter the three-step setup; completed profiles skip it. Failed profile reads offer retry instead of resetting setup.
- Per-account providers and navigation are disposed on account changes, including Firestore streams.
- Responsive overview dashboard, partner search, compatibility ranking based on actual saved interests/area/time slots, and optional shared-time filtering.
- Real-time game lists, functional hosting/joined/past filters, validated game publishing, host editing of upcoming games, live details, accepted-friend-only join requests, host approval before a player joins, transaction-based capacity checks, leave/reopen and host cancellation.
- Connected-player direct chat, participant-only group chat, retained message drafts on failures and atomic message/preview writes. Existing direct and activity conversations are reused.
- Approved venue directory, sport/area filters, venue details and persisted suggestions for review.
- Saved profile edits: name, bio, area, public HTTPS photo URL, sports/skill and weekly availability.
- Incoming connection request acceptance/decline and an in-app schedule. A game can only be joined by an accepted friend of its host; this is enforced in the app, transaction service and Firestore rules.
- Host game-join requests and player approval/decline updates appear in the Notifications screen. This is an in-app notification; push notifications are not configured.
- Friend and game-join requests show the requester's public profile, sports/skills, shared availability and compatibility, with an Explore profile action before accepting or declining.
- Settings provides a direct password change form for email/password accounts: the current password is verified through Firebase reauthentication before updating the new password. Google-only accounts manage their password with Google. Settings no longer offers account deletion, verification emails or reset-password email links; login recovery remains available on the login screen. About Sportify shows app details and developer credit without a license-list button.
- Account deletion is not offered in the app while the project uses Spark. The optional server functions and targeted administrator cleanup scripts remain in `functions/`; automatic cleanup requires deploying the functions on a supported billing plan. The cleanup removes the profile, hosted games and their chat rooms/requests, connections, direct chats, authored messages (including rooms already left), reports, venue suggestions and UID-scoped Storage files, and removes participation in other games/chats.

## Database rules and hosting

`firestore.rules`, `firestore.indexes.json` and `functions/` are provided. **They have not been deployed to the live project.** Review existing production rules and data before deploying: rule deployment replaces the project's rules. New rules protect ownership, accepted-friend game joining, game capacity, connection decisions and chat membership. Admin writes require an `admin: true` custom claim assigned from a trusted backend.

When you are ready to apply the backend configuration:

```sh
flutter pub get
npm install --prefix functions
firebase deploy --project sportify-52862 --only "firestore:rules,firestore:indexes,functions:deleteMyAccount,functions:cleanupDeletedUser"
flutter build web
firebase deploy --project sportify-52862 --only hosting
```

Publishing is optional; no live deployment was performed during this rebuild. Firebase Hosting is configured for Flutter's generated `build/web` directory.

### Repair data from accounts already deleted in Authentication

Do not delete all Firestore data. Use the old user's exact UID (normally the remaining `users` document ID). The Auth deletion trigger cannot replay deletions from before it was deployed.

`functions/cleanup_deleted_user.js` is a targeted admin tool for this project. It refuses UIDs that still have an Auth account. Install the functions dependencies as above and configure Google Application Default Credentials with access to this project's Auth, Firestore and Storage. Firebase CLI login alone does not provide these credentials. Keep credential files outside the repository.

Preview affected records, then apply for that same UID:

```sh
node functions/cleanup_deleted_user.js --uid "EXACT_DELETED_USER_UID"
node functions/cleanup_deleted_user.js --uid "EXACT_DELETED_USER_UID" --apply
```

Deploy the message collection-group index above and wait for it to finish building before cleanup. Shared games and other players' messages are retained; hosted games and direct conversations are removed. A surviving group chat's preview is cleared to avoid retaining deleted message text. New messages repopulate it. Uploaded files are deleted only under `users/UID/` and `profile_photos/UID/`; external photo URLs are not hosted by this app. Rebuild/reinstall Android and republish the web build after updating the client dependency.

## Verification

```sh
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

The Flutter tests cover authentication gates, first-time setup completion and returning-user routing, failed profile lookup/retry, account switching and stream disposal, activity filters, saved profile changes, compatibility scoring and responsive layouts.

Layout selection uses available logical screen width, not the operating system: below 900 pixels the app uses bottom navigation; at 900 pixels and above it uses a scrolling sidebar. Resizing a browser keeps the selected page and its state. Android tablets and landscape screens follow the same rule. Forms use bounded reading widths, collection filters scroll with results, empty states scroll in short viewports, and narrow availability tables scroll horizontally rather than squeezing their cells.

Responsive tests exercise all six destinations with empty and populated data at widths 320, 640, 899, 900 and 1280 and heights down to 240 pixels, with normal and 150% text. Additional checks cover keyboard insets, onboarding, reports, login and chat. This is a tested viewport range, not a guarantee for every possible size or future content.

Database security tests use a **demo project** and a local Firestore emulator. They never write to the real Firebase project:

```sh
npm ci --prefix test/firestore
firebase emulators:exec --only firestore --project demo-sportify "node --test test/firestore/rules.test.mjs"
```

Use Java 21 for the current emulator. On this Windows machine, the working JDK is `C:\Program Files\Java\jdk-21`; the Oracle `javapath` launcher stalled during verification.

`docs/previews/` contains fixture-based desktop and mobile dashboard, partner discovery and player profile previews, not screenshots of live user data. To regenerate on Windows:

```powershell
$env:SPORTIFY_CAPTURE_UI = '1'
$env:SPORTIFY_ICON_FONT = '<flutter-sdk>\bin\cache\artifacts\material_fonts\materialicons-regular.otf'
flutter test --plain-name 'UI preview'
```

## Remaining release work

- Verify real Firebase sign-in, rules/index deployment and two-account interaction on a real browser/device. Local tests use simulated auth and an emulator; they do not prove the live project's permissions or OAuth setup.
- iOS configuration is still a placeholder and there is no iOS runner in this checkout. Configure the real iOS Firebase app and add the platform before claiming iOS support. Android and web builds are verified.
- FCM push/reminders, an admin moderation UI, storage-backed photo uploads, blocking, maps, radius-based geo matching, waitlists, recurring games and communities are not implemented. Account deletion depends on deploying both account functions and the message collection-group index. Individual Auth deletions in Firebase Console run the fallback trigger after deployment; accounts deleted earlier require the targeted repair command above. Bulk Admin SDK deletions do not emit individual Auth deletion events.
- Availability uses the existing broad morning/afternoon/evening slots. Compatibility does not claim exact distances, minute-level overlap or reputation scores.
- The existing public profile schema includes email. Separate private account fields from discoverable profiles and migrate existing data before a public launch; Firestore rules cannot hide individual fields within a readable document.
- Data is not seeded with fabricated players, games or venues. Empty states explain how to create/suggest content; venues appear after an administrator approves them.

See `sportify-design-requirements.md` for the broader product roadmap. This rebuild makes the core app functional; it does not implement every item in that roadmap.
