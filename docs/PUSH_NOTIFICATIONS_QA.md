# Push Notifications QA — Ditelo sui Tetti iOS

## Architecture Overview

The app has TWO separate notification mechanisms. Understanding both is essential for debugging.

### Mechanism A — Local Notifications (sync-diff, fires on app open)

**What it is**: A `UNTimeIntervalNotificationTrigger` with `timeInterval: 1` scheduled by `LocalNotificationManager` when a sync detects new content.

**When it fires**: 1 second after the user opens the app, IF the sync finds content that wasn't in the previous cached payload.

**When it does NOT fire**: When the app is killed or backgrounded and the user hasn't opened it.

**Code path**:
```
DiteloSuiTettiApp.loadContent()
  → EditorialSyncCoordinator.syncAll()
  → NewContentDetector.detect(previous:fresh:)
  → LocalNotificationManager.scheduleIfNeeded(for:)
  → UNUserNotificationCenter.add(UNNotificationRequest)  ← fires 1 second later
```

**This is the current "notification on app open" behavior.** It is intentional for on-launch new-content awareness, but it is NOT a substitute for remote APNs pushes.

---

### Mechanism B — Remote APNs Pushes (backend-triggered, independent of app state)

**What it is**: A true APNs remote push notification sent by the backend when new content is published.

**When it fires**: Whenever the backend sends it — regardless of whether the app is open, backgrounded, or killed.

**When it does NOT fire**: If the backend hasn't implemented the push-sending logic, or if the APNs token environment is mismatched.

**Code path (iOS receive side)**:
```
Backend → APNs server → iOS system → UNUserNotificationCenterDelegate
  → willPresent (if app is foreground) → shows banner + sound
  → didReceive (when user taps) → AppDeepLinkRouter.handle(link)
```

---

## Current Status

| Behavior | Expected | Current |
|---|---|---|
| Foreground notification banner | ✅ | ✅ `willPresent` returns `.banner .sound` |
| Background notification delivery | ✅ | ✅ `send-apns-push` deployed |
| Killed app notification delivery | ✅ | ✅ APNs delivers independently of app state — **needs TestFlight QA** |
| On-launch notification (new content) | ✅ Local fallback | ✅ `LocalNotificationManager` fires on sync diff |
| Token registration | ✅ | ✅ Sent to `/functions/v1/register-push-token` |
| Deep link on tap | ✅ | ✅ `NotificationDeepLink` + `AppDeepLinkRouter` |
| Backend push send | ✅ | ✅ `send-apns-push` and `notify-content-published` deployed |
| `APNS_ENV` production | Required for TestFlight | ⚠️ **Verify in Supabase secrets** |

---

## Foreground Behavior

- `NotificationCenterDelegate.willPresent` is called with `handler([.banner, .sound])`
- Banner + sound display even when app is active
- `NSLog("[APNs] 📲 foreground notification")` is written to Console.app
- Tapping the banner calls `didReceive` → routes deep link

---

## Background Behavior (app in background, not killed)

- iOS delivers the notification automatically from the APNs payload
- No app code runs until the user taps the notification
- App is briefly woken for background refresh if `content-available: 1` is in the payload
- `didReceive` fires on tap → deep link routed to `AppDeepLinkRouter`

---

## Killed App Behavior

- iOS delivers the notification automatically from the APNs payload
- The system shows the banner without launching the app
- When the user taps, the app launches cold → `AppDelegate.application(_:didFinishLaunchingWithOptions:)` → `UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared`
- `didReceive` fires after app launches → `AppDeepLinkRouter.handle(link)` stores the link → resolved in `ContentView.onAppear` after stores load

---

## APNs Token Environment

| Build type | Token environment | Backend must use |
|---|---|---|
| Xcode Debug (direct run) | Sandbox | `api.sandbox.push.apple.com` |
| TestFlight (Ad Hoc / App Store Connect) | Production | `api.push.apple.com` |
| App Store | Production | `api.push.apple.com` |

**Critical**: `aps-environment = production` is set in `DiteloSuiTetti.entitlements`. This means the device receives a **production APNs token** for ALL builds (including TestFlight). The `PushTokenRegistrationService` sends `environment: "production"` for Release builds and `environment: "sandbox"` for Debug. The backend must use the appropriate APNs endpoint based on the `environment` field.

**If notifications are not arriving on TestFlight**: Check that the backend's Supabase function is using the PRODUCTION APNs endpoint (`api.push.apple.com:443`) and the correct p8/p12 credential, not the sandbox endpoint.

---

## Required APNs Payload Format

```json
{
  "aps": {
    "alert": {
      "title": "Ditelo sui Tetti",
      "body": "Nuovo articolo: Sussidiarietà nel territorio"
    },
    "sound": "default"
  },
  "content_type": "article",
  "content_id": "UUID-HERE",
  "url": "https://www.suitetti.org/articoli/sussidiarieta-nel-territorio"
}
```

The `content_type`, `content_id`, `url` fields are parsed by `NotificationDeepLink(userInfo:)` for deep link routing on tap.

**Canonical public URL domain**: `https://www.suitetti.org`
- Articles: `https://www.suitetti.org/articoli/{slug}`
- Events: `https://www.suitetti.org/eventi/{slug}`
- Documents: `https://www.suitetti.org/documenti/{slug}`

---

## Debugging with Console.app

All push events now use `NSLog` (visible in production/TestFlight builds, not just Debug):

| Log prefix | Meaning |
|---|---|
| `[APNs] ✓ registration succeeded` | Device token received from iOS |
| `[APNs] ✗ registration failed` | APNs registration failed — check entitlements and provisioning |
| `[APNs] 📲 foreground notification` | Remote or local notification received while app is foreground; `remote: 1` = APNs push |
| `[APNs] 👆 notification tapped` | User tapped a notification; `remote: 1` = APNs push |
| `[PushTokenRegistrationService] ✓ registered` | Token successfully sent to backend |
| `[PushTokenRegistrationService] ✗ server rejected` | Backend returned non-2xx — check edge function logs in Supabase |
| `[PushTokenRegistrationService] ✗ network error` | Network failure sending token to backend |

**To view on a connected device**:
1. Open Console.app → select device in sidebar
2. Filter by `[APNs]` or `PushTokenRegistrationService`
3. Launch the app — you should see the token registration log immediately

---

## How to Test with a Real Device

### Test 1: Token registration

1. Connect device, open Console.app, filter `PushTokenRegistrationService`
2. Launch app (or force-restart)
3. Confirm `[PushTokenRegistrationService] ✓ registered (HTTP 200)` appears
4. If `HTTP 4xx/5xx` appears: check Supabase edge function `register-push-token` logs

### Test 2: Foreground delivery

1. Trigger a push from the backend (e.g. publish new content, or use Supabase edge function tester)
2. Keep the app open in foreground
3. Confirm banner appears + Console.app shows `📲 foreground notification remote: 1`

### Test 3: Background delivery

1. Send app to background (press Home)
2. Trigger a push from backend
3. Confirm notification banner appears on lock screen / notification center
4. Tap it → confirm app opens to the correct article/event/document

### Test 4: Killed app delivery

1. Force-quit the app (swipe up in app switcher)
2. Trigger a push from backend
3. Confirm notification banner appears (no app launch needed)
4. Tap it → confirm app launches and navigates to the correct content

### Test 5: Silent push (content-available, no banner)

Currently NOT implemented. `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` is not implemented in `AppDelegate`. Silent pushes are not used in the current architecture.

---

## Known Limitations

1. **Local notification deduplication**: Once a notification is fired for an article/event/document ID (via `LocalNotificationManager.markSent`), it will NEVER fire again for that ID, even if the user clears the notification. This is by design to prevent spam on every sync.

2. **Dynamic Island / Live Activity**: Not implemented. Stretch goal.

3. **Background sync**: The app does NOT implement background fetch via `content-available: 1`. All sync happens on foreground app launch. Future enhancement: add silent push support to trigger a sync when the app is backgrounded.

---

## TestFlight QA Procedure (Killed App)

1. Install TestFlight build on a physical device
2. Open app, grant notification permission, confirm `[PushTokenRegistrationService] ✓ registered` in Console.app
3. Force-quit the app (swipe up in app switcher)
4. From Supabase dashboard or CMS: publish a new article/event, OR trigger `notify-content-published` manually
5. Wait up to 30 seconds; confirm notification banner appears on the lock screen / notification centre
6. Tap the notification
7. Confirm app launches cold and navigates to the correct article/event/document detail view
8. If notification doesn't arrive: check Supabase function logs for APNs HTTP/2 response codes; verify `APNS_ENV = production`

---

## Backend Checklist

For the backend developer:

- [x] `register-push-token` edge function deployed — stores token with `platform`, `environment`, `bundleId`
- [x] `send-apns-push` deployed — uses production APNs endpoint; payload includes `content_type`, `content_id`, `url`
- [x] `notify-content-published` deployed — constructs `https://www.suitetti.org/{articoli|eventi|documenti}/{slug}` URLs
- [ ] **Verify `APNS_ENV = production`** in Supabase project secrets (Dashboard → Settings → Edge Functions → Secrets)
- [ ] Push-sending function uses SANDBOX APNs endpoint for `environment = "sandbox"` tokens (Xcode Debug builds)
- [ ] APNs HTTP/2 response codes are logged (200 = delivered, 410 = token invalid/expired)
- [ ] Expired tokens (APNs 410 response) are deleted from the token store
