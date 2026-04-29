import 'package:flutter/material.dart';
import '../theme.dart';

enum ToastType { info, success, error, warning }

void showToast(BuildContext context, String message,
    {ToastType type = ToastType.info}) {
  final color = switch (type) {
    ToastType.success => AppColors.green,
    ToastType.error   => AppColors.red,
    ToastType.warning => AppColors.yellow,
    ToastType.info    => AppColors.accent2,
  };

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(_icon(type), color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.text1, fontSize: 13)),
          ),
        ],
      ),
      backgroundColor: AppColors.bg3,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 3),
    ),
  );
}

IconData _icon(ToastType t) => switch (t) {
      ToastType.success => Icons.check_circle_outline,
      ToastType.error   => Icons.error_outline,
      ToastType.warning => Icons.warning_amber_outlined,
      ToastType.info    => Icons.info_outline,
    };
