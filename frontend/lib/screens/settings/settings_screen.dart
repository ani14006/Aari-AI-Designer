import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';
import '../../widgets/common/luxury_card.dart';
import '../../widgets/common/responsive_page.dart';

const _languages = {
  'en': 'English',
  'ta': 'தமிழ் (Tamil)',
  'hi': 'हिन्दी (Hindi)'
};

/// Feature: Dark Mode, Language, Notifications, Profile.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final hPad =
        ResponsiveUtils.horizontalPadding(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: Breakpoints.formMaxWidth,
          child: ListView(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 110),
            children: [
              userAsync.when(
                loading: () => const SizedBox(height: 72),
                error: (_, __) => const SizedBox.shrink(),
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return LuxuryCard(
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      AppColors.ink.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                  spreadRadius: -4),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.champagne,
                            backgroundImage: user.photoUrl.isNotEmpty
                                ? NetworkImage(user.photoUrl)
                                : null,
                            child: user.photoUrl.isEmpty
                                ? Text(
                                    (user.displayName.isNotEmpty
                                            ? user.displayName[0]
                                            : user.email[0])
                                        .toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName
                                    : 'Aari Designer',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(user.email,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text('Preferences',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              LuxuryCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .setDarkMode(value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Notifications'),
                      secondary: const Icon(Icons.notifications_none_rounded),
                      value: settings.notificationsEnabled,
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .setNotificationsEnabled(value),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.language_rounded),
                      title: const Text('Language'),
                      trailing: DropdownButton<String>(
                        value: settings.language,
                        underline: const SizedBox.shrink(),
                        items: _languages.entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .setLanguage(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LuxuryCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Container(
                    height: 36,
                    width: 36,
                    decoration: const BoxDecoration(
                        color: AppColors.ink, shape: BoxShape.circle),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: Colors.white, size: 18),
                  ),
                  title: const Text('My Cart'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/cart'),
                ),
              ),
              const SizedBox(height: 20),
              LuxuryCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 18),
                  ),
                  title: const Text('Sign Out',
                      style: TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
