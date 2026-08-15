import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nyumbasearch/core/network/mobile_api_repository.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class ServiceProviderItem {
  const ServiceProviderItem({
    required this.id,
    required this.name,
    this.category,
    this.neighborhood,
    this.description,
    this.phone,
    this.verified = false,
  });

  final String id;
  final String name;
  final String? category;
  final String? neighborhood;
  final String? description;
  final String? phone;
  final bool verified;

  factory ServiceProviderItem.fromJson(Map<String, dynamic> json) {
    String? category;
    final cats = json['categories'];
    if (cats is List && cats.isNotEmpty) {
      category = cats.first.toString();
    }
    category ??= (json['category'] as String?) ?? (json['service_category'] as String?);

    String? neighborhood;
    final areas = json['areasServed'] ?? json['areas_served'];
    if (areas is List && areas.isNotEmpty) {
      neighborhood = areas.first.toString();
    }
    neighborhood ??=
        (json['neighborhood'] as String?) ?? (json['location'] as String?);

    return ServiceProviderItem(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?) ??
          (json['businessName'] as String?) ??
          (json['business_name'] as String?) ??
          (json['full_name'] as String?) ??
          'Provider',
      category: category,
      neighborhood: neighborhood,
      description: json['description'] as String?,
      phone: (json['phone'] as String?) ?? (json['contact_phone'] as String?),
      verified: json['verified'] == true || json['is_verified'] == true,
    );
  }
}

final providerDetailProvider =
    FutureProvider.autoDispose.family<ServiceProviderItem?, String>((ref, id) async {
  final json = await ref.watch(mobileApiRepositoryProvider).providerDetail(id);
  final raw = json['provider'] ?? json['data'] ?? json;
  if (raw is! Map) return null;
  final item = ServiceProviderItem.fromJson(Map<String, dynamic>.from(raw));
  return item.id.isEmpty ? null : item;
});

class ProviderDetailPage extends ConsumerWidget {
  const ProviderDetailPage({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(providerDetailProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Provider')),
      body: AsyncScaffoldBody(
        async: async,
        onRetry: () => ref.invalidate(providerDetailProvider(providerId)),
        builder: (provider) {
          if (provider == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Provider not found.',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                provider.name,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (provider.verified) ...[
                const SizedBox(height: 8),
                const Chip(
                  avatar: Icon(Icons.verified, size: 18),
                  label: Text('Verified'),
                ),
              ],
              if (provider.category != null && provider.category!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(provider.category!, style: theme.textTheme.titleSmall),
              ],
              if (provider.neighborhood != null &&
                  provider.neighborhood!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  provider.neighborhood!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (provider.description != null &&
                  provider.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(provider.description!),
              ],
              if (provider.phone != null && provider.phone!.isNotEmpty) ...[
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(provider.phone!),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final uri = Uri(scheme: 'tel', path: provider.phone);
                          await launchUrl(uri);
                        },
                        icon: const Icon(Icons.call),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final digits = provider.phone!
                              .replaceAll(RegExp(r'[^\d+]'), '');
                          final uri = Uri.parse('https://wa.me/$digits');
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
