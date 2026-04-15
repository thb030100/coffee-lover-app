import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../home/home_shell.dart';
import '../onboarding/preferences_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SignInScreen();

    final prefsAsync = ref.watch(userPreferencesProvider);
    return prefsAsync.when(
      data: (prefs) {
        if (prefs == null) {
          // First sign-in — onboard the user.
          return PreferencesScreen(
            onComplete: () => ref.invalidate(userPreferencesProvider),
          );
        }
        return const HomeShell();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const HomeShell(), // fail open — let them use the app
    );
  }
}
