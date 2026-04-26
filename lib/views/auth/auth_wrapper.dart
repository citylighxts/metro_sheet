import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../home/home_view.dart';
import 'login_view.dart';
import 'register_view.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) =>
      ref.watch(authStateProvider).when(
        data: (user) {
          if (user != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(ensureLocalUserProvider)(user.uid, user.email ?? '');
            });
            return const HomeView();
          }
          return _showRegister
              ? RegisterView(onGoToLogin: () => setState(() => _showRegister = false))
              : LoginView(onGoToRegister: () => setState(() => _showRegister = true));
        },
        loading: () => const Scaffold(backgroundColor: CupertinoColors.systemGroupedBackground),
        error: (err, _) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text('Auth Error', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(err.toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
}
