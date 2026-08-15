import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';
import 'package:nyumbasearch/shared/widgets/motion.dart';

class HomeTestimonial {
  const HomeTestimonial({
    required this.name,
    required this.roleLabel,
    required this.body,
    required this.rating,
  });

  final String name;
  final String roleLabel;
  final String body;
  final int rating;

  factory HomeTestimonial.fromJson(Map<String, dynamic> json) {
    return HomeTestimonial(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'NyumbaSearch user',
      roleLabel: (json['roleLabel'] as String?) ??
          (json['role_label'] as String?) ??
          'Tenant · Nairobi',
      body: (json['body'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
    );
  }
}

const kFallbackTestimonials = <HomeTestimonial>[
  HomeTestimonial(
    name: 'Faith W.',
    roleLabel: 'Tenant · Kilimani',
    body:
        'Found my 1BR in two days. The verified badge actually meant something — landlord picked up on the first call.',
    rating: 5,
  ),
  HomeTestimonial(
    name: 'Brian O.',
    roleLabel: 'Tenant · Westlands',
    body:
        'Honest reviews on water and security saved me from a place that looked perfect online. Worth its weight in gold.',
    rating: 5,
  ),
  HomeTestimonial(
    name: "Achieng' M.",
    roleLabel: 'Landlord · Lavington',
    body:
        'Filled a vacancy in 9 days, all leads pre-qualified. Way better than dealing with random WhatsApp brokers.',
    rating: 5,
  ),
];

final homeTestimonialsProvider =
    FutureProvider.autoDispose<List<HomeTestimonial>>((ref) async {
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: const {'Accept': 'application/json'},
      ),
    );
    final res = await dio.get<dynamic>('${AppConfig.apiBaseUrl}/api/testimonials');
    final decoded = res.data;
    final list = decoded is List
        ? decoded
        : (decoded is Map && decoded['items'] is List)
            ? decoded['items'] as List
            : const [];
    final parsed = list
        .whereType<Map>()
        .map((e) => HomeTestimonial.fromJson(Map<String, dynamic>.from(e)))
        .where((t) => t.body.trim().isNotEmpty)
        .toList();
    if (parsed.isNotEmpty) return parsed;
  } catch (_) {
    // Fall through to curated copy — home must never blank.
  }
  return kFallbackTestimonials;
});

/// Auto-advancing testimonial carousel (web landing TestimonialCarousel parity).
class HomeTestimonialsCarousel extends ConsumerStatefulWidget {
  const HomeTestimonialsCarousel({super.key});

  @override
  ConsumerState<HomeTestimonialsCarousel> createState() =>
      _HomeTestimonialsCarouselState();
}

class _HomeTestimonialsCarouselState
    extends ConsumerState<HomeTestimonialsCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  var _index = 0;
  var _armedFor = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _armAutoplay(int count) {
    if (count == _armedFor && _timer != null) return;
    _armedFor = count;
    _timer?.cancel();
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: NyumbaTokens.easeOutSoft,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(homeTestimonialsProvider);
    final theme = Theme.of(context);

    return async.when(
      loading: () => const SizedBox(height: 160),
      error: (_, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _armAutoplay(kFallbackTestimonials.length);
        });
        return _buildBody(theme, kFallbackTestimonials);
      },
      data: (items) {
        final list = items.isEmpty ? kFallbackTestimonials : items;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _armAutoplay(list.length);
        });
        return ScrollReveal(child: _buildBody(theme, list));
      },
    );
  }

  Widget _buildBody(ThemeData theme, List<HomeTestimonial> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FROM THE COMMUNITY',
          style: theme.textTheme.labelMedium?.copyWith(
            color: const Color(0xFF22C55E),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Trusted by renters and owners',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _controller,
            itemCount: list.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final t = list[i];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: NyumbaTokens.borderRadiusLg,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            for (var s = 0; s < t.rating.clamp(1, 5); s++)
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: NyumbaTokens.gold,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            '"${t.body}"',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          t.roleLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < list.length; i++)
              AnimatedContainer(
                duration: NyumbaTokens.durationFast,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
