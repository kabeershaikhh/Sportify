# Project audit and rebuild

Sportify already had Firebase authentication, models, providers and the outline of the main screens. The largest gaps were disconnected actions and inconsistent account/navigation state rather than a missing technology stack. The rebuild keeps Flutter, Provider, Firebase and the existing Android/web registrations.

| Area | Finding | Rebuild |
| --- | --- | --- |
| Authentication and setup | A profile-read error was swallowed and could be treated as an incomplete profile. Setup could be reopened through Settings. | An authenticated session gate distinguishes failure from missing data, retries failed reads, and routes completed profiles to the dashboard. Settings opens a real editor. |
| Account changes | Account-specific providers and subscriptions could survive logout. | The UID keys the provider tree and navigator; switching accounts disposes the old state and streams. |
| Web support | Profile photo selection depended on `dart:io` and never persisted the picked file. Google used the native flow on web. | Public HTTPS photo URLs persist on both platforms, and browser Google login uses Firebase's popup flow. |
| Main UI | Nested app bars, navigation typos, full-width web forms and placeholder screens. | A responsive dashboard/sidebar/mobile navigation shell, bounded forms, consistent blue-and-white components, useful empty/error states and working navigation. |
| Partner discovery | No initial query, limited filtering, no availability ranking. | Initial search, resettable filters, name/bio search, saved-slot overlap filtering and documented compatibility scoring. |
| Games | Filters changed labels without filtering data; joins could overfill; details stayed stale; chat/share actions were empty. | Functional filters, real-time lists/details, validated future games, transactional joins/leaves and capacity state, cancellation, group chat and clipboard sharing. |
| Profile edits | Name/bio input was ignored; availability toggles did nothing; Save sent an empty map. | Real field controllers, detached slot drafts and persisted profile/sport/skill/availability changes. |
| Venues | The list stayed on a permanent loading placeholder and suggestions showed success without a database write. | Approved Firestore directory, filters/details and validated, persisted suggestions. |
| Communication and reports | Direct chat creation did not open the conversation; group chat was disconnected; messages cleared before confirming send; reports were discarded. | Connected-player direct chat, game chat, atomic message writes, retained failed drafts and persisted reports. |
| Account deletion | The Delete button only signed out. | An explicitly labelled deletion request is saved for review; automatic deletion is still release work. |

## Verification

The Flutter regression suite now contains 30 tests, including first-time setup with backward navigation, returning-user startup, profile-read failure/retry, account changes, activity filters and saved edits. Responsive checks exercise all six main destinations with empty and populated data, short phone and desktop windows, 150% text, navigation breakpoint changes, keyboard insets, onboarding, login, chat and report dialogs. Collection headers and empty states scroll; availability uses a horizontal scroll on narrow screens. Ten Firestore emulator tests cover access control, capacity, simultaneous joins, connection decisions, chat membership and write validation. Fixture-based mobile and desktop previews are in `docs/previews/`.

## Scope limits

The broader design document is a roadmap, not a claim that every listed feature is delivered. Remaining work and deployment instructions are in the root README. Real Firebase OAuth/permissions still need live-device verification; rules and indexes were tested only in the local demo emulator and have not been deployed. iOS is not configured in this checkout. Android release signing is still the original debug signing configuration.
