import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/services/preferences_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  late final List<_Slide> _slides;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    _slides = isTr
        ? const [
            _Slide(
              icon: Icons.wb_sunny_outlined,
              title: 'Bugüne odaklan',
              body:
                  'Günüm listesi her sabah tertemiz başlar. Buraya bugün için önemli görevlerini ekle.',
            ),
            _Slide(
              icon: Icons.swipe_rounded,
              title: 'Hızlıca işle',
              body:
                  'Görevi sağa kaydır → tamamla. Sola kaydır → Günüme ekle ya da çıkar.',
            ),
            _Slide(
              icon: Icons.cloud_done_outlined,
              title: 'Her cihazda senkron',
              body:
                  'Görevlerin tüm cihazların arasında otomatik eşitlenir, çevrimdışı bile çalışır.',
            ),
          ]
        : const [
            _Slide(
              icon: Icons.wb_sunny_outlined,
              title: 'Focus on today',
              body:
                  'My Day starts fresh every morning. Add what matters most today.',
            ),
            _Slide(
              icon: Icons.swipe_rounded,
              title: 'Swipe to act',
              body:
                  'Swipe right to complete. Swipe left to add or remove from My Day.',
            ),
            _Slide(
              icon: Icons.cloud_done_outlined,
              title: 'Synced everywhere',
              body:
                  'Tasks sync via Firebase across your devices and work offline too.',
            ),
          ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    } else {
      ref.read(onboardingSeenProvider.notifier).markSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _index == _slides.length - 1;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/branding/estodo_uzun.svg',
                    height: 28,
                    placeholderBuilder: (_) => const SizedBox(height: 28),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        ref.read(onboardingSeenProvider.notifier).markSeen(),
                    child: Text(isTr ? 'Atla' : 'Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon,
                              size: 64, color: scheme.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: _index == i ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _index == i
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _next,
                child: Text(
                  isLast
                      ? (isTr ? 'Hadi başlayalım' : 'Get started')
                      : (isTr ? 'İleri' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
