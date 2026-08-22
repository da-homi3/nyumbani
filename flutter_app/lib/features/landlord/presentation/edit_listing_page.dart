import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/landlord/data/property_media_uploader.dart';
import 'package:nyumbasearch/features/landlord/presentation/my_listings_page.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';

class EditListingPage extends ConsumerStatefulWidget {
  const EditListingPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends ConsumerState<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _bedsCtrl = TextEditingController(text: '1');
  final _bathsCtrl = TextEditingController(text: '1');
  var _isActive = true;
  var _isVacant = true;
  var _loading = true;
  var _busy = false;
  String? _error;
  List<String> _images = const [];
  final _amenities = <String>{};
  String? _locationId;
  List<_EditLocationSuggestion> _suggestions = const [];
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
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    _descriptionCtrl.dispose();
    _videoCtrl.dispose();
    _imageUrlCtrl.dispose();
    _bedsCtrl.dispose();
    _bathsCtrl.dispose();
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
      final items = <_EditLocationSuggestion>[];
      if (raw is List) {
        for (final row in raw) {
          if (row is! Map) continue;
          final id = row['id']?.toString();
          final name = row['name']?.toString();
          if (id == null || name == null || name.isEmpty) continue;
          items.add(
            _EditLocationSuggestion(
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

  void _pickSuggestion(_EditLocationSuggestion hit) {
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

  Future<void> _load() async {
    try {
      final json =
          await ref.read(mobileApiRepositoryProvider).getProperty(widget.propertyId);
      final prop = json['property'];
      if (prop is Map) {
        final m = Map<String, dynamic>.from(prop);
        _titleCtrl.text = (m['title'] as String?) ?? '';
        _neighborhoodCtrl.text = (m['neighborhood'] as String?) ?? '';
        _locationId = m['location_id']?.toString();
        _rentCtrl.text = ((m['rent_kes'] as num?)?.toInt() ?? 0).toString();
        _depositCtrl.text = ((m['deposit_kes'] as num?)?.toInt() ?? 0).toString();
        _descriptionCtrl.text = (m['description'] as String?) ?? '';
        _videoCtrl.text = (m['video_url'] as String?) ?? '';
        _bedsCtrl.text = ((m['bedrooms'] as num?)?.toInt() ?? 0).toString();
        _bathsCtrl.text = ((m['bathrooms'] as num?)?.toInt() ?? 0).toString();
        _isActive = m['is_active'] != false;
        _isVacant = m['is_vacant'] != false;
        final imgs = m['images'];
        if (imgs is List) {
          _images = imgs.whereType<String>().toList();
        }
        final am = m['amenities'];
        if (am is List) {
          _amenities
            ..clear()
            ..addAll(am.whereType<String>());
        }
      }
    } catch (e) {
      _error = e is AppFailure ? e.message : 'Could not load listing.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rent = int.parse(_rentCtrl.text.trim().replaceAll(',', ''));
      final deposit = int.tryParse(_depositCtrl.text.trim().replaceAll(',', '')) ?? 0;
      final beds = int.tryParse(_bedsCtrl.text.trim()) ?? 0;
      final baths = int.tryParse(_bathsCtrl.text.trim()) ?? 0;
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'neighborhood': _neighborhoodCtrl.text.trim(),
        'rent_kes': rent,
        'deposit_kes': deposit,
        'bedrooms': beds,
        'bathrooms': baths,
        'description': _descriptionCtrl.text.trim(),
        'video_url': _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim(),
        'amenities': _amenities.toList(),
        'is_active': _isActive,
        'is_vacant': _isVacant,
      };
      final locationId = _locationId;
      if (locationId != null && locationId.isNotEmpty) {
        body['location_id'] = locationId;
      }
      await ref.read(mobileApiRepositoryProvider).patchProperty(widget.propertyId, body);
      ref.invalidate(ownerPropertiesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing updated.')),
      );
      context.pop();
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not save listing.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUploadPhotos() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final images = await PropertyMediaUploader(
        ref.read(mobileApiRepositoryProvider),
      ).pickAndUpload(propertyId: widget.propertyId);
      if (images.isNotEmpty) {
        setState(() => _images = images);
      }
      if (!mounted) return;
      if (images.isEmpty) {
        // User cancelled picker — no snackbar.
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${images.length} photo(s) on listing.')),
      );
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not upload photos.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attachImageUrl() async {
    final url = _imageUrlCtrl.text.trim();
    if (!url.startsWith('http')) {
      setState(() => _error = 'Enter a full https image URL.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final json = await ref.read(mobileApiRepositoryProvider).attachPropertyMedia(
            widget.propertyId,
            appendImages: [url],
          );
      final prop = json['property'];
      if (prop is Map && prop['images'] is List) {
        _images = (prop['images'] as List).whereType<String>().toList();
      } else {
        _images = [..._images, url];
      }
      _imageUrlCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo attached.')),
      );
    } catch (e) {
      setState(() {
        _error = e is AppFailure ? e.message : 'Could not attach photo.';
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
        appBar: AppBar(title: const Text('Edit listing')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(
              loginLocation(from: '/landlord/listings/${widget.propertyId}/edit'),
            ),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit listing')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _neighborhoodCtrl,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              onChanged: _onNeighborhoodChanged,
              decoration: InputDecoration(
                labelText: 'Neighborhood',
                border: const OutlineInputBorder(),
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
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Neighborhood required' : null,
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _rentCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Rent (KES)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Rent required';
                if (int.tryParse(v.trim()) == null) return 'Enter a number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _depositCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Deposit (KES)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bedsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Bedrooms',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bathsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Bathrooms',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _videoCtrl,
              decoration: const InputDecoration(
                labelText: 'Walkthrough video URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
                    onSelected: (v) {
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Published (active)'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vacant'),
              value: _isVacant,
              onChanged: (v) => setState(() => _isVacant = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Photos (${_images.length})',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_images.isNotEmpty)
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _images[i],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 72,
                          height: 72,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _pickAndUploadPhotos,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Upload from gallery'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Or add photo by URL',
                hintText: 'https://…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _attachImageUrl,
              child: const Text('Attach photo URL'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditLocationSuggestion {
  const _EditLocationSuggestion({
    required this.id,
    required this.name,
    required this.subtitle,
  });

  final String id;
  final String name;
  final String subtitle;
}
