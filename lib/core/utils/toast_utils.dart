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
}
