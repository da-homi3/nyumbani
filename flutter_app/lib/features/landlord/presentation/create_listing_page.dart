import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/landlord/presentation/my_listings_page.dart';
import 'package:nyumbasearch/features/subscriptions/data/subscriptions_repository.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';

const _propertyTypeOptions = <({String id, String label})>[
  (id: 'bedsitter', label: 'Bedsitter'),
  (id: 'single_room', label: 'Single room'),
  (id: 'studio', label: 'Studio'),
  (id: 'hostel', label: 'Hostel'),
  (id: 'one_bedroom', label: '1 bedroom'),
  (id: 'two_bedroom', label: '2 bedroom'),
  (id: 'three_bedroom', label: '3 bedroom'),
  (id: 'four_bedroom', label: '4 bedroom'),
  (id: 'maisonette', label: 'Maisonette'),
  (id: 'bungalow', label: 'Bungalow'),
  (id: 'townhouse', label: 'Townhouse'),
  (id: 'penthouse', label: 'Penthouse'),
  (id: 'guest_house', label: 'Guest house'),
  (id: 'villa', label: 'Villa'),
  (id: 'bnb', label: 'BnB'),
  (id: 'hotel', label: 'Hotel'),
  (id: 'commercial', label: 'Commercial'),
];

int _bedroomsForType(String type) {
  return switch (type) {
    'one_bedroom' => 1,
    'two_bedroom' => 2,
    'three_bedroom' => 3,
    'four_bedroom' => 4,
    'maisonette' || 'bungalow' || 'townhouse' || 'villa' || 'penthouse' => 3,
    _ => 0,
  };
}

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({super.key});

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _propertyType = 'bedsitter';
  final _amenities = <String>{};
  var _busy = false;
  String? _localError;
  String? _locationId;
  List<_LocationSuggestion> _suggestions = const [];
  var _suggesting = false;
  int _suggestSeq = 0;

  static const _amenityOptions = [
    'WiFi',
    'Parking',
    'CCTV',
    'Water',
    'Backup power',
    'Borehole',
    'Elevator',
    'Gym',
    'Furnished',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _rentCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNeighborhoodChanged(String value) async {
    final q = value.trim();
    if (_locationId != null) {
      setState(() => _locationId = null);
    }
    if (q.length < 2) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
      return;
    }
    final seq = ++_suggestSeq;
    setState(() => _suggesting = true);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted || seq != _suggestSeq) return;
    try {
      final res = await ref.read(mobileApiRepositoryProvider).searchLocations(q: q, limit: 8);
      if (!mounted || seq != _suggestSeq) return;
      final raw = res['items'];
      final items = <_LocationSuggestion>[];
      if (raw is List) {
        for (final row in raw) {
          if (row is! Map) continue;
          final id = row['id']?.toString();
          final name = row['name']?.toString();
          if (id == null || name == null || name.isEmpty) continue;
          items.add(
            _LocationSuggestion(
              id: id,
              name: name,
              subtitle: row['subtitle']?.toString() ?? row['type']?.toString() ?? '',
            ),
          );
        }
      }
      setState(() {
        _suggestions = items;
        _suggesting = false;
      });
    } catch (_) {
      if (!mounted || seq != _suggestSeq) return;
      setState(() {
        _suggestions = const [];
        _suggesting = false;
      });
    }
  }

  void _pickSuggestion(_LocationSuggestion hit) {
    _neighborhoodCtrl.text = hit.name;
    setState(() {
      _locationId = hit.id;
      _suggestions = const [];
    });
    unawaited(
      ref.read(mobileApiRepositoryProvider).recordLocationSelect(
            locationId: hit.id,
            q: hit.name,
          ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _localError = null;
    });

    try {
      final rent = int.parse(_rentCtrl.text.trim().replaceAll(',', ''));
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'neighborhood': _neighborhoodCtrl.text.trim(),
        'property_type': _propertyType,
        'rent_kes': rent,
        'bedrooms': _bedroomsForType(_propertyType),
        'bathrooms': 1,
        'pricing_mode': 'rent',
        'description': _descriptionCtrl.text.trim(),
        'amenities': _amenities.toList(),
        'images': <String>[],
      };
      final locationId = _locationId;
      if (locationId != null && locationId.isNotEmpty) {
        body['location_id'] = locationId;
      }
      await ref.read(mobileApiRepositoryProvider).createProperty(body);

      ref.invalidate(ownerPropertiesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created.')),
      );
      context.go('/landlord/listings');
    } catch (e) {
      setState(() {
        _localError =
            e is AppFailure ? e.message : 'Could not create listing. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('New listing')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to create a listing',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    context.push(loginLocation(from: '/landlord/listings/new')),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final entitlementsAsync = ref.watch(entitlementsProvider);
    if (entitlementsAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('New listing')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final listingLimit = entitlementsAsync.valueOrNull?.listingLimit;
    if (listingLimit != null && listingLimit <= 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('New listing')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Subscribe to list properties',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'A paid landlord plan is required before you can publish listings.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/landlord/plan'),
                child: const Text('View plans'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            TextFormField(
              controller: _titleCtrl,
              enabled: !_busy,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Bright bedsitter in Kilimani',
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.length < 3) return 'Enter a title (at least 3 characters).';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _neighborhoodCtrl,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              onChanged: _onNeighborhoodChanged,
              decoration: InputDecoration(
                labelText: 'Neighborhood',
                hintText: 'e.g. Kilimani',
                helperText: _locationId != null
                    ? 'Matched to NyumbaSearch place directory'
                    : 'Start typing to match a known place',
                suffixIcon: _suggesting
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.place_outlined),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.length < 2) return 'Enter a neighborhood.';
                return null;
              },
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Material(
                elevation: 1,
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final hit = _suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(hit.name),
                      subtitle: hit.subtitle.isEmpty ? null : Text(hit.subtitle),
                      onTap: _busy ? null : () => _pickSuggestion(hit),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _propertyType,
              decoration: const InputDecoration(labelText: 'Property type'),
              items: [
                for (final opt in _propertyTypeOptions)
                  DropdownMenuItem(value: opt.id, child: Text(opt.label)),
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v != null) setState(() => _propertyType = v);
                    },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _rentCtrl,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Rent (KES)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim().replaceAll(',', ''));
                if (n == null || n <= 0) return 'Enter a valid rent amount.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionCtrl,
              enabled: !_busy,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 14),
            Text('Amenities', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in _amenityOptions)
                  FilterChip(
                    label: Text(a),
                    selected: _amenities.contains(a),
                    onSelected: _busy
                        ? null
                        : (v) {
                            setState(() {
                              if (v) {
                                _amenities.add(a);
                              } else {
                                _amenities.remove(a);
                              }
                            });
                          },
                  ),
              ],
            ),
            if (_localError != null) ...[
              const SizedBox(height: 12),
              Text(_localError!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create listing'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSuggestion {
  const _LocationSuggestion({
    required this.id,
    required this.name,
    required this.subtitle,
  });

  final String id;
  final String name;
  final String subtitle;
}
