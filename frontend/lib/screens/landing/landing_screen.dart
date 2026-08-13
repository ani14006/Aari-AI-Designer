import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/common/decorative_background.dart';
import '../../widgets/common/embroidery_motif.dart';
import '../../widgets/common/luxury_button.dart';

/// Public marketing/landing page shown to signed-out visitors before Login/Signup — modelled on
/// the reference layout: top nav (logo + Sign in/Get Started), a hero pitch, a "How it works"
/// 3-step explainer, a feature-highlights bullet list, and a footer.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveUtils.isTabletOrWider(width);
    final hPad = ResponsiveUtils.horizontalPadding(width);

    return Scaffold(
      body: DecorativeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 960 : 680),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopNav(
                        onSignIn: () => context.push('/login'),
                        onGetStarted: () => context.push('/signup'),
                      ),
                      const SizedBox(height: 48),
                      _Hero(
                        isWide: isWide,
                        onGetStarted: () => context.push('/signup'),
                        onSignIn: () => context.push('/login'),
                      ),
                      const SizedBox(height: 64),
                      const _HowItWorks(),
                      const SizedBox(height: 56),
                      const _FeatureHighlights(),
                      const SizedBox(height: 48),
                      const _Footer(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onGetStarted;

  const _TopNav({required this.onSignIn, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Aari AI Designer',
            style: Theme.of(context).textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(onPressed: onSignIn, child: const Text('Sign in')),
        const SizedBox(width: 4),
        LuxuryButton(
          label: 'Get Started',
          fullWidth: false,
          onPressed: onGetStarted,
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final bool isWide;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _Hero(
      {required this.isWide,
      required this.onGetStarted,
      required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final content = isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  flex: 6,
                  child: _HeroText(
                      isWide: true,
                      onGetStarted: onGetStarted,
                      onSignIn: onSignIn)),
              const SizedBox(width: 40),
              const Expanded(flex: 5, child: _AtelierPanel()),
            ],
          )
        : _HeroText(
            isWide: false, onGetStarted: onGetStarted, onSignIn: onSignIn);

    return content
        .animate()
        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

class _HeroText extends StatelessWidget {
  final bool isWide;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _HeroText(
      {required this.isWide,
      required this.onGetStarted,
      required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final align = isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = isWide ? TextAlign.left : TextAlign.center;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          'AI-POWERED AARI EMBROIDERY DESIGN',
          textAlign: textAlign,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
                color: AppColors.antiqueGold,
              ),
        ),
        const SizedBox(height: 14),
        Text(
          'Visualise Your Embroidery\nBefore You Stitch',
          textAlign: textAlign,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Upload your embroidery design, saree and blouse fabric. Our AI analyses the colours, '
          'recommends bead palettes, and generates a photorealistic preview — plus a ready-made '
          'materials shopping list — before a single stitch is made.',
          textAlign: textAlign,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            LuxuryButton(
              label: 'Start Colour Recommendation',
              icon: Icons.auto_awesome_rounded,
              fullWidth: false,
              onPressed: onGetStarted,
            ),
            LuxuryButton(
              label: 'Sign In',
              variant: LuxuryButtonVariant.outline,
              fullWidth: false,
              onPressed: onSignIn,
            ),
          ],
        ),
        if (!isWide) ...[
          const SizedBox(height: 32),
          const Center(child: EmbroideryMotif(size: 110, opacity: 0.6)),
        ],
      ],
    );
  }
}

/// Decorative right-hand panel for the wide hero layout — a bordered "atelier-grade" card with a
/// palette icon, mirroring the reference site's decorative preview panel. No image asset exists,
/// so this is built from shapes/icon + caption only.
class _AtelierPanel extends StatelessWidget {
  const _AtelierPanel();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.champagne,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: AppTheme.softShadow(context, strength: 0.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: const BoxDecoration(
                  gradient: AppColors.goldGradient, shape: BoxShape.circle),
              child: const Icon(Icons.palette_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              'Atelier-grade palette',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    (
      'Upload Your Inspiration',
      'Add your embroidery design, saree, and blouse fabric — photos or colours, whatever you have on hand.',
    ),
    (
      'Get AI Colour Palettes',
      'Our AI analyses your fabrics and recommends three bead palettes, each labelled by colour theory.',
    ),
    (
      'Preview & Shop Materials',
      'See a photorealistic preview on your blouse, then get an itemised materials list with cost estimates.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How It Works', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        for (final entry in _steps.asMap().entries) ...[
          if (entry.key > 0) const SizedBox(height: 20),
          _StepTile(
                  number: entry.key + 1,
                  title: entry.value.$1,
                  description: entry.value.$2)
              .animate(delay: (100 * entry.key).ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
        ],
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const _StepTile(
      {required this.number, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 1.4),
            color: isDark ? AppColors.cardDark : AppColors.champagne,
          ),
          child: Text(
            number.toString().padLeft(2, '0'),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.antiqueGold,
                fontSize: 13),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureHighlights extends StatelessWidget {
  const _FeatureHighlights();

  static const _features = [
    (
      '3 curated palettes',
      'Complementary, analogous and triadic colour schemes — not just one guess.'
    ),
    (
      'Photorealistic previews',
      'See your saree, blouse and embroidery combined before a single stitch.'
    ),
    (
      'Material-accurate shopping lists',
      'Beads, zari, silk thread, stones and kundan, sized to your blouse.'
    ),
    (
      'Budget-aware recommendations',
      'Tell us your budget and coverage level; materials scale to fit.'
    ),
    (
      'Share in one tap',
      'A ready-made WhatsApp message with your design, materials and cost.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Designer logic, not guesswork',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 20),
        for (final feature in _features)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('◆ ',
                    style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700)),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: '${feature.$1} — ',
                            style: Theme.of(context).textTheme.titleSmall),
                        TextSpan(
                            text: feature.$2,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          '© 2026 Aari AI Designer',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Made with care for Aari embroidery lovers.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
