import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

class AdminAnnouncementsPage extends ConsumerStatefulWidget {
  const AdminAnnouncementsPage({super.key});

  @override
  ConsumerState<AdminAnnouncementsPage> createState() =>
      _AdminAnnouncementsPageState();
}

class _AdminAnnouncementsPageState
    extends ConsumerState<AdminAnnouncementsPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _ctaLabel = TextEditingController(text: 'Learn more');
  final _ctaUrl = TextEditingController(text: 'https://nyumbasearch.com');
  final _roles = <String>{'all'};
  var _busy = false;

  static const _roleOptions = [
    ('all', 'All users'),
    ('tenant', 'Tenants'),
    ('landlord', 'Landlords'),
    ('agency', 'Agencies'),
    ('manager', 'Property managers'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _ctaLabel.dispose();
    _ctaUrl.dispose();
    super.dispose();
  }

  void _toggleRole(String id) {
    setState(() {
      if (id == 'all') {
        _roles
          ..clear()
          ..add('all');
        return;
      }
      _roles.remove('all');
      if (!_roles.add(id)) _roles.remove(id);
      if (_roles.isEmpty) _roles.add('all');
    });
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.length < 3 || body.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await ref.read(mobileApiRepositoryProvider).adminSendAnnouncement(
            title: title,
            body: body,
            ctaLabel: _ctaLabel.text.trim().isEmpty ? 'Learn more' : _ctaLabel.text.trim(),
            ctaUrl: _ctaUrl.text.trim().isEmpty
                ? 'https://nyumbasearch.com'
                : _ctaUrl.text.trim(),
            targetRoles: _roles.toList(),
          );
      if (!mounted) return;
      final sent = res['sent'] ?? 0;
      final skipped = res['skipped'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent to $sent users ($skipped skipped)')),
      );
      _title.clear();
      _body.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is AppFailure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: ListView(
        padding: const EdgeInsets.all(NyumbaTokens.space6),
        children: [
          Text(
            'Send a product update email to opted-in users. Transactional emails are unaffected.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctaLabel,
            decoration: const InputDecoration(labelText: 'CTA label'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctaUrl,
            decoration: const InputDecoration(labelText: 'CTA URL'),
          ),
          const SizedBox(height: 16),
          Text('Audience', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (id, label) in _roleOptions)
                FilterChip(
                  label: Text(label),
                  selected: _roles.contains(id),
                  onSelected: (_) => _toggleRole(id),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: Text(_busy ? 'Sending…' : 'Send announcement'),
          ),
        ],
      ),
    );
  }
}
