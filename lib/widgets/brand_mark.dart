import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 46, this.dark = false});

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.34),
            boxShadow: [
              BoxShadow(
                color: AppPalette.ink.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/nourish_logo.png',
            fit: BoxFit.cover,
            semanticLabel: 'Nourish logo',
          ),
        ),
        const SizedBox(width: 11),
        Text(
          'NOURISH',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
            fontSize: size * 0.31,
            color: dark ? Colors.white : AppPalette.ink,
          ),
        ),
      ],
    );
  }
}
