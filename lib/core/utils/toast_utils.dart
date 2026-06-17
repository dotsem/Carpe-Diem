import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/routes/keys.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtils {
  static const alignment = Alignment.topLeft;
  static final borderRadius = BorderRadius.circular(12);
  static const showProgressBar = false;
  static const applyBlurEffect = true;
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

  static void showSuccess(String message, {BuildContext? context}) {
    final effectiveContext = _getEffectiveContext(context);
    if (effectiveContext == null) return;
    toastification.show(
      context: effectiveContext,
      title: Text(message),
      autoCloseDuration: autoCloseDuration,
      type: ToastificationType.success,
      style: style,
      alignment: alignment,
      primaryColor: AppColors.accent,
      backgroundColor: Theme.of(effectiveContext).colorScheme.surfaceContainerHigh,
      foregroundColor: Theme.of(effectiveContext).colorScheme.onSurface,
      borderRadius: borderRadius,
      showProgressBar: showProgressBar,
      applyBlurEffect: applyBlurEffect,
      dragToClose: dragToClose,
    );
  }

  static void showInfo(String message, {BuildContext? context}) {
    final effectiveContext = _getEffectiveContext(context);
    if (effectiveContext == null) return;
    toastification.show(
      context: effectiveContext,
      title: Text(message),
      autoCloseDuration: autoCloseDuration,
      type: ToastificationType.info,
      style: style,
      alignment: alignment,
      primaryColor: AppColors.info,
      backgroundColor: Theme.of(effectiveContext).colorScheme.surfaceContainerHigh,
      foregroundColor: Theme.of(effectiveContext).colorScheme.onSurface,
      borderRadius: borderRadius,
      showProgressBar: showProgressBar,
      applyBlurEffect: applyBlurEffect,
      dragToClose: dragToClose,
    );
  }

  static void showWarning(String message, {BuildContext? context}) {
    final effectiveContext = _getEffectiveContext(context);
    if (effectiveContext == null) return;
    toastification.show(
      context: effectiveContext,
      title: Text(message),
      autoCloseDuration: autoCloseDuration,
      type: ToastificationType.warning,
      style: style,
      alignment: alignment,
      primaryColor: AppColors.priorityMedium,
      backgroundColor: Theme.of(effectiveContext).colorScheme.surfaceContainerHigh,
      foregroundColor: Theme.of(effectiveContext).colorScheme.onSurface,
      borderRadius: borderRadius,
      showProgressBar: showProgressBar,
      applyBlurEffect: applyBlurEffect,
      dragToClose: dragToClose,
    );
  }

  static void showUndoable(String message, VoidCallback onUndo, {BuildContext? context}) {
    final effectiveContext = _getEffectiveContext(context);
    if (effectiveContext == null) return;

    late final ToastificationItem item;
    item = toastification.show(
      context: effectiveContext,
      title: Row(
        children: [
          Expanded(child: Text(message)),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              onUndo();
              toastification.dismiss(item);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Undo',
              style: TextStyle(color: Theme.of(effectiveContext).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      autoCloseDuration: autoCloseDuration,
      type: ToastificationType.success,
      style: style,
      alignment: alignment,
      primaryColor: AppColors.accent,
      backgroundColor: Theme.of(effectiveContext).colorScheme.surfaceContainerHigh,
      foregroundColor: Theme.of(effectiveContext).colorScheme.onSurface,
      borderRadius: borderRadius,
      showProgressBar: showProgressBar,
      applyBlurEffect: applyBlurEffect,
      dragToClose: dragToClose,
    );
  }
}
