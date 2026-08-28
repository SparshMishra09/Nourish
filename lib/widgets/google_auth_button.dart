import 'package:flutter/material.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    super.key,
    required this.onPressed,
    required this.isSignUp,
    this.isLoading = false,
  });

  static const logoAsset = 'assets/images/google_g_logo.png';

  final VoidCallback? onPressed;
  final bool isSignUp;
  final bool isLoading;

  String get _label => isSignUp ? 'Sign up with Google' : 'Sign in with Google';

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: isLoading ? 'Connecting to Google' : _label,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF747775)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('googleSignIn'),
            onTap: enabled ? onPressed : null,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFF1F1F1F).withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return const Color(0xFF1F1F1F).withValues(alpha: 0.04);
              }
              return null;
            }),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isLoading
                  ? const _GoogleLoadingLabel()
                  : _GoogleLabel(label: _label, enabled: enabled),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLabel extends StatelessWidget {
  const _GoogleLabel({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey(label),
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Image.asset(
            GoogleAuthButton.logoAsset,
            width: 20,
            height: 20,
            filterQuality: FilterQuality.high,
            semanticLabel: 'Google',
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: const Color(
              0xFF1F1F1F,
            ).withValues(alpha: enabled ? 1 : 0.45),
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _GoogleLoadingLabel extends StatelessWidget {
  const _GoogleLoadingLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: ValueKey('googleLoading'),
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 19,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Color(0xFF4285F4),
          ),
        ),
        SizedBox(width: 11),
        Text(
          'Connecting to Google…',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
