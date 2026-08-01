import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common/auth_header.dart';
import '../../widgets/common/decorative_background.dart';
import '../../widgets/common/luxury_button.dart';
import '../../widgets/common/luxury_card.dart';
import '../../widgets/common/responsive_page.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text.trim());
    final state = ref.read(authControllerProvider);
    if (state.hasError && mounted) {
      setState(() => _errorMessage =
          state.error.toString().replaceFirst('Exception: ', ''));
    } else if (mounted) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: DecorativeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: ResponsivePage(
              maxWidth: Breakpoints.authMaxWidth,
              child: Column(
                children: [
                  const AuthHeader(
                    icon: Icons.key_rounded,
                    eyebrow: 'ACCOUNT RECOVERY',
                    title: 'Reset Password',
                    subtitle:
                        'Enter your email and we will send you a link to reset your password.',
                  ),
                  const SizedBox(height: 32),
                  LuxuryCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded)),
                            validator: (value) =>
                                (value == null || !value.contains('@'))
                                    ? 'Enter a valid email'
                                    : null,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(_errorMessage!,
                                style: const TextStyle(color: AppColors.error)),
                          ],
                          if (_sent) ...[
                            const SizedBox(height: 12),
                            const Text(
                                'Password reset email sent. Check your inbox.',
                                style: TextStyle(color: AppColors.success)),
                          ],
                          const SizedBox(height: 20),
                          LuxuryButton(
                              label: 'Send Reset Link',
                              isLoading: isLoading,
                              onPressed: _submit),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 420.ms, duration: 450.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
