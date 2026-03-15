import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtils {
  static void showSuccess(String message, {BuildContext? context}) {
    toastification.show(
      context: context,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      alignment: Alignment.bottomRight,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      primaryColor: AppColors.accent,
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
      applyBlurEffect: true,
    );
  }

  static void showInfo(String message, {BuildContext? context}) {
    toastification.show(
      context: context,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      type: ToastificationType.info,
      style: ToastificationStyle.minimal,
      alignment: Alignment.bottomRight,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      primaryColor: AppColors.info,
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
      applyBlurEffect: true,
    );
  }

  static void showWarning(String message, {BuildContext? context}) {
    toastification.show(
      context: context,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      type: ToastificationType.warning,
      style: ToastificationStyle.minimal,
      alignment: Alignment.bottomRight,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      primaryColor: AppColors.priorityMedium,
      borderRadius: BorderRadius.circular(12),
      showProgressBar: false,
      applyBlurEffect: true,
    );
  }
}
