import 'package:flutter/material.dart';

class NotificationHelper {
  static void showNotification(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    showNotification(
      context,
      message,
      backgroundColor: Colors.green[600],
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(BuildContext context, String message) {
    showNotification(
      context,
      message,
      backgroundColor: Colors.red[600],
      icon: Icons.error_outline,
    );
  }

  static void showWarning(BuildContext context, String message) {
    showNotification(
      context,
      message,
      backgroundColor: Colors.orange[600],
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    showNotification(
      context,
      message,
      backgroundColor: Colors.blue[600],
      icon: Icons.info_outline,
    );
  }
}
