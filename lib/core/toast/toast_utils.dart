import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/toast/cheesy_toast.dart';
import 'package:carpe_diem/routes/keys.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtils {
  static const alignment = Alignment.bottomRight;
  static final borderRadius = BorderRadius.circular(12);
  static const showProgressBar = false;
  static const applyBlurEffect = false;
  static const dragToClose = true;
  static const autoCloseDuration = Duration(seconds: 3);
  static const style = ToastificationStyle.minimal;

  static BuildContext? _getEffectiveContext(BuildContext? context) {
    if (context != null) return context;
    try {
      return rootNavigatorKey.currentContext;
    } catch (_) {
      return null;
    }
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
    toastification.show(
      context: effectiveContext,
      title: CheesyToast(message: message, subtitle: subtitle),
      icon: Icon(
        icon ?? Icons.check_circle_outline,
        size: 20,
        color: iconColor ?? AppColors.success,
      ),
      autoCloseDuration: autoCloseDuration,
      type: ToastificationType.success,
      style: style,
      alignment: alignment,
      primaryColor: AppColors.success,
      backgroundColor: Theme.of(
        effectiveContext,
      ).colorScheme.surfaceContainerHigh,
      foregroundColor: Theme.of(effectiveContext).colorScheme.onSurface,
      borderRadius: borderRadius,
      showProgressBar: showProgressBar,
      applyBlurEffect: applyBlurEffect,
      dragToClose: dragToClose,
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
    toastification.show(
      context: effectiveContext,
      title: CheesyToast(message: message, subtitle: subtitle),
      icon: Icon(
        icon ?? Icons.info_outline,
        size: 20,
        color: iconColor ?? AppColors.info,
      ),
      autoCloseDuration: autoCloseDuration,
      type: ToastificationType.info,
      style: style,
      alignment: alignment,
      primaryColor: AppColors.info,
      backgroundColor: Theme.of(
        effectiveContext,
      ).colorScheme.surfaceContainerHigh,
      foregroundColor: Theme.of(effectiveContext).colorScheme.onSurface,
      borderRadius: borderRadius,
      showProgressBar: showProgressBar,
      applyBlurEffect: applyBlurEffect,
      dragToClose: dragToClose,
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
    toastification.show(
      context: effectiveContext,
      title: CheesyToast(message: message, subtitle: subtitle),
      icon: Icon(
        icon ?? Icons.warning_amber_rounded,
        size: 20,
        color: iconColor ?? AppColors.warning,
      ),
      autoCloseDuration: autoCloseDuration,
      type: ToastificationType.warning,
      style: style,
      alignment: alignment,
      primaryColor: AppColors.warning,
      backgroundColor: Theme.of(
        effectiveContext,
      ).colorScheme.surfaceContainerHigh,
      foregroundColor: Theme.of(effectiveContext).colorScheme.onSurface,
      borderRadius: borderRadius,
      showProgressBar: showProgressBar,
      applyBlurEffect: applyBlurEffect,
      dragToClose: dragToClose,
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

    final resolvedColor = primaryColor ?? AppColors.info;
    late final ToastificationItem item;
    item = toastification.show(
      context: effectiveContext,
      title: CheesyToast(
        message: message,
        subtitle: subtitle,
        onUndo: onUndo,
        getItem: () => item,
      ),
      icon: Icon(
        icon ?? Icons.check_circle_outline,
        size: 20,
        color: iconColor ?? resolvedColor,
      ),
      autoCloseDuration: autoCloseDuration,
      type: ToastificationType.success,
      style: style,
      alignment: alignment,
      primaryColor: resolvedColor,
      backgroundColor: Theme.of(
        effectiveContext,
      ).colorScheme.surfaceContainerHigh,
      foregroundColor: Theme.of(effectiveContext).colorScheme.onSurface,
      borderRadius: borderRadius,
      showProgressBar: showProgressBar,
      applyBlurEffect: applyBlurEffect,
      dragToClose: dragToClose,
    );
  }
}
