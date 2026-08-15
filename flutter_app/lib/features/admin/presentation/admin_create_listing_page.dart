import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';

class AdminCreateListingPage extends ConsumerStatefulWidget {
  const AdminCreateListingPage({super.key});

  @override
  ConsumerState<AdminCreateListingPage> createState() =>
      _AdminCreateListingPageState();
}

class _AdminCreateListingPageState
    extends ConsumerState<AdminCreateListingPage> {
  final _titleCtrl = TextEditingController();
  final _hoodCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _hoodCtrl.dispose();
    _rentCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rent = int.tryParse(_rentCtrl.text.trim());
    setState(() => _busy = true);
    try {
      await ref.read(mobileApiRepositoryProvider).adminCreateProperty({
        'title': _titleCtrl.text.trim(),
        'neighborhood': _hoodCtrl.text.trim(),
        'rentKes': rent,
        'contactName': _contactNameCtrl.text.trim(),
        'contactPhone': _contactPhoneCtrl.text.trim(),
        'propertyType': 'apartment',
        'isActive': true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is AppFailure ? e.message : 'Failed')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create listing')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () =>
                context.push(loginLocation(from: '/admin/listings/new')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create listing')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hoodCtrl,
            decoration: const InputDecoration(labelText: 'Neighborhood'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rentCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Rent (KES)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactNameCtrl,
            decoration: const InputDecoration(labelText: 'Contact name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact phone'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Saving…' : 'Create'),
          ),
        ],
      ),
    );
  }
}
