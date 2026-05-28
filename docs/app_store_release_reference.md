# App Store Release Reference

This document is the final pre-submission checklist for removing QA-only behavior and setting production-safe values.

## 1) Required Feature Flag Values

Set these in `lib/core/constants/feature_flags.dart` before building App Store binaries:

- `subscriptionDevBypass = false`
- `subscriptionIgnoreRevenueCatEntitlement = false`
- `subscriptionFreeSessionLimit = 5`
- `subscriptionDebugPanel = false`
- `entryAudioPlayback = false` (unless intentionally shipping audio upload now)

## 2) Remove / Disable Debug UX

### Subscription debug panel

Current implementation:
- `lib/features/account/widgets/subscription_debug_sheet.dart`
- entry point in `lib/features/account/screens/user_account_screen.dart`

For App Store:
- Keep `subscriptionDebugPanel = false` at minimum.
- Preferred: remove the debug sheet + account entry-point in a cleanup PR if no longer needed.

### Debug logs

Reduce noisy QA logs before release (especially subscription and onboarding logs):
- RevenueCat linkage logs
- Gate diagnostics
- One-off onboarding prints

Keep only actionable production logs.

## 3) Subscription / Paywall Guardrails

Confirm release behavior:
- RevenueCat entitlement is respected (`subscriptionIgnoreRevenueCatEntitlement = false`).
- Free tier gate blocks at 5 saved entries for non-subscribers.
- No dev bypass account can skip paywall.
- Restore purchases works from paywall.

## 4) QA-Only Test Settings to Revert

If used during testing, revert all of the following:

- Any temporary increase to free limit (for example `50`).
- Any temporary SQL changes done only for test users.
- Any temporary routing shortcuts in onboarding flow.
- Any temporary local simulator / sandbox-specific hardcoded behavior.

## 5) iOS Build Safety Checks

Before archive/upload:

- Build from `ios/Runner.xcworkspace` (not `.xcodeproj`).
- `flutter clean`, `flutter pub get`, `cd ios && pod install`.
- Archive and validate in Xcode Organizer.
- Verify app installs and launches on a clean simulator/device.
- Confirm no installation/runtime issues caused by framework mutation scripts.

## 6) RevenueCat Production Verification

- API key in `.env` is correct for the build target.
- Offering and entitlement IDs match app code:
  - entitlement: `Thankful: AI voice Journal Pro`
  - offering fallback: `ThankfulDefault`
- Test purchase, restore, and existing subscriber flow on TestFlight.

## 7) Onboarding Flow Verification

Current intended sequence (when not blocked by auth/session state):
- signup/login -> onb1 -> onb2 -> lhamo intro -> onb3 -> convo -> entry review -> paywall -> home

Confirm before release:
- progress bar step counts are correct for shipped flow
- no hidden/unwired dev-only steps are accidentally reachable

## 8) Store Submission Readiness (Product/Policy)

Confirm from project requirements:
- Privacy policy URL live and linked
- GDPR consent shown before analytics/data collection
- Microphone permission copy is clear and accurate
- Restore purchases available
- No unsupported claims in App Store copy
- RLS policies are enabled and audited on Supabase tables

## 9) Final Pre-Release Smoke Test

Run end-to-end on a clean account:
- new user onboarding
- first session save
- paywall display at free limit
- purchase/restore
- post-purchase session creation
- logout/login state recovery

Only cut release build after this passes.
