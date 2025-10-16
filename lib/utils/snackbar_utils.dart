import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isWarning = false, 
    bool isInfo = false,
    bool showLoading = false,
    VoidCallback? onRetry,
  }) async {
    // Show loading dialog if requested
    if (showLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          ),
        ),
      );

      await Future.delayed(Duration(milliseconds: 500));
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Auto-detect message type based on content
    final messageLower = message.toLowerCase();
    Color backgroundColor;
    IconData icon;
    
    if (isError || _isErrorMessage(messageLower)) {
      backgroundColor = Color(0xFFD32F2F); // Red
      icon = Icons.error_outline;
    } else if (isWarning || _isWarningMessage(messageLower)) {
      backgroundColor = Color(0xFFFF9800); // Yellow/Orange
      icon = Icons.warning_amber;
    } else if (isInfo || _isPendingMessage(messageLower)) {
      backgroundColor = Color(0xFF2196F3); // Blue
      icon = Icons.info_outline;
    } else if (_isSuccessMessage(messageLower)) {
      backgroundColor = Color(0xFF2E7D32); // Green
      icon = Icons.check_circle;
    } else {
      backgroundColor = Color(0xFF2E7D32); // Default green
      icon = Icons.check_circle;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        elevation: 6,
        duration: Duration(seconds: 3),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static bool _isErrorMessage(String message) {
    return message.contains('error') || 
           message.contains('failed') || 
           message.contains('fail') ||
           message.contains('cannot') ||
           message.contains('unable') ||
           message.contains('invalid') ||
           message.contains('not found') ||
           message.contains('denied');
  }

  static bool _isWarningMessage(String message) {
    return message.contains('warning') || 
           message.contains('caution') || 
           message.contains('only') ||
           message.contains('limit') ||
           message.contains('select') ||
           message.contains('choose') ||
           message.contains('stock');
  }

  static bool _isPendingMessage(String message) {
    return message.contains('pending') || 
           message.contains('processing') || 
           message.contains('loading') ||
           message.contains('waiting') ||
           message.contains('in progress') ||
           message.contains('please wait');
  }

  static bool _isSuccessMessage(String message) {
    return message.contains('success') || 
           message.contains('completed') || 
           message.contains('added') ||
           message.contains('saved') ||
           message.contains('updated') ||
           message.contains('removed') ||
           message.contains('cleared') ||
           message.contains('restored') ||
           message.contains('assigned');
  }

  // Auto-detect message type and show appropriate snackbar
  static void show(BuildContext context, String message, {VoidCallback? onRetry}) {
    showSnackBar(context, message, onRetry: onRetry);
  }

  // Convenience methods for different types (override auto-detection)
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message);
  }

  static void showError(BuildContext context, String message, {VoidCallback? onRetry}) {
    showSnackBar(context, message, isError: true, onRetry: onRetry);
  }

  static void showWarning(BuildContext context, String message) {
    showSnackBar(context, message, isWarning: true);
  }

  static void showInfo(BuildContext context, String message) {
    showSnackBar(context, message, isInfo: true);
  }

  // Special method for network errors with retry
  static void showNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    showSnackBar(
      context,
      'Network error. Please check your connection.',
      isWarning: true,
      onRetry: onRetry,
    );
  }

  // Special method for API errors with retry
  static void showApiError(BuildContext context, String message, {VoidCallback? onRetry}) {
    showSnackBar(
      context,
      message,
      isError: true,
      onRetry: onRetry,
    );
  }

  // Method for notification-style snackbars (like new orders)
  static void showNotification(BuildContext context, String message, {IconData? customIcon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(customIcon ?? Icons.notifications_active, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        elevation: 6,
        duration: Duration(seconds: 3),
      ),
    );
  }
}