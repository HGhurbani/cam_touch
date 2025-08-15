import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double elevation;
  final Widget? flexibleSpace;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
    this.elevation = 0,
    this.flexibleSpace,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final logoPath = brightness == Brightness.dark
        ? 'assets/img/white_logo.png'
        : 'assets/img/black_logo.png';

    return AppBar(
      title: Text(
        title,
        style: AppStyles.headline4.copyWith(
          color: foregroundColor ?? AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? AppColors.textOnPrimary,
      elevation: elevation,
      leading: _buildLeading(context, logoPath),
      actions: _buildActions(),
      flexibleSpace: flexibleSpace ?? _buildFlexibleSpace(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, String logoPath) {
    if (leading != null) return leading;
    
    if (showBackButton) {
      return Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.whiteWithOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textOnPrimary,
            size: 20,
          ),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          logoPath,
          width: 32,
          height: 32,
        ),
      ),
    );
  }

  List<Widget>? _buildActions() {
    if (actions == null) return null;
    
    return actions!.map((action) {
      if (action is IconButton) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.whiteWithOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: action,
        );
      }
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: action,
      );
    }).toList();
  }

  Widget _buildFlexibleSpace() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }
}

// مكون شريط تطبيق محسن مع تأثيرات إضافية
class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double elevation;
  final Widget? subtitle;
  final Widget? bottom;

  const EnhancedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
    this.elevation = 0,
    this.subtitle,
    this.bottom,
  });

  @override
  Size get preferredSize {
    double height = kToolbarHeight;
    if (subtitle != null) height += 20;
    if (bottom != null) height += 60;
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Column(
                children: [
                  Text(
                    title,
                    style: AppStyles.headline4.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    subtitle!,
                  ],
                ],
              ),
              centerTitle: centerTitle,
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              leading: _buildLeading(context),
              actions: _buildActions(),
            ),
            if (bottom != null) ...[
              const SizedBox(height: 8),
              bottom!,
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    
    if (showBackButton) {
      return Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.whiteWithOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textOnPrimary,
            size: 20,
          ),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        ),
      );
    }

    return null;
  }

  List<Widget>? _buildActions() {
    if (actions == null) return null;
    
    return actions!.map((action) {
      if (action is IconButton) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.whiteWithOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: action,
        );
      }
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: action,
      );
    }).toList();
  }
}
