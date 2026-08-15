// Visual regression checklist vs website mobile chrome (print-only).
// Usage: dart run tool/visual_qa_checklist.dart
import 'dart:io';

void main() {
  const items = <String>[
    'Home: brand mark, Syne headline, jade accents, hero orbs/ambient particles visible',
    'Home: search card + popular chips spacing matches mobile web density',
    'Property cards: shadow-card elevation, badges, price pill, tilt/press depth',
    'Browse/Search: filter chips, NyumbaAI affordance, listing grid gutters',
    'Detail: gallery, verified chips, unlock CTA hierarchy',
    'Map: markers readable; document 3D buildings status (raster vs Mapbox SDK)',
    'SiteTopBar: frosted glass, logo · notifs badge · Menu',
    'Tenant bottom nav: glass pill, safe-area clearance (shellBottomInset)',
    'Portal drawer: landlord/agency/manager labels + active route',
    'PM units: horizontal table keeps Unit/Status/Rent/Beds columns',
    'Provider me: Edit/Save uses PATCH /providers/me when profile exists',
    'Admin queues: card layout readable on phone (not truncated desktop table)',
    'Dark mode: jade/gold/cocoa readable on graphite surfaces',
    'Fonts: Syne display + Manrope body (not system default)',
  ];

  stdout.writeln('NyumbaSearch Flutter — visual QA checklist');
  stdout.writeln('Compare each item to nyumbasearch.com mobile viewport screenshots.\n');
  for (var i = 0; i < items.length; i++) {
    stdout.writeln('[ ] ${i + 1}. ${items[i]}');
  }
  stdout.writeln(
    '\nGate: do not cut over WebView until this list + device_qa_checklist.dart are green.',
  );
}
