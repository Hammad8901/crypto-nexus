import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/mock_data.dart';
import '../services/crypto_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/live_ticker.dart';
import 'portfolio_screen.dart';
import 'markets_screen.dart';
import 'ai_oracle_screen.dart';
import 'news_screen.dart';

/// Responsive wrapper: uses side-nav on wide screens (web/tablet),
/// bottom-nav on narrow screens (mobile).
class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({super.key});

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  int _index = 0;
  int _prevIndex = 0;

  static const _screens = [
    PortfolioScreen(),
    MarketsScreen(),
    AiOracleScreen(),
    NewsScreen(),
  ];

  void _navigate(int i) {
    if (i == _index) return;
    setState(() {
      _prevIndex = _index;
      _index = i;
    });
    // Start WebSocket on first use
    CryptoService().connectPriceWebSocket();
  }

  @override
  void initState() {
    super.initState();
    CryptoService().connectPriceWebSocket();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return AnimatedMeshBackground(
      child: isWide
          ? _WebLayout(index: _index, onNav: _navigate, screens: _screens)
          : _MobileLayout(index: _index, onNav: _navigate, screens: _screens),
    );
  }
}

class _WebLayout extends StatelessWidget {
  final int index;
  final ValueChanged<int> onNav;
  final List<Widget> screens;

  static const _navItems = [
    (Icons.account_balance_wallet_rounded, 'Portfolio'),
    (Icons.candlestick_chart_rounded, 'Markets'),
    (Icons.auto_awesome_rounded, 'AI Oracle'),
    (Icons.newspaper_rounded, 'News'),
  ];

  const _WebLayout({required this.index, required this.onNav, required this.screens});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // Side navigation
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(colors: [AppColors.primary, AppColors.secondary]),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12)],
                        ),
                        child: const Center(child: Text('CN', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900))),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CRYPTO', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          Text('NEXUS', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Nav items
                ...List.generate(_navItems.length, (i) {
                  final (icon, label) = _navItems[i];
                  final isActive = i == index;
                  return GestureDetector(
                    onTap: () => onNav(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primaryDim : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: isActive ? AppColors.primary : AppColors.textTertiary, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: TextStyle(
                              color: isActive ? AppColors.primary : AppColors.textTertiary,
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Status bar
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.positiveDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.positive.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.positive, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Models', style: TextStyle(color: AppColors.positive, fontSize: 10, fontWeight: FontWeight.w700)),
                          Text('All 4 active', style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Live price ticker bar
                LivePriceTicker(assets: mockCryptos),
                // Screen content with animated transitions
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(index),
                          child: screens[index],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final int index;
  final ValueChanged<int> onNav;
  final List<Widget> screens;

  static const _navItems = [
    (Icons.account_balance_wallet_rounded, 'Portfolio'),
    (Icons.candlestick_chart_rounded, 'Markets'),
    (Icons.auto_awesome_rounded, 'AI Oracle'),
    (Icons.newspaper_rounded, 'News'),
  ];

  const _MobileLayout({required this.index, required this.onNav, required this.screens});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          LivePriceTicker(assets: mockCryptos),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(index), child: screens[index]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final (icon, label) = _navItems[i];
                final isActive = i == index;
                return GestureDetector(
                  onTap: () => onNav(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryDim : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: isActive ? AppColors.primary : AppColors.textTertiary, size: 22),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: TextStyle(
                            color: isActive ? AppColors.primary : AppColors.textTertiary,
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
