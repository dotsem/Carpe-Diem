import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/toast/cheesy_toast.dart';
import 'package:carpe_diem/routes/keys.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtils {
  static const alignment = Alignment.bottomRight;
  static const autoCloseDuration = Duration(seconds: 3);

  static BuildContext? _getEffectiveContext(BuildContext? context) {
    if (context != null) return context;
    try {
      return rootNavigatorKey.currentContext;
    } catch (_) {
      return null;
    }
  }

  static void _showToast({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color color,
    String? subtitle,
    VoidCallback? onUndo,
  }) {
    toastification.showCustom(
      context: context,
      alignment: alignment,
      autoCloseDuration: autoCloseDuration,
      dismissDirection: DismissDirection.horizontal,
      builder: (context, holder) => CheesyToast(
        message: message,
        icon: icon,
        color: color,
        subtitle: subtitle,
        onUndo: onUndo,
        item: holder,
      ),
    );
  }

  static void showSuccess(
    String message, {
    BuildContext? context,
    IconData? icon,
    Color? iconColor,
    String? subtitle,
  }) {
    final effectiveContext = _getEffectiveContext(context);
    if (effectiveContext == null) return;
    _showToast(
      context: effectiveContext,
      message: message,
      icon: icon ?? Icons.check_circle_outline,
      color: iconColor ?? AppColors.success,
      subtitle: subtitle,
    );
  }

  static void showInfo(
    String message, {
    BuildContext? context,
    IconData? icon,
    Color? iconColor,
    String? subtitle,
  }) {
    final effectiveContext = _getEffectiveContext(context);
    if (effectiveContext == null) return;
    _showToast(
      context: effectiveContext,
      message: message,
      icon: icon ?? Icons.info_outline,
      color: iconColor ?? AppColors.info,
      subtitle: subtitle,
    );
  }

  static void showWarning(
    String message, {
    BuildContext? context,
    IconData? icon,
    Color? iconColor,
    String? subtitle,
  }) {
    final effectiveContext = _getEffectiveContext(context);
    if (effectiveContext == null) return;
    _showToast(
      context: effectiveContext,
      message: message,
      icon: icon ?? Icons.warning_amber_rounded,
      color: iconColor ?? AppColors.warning,
      subtitle: subtitle,
    );
  }

  static void showUndoable(
    String message,
    VoidCallback onUndo, {
    BuildContext? context,
    IconData? icon,
    Color? iconColor,
    String? subtitle,
    Color? primaryColor,
  }) {
    final effectiveContext = _getEffectiveContext(context);
    if (effectiveContext == null) return;
    final color = primaryColor ?? iconColor ?? AppColors.info;
    _showToast(
      context: effectiveContext,
      message: message,
      icon: icon ?? Icons.check_circle_outline,
      color: color,
      subtitle: subtitle,
      onUndo: onUndo,
    );
  }
}
