import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class ProviderMeSnapshot {
  const ProviderMeSnapshot({this.provider, this.inquiries = const []});

  final Map<String, dynamic>? provider;
  final List<Map<String, dynamic>> inquiries;
}

final providerMeProvider =
    FutureProvider.autoDispose<ProviderMeSnapshot>((ref) async {
  final json = await ref.watch(mobileApiRepositoryProvider).providerMe();
  final providerRaw = json['provider'];
  final provider = providerRaw is Map
      ? Map<String, dynamic>.from(providerRaw)
      : null;
  final raw = json['inquiries'];
  final inquiries = raw is List
      ? raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList()
      : <Map<String, dynamic>>[];
  return ProviderMeSnapshot(provider: provider, inquiries: inquiries);
});

class ProviderMePage extends ConsumerStatefulWidget {
  const ProviderMePage({super.key});

  @override
  ConsumerState<ProviderMePage> createState() => _ProviderMePageState();
}

class _ProviderMePageState extends ConsumerState<ProviderMePage> {
  var _busy = false;
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _upgrade(String plan, int amountKes) async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter M-Pesa phone for checkout.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await ref.read(mobileApiRepositoryProvider).subscriptionsCheckout(
            paymentType: 'provider_subscription',
            plan: plan,
            amountKes: amountKes,
            title: 'Provider $plan',
            billingCycle: 'monthly',
            successPath: '/services/me',
            paymentMethod: 'mpesa',
            phoneNumber: phone,
          );
      if (!mounted) return;
      final msg = res['message']?.toString() ??
          res['status']?.toString() ??
          'Checkout started. Complete M-Pesa prompt.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is AppFailure ? e.message : 'Checkout failed')),
      );
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
        appBar: AppBar(title: const Text('Provider dashboard')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/services/me')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(providerMeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider dashboard'),
        actions: [
          TextButton(
            onPressed: () => context.push('/services/register'),
            child: const Text('Edit / apply'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(providerMeProvider);
          await ref.read(providerMeProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(providerMeProvider),
          builder: (snap) {
            if (snap.provider == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'No provider profile yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Register to appear in the services directory.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/services/register'),
                    child: const Text('Register'),
                  ),
                ],
              );
            }

            final p = snap.provider!;
            final name = (p['business_name'] as String?) ??
                (p['businessName'] as String?) ??
                'Provider';
            final status = (p['status'] as String?) ?? '';
            final tier = (p['tier'] as String?) ?? '';
            final phone = (p['phone'] as String?) ?? '';
            if (_phoneCtrl.text.isEmpty && phone.isNotEmpty) {
              _phoneCtrl.text = phone;
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (status.isNotEmpty) status,
                    if (tier.isNotEmpty) tier,
                    if (phone.isNotEmpty) phone,
                  ].join(' · '),
                ),
                const SizedBox(height: 20),
                Text(
                  'Upgrade listing',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'M-Pesa phone'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _busy ? null : () => _upgrade('featured', 1500),
                      child: const Text('Featured KES 1,500'),
                    ),
                    OutlinedButton(
                      onPressed: _busy ? null : () => _upgrade('premium', 2500),
                      child: const Text('Premium KES 2,500'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent inquiries',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (snap.inquiries.isEmpty)
                  const Text('No inquiries yet.')
                else
                  ...snap.inquiries.map((inq) {
                    final msg = (inq['message'] as String?) ?? 'Inquiry';
                    final created = (inq['created_at'] as String?) ??
                        (inq['createdAt'] as String?) ??
                        '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.mail_outline),
                      title: Text(msg, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: created.isEmpty ? null : Text(created),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
