import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;
  final TextStyle? textStyle;

  const AppLogo({
    super.key,
    this.size = 56,
    this.showText = true,
    this.color,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // If client configures an asset path later, render the asset image
    final Widget logoSymbol;
    if (AppBranding.assetLogoPath != null &&
        AppBranding.assetLogoPath!.isNotEmpty) {
      logoSymbol = ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          AppBranding.assetLogoPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to placeholder if asset cannot be loaded
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: (color ?? AppBranding.primaryBlue).withOpacity(0.12),
                borderRadius: BorderRadius.circular(size * 0.22),
              ),
              child: Center(
                child: Icon(
                  AppBranding.logoIcon,
                  size: size * 0.58,
                  color: color ?? AppBranding.primaryBlue,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Elegant minimal water drop placeholder
      logoSymbol = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: (color ?? AppBranding.primaryBlue).withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            AppBranding.logoIcon,
            size: size * 0.58,
            color: color ?? AppBranding.primaryBlue,
          ),
        ),
      );
    }

    if (!showText) {
      return logoSymbol;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoSymbol,
        const SizedBox(height: 12),
        Text(
          AppBranding.appName,
          style: textStyle ??
              TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                color: AppBranding.deepNavy,
                letterSpacing: -0.5,
              ),
        ),
        if (AppBranding.appTagline.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            AppBranding.appTagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppBranding.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
