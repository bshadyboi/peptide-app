# TestFlight checklist

One-time setup to install the app on your iPhone without plugging in for every build.

## Prerequisites

- [Apple Developer Program](https://developer.apple.com/programs/) membership ($99/yr) — **required for TestFlight and push**
- Xcode signed in with your Apple ID (**Xcode → Settings → Accounts**)
- `DEVELOPMENT_TEAM` set in `Secrets.xcconfig` (your 10-character Team ID from the Accounts pane)

### Fix "Cannot create provisioning profile" errors

1. Copy `Secrets.xcconfig.example` → `Secrets.xcconfig` and set a real `DEVELOPMENT_TEAM` (not `YOUR_TEAM_ID_HERE`).
2. Run `xcodegen generate` and reopen the project.
3. In Xcode: select the **PeptidePriceTracker** target → **Signing & Capabilities** → choose your **Team**.
4. For **Simulator** builds, use the **Debug** scheme (push entitlements are disabled in Debug).
5. For **Archive / TestFlight**, you need the paid Developer Program. In [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list) → App IDs → `com.peptideprice.tracker` → enable **Push Notifications**.

If you only have a free Personal Team, you can run on Simulator but not Archive to TestFlight until you enroll in the Developer Program.

## 1. Enable push (physical device only)

Push alerts require APNs secrets in Supabase (see `DEPLOY.md` → Push notifications):

| Supabase secret | Source |
|-----------------|--------|
| `APNS_KEY_ID` | Apple Developer → Keys → APNs key |
| `APNS_TEAM_ID` | Membership details |
| `APNS_AUTH_KEY` | `.p8` key contents |
| `APNS_BUNDLE_ID` | `com.peptideprice.tracker` |
| `APNS_PRODUCTION` | `false` for TestFlight sandbox, `true` for App Store |

Entitlements are already enabled in the project (`PeptidePriceTracker.entitlements`).

## 2. Archive & upload

1. Open `PeptidePriceTracker.xcodeproj` in Xcode
2. Select **Any iOS Device (arm64)** as the run destination (not Simulator)
3. **Product → Archive**
4. In the Organizer window: **Distribute App → App Store Connect → Upload**
5. Wait for processing (~5–15 min) in [App Store Connect](https://appstoreconnect.apple.com)

## 3. TestFlight

1. App Store Connect → **My Apps** → **Peptide Price Tracker** (create app record if needed)
2. **TestFlight** tab → add yourself as an internal tester
3. Install **TestFlight** on your iPhone → accept invite → install build

## 4. What updates automatically

After TestFlight install, you **do not** need to rebuild for:

- Scraper price updates (every 6 hours via GitHub Actions)
- Daily price history snapshots
- Hourly alert checks

You **do** need a new TestFlight build when we change the iOS app code.

## 5. App Store Connect app record (first time)

- **Name:** Peptide Prices (or your choice)
- **Bundle ID:** `com.peptideprice.tracker`
- **SKU:** `peptide-price-tracker`
- **Category:** Health & Fitness or Utilities
- **Privacy policy URL:** required before public release (can use a simple GitHub Pages doc)

## Troubleshooting

| Issue | Fix |
|-------|-----|
| DerivedData / build database error | Quit Xcode → `./scripts/clean-xcode.sh` → reopen |
| Push not received | Must use physical device; check APNs secrets; allow notifications in Settings |
| Archive fails signing | Set Team in Xcode target → Signing & Capabilities |
| TestFlight “Missing Compliance” | Export compliance → No encryption beyond HTTPS |

## Version bumps

Before each upload, bump in `project.yml`:

```yaml
MARKETING_VERSION: 1.2   # user-visible
CURRENT_PROJECT_VERSION: 3   # build number, must increase each upload
```

Then run `xcodegen generate` and archive again.
