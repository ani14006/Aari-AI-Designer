import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/common/luxury_button.dart';

/// Public marketing/landing page shown to signed-out visitors before Login/Signup.
///
/// Apple-inspired refresh: full-bleed alternating sections (no max-width card wrapper around the
/// whole page) — champagne hero, near-black "How it works", champagne feature highlights, ivory
/// footer. The colour change between sections is the divider; there are no card borders/shadows
/// between them.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.champagne,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Section(
                background: Colors.transparent,
                verticalPadding: 28,
                child: _TopNav(
                  onSignIn: () => context.push('/login'),
                  onGetStarted: () => context.push('/signup'),
                ),
              ),
              _Section(
                background: AppColors.champagne,
                child: _Hero(
                  onGetStarted: () => context.push('/signup'),
                  onSignIn: () => context.push('/login'),
                ),
              ),
              _Section(
                background: AppColors.ink,
                child: Theme(
                  data:
                      Theme.of(context).copyWith(textTheme: AppTextStyles.dark),
                  child: const _HowItWorks(),
                ),
              ),
              const _Section(
                background: AppColors.champagne,
                child: _FeatureHighlights(),
              ),
              _Section(
                background: AppColors.ivory,
                topBorder: true,
                verticalPadding: 64,
                child: const _Footer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-bleed section: background colour extends edge-to-edge; content inside is centred and
/// width-capped for readability. The background colour change between sections is the only
/// divider — no borders or shadows separate them.
class _Section extends StatelessWidget {
  final Color background;
  final Widget child;
  final double? verticalPadding;
  final bool topBorder;

  const _Section({
    required this.background,
    required this.child,
    this.verticalPadding,
    this.topBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveUtils.isTabletOrWider(width);
    final hPad = isWide ? 64.0 : ResponsiveUtils.horizontalPadding(width);
    final vPad = verticalPadding ??
        (isWide ? AppConstants.spaceSection : AppConstants.spaceXxl);

    return Container(
      width: double.infinity,
      color: background,
      decoration: topBorder
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight)))
          : null,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: child,
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
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _Hero({required this.onGetStarted, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = ResponsiveUtils.isTabletOrWider(width);

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
          style: AppTextStyles.eyebrow(),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Visualise Your Embroidery\nBefore You Stitch',
            textAlign: textAlign,
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            'Upload your embroidery design, saree and blouse fabric. Our AI analyses the colours, '
            'recommends bead palettes, and generates a photorealistic preview — plus a ready-made '
            'materials shopping list — before a single stitch is made.',
            textAlign: textAlign,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
      ],
    );
  }
}

/// Decorative right-hand panel for the wide hero layout — a bordered "atelier-grade" card with a
/// palette icon, standing in for a product/mannequin photo (none exists in the repo). Carries
/// the app's one deliberate shadow, since it occupies the "product image" slot.
class _AtelierPanel extends StatelessWidget {
  const _AtelierPanel();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppTheme.photoShadow,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: const BoxDecoration(
                  color: AppColors.ink, shape: BoxShape.circle),
              child: const Icon(Icons.palette_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              'Atelier-grade palette',
              style: AppTextStyles.accentItalic(18),
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
          ),
          child: Text(
            number.toString().padLeft(2, '0'),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
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
          style: AppTextStyles.accentItalic(28),
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
                        color: AppColors.gold, fontWeight: FontWeight.w700)),
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
