# App Store Checklist — Ditelo sui Tetti iOS

Pre-submission checklist for v1.0 App Store release. Updated: 2026-06-06.

---

## Technical — Completed

- [x] **Privacy Manifest (`PrivacyInfo.xcprivacy`)** — file created at `DiteloSuiTetti/PrivacyInfo.xcprivacy`
  - ⚠️ **Must be added to Xcode target**: drag into Project Navigator → check "DiteloSuiTetti" target membership. Without this step the manifest is on disk but not bundled in the .ipa.
- [x] **APNs `aps-environment = production`** — set in `DiteloSuiTetti.entitlements`
- [x] **App Transport Security** — all HTTPS, no `NSAllowsArbitraryLoads` exceptions
- [x] **App Icon 1024×1024** — `ios-marketing.png` present in `AppIcon.appiconset/`
- [x] **`NSCalendarsFullAccessUsageDescription`** — set via `INFOPLIST_KEY_` in xcodeproj build settings
- [x] **Screenshot Capture Mode** — `--screenshots` launch argument; `AppStorePreviewData` fixtures
- [x] **iPad adaptive layout** — readable-width constraint, split-panel ArticoliView, 2-column home grid
- [x] **Dark Mode navigation titles** — all cream-background screens use `.brandCream` toolbar background
- [x] **Attachment support** — full iOS pipeline + backend deployed
- [x] **SwiftData offline cache** — all three content types persist across launches
- [x] **Onboarding screen** — `@AppStorage("hasSeenOnboarding")` gate; shown on first launch only
- [x] **Push token registration** — wired end-to-end; deduplicates in `UserDefaults`
- [x] **Version/build display** — `AboutDeveloperSection` shows `CFBundleShortVersionString` + `CFBundleVersion`
- [x] **Build verified** — `BUILD SUCCEEDED` with no errors (warnings only)

---

## Technical — Pending

- [ ] **PrivacyInfo.xcprivacy → Xcode target** — see note above; must be done in Xcode manually
- [ ] **App Icon dark/tinted variants** — `Contents.json` has JSON entries; PNG files missing. Designer must provide 1024×1024 dark and tinted PNGs; add to `AppIcon.appiconset/`; set `filename` keys in `Contents.json`
- [ ] **`APNS_ENV = production` in Supabase secrets** — verify in Supabase Dashboard → Settings → Edge Functions → Secrets. Without this TestFlight / App Store pushes will not arrive.

---

## App Store Connect — Pending

- [ ] **Create App Store Connect record** — under Digital Yogin Apple Developer account
- [ ] **Bundle ID** — confirm final bundle ID; update `PRODUCT_BUNDLE_IDENTIFIER` if changed from `com.romeshsinghabahu.DiteloSuiTetti`; re-provision certificates
- [ ] **Age rating** — 4+ (no objectionable content; civic/editorial app)
- [ ] **Primary category** — News
- [ ] **Secondary category** — Lifestyle (optional)
- [ ] **Pricing** — Free
- [ ] **App description (Italian)** — max 4,000 characters; describe the app as a civic editorial platform
- [ ] **App description (English)** — for international App Store connect metadata
- [ ] **Subtitle** — max 30 characters; e.g. "Voce civica italiana"
- [ ] **Keywords** — max 100 characters; e.g. "civico,famiglia,sussidiarietà,notizie,referendum,italia"
- [ ] **Support URL** — `https://www.suitetti.org`
- [ ] **Privacy Policy URL** — `https://www.suitetti.org/privacy`
- [ ] **Marketing URL** — `https://www.suitetti.org` (optional)
- [ ] **Release notes ("What's New")** — max 4,000 characters; first release: brief Italian copy
- [ ] **Screenshots — iPhone 6.9"** (iPhone 17 Pro Max) — minimum 3, up to 10
- [ ] **Screenshots — iPhone 6.1"** (iPhone 17) — minimum 3, up to 10
- [ ] **Screenshots — iPad 12.9"** (iPad Pro) — required if iPad is supported
- [ ] **App preview video** — optional; 15–30 seconds; capture screen recording on device

---

## QA — Pending

- [ ] **TestFlight killed-app push delivery** — force-quit app → trigger push → confirm banner + deep link on tap (see `docs/PUSH_NOTIFICATIONS_QA.md`)
- [ ] **E2E attachment test** — insert row in `public.allegati` → sync app → confirm `LinkedDocumentCard` appears in article/event detail
- [ ] **Final TestFlight RC QA** — all tabs, dark mode, offline mode, dynamic type, VoiceOver, iPad, push notifications
- [ ] **Accessibility audit** — VoiceOver narration of article list, article detail, event detail, document list

---

## Deployment Sequence

When all items above are checked:

1. Increment `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in Xcode build settings
2. Archive: Xcode → Product → Archive
3. Upload to App Store Connect via Xcode Organizer (Distribute App → App Store Connect)
4. Submit for TestFlight external testing; wait for Apple beta review
5. Capture screenshots with `--screenshots` mode on physical device or simulator
6. Fill in App Store Connect metadata
7. Select the build and submit for App Review
8. Monitor App Review status; respond to rejections within 24 hours
