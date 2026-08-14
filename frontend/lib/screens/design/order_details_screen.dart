import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/order_details.dart';
import '../../state/design_provider.dart';
import '../../widgets/common/buffer_screen.dart';
import '../../widgets/common/luxury_button.dart';
import '../../widgets/common/responsive_page.dart';

/// Order-details step: occasion, blouse fit, size, embroidery coverage, budget and style
/// preference, captured before AI colour analysis so recommendations can factor them in.
class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  String? _occasion;
  String? _silhouette;
  String _coverage = EmbroideryCoverages.medium;
  final _budgetController = TextEditingController();
  final _styleController = TextEditingController();

  final _bustController = TextEditingController();
  final _waistController = TextEditingController();
  final _shoulderController = TextEditingController();
  final _sleeveLengthController = TextEditingController();
  final _backNeckController = TextEditingController();
  final _frontNeckController = TextEditingController();

  @override
  void dispose() {
    _budgetController.dispose();
    _styleController.dispose();
    _bustController.dispose();
    _waistController.dispose();
    _shoulderController.dispose();
    _sleeveLengthController.dispose();
    _backNeckController.dispose();
    _frontNeckController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final details = OrderDetails(
      occasion: _occasion,
      blouseSilhouette: _silhouette,
      bust: double.tryParse(_bustController.text.trim()),
      waist: double.tryParse(_waistController.text.trim()),
      shoulder: double.tryParse(_shoulderController.text.trim()),
      sleeveLength: double.tryParse(_sleeveLengthController.text.trim()),
      backNeck: double.tryParse(_backNeckController.text.trim()),
      frontNeck: double.tryParse(_frontNeckController.text.trim()),
      embroideryCoverage: _coverage,
      budget: double.tryParse(_budgetController.text.trim()),
      stylePreference: _styleController.text.trim().isEmpty
          ? null
          : _styleController.text.trim(),
    );
    final notifier = ref.read(designFlowProvider.notifier);
    notifier.setOrderDetails(details);
    await notifier.runAnalysis();

    if (!mounted) return;
    final state = ref.read(designFlowProvider);
    if (state.paletteOptions.isNotEmpty) {
      context.push('/palette-selection');
    } else if (state.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.error!)));
    }
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 20),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _chipGroup(
      List<String> options, String? selected, ValueChanged<String> onSelected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: AppColors.ink.withValues(alpha: 0.18),
          side: BorderSide(
              color: isSelected ? AppColors.ink : AppColors.borderLight),
          labelStyle: TextStyle(
              color: isSelected ? AppColors.ink : null,
              fontWeight: FontWeight.w600),
        );
      }).toList(),
    );
  }

  Widget _measurementField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'e.g. 36'),
        ),
      ],
    );
  }

  Widget _measurementsGrid() {
    final fields = <(String, TextEditingController)>[
      ('Bust', _bustController),
      ('Waist', _waistController),
      ('Shoulder', _shoulderController),
      ('Sleeve length', _sleeveLengthController),
      ('Back neck', _backNeckController),
      ('Front neck', _frontNeckController),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final columns = constraints.maxWidth >= 500
            ? 3
            : (constraints.maxWidth >= 320 ? 2 : 1);
        final fieldWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: fields
              .map((f) => SizedBox(
                  width: fieldWidth, child: _measurementField(f.$1, f.$2)))
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnalyzing =
        ref.watch(designFlowProvider.select((s) => s.isAnalyzing));
    if (isAnalyzing) return const BufferScreen();

    final width = MediaQuery.sizeOf(context).width;
    final hPad = ResponsiveUtils.horizontalPadding(width);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: Breakpoints.formMaxWidth,
          child: ListView(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 20),
            children: [
              Text('Tell us about the occasion',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Optional, but it helps the AI tailor colours and materials to your budget and event.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              _sectionLabel('Occasion'),
              _chipGroup(Occasions.all, _occasion,
                  (v) => setState(() => _occasion = v)),
              _sectionLabel('Blouse Silhouette'),
              _chipGroup(BlouseSilhouettes.all, _silhouette,
                  (v) => setState(() => _silhouette = v)),
              _sectionLabel('Blouse Size (inches, optional)'),
              _measurementsGrid(),
              _sectionLabel('Embroidery Coverage'),
              _chipGroup(EmbroideryCoverages.all, _coverage,
                  (v) => setState(() => _coverage = v)),
              _sectionLabel('Materials Budget (₹, optional)'),
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: 'e.g. 5000', prefixText: '₹ '),
              ),
              _sectionLabel('Style Preference (optional)'),
              TextField(
                controller: _styleController,
                decoration: const InputDecoration(
                    hintText:
                        'e.g. minimal, temple-inspired, bold contrast...'),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.champagne,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Next, we\'ll analyse your colours and suggest 3 bead palettes to choose from.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ),
              LuxuryButton(
                label: 'Analyse Colours',
                icon: Icons.auto_awesome_rounded,
                onPressed: _handleContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
