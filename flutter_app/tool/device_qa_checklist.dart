// Device QA + cutover runbook (print-only).
// Usage: dart run tool/device_qa_checklist.dart
//        dart run tool/device_qa_checklist.dart --howto
import 'dart:io';

void main(List<String> args) {
  final howto = args.contains('--howto') || args.contains('-h');

  if (howto) {
    _printHowto();
  }

  const items = <String>[
    'Email/password sign-in + session restore after kill',
    'Google OAuth: browser → ke.co.nyumbasearch.app://login-callback/ → home',
    'Privileged signup lands on /auth/pending',
    'Password reset request + deep link return',
    'Browse listings, search filters, map markers, property detail (amenities/video/Trust)',
    'Saved + compare + saved-search alerts (Plus gate if applicable)',
    'Contact unlock pay (Daraja M-Pesa) and card (Pesapal) if offered',
    'Landlord: create/edit listing, boost, plan checkout, analytics',
    'Tenant rent pay (IntaSend) + invite accept',
    'PM: units PATCH, rent generate, maintenance status/assign; units table horizontal scroll',
    'Agency/manager dashboards + org team',
    'Admin: verify toggle, authenticity ±5, create listing/provider',
    'Provider Edit/Save profile (PATCH /providers/me)',
    'Android App Link: https://nyumbasearch.com/tenant/property/<id>',
    'iOS Universal Link after APPLE_TEAM_ID is set (not TEAMID placeholder)',
    'Notifications list + prefs (push receive only if FCM client configured)',
    'Provider Call/WhatsApp from detail',
    'Visual QA: dart run tool/visual_qa_checklist.dart (all checked)',
  ];

  stdout.writeln('NyumbaSearch Flutter — device QA checklist');
  stdout.writeln('Package: ke.co.nyumbasearch.app');
  stdout.writeln(
    'Do not claim production cutover until every item is checked on a real device.\n',
  );
  for (var i = 0; i < items.length; i++) {
    stdout.writeln('[ ] ${i + 1}. ${items[i]}');
  }
  stdout.writeln(
    '\nRemaining PARTIAL: Google OAuth device QA, iOS APPLE_TEAM_ID, FCM client files.',
  );
  if (!howto) {
    stdout.writeln('Tip: dart run tool/device_qa_checklist.dart --howto');
  }
}

void _printHowto() {
  stdout.writeln('''
═══════════════════════════════════════════════════════════════
 CUTOVER HOW-TO (Device QA · Google OAuth · Apple Team ID · FCM)
═══════════════════════════════════════════════════════════════

───────────────────────────────────────────────────────────────
1) DEVICE QA — run the app on a phone
───────────────────────────────────────────────────────────────
Prereqs:
  • USB debugging on (Android) or a configured iOS device/Mac
  • Phone appears in: flutter devices

Install on Android emulator (no physical phone):
  # one-time (already done on this machine):
  #   sdkmanager "system-images;android-34;google_apis;x86_64"
  #   avdmanager create avd -n nyumba_api34 -k "system-images;android-34;google_apis;x86_64" -d pixel_6
  emulator -avd nyumba_api34 -dns-server 8.8.8.8,8.8.4.4
  cd flutter_app
  flutter run -d emulator-5554

If you see "Failed host lookup: 'nyumbasearch.com'" (ping IP works, names fail):
  # Private DNS "dns.google" on this AVD often breaks name resolution.
  adb shell settings put global private_dns_mode off
  adb shell svc wifi disable
  adb shell svc wifi enable
  # then tap Retry in the app (or hot-restart)

Or physical phone:
  flutter devices
  flutter run -d <deviceId>

───────────────────────────────────────────────────────────────
2) GOOGLE OAUTH — confirm deep link return
───────────────────────────────────────────────────────────────
App redirect (already coded):
  ke.co.nyumbasearch.app://login-callback/

Android intent-filter: present in AndroidManifest.xml
iOS URL scheme: CFBundleURLTypes in ios/Runner/Info.plist

Supabase Dashboard (required once):
  1. Open https://supabase.com/dashboard → project fnycwcbxorhreidhbers
  2. Authentication → URL Configuration
  3. Add Redirect URL exactly:
       ke.co.nyumbasearch.app://login-callback/
  4. Ensure Google provider is enabled (Auth → Providers → Google)

Google Cloud (if Google sign-in fails with redirect_uri_mismatch):
  • OAuth client type: Web (Supabase uses this) — authorized redirect URIs
    must include your Supabase callback:
    https://fnycwcbxorhreidhbers.supabase.co/auth/v1/callback

Device test:
  1. flutter run on phone
  2. Sign in → Continue with Google
  3. Complete Google in the browser as kevinbuluma9@gmail.com
  4. Phone should reopen the app on login-callback and land signed-in
  5. If stuck in browser: Supabase redirect allowlist is usually wrong

QA account (emulator in progress):
  kevinbuluma9@gmail.com — Google password step is interactive; do not commit secrets.

ADB deep-link smoke (Android, app installed):
  adb shell am start -a android.intent.action.VIEW ^
    -d "ke.co.nyumbasearch.app://login-callback/"

App route after return:
  /login-callback → OAuthCallbackPage (polls session / getSessionFromUrl)
  LoginPage also resumes Google wait on AppLifecycleState.resumed

───────────────────────────────────────────────────────────────
3) APPLE TEAM ID — set Worker env for Universal Links
───────────────────────────────────────────────────────────────
Find Team ID (10 characters, e.g. AB12CD34EF):
  • https://developer.apple.com/account → Membership details → Team ID
  • or Xcode → Settings → Accounts → select team → Team ID

Set + deploy (from find-nyumba-smart):
  node scripts/set-apple-team-id.mjs YOURTEAMID
  npm run deploy

Verify:
  curl -s https://nyumbasearch.com/.well-known/apple-app-site-association
  # appID must be YOURTEAMID.ke.co.nyumbasearch.app  (not TEAMID.…)

Until this is set, AASA still serves placeholder TEAMID and iOS Universal
Links will not associate.

───────────────────────────────────────────────────────────────
4) FIREBASE MESSAGING (optional native push receive)
───────────────────────────────────────────────────────────────
Server already has FCM_PROJECT_ID=nyumbasearch-b70a1 and FCM_SEND_ENABLED.
Inbox works via BFF without this. Native push receive needs client files:

  1. Firebase Console → project nyumbasearch-b70a1  (or run fetch script)
     node scripts/fetch-google-services-json.mjs   # from find-nyumba-smart
  2. File lands at flutter_app/android/app/google-services.json
  3. (iOS later) Add iOS app + GoogleService-Info.plist → ios/Runner/
  4. flutter pub get && flutter run

Push bootstrap registers the FCM token to POST /api/mobile/v1/fcm-token
when Firebase initializes successfully and the user is signed in.
Without google-services.json the app still runs; push registration is skipped.

═══════════════════════════════════════════════════════════════
''');
}
