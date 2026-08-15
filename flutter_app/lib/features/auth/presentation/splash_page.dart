import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/utils/app_log.dart';
import 'package:nyumbasearch/features/auth/data/auth_controller.dart';
import 'package:nyumbasearch/routing/deep_links.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    setState(() => _status = 'Restoring session…');
    AppLog.i('API base ${AppConfig.mobileApiV1}');

    await ref.read(authControllerProvider.notifier).waitForHydration();

    if (!mounted) return;

    // Preserve App Link / deep link if the engine already landed on a real route.
    // When splash is the intentional boot path, continue to home.
    final loc = GoRouterState.of(context).uri;
    final mapped = DeepLinks.toAppLocation(loc);
    if (mapped != null && mapped != '/splash' && mapped != '/home') {
      setState(() => _status = 'Opening listing…');
      context.go(mapped);
      return;
    }

    setState(() => _status = 'Connected');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NyumbaSearch',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_status!, textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
