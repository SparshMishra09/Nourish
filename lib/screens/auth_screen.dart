import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/brand_mark.dart';
import '../widgets/google_auth_button.dart';
import '../widgets/shared_ui.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await widget.authService.createAccount(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await widget.authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (error) {
      if (mounted) showAppMessage(context, AuthService.friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _googleLoading = true;
    });
    try {
      await widget.authService.signInWithGoogle();
    } catch (error) {
      if (mounted) showAppMessage(context, AuthService.friendlyError(error));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _googleLoading = false;
        });
      }
    }
  }

  Future<void> _showResetDialog() async {
    final controller = TextEditingController(text: _emailController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty) return;
    try {
      await widget.authService.sendPasswordReset(email);
      if (mounted) showAppMessage(context, 'Password reset email sent.');
    } catch (error) {
      if (mounted) showAppMessage(context, AuthService.friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.ink,
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandMark(dark: true),
                      const SizedBox(height: 36),
                      Text(
                        _isSignUp
                            ? 'Your healthiest\nrhythm starts here.'
                            : 'Welcome back.\nLet’s feel better.',
                        style: context.text.displayLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        'Smart meals. Practical workouts. One plan shaped around your life.',
                        style: context.text.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.62),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppPalette.canvas,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 32,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _ModeSwitcher(
                              isSignUp: _isSignUp,
                              onChanged: (value) => setState(() {
                                _isSignUp = value;
                                _formKey.currentState?.reset();
                              }),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                22,
                                14,
                                14,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child: _isSignUp
                                          ? Column(
                                              children: [
                                                TextFormField(
                                                  key: const ValueKey(
                                                    'nameField',
                                                  ),
                                                  controller: _nameController,
                                                  textCapitalization:
                                                      TextCapitalization.words,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Your name',
                                                    prefixIcon: Icon(
                                                      Icons
                                                          .person_outline_rounded,
                                                    ),
                                                  ),
                                                  validator: (value) =>
                                                      value == null ||
                                                          value.trim().length <
                                                              2
                                                      ? 'Tell us what to call you.'
                                                      : null,
                                                ),
                                                const SizedBox(height: 12),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    TextFormField(
                                      key: const ValueKey('emailField'),
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Email address',
                                        prefixIcon: Icon(
                                          Icons.alternate_email_rounded,
                                        ),
                                      ),
                                      validator: (value) {
                                        final email = value?.trim() ?? '';
                                        return !email.contains('@') ||
                                                !email.contains('.')
                                            ? 'Enter a valid email address.'
                                            : null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      key: const ValueKey('passwordField'),
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      autofillHints: [
                                        _isSignUp
                                            ? AutofillHints.newPassword
                                            : AutofillHints.password,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (value) =>
                                          (value?.length ?? 0) < 6
                                          ? 'Use at least 6 characters.'
                                          : null,
                                      onFieldSubmitted: (_) =>
                                          _loading ? null : _submit(),
                                    ),
                                    if (!_isSignUp)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _showResetDialog,
                                          child: const Text('Forgot password?'),
                                        ),
                                      )
                                    else
                                      const SizedBox(height: 16),
                                    FilledButton(
                                      key: const ValueKey('authSubmit'),
                                      onPressed: _loading ? null : _submit,
                                      child: _loading && !_googleLoading
                                          ? const SizedBox.square(
                                              dimension: 21,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _isSignUp
                                                  ? 'Create my plan'
                                                  : 'Sign in',
                                            ),
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        const Expanded(child: Divider()),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'OR CONTINUE WITH',
                                            style: TextStyle(
                                              color: AppPalette.muted
                                                  .withValues(alpha: 0.7),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const Expanded(child: Divider()),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    GoogleAuthButton(
                                      onPressed: _loading
                                          ? null
                                          : _googleSignIn,
                                      isSignUp: _isSignUp,
                                      isLoading: _googleLoading,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Your wellness data stays private in your account.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.isSignUp, required this.onChanged});
  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppPalette.line.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          _ModeItem(
            label: 'Sign in',
            selected: !isSignUp,
            onTap: () => onChanged(false),
          ),
          _ModeItem(
            label: 'Create account',
            selected: isSignUp,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppPalette.ink.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppPalette.ink : AppPalette.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -100,
            top: -90,
            child: Container(
              width: 310,
              height: 310,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.lime.withValues(alpha: 0.13),
              ),
            ),
          ),
          Positioned(
            left: -70,
            top: 250,
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 170,
                height: 86,
                decoration: BoxDecoration(
                  color: AppPalette.coral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(45),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: Icon(
              Icons.eco_outlined,
              color: Colors.white.withValues(alpha: 0.06),
              size: 130,
            ),
          ),
        ],
      ),
    );
  }
}
