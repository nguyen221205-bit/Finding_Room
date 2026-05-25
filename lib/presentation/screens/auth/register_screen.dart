import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _confirmValidator(String? value) {
    final String? required = Validators.requiredField(
      value,
      label: 'Confirm password',
    );
    if (required != null) return required;
    if (value != _passCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    late final bool ok;
    try {
      ok = await auth.register(
        username: _usernameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    if (!ok) {
      AppSnackbar.error(
        context,
        'Could not create account. Email may already exist.',
      );
      return;
    }

    AppSnackbar.success(context, 'Account created. Please log in.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.select<AuthProvider, bool>(
      (AuthProvider p) => p.isLoading,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingAllLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingAllLg,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      AppTextField(
                        controller: _usernameCtrl,
                        label: 'Username',
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (String? v) =>
                            Validators.requiredField(v, label: 'Username'),
                      ),
                      AppSpacing.vMd,
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
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
                      ),
                      AppSpacing.vMd,
                      AppTextField(
                        controller: _confirmCtrl,
                        label: 'Confirm password',
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: _confirmValidator,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!isLoading) _submit();
                        },
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'Create account',
                        icon: Icons.person_add_alt_1,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _submit,
                      ),
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
