import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final referralsMeProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(mobileApiRepositoryProvider).referralsMe();
});

class ReferralsPage extends ConsumerWidget {
  const ReferralsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Referrals')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/referrals')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final async = ref.watch(referralsMeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(referralsMeProvider);
          await ref.read(referralsMeProvider.future);
        },
        child: AsyncScaffoldBody(
          async: async,
          onRetry: () => ref.invalidate(referralsMeProvider),
          builder: (json) {
            final code = (json['referralCode'] as String?) ?? '';
            final pending = (json['pendingCount'] as num?)?.toInt() ?? 0;
            final converted = (json['convertedCount'] as num?)?.toInt() ?? 0;
            final rewards = (json['totalRewardsSummary'] as String?) ?? '—';
            final raw = json['referrals'];
            final referrals = raw is List
                ? raw
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : <Map<String, dynamic>>[];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Your referral code',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        code.isEmpty ? '—' : code,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (code.isNotEmpty)
                      IconButton(
                        tooltip: 'Copy',
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied')),
                            );
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Pending: $pending · Converted: $converted'),
                const SizedBox(height: 4),
                Text('Rewards: $rewards'),
                const SizedBox(height: 24),
                Text(
                  'Referrals',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (referrals.isEmpty)
                  const Text('No referrals yet. Share your code to get started.')
                else
                  ...referrals.map((r) {
                    final name = (r['referredName'] as String?) ?? 'User';
                    final status = (r['status'] as String?) ?? '';
                    final role = (r['referredRole'] as String?) ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: Text(name),
                      subtitle: Text(
                        [
                          if (role.isNotEmpty) role,
                          if (status.isNotEmpty) status,
                        ].join(' · '),
                      ),
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
