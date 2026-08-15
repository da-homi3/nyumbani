import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/features/landlord/presentation/my_listings_page.dart';
import 'package:nyumbasearch/features/properties/presentation/contact_unlock_card.dart'
    show isKenyanMpesaPhone;
import 'package:nyumbasearch/features/subscriptions/data/subscriptions_repository.dart';
import 'package:nyumbasearch/routing/auth_nav.dart';
import 'package:nyumbasearch/shared/widgets/async_body.dart';

class BoostPage extends ConsumerStatefulWidget {
  const BoostPage({super.key, this.initialPropertyId});

  final String? initialPropertyId;

  @override
  ConsumerState<BoostPage> createState() => _BoostPageState();
}

class _BoostPageState extends ConsumerState<BoostPage> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  var _busy = false;
  String? _localError;
  String? _propertyId;
  String? _packageId;

  @override
  void initState() {
    super.initState();
    _propertyId = widget.initialPropertyId;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay(BoostPackageOffer pkg, {required String method}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      context.push(loginLocation(from: '/landlord/boost'));
      return;
    }

    final propertyId = _propertyId ??
        ref.read(ownerPropertiesProvider).valueOrNull?.firstOrNull?.id;
    if (propertyId == null || propertyId.isEmpty) {
      setState(() => _localError = 'Select a listing to boost.');
      return;
    }

    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (method == 'mpesa' && !isKenyanMpesaPhone(phone)) {
      setState(() => _localError = 'Enter a valid Kenyan M-Pesa number.');
      return;
    }

    setState(() {
      _busy = true;
      _localError = null;
      _packageId = pkg.id;
    });

    try {
      final key =
          'boost-$method-${pkg.id}-$propertyId-${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref.read(subscriptionsRepositoryProvider).checkoutBoost(
            propertyId: propertyId,
            boostPackage: pkg.id,
            packageName: pkg.name,
            amountKes: pkg.priceKes,
            paymentMethod: method,
            phoneNumber: phone,
            email: email.isEmpty ? null : email,
            idempotencyKey: key.length > 64 ? key.substring(0, 64) : key,
          );

      if (result.isCompleted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pkg.name} boost is active.')),
          );
        }
        return;
      }

      if (method == 'card' && result.hasCardRedirect) {
        final uri = Uri.tryParse(result.redirectUrl!);
        if (uri == null) {
          setState(() => _localError = 'Invalid card checkout URL.');
          return;
        }
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened) {
          setState(() => _localError = 'Could not open Pesapal checkout.');
          return;
        }
      }

      final paymentId = result.paymentId;
      if (paymentId == null || paymentId.isEmpty) {
        setState(() => _localError = result.message ?? 'Payment did not start.');
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waiting for payment confirmation…')),
        );
      }

      final polled =
          await ref.read(subscriptionsRepositoryProvider).waitForPayment(paymentId);
      if (!mounted) return;
      if (polled.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pkg.name} boost is active.')),
        );
      } else if (polled.isFailed) {
        setState(() => _localError = polled.message);
      } else {
        setState(() => _localError = 'Payment still pending. Check Billing shortly.');
      }
    } catch (e) {
      setState(() {
        _localError = e is AppFailure ? e.message : 'Checkout failed. Try again.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final listings = ref.watch(ownerPropertiesProvider);
    final catalog = ref.watch(revenueCatalogProvider);
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boost listing')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () => context.push(loginLocation(from: '/landlord/boost')),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Boost listing')),
      body: AsyncScaffoldBody(
        async: catalog,
        onRetry: () => ref.invalidate(revenueCatalogProvider),
        builder: (rev) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Choose a listing',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              AsyncScaffoldBody(
                async: listings,
                onRetry: () => ref.invalidate(ownerPropertiesProvider),
                builder: (items) {
                  if (items.isEmpty) {
                    return Text(
                      'No listings yet. Create one first.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  final selectedId = items.any((p) => p.id == _propertyId)
                      ? _propertyId!
                      : items.first.id;
                  return DropdownButtonFormField<String>(
                    initialValue: selectedId,
                    items: items
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.title, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _propertyId = v),
                    decoration: const InputDecoration(labelText: 'Listing'),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'M-Pesa phone',
                  hintText: '07XX XXX XXX',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (card receipt, optional)',
                ),
              ),
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Text(_localError!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 20),
              ...rev.boostPackages.map((pkg) {
                final selected = _packageId == pkg.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            pkg.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('KES ${pkg.priceKes} · ${pkg.durationDays} days'),
                          if (pkg.placement.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(pkg.placement),
                          ],
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _pay(pkg, method: 'mpesa'),
                            child: Text('Pay M-Pesa · KES ${pkg.priceKes}'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _pay(pkg, method: 'card'),
                            child: const Text('Pay with card'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
