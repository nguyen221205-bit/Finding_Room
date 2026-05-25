import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    late final bool ok;
    try {
      ok = await auth.login(email: _emailCtrl.text, password: _passCtrl.text);
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    if (!ok) {
      AppSnackbar.error(
        context,
        'Invalid email or password. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.select<AuthProvider, bool>(
      (AuthProvider p) => p.isLoading,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingAllLg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: AppSpacing.paddingAllLg,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Room Rental Finder',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Login to continue',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.vXl,
                        AppTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hintText: 'example@mail.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: Validators.email,
                        ),
                        AppSpacing.vMd,
                        AppTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline),
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!isLoading) _submit();
                          },
                        ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          label: 'Login',
                          icon: Icons.login,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                        ),
                        AppSpacing.vSm,
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: const Text("Don't have an account? Register"),
                        ),
                      ],
                    ),
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
