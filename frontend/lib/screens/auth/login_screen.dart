import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common/auth_header.dart';
import '../../widgets/common/decorative_background.dart';
import '../../widgets/common/luxury_button.dart';
import '../../widgets/common/luxury_card.dart';
import '../../widgets/common/or_divider.dart';
import '../../widgets/common/responsive_page.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    await ref.read(authControllerProvider.notifier).signInWithEmail(
        _emailController.text.trim(), _passwordController.text);
    final state = ref.read(authControllerProvider);
    if (state.hasError && mounted) {
      setState(() => _errorMessage = readableApiError(state.error as Object));
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _errorMessage = null);
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    final state = ref.read(authControllerProvider);
    if (state.hasError && mounted) {
      setState(() => _errorMessage = readableApiError(state.error as Object));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: DecorativeBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: ResponsivePage(
              maxWidth: Breakpoints.authMaxWidth,
              child: Column(
                children: [
                  const AuthHeader(
                    icon: Icons.auto_awesome_rounded,
                    eyebrow: 'AARI AI DESIGNER',
                    title: 'Welcome Back',
                    subtitle:
                        'Sign in to continue designing your dream blouse.',
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.length < 6)
                                    ? 'Password must be at least 6 characters'
                                    : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(_errorMessage!,
                                style: const TextStyle(color: AppColors.error)),
                          ],
                          const SizedBox(height: 8),
                          LuxuryButton(
                              label: 'Sign In',
                              isLoading: isLoading,
                              onPressed: _submit),
                          const SizedBox(height: 22),
                          const OrDivider(),
                          const SizedBox(height: 22),
                          LuxuryButton(
                            label: 'Continue with Google',
                            variant: LuxuryButtonVariant.outline,
                            icon: Icons.g_mobiledata_rounded,
                            onPressed: isLoading ? null : _submitGoogle,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 420.ms, duration: 450.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?",
                          style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 520.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
