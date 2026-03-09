import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _prefsKey = 'has_seen_onboarding';

  final PageController _pageController = PageController();
  int _pageIndex = 0;
  bool _isFinishing = false;
  bool _isChecking = true;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon: Icons.home_rounded,
      title: 'Добро пожаловать в Chronolink',
      description:
      'Здесь ты можешь быстро держать под контролем день, неделю и месяц без перегруза.',
    ),
    _OnboardingPageData(
      icon: Icons.add_circle_outline_rounded,
      title: 'Добавляй события за пару секунд',
      description:
      'Нажимай на “+”, создавай событие и сразу ставь напоминание на удобное время.',
    ),
    _OnboardingPageData(
      icon: Icons.notifications_active_outlined,
      title: 'Не забывай о важном',
      description:
      'Chronolink подскажет, когда пора собираться, начинать встречу или переходить к делу.',
    ),
    _OnboardingPageData(
      icon: Icons.calendar_month_outlined,
      title: 'Выбирай удобный режим',
      description:
      'Смотри задачи по дням, планируй неделю и держи месяц перед глазами.',
    ),
  ];

  bool get _isLastPage => _pageIndex == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _checkOnboardingState();
  }

  Future<void> _checkOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_prefsKey) ?? false;

    if (!mounted) return;

    if (hasSeen) {
      context.go(AppRoute.home);
      return;
    }

    setState(() {
      _isChecking = false;
    });
  }

  Future<void> _finish() async {
    if (_isFinishing) return;

    setState(() {
      _isFinishing = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);

    if (!mounted) return;
    context.go(AppRoute.home);
  }

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() {
    _finish();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _isFinishing ? null : _skip,
                    child: const Text('Пропустить'),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 132,
                            height: 132,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              page.icon,
                              size: 62,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            page.title,
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            page.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _pageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _pageIndex == index
                          ? AppColors.primary
                          : AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isFinishing ? null : _next,
                  child: _isFinishing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(_isLastPage ? 'Начать' : 'Далее'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}