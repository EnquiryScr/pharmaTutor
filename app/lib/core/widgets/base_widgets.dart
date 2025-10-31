import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Base button widget with consistent styling
class BaseButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double? height;

  const BaseButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final buttonSize = _getButtonSize();

    return SizedBox(
      width: width,
      height: height ?? buttonSize.height,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonStyle.backgroundColor,
          foregroundColor: buttonStyle.textColor,
          elevation: buttonStyle.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BorderRadius.md),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: buttonSize.horizontalPadding,
            vertical: buttonSize.verticalPadding,
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getButtonStyle().textColor,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: _getIconSize(),
          ),
          const SizedBox(width: Spacing.sm),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: _getTextSize(),
            fontWeight: FontWeights.medium,
          ),
        ),
      ],
    );
  }

  ButtonStyleConfig _getButtonStyle() {
    switch (type) {
      case ButtonType.primary:
        return ButtonStyleConfig(
          backgroundColor: Colors.primary,
          textColor: Colors.white,
          elevation: 2,
        );
      case ButtonType.secondary:
        return ButtonStyleConfig(
          backgroundColor: Colors.secondary,
          textColor: Colors.white,
          elevation: 2,
        );
      case ButtonType.outline:
        return ButtonStyleConfig(
          backgroundColor: Colors.transparent,
          textColor: Colors.primary,
          elevation: 0,
        );
      case ButtonType.ghost:
        return ButtonStyleConfig(
          backgroundColor: Colors.transparent,
          textColor: Colors.primary,
          elevation: 0,
        );
      case ButtonType.destructive:
        return ButtonStyleConfig(
          backgroundColor: Colors.error,
          textColor: Colors.white,
          elevation: 2,
        );
      case ButtonType.success:
        return ButtonStyleConfig(
          backgroundColor: Colors.success,
          textColor: Colors.white,
          elevation: 2,
        );
    }
  }

  ButtonSizeConfig _getButtonSize() {
    switch (size) {
      case ButtonSize.small:
        return ButtonSizeConfig(
          height: 36,
          horizontalPadding: Spacing.md,
          verticalPadding: Spacing.sm,
        );
      case ButtonSize.medium:
        return ButtonSizeConfig(
          height: 48,
          horizontalPadding: Spacing.lg,
          verticalPadding: Spacing.md,
        );
      case ButtonSize.large:
        return ButtonSizeConfig(
          height: 56,
          horizontalPadding: Spacing.xl,
          verticalPadding: Spacing.lg,
        );
    }
  }

  double _getTextSize() {
    switch (size) {
      case ButtonSize.small:
        return FontSizes.sm;
      case ButtonSize.medium:
        return FontSizes.md;
      case ButtonSize.large:
        return FontSizes.lg;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }
}

/// Button configuration classes
class ButtonStyleConfig {
  final Color backgroundColor;
  final Color textColor;
  final double elevation;

  const ButtonStyleConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.elevation,
  });
}

class ButtonSizeConfig {
  final double height;
  final double horizontalPadding;
  final double verticalPadding;

  const ButtonSizeConfig({
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
  });
}

/// Button type enum
enum ButtonType {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
  success,
}

/// Button size enum
enum ButtonSize {
  small,
  medium,
  large,
}

/// Base card widget with consistent styling
class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final double? borderRadius;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final bool isClickable;

  const BaseCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.shadow,
    this.onTap,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(borderRadius ?? BorderRadius.md),
        ),
        boxShadow: shadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (isClickable && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.all(
          Radius.circular(borderRadius ?? BorderRadius.md),
        ),
        child: card,
      );
    }

    return card;
  }
}

/// Base input field widget
class BaseInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? error;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final FocusNode? focusNode;

  const BaseInputField({
    super.key,
    required this.label,
    this.hint,
    this.error,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines,
    this.maxLength,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: FontSizes.sm,
            fontWeight: FontWeights.medium,
            color: Colors.textPrimary,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.textMuted,
            ),
            errorText: error,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.gray50 : Colors.gray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadius.md),
              borderSide: const BorderSide(color: Colors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadius.md),
              borderSide: const BorderSide(color: Colors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadius.md),
              borderSide: const BorderSide(color: Colors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BorderRadius.md),
              borderSide: const BorderSide(color: Colors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.md,
            ),
          ),
        ),
      ],
    );
  }
}

/// Base loading widget
class BaseLoading extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;

  const BaseLoading({
    super.key,
    this.message,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: size ?? 40,
            width: size ?? 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Colors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              message!,
              style: const TextStyle(
                fontSize: FontSizes.md,
                color: Colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Base empty state widget
class BaseEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;
  final double iconSize;
  final Color? iconColor;

  const BaseEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Colors.textMuted,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: FontSizes.lg,
                fontWeight: FontWeights.semibold,
                color: Colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: FontSizes.md,
                  color: Colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: Spacing.lg),
              BaseButton(
                text: actionText!,
                onPressed: onAction,
                type: ButtonType.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Base error state widget
class BaseErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData icon;

  const BaseErrorState({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return BaseEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionText: actionText,
      onAction: onAction,
      iconColor: Colors.error,
    );
  }
}

/// Base app bar widget
class BaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const BaseAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onBack,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget? effectiveLeading = leading;
    
    if (automaticallyImplyLeading && effectiveLeading == null) {
      if (Navigator.of(context).canPop()) {
        effectiveLeading = IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => Navigator.of(context).pop(),
        );
      }
    }

    return AppBar(
      title: Text(title),
      actions: actions,
      leading: effectiveLeading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? Colors.textPrimary,
      elevation: elevation,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Base FAB widget
class BaseFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final String? tooltip;

  const BaseFAB({
    super.key,
    this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Colors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation ?? 6,
      tooltip: tooltip,
      child: child,
    );
  }
}