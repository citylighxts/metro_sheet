import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_shared.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key, required this.onGoToLogin});
  final VoidCallback onGoToLogin;

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(registerProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted || !success) return;
    widget.onGoToLogin();
  }

  String? _validateEmail(String? v) {
    if (v?.isEmpty ?? true) return 'Email tidak boleh kosong';
    if (!v!.contains('@')) return 'Email tidak valid';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v?.isEmpty ?? true) return 'Password tidak boleh kosong';
    if (v!.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v?.isEmpty ?? true) return 'Konfirmasi password tidak boleh kosong';
    if (v != _passwordController.text) return 'Password tidak cocok';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthAppLogo(primary: primary, subtitle: 'Create your account'),
                    const SizedBox(height: 40),
                    AuthTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: CupertinoIcons.mail,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      prefixIcon: CupertinoIcons.lock,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Konfirmasi Password',
                      obscureText: true,
                      prefixIcon: CupertinoIcons.lock_shield,
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      onPressed: registerState is AsyncLoading ? null : _submit,
                      borderRadius: BorderRadius.circular(14),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: registerState is AsyncLoading
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    if (registerState is AsyncError) ...[
                      const SizedBox(height: 16),
                      AuthErrorBanner(registerState.error),
                    ],
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sudah punya akun? ', style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 14)),
                        GestureDetector(
                          onTap: widget.onGoToLogin,
                          child: Text('Sign In', style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
