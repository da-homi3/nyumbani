import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Kenya approx bounds (website map maxBounds parity).
final kenyaBounds = CoordinateBounds(
  southwest: Point(coordinates: Position(33.9, -4.72)),
  northeast: Point(coordinates: Position(41.91, 5.03)),
  infiniteBounds: false,
);

final nairobiCenter = Point(coordinates: Position(36.817223, -1.286389));

/// Enables Mapbox 3D buildings + DEM terrain for streets-v12 (or adds pitch-friendly
/// Standard basemap config). Call after style has loaded.
///
/// All steps are best-effort — failures must not crash the host Activity.
Future<void> enableMapbox3d(MapboxMap map) async {
  final style = map.style;

  // Prefer Standard basemap 3D objects when present.
  try {
    await style.setStyleImportConfigProperties('basemap', {
      'show3dObjects': true,
      'lightPreset': 'dusk',
    });
  } catch (_) {
    // Not a Standard import style — continue with extrusion layer path.
  }

  // Classic fill-extrusion on composite building layer (streets / light / dark).
  try {
    final existing = await style.styleLayerExists('nyumba-3d-buildings');
    if (!existing) {
      await style.addLayer(
        FillExtrusionLayer(
          id: 'nyumba-3d-buildings',
          sourceId: 'composite',
          sourceLayer: 'building',
          minZoom: 13,
          filter: [
            '==',
            ['get', 'extrude'],
            'true',
          ],
          fillExtrusionColor: const Color(0xFF94A3B8).toARGB32(),
          fillExtrusionOpacity: 0.72,
          fillExtrusionHeightExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            13,
            0,
            13.05,
            ['get', 'height'],
          ],
          fillExtrusionBaseExpression: ['get', 'min_height'],
          fillExtrusionVerticalGradient: true,
          fillExtrusionCastShadows: true,
        ),
      );
    }
  } catch (_) {
    // Standard style may not expose composite/building the same way.
  }

  // Terrain DEM (minzoom ~12 parity with website).
  try {
    final hasDem = await style.styleSourceExists('mapbox-dem');
    if (!hasDem) {
      await style.addSource(
        RasterDemSource(
          id: 'mapbox-dem',
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
          tileSize: 512,
          maxzoom: 14,
        ),
      );
    }
    final ready = await style.styleSourceExists('mapbox-dem');
    if (ready) {
      await style.setStyleTerrain(
        jsonEncode({
          'source': 'mapbox-dem',
          'exaggeration': 1.15,
        }),
      );
    }
  } catch (_) {
    // Terrain optional if token/style rejects DEM.
  }

  try {
    await map.setBounds(
      CameraBoundsOptions(
        bounds: kenyaBounds,
        minZoom: 5.5,
        maxZoom: 18.5,
        maxPitch: 60,
      ),
    );
  } catch (_) {
    // Map may have been disposed mid-setup (tab rebuild).
  }
}

Future<Uint8List> buildMapPinBytes({
  required Color fill,
  int size = 96,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = fill;
  final stroke = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.06;

  final path = Path();
  final cx = size / 2;
  final cy = size * 0.38;
  final r = size * 0.28;
  path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
  path.moveTo(cx - r * 0.72, cy + r * 0.45);
  path.quadraticBezierTo(cx, size * 0.95, cx, size * 0.95);
  path.quadraticBezierTo(cx, size * 0.95, cx + r * 0.72, cy + r * 0.45);
  path.close();

  canvas.drawPath(path, paint);
  canvas.drawPath(path, stroke);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
