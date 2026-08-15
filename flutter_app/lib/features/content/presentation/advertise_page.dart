import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

class AdvertisePage extends ConsumerStatefulWidget {
  const AdvertisePage({super.key});

  @override
  ConsumerState<AdvertisePage> createState() => _AdvertisePageState();
}

class _AdvertisePageState extends ConsumerState<AdvertisePage> {
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  String? _packageId;
  var _busy = false;
  var _done = false;

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pkg = _packageId;
    if (pkg == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(mobileApiRepositoryProvider).submitAdvertiseInquiry(
            name: _name.text.trim(),
            company: _company.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            packageId: pkg,
            message: _message.text.trim(),
          );
      setState(() => _done = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(advertisePackagesProvider);
    if (_done) {
      return Scaffold(
        appBar: AppBar(title: const Text('Advertise')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Enquiry received — check your email for confirmation. We will reply within 24 hours.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertise'),
        actions: [
          TextButton(
            onPressed: () => context.pushAdvertisePay(),
            child: const Text('Pay'),
          ),
        ],
      ),
      body: packagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          return ListView(
            padding: const EdgeInsets.all(NyumbaTokens.space6),
            children: [
              Text(
                'Promote on NyumbaSearch',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ...items.map((p) {
                final id = '${p['id']}';
                final selected = _packageId == id;
                return Card(
                  child: ListTile(
                    selected: selected,
                    title: Text('${p['name']}'),
                    subtitle: Text('KES ${p['priceKes']}'),
                    onTap: () => setState(() => _packageId = id),
                    trailing: selected ? const Icon(Icons.check_circle) : null,
                  ),
                );
              }),
              const SizedBox(height: 16),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _company, decoration: const InputDecoration(labelText: 'Company')),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(
                controller: _message,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || _packageId == null ? null : _submit,
                child: const Text('Send inquiry'),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension on BuildContext {
  void pushAdvertisePay() {
    // Opens website pay flow with package selection when email approval link is not used.
    launchUrl(
      Uri.parse('https://nyumbasearch.com/advertise/pay'),
      mode: LaunchMode.externalApplication,
    );
  }
}

final advertisePackagesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(mobileApiRepositoryProvider).advertisePackages();
  final items = res['items'];
  if (items is List) {
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return const [];
});
