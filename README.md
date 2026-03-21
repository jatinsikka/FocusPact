# FocusPact

> Accountability-based focus app for iOS — block distracting sites and make pacts with friends to stay on task.

FocusPact lets you start a timed focus session, block a custom list of distracting domains at the network level (via iOS Network Extension), and optionally create a **pact** with a friend — a mutual commitment to stay focused for the same duration. An AI coach powered by Claude analyzes your session history and recommends optimal session lengths and blocklists.

---

## Features

- **Network-level blocking** — uses `NEFilterProvider` (iOS Content Filter) to block domains system-wide during a session; no VPN profile needed
- **Custom blocklists** — create and manage multiple named blocklists (e.g. "Social Media", "News", "Gaming")
- **Pacts** — challenge a friend to a simultaneous focus session; both must complete for the pact to be honored
- **AI Coach** — Claude analyzes your past sessions and recommends the best duration and blocklist for your next session
- **Dashboard** — streak tracker, today's focused time, recent sessions
- **Analytics** — session history, completion rate, time blocked per category
- **Onboarding** — guided setup for permissions (Network Extension, Notifications)
- **Dark mode** — dark-first UI

---

## Architecture

```
FocusPact/
├── App/
│   ├── FocusPactApp.swift        # App entry, SwiftData container setup
│   └── ContentView.swift         # Root navigation
├── Core/
│   ├── Models/
│   │   ├── Pact.swift            # Codable pact (pending/active/completed/broken)
│   │   ├── LocalPact.swift       # SwiftData local pact record
│   │   ├── Session.swift         # SwiftData session record
│   │   ├── BlockList.swift       # SwiftData blocklist (name + domains)
│   │   └── User.swift            # User profile
│   ├── Services/
│   │   ├── BlockingService.swift # NEFilterManager — start/stop blocking
│   │   ├── AICoachService.swift  # Claude API integration (session recommendations)
│   │   ├── SupabaseService.swift # Auth + pact sync via Supabase
│   │   └── NotificationService.swift
│   └── Extensions/
│       └── Color+Theme.swift
├── Features/
│   ├── Onboarding/               # Permission setup flow
│   ├── Dashboard/                # Streak, today stats, quick start
│   ├── Session/                  # Session setup, active timer, post-session summary
│   ├── Pacts/                    # Pact list, detail, invite flow
│   ├── Blocklists/               # Blocklist CRUD
│   ├── Analytics/                # Session history + charts
│   └── AICoach/                  # Coach chat + recommendation display
└── NetworkExtension/
    ├── FilterDataProvider.swift  # NEFilterDataProvider — blocks matched domains
    └── FilterControlProvider.swift
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Local persistence | SwiftData |
| Network blocking | NetworkExtension (`NEFilterProvider`) |
| Backend / Auth | Supabase |
| AI | Anthropic Claude API |
| Notifications | UserNotifications |

---

## Setup

### Prerequisites

- Xcode 15+
- iOS 17+ device or simulator
- Apple Developer account (Network Extension entitlement requires a paid account)
- Supabase project
- Anthropic API key

### Configuration

1. Open `FocusPact.xcodeproj` in Xcode.
2. Set your Team in **Signing & Capabilities** for both the main target and the Network Extension target.
3. Update the App Group ID (`group.com.yourname.focuspact`) in:
   - `BlockingService.swift`
   - `FilterDataProvider.swift`
   - Both target entitlements
4. Add a `Config.xcconfig` (or set in `Info.plist`) with:
   ```
   CLAUDE_API_KEY = sk-ant-...
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = ...
   ```
5. Build and run on a physical device (Network Extension does not work in simulator).

---

## Notes

- The Network Extension target must be signed with the same Team as the main app and share the App Group.
- `NEFilterManager` requires the `com.apple.developer.network-extension.content-filter` entitlement, which needs explicit approval from Apple for App Store distribution.
- Local sessions are stored via SwiftData; pacts are synced to Supabase for multiplayer functionality.

---

## License

MIT
