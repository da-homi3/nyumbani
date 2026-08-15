import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

final adminAdvertiseProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final json = await ref.watch(mobileApiRepositoryProvider).adminAdvertiseInquiries();
  final raw = json['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

class AdminAdvertisePage extends ConsumerWidget {
  const AdminAdvertisePage({super.key});

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    String inquiryId,
  ) async {
    try {
      final res = await ref
          .read(mobileApiRepositoryProvider)
          .adminApproveAdvertise(inquiryId: inquiryId);
      final link = res['paymentLink']?.toString();
      if (link != null && link.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: link));
      }
      ref.invalidate(adminAdvertiseProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            link == null
                ? 'Approval sent'
                : 'Approval sent — payment link copied',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is AppFailure ? e.message : '$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAdvertiseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Advertise inquiries')),
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(adminAdvertiseProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No advertising enquiries yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(NyumbaTokens.space6),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final inq = items[i];
              final meta = inq['metadata'] is Map
                  ? Map<String, dynamic>.from(inq['metadata'] as Map)
                  : <String, dynamic>{};
              final approved = meta['status'] == 'approved';
              final packageId = meta['package']?.toString() ?? 'listing_banner';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${inq['company'] ?? 'Company'} — ${inq['contact_name'] ?? ''}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Chip(
                            label: Text(approved ? 'Approved' : 'Pending'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${inq['email'] ?? 'No email'} · ${inq['phone'] ?? 'No phone'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        packageId +
                            (meta['budget'] != null
                                ? ' · Budget ${meta['budget']}'
                                : ''),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Text('${inq['message'] ?? ''}'),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: inq['email'] == null
                              ? null
                              : () => _approve(
                                    context,
                                    ref,
                                    inq['id'].toString(),
                                  ),
                          child: Text(
                            approved
                                ? 'Resend payment link'
                                : 'Approve & send payment link',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
