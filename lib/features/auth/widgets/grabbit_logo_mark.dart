import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

/// Grabbit wordmark + soft green glow (reference-style welcome hero).
class GrabbitLogoMark extends StatelessWidget {
  const GrabbitLogoMark({
    super.key,
    this.size = 200,
    this.showGlow = true,
  });

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 0.72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (showGlow)
                Container(
                  width: size * 0.85,
                  height: size * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.22),
                        blurRadius: 56,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'lib/assets/grabbit_logo.png',
                  width: size * 0.72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.shopping_basket_rounded,
                    size: size * 0.35,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact logo for app bars (square tile on white).
class GrabbitLogoSmall extends StatelessWidget {
  const GrabbitLogoSmall({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'lib/assets/grabbit_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shopping_basket_rounded, color: Colors.white),
        ),
      ),
    );
  }
}
