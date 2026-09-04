import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:permission_handler/permission_handler.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/features/maps/data/map_providers.dart';
import 'package:nyumbasearch/features/maps/data/mapbox_3d.dart';
import 'package:nyumbasearch/features/properties/data/listing.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with AutomaticKeepAliveClientMixin {
  MapboxMap? _map;
  PointAnnotationManager? _pins;
  Listing? _selected;
  String? _locationHint;
  double _zoom = 13;
  var _tokenReady = false;
  var _preparingToken = false;
  String? _tokenError;
  Uint8List? _pinBytes;
  Uint8List? _pinSelectedBytes;
  final _annotationToListing = <String, Listing>{};
  Point? _frozenCenter;

  /// Bumped whenever the native map is (re)created so stale async work bails out.
  var _mapGeneration = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _mapGeneration++;
    _pins = null;
    _map = null;
    super.dispose();
  }

  Future<void> _prepareToken(String token) async {
    if (_tokenReady || _preparingToken) return;
    _preparingToken = true;
    try {
      MapboxOptions.setAccessToken(token);
      _pinBytes ??= await buildMapPinBytes(fill: const Color(0xFF0A8F3D));
      _pinSelectedBytes ??= await buildMapPinBytes(fill: const Color(0xFFFFD54F));
      if (!mounted) return;
      setState(() {
        _tokenReady = true;
        _tokenError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _tokenError = 'Could not initialize map.');
    } finally {
      _preparingToken = false;
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    final gen = ++_mapGeneration;
    _map = map;
    _pins = null;
    _annotationToListing.clear();

    try {
      await map.logo.updateSettings(LogoSettings(enabled: true));
      await map.compass.updateSettings(CompassSettings(enabled: true));
      await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
      await map.gestures.updateSettings(
        GesturesSettings(
          rotateEnabled: true,
          pitchEnabled: true,
          scrollEnabled: true,
          simultaneousRotateAndPinchToZoomEnabled: true,
        ),
      );
    } catch (_) {
      // Native map may still be wiring channels; ignore soft failures.
    }

    if (!mounted || gen != _mapGeneration) return;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final gen = _mapGeneration;
    final map = _map;
    if (map == null || !mounted || gen != _mapGeneration) return;

    await enableMapbox3d(map);
    if (!mounted || gen != _mapGeneration || !identical(_map, map)) return;

    try {
      _pins = await map.annotations.createPointAnnotationManager();
      _pins!.tapEvents(
        onTap: (annotation) {
          if (!mounted) return;
          final listing = _annotationToListing[annotation.id];
          if (listing != null) setState(() => _selected = listing);
        },
      );
    } catch (_) {
      _pins = null;
      return;
    }

    final page = ref.read(mapListingsProvider).valueOrNull;
    if (page != null) {
      await _syncMarkers(page.items, generation: gen);
    }
  }

  Future<void> _syncMarkers(
    List<Listing> listings, {
    int? generation,
  }) async {
    final gen = generation ?? _mapGeneration;
    final manager = _pins;
    final pin = _pinBytes;
    final pinSel = _pinSelectedBytes;
    if (manager == null || pin == null || pinSel == null) return;
    if (!mounted || gen != _mapGeneration) return;

    final withCoords = listings
        .where((l) => l.latitude != null && l.longitude != null)
        .toList();

    try {
      await manager.deleteAll();
    } catch (_) {
      // Stale manager after map recreate — drop and wait for next style load.
      if (identical(_pins, manager)) _pins = null;
      return;
    }
    if (!mounted || gen != _mapGeneration) return;
    _annotationToListing.clear();

    // High zoom: individual pins. Lower zoom: grid clusters as numbered circles.
    try {
      if (_zoom >= 14) {
        final options = <PointAnnotationOptions>[];
        for (final listing in withCoords) {
          final selected = _selected?.id == listing.id;
          options.add(
            PointAnnotationOptions(
              geometry: Point(
                coordinates: Position(listing.longitude!, listing.latitude!),
              ),
              image: selected ? pinSel : pin,
              iconSize: 0.55,
              iconAnchor: IconAnchor.BOTTOM,
            ),
          );
        }
        final created = await manager.createMulti(options);
        if (!mounted || gen != _mapGeneration) return;
        for (var i = 0; i < created.length; i++) {
          final ann = created[i];
          if (ann != null && i < withCoords.length) {
            _annotationToListing[ann.id] = withCoords[i];
          }
        }
        return;
      }

      final cell = _zoom >= 12 ? 0.02 : _zoom >= 10 ? 0.05 : 0.1;
      final buckets = <String, List<Listing>>{};
      for (final listing in withCoords) {
        final key =
            '${(listing.latitude! / cell).floor()}_${(listing.longitude! / cell).floor()}';
        (buckets[key] ??= []).add(listing);
      }

      final options = <PointAnnotationOptions>[];
      final order = <Listing>[];
      for (final group in buckets.values) {
        if (group.length == 1) {
          options.add(
            PointAnnotationOptions(
              geometry: Point(
                coordinates:
                    Position(group.first.longitude!, group.first.latitude!),
              ),
              image: pin,
              iconSize: 0.5,
              iconAnchor: IconAnchor.BOTTOM,
            ),
          );
          order.add(group.first);
        } else {
          final lat = group.map((l) => l.latitude!).reduce((a, b) => a + b) /
              group.length;
          final lng = group.map((l) => l.longitude!).reduce((a, b) => a + b) /
              group.length;
          options.add(
            PointAnnotationOptions(
              geometry: Point(coordinates: Position(lng, lat)),
              textField: '${group.length}',
              textColor: Colors.white.toARGB32(),
              textSize: 14,
              textHaloColor: const Color(0xFF0A8F3D).toARGB32(),
              textHaloWidth: 2,
              iconSize: 0.01,
            ),
          );
          order.add(group.first);
        }
      }

      final created = await manager.createMulti(options);
      if (!mounted || gen != _mapGeneration) return;
      for (var i = 0; i < created.length; i++) {
        final ann = created[i];
        if (ann != null && i < order.length) {
          _annotationToListing[ann.id] = order[i];
        }
      }
    } catch (_) {
      if (identical(_pins, manager)) _pins = null;
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locationHint = null);
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      setState(() {
        _locationHint = status.isPermanentlyDenied
            ? 'Location permission denied. Enable it in Settings to center on you.'
            : 'Location permission is needed to show your position.';
      });
      return;
    }

    final enabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      setState(
        () => _locationHint = 'Turn on location services to use this feature.',
      );
      return;
    }

    final pos = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.medium,
      ),
    );
    final map = _map;
    if (map == null || !mounted) return;
    try {
      await map.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 15,
          pitch: 50,
        ),
        MapAnimationOptions(duration: 900),
      );
    } catch (_) {
      // Ignore if map was disposed during the fly.
    }
  }

  Future<void> _onCameraChanged(CameraChangedEventData data) async {
    final z = data.cameraState.zoom;
    if ((z - _zoom).abs() > 0.2) {
      final prev = _zoom;
      if (!mounted) return;
      setState(() => _zoom = z);
      // Re-cluster when crossing the individual-pin threshold.
      if ((prev >= 14) != (z >= 14)) {
        final page = ref.read(mapListingsProvider).valueOrNull;
        if (page != null) await _syncMarkers(page.items);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tokenAsync = ref.watch(mapboxTokenProvider);
    final listingsAsync = ref.watch(mapListingsProvider);
    final theme = Theme.of(context);
    final bottomPad = NyumbaTokens.shellBottomInset(context);

    ref.listen(mapboxTokenProvider, (prev, next) {
      next.whenData((token) {
        if (token != null) _prepareToken(token);
      });
    });

    ref.listen(mapListingsProvider, (prev, next) {
      next.whenData((page) {
        _syncMarkers(page.items);
      });
    });

    tokenAsync.whenData((token) {
      if (token != null && !_tokenReady && !_preparingToken) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _prepareToken(token);
        });
      }
    });

    final listings = listingsAsync.valueOrNull;
    final withCoords = listings?.items
            .where((l) => l.latitude != null && l.longitude != null)
            .toList() ??
        const <Listing>[];
    // Freeze center once so listing loads don't recreate MapWidget/viewport.
    _frozenCenter ??= withCoords.isNotEmpty
        ? Point(
            coordinates: Position(
              withCoords.first.longitude!,
              withCoords.first.latitude!,
            ),
          )
        : nairobiCenter;
    final initial = _frozenCenter!;

    Widget body;
    if (_tokenError != null) {
      body = Center(child: Text(_tokenError!));
    } else if (tokenAsync.hasError) {
      body = const Center(child: Text('Could not load map configuration.'));
    } else if (tokenAsync.isLoading || !_tokenReady) {
      if (tokenAsync.hasValue &&
          tokenAsync.value == null &&
          !tokenAsync.isLoading) {
        body = const Center(child: Text('Map token unavailable.'));
      } else {
        body = const Center(child: CircularProgressIndicator());
      }
    } else {
      body = Stack(
        children: [
          MapWidget(
            key: const ValueKey('nyumba-mapbox-3d'),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            textureView: true,
            viewport: CameraViewportState(
              center: initial,
              zoom: 13.2,
              pitch: 52,
              bearing: -18,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onCameraChangeListener: _onCameraChanged,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Search Kilimani, Yaya Centre, Ngong Rd...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'My location',
                            onPressed: _goToMyLocation,
                            icon: const Icon(
                              Icons.near_me_outlined,
                              color: Colors.white,
                            ),
                          ),
                          Material(
                            color: NyumbaTokens.primaryDark,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: '3D buildings on',
                              onPressed: () async {
                                final map = _map;
                                if (map == null) return;
                                await enableMapbox3d(map);
                                try {
                                  await map.easeTo(
                                    CameraOptions(pitch: 55, zoom: 15.2),
                                    MapAnimationOptions(duration: 700),
                                  );
                                } catch (_) {}
                              },
                              icon: const Icon(
                                Icons.apartment,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () => context.go('/search'),
                            style: FilledButton.styleFrom(
                              backgroundColor: NyumbaTokens.gold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                            child: const Text('List view'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const _MapChip(
                          icon: Icons.view_in_ar,
                          label: '3D buildings',
                        ),
                        const _MapChip(label: 'Water'),
                        const _MapChip(label: 'Security'),
                        _MapChip(
                          icon: Icons.layers_outlined,
                          label: listingsAsync.isLoading
                              ? 'Loading…'
                              : '${withCoords.length} listings',
                        ),
                      ],
                    ),
                  ),
                  if (_locationHint != null) ...[
                    const SizedBox(height: 8),
                    Material(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_locationHint!),
                      ),
                    ),
                  ],
                  if (listingsAsync.hasError) ...[
                    const SizedBox(height: 8),
                    Material(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Listings failed to load. Map still works.',
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(mapListingsProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPad - 36,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    '3D buildings · two-finger tilt · tap a pin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: bottomPad,
              child: _MapPreviewCard(
                listing: _selected!,
                onOpen: () => context.push('/property/${_selected!.id}'),
                onClose: () => setState(() => _selected = null),
              ),
            ),
        ],
      );
    }

    return Scaffold(body: body);
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({
    required this.listing,
    required this.onOpen,
    required this.onClose,
  });

  final Listing listing;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.94),
      elevation: 8,
      shadowColor: Colors.black45,
      borderRadius: NyumbaTokens.borderRadius2xl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 108,
              child: listing.primaryImage.isEmpty
                  ? ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.home_work_outlined),
                    )
                  : CachedNetworkImage(
                      imageUrl: listing.primaryImage,
                      fit: BoxFit.cover,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listing.priceLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      listing.neighborhood,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: NyumbaTokens.gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'View',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: NyumbaTokens.goldForeground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );
  }
}
