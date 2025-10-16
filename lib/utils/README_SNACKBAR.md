# Snackbar Design Guide

This document explains how to use the standardized snackbar design across the FarmerCrate project.

## Import

```dart
import '../utils/snackbar_utils.dart';
```

## Usage Examples

### Success Messages
```dart
SnackBarUtils.showSuccess(context, 'Item added to cart successfully!');
SnackBarUtils.showSuccess(context, 'Order placed successfully!');
```

### Error Messages
```dart
SnackBarUtils.showError(context, 'Failed to load products');
SnackBarUtils.showError(context, 'Network connection failed', onRetry: _retryFunction);
```

### Warning Messages
```dart
SnackBarUtils.showWarning(context, 'Only 5 items available in stock');
SnackBarUtils.showWarning(context, 'Please select at least one item');
```

### Info Messages
```dart
SnackBarUtils.showInfo(context, 'Your order is being processed');
SnackBarUtils.showInfo(context, 'New features available in settings');
```

### Network Errors (with retry)
```dart
SnackBarUtils.showNetworkError(context, onRetry: _fetchData);
```

### API Errors (with retry)
```dart
SnackBarUtils.showApiError(context, 'Failed to save changes', onRetry: _saveData);
```

### Notifications
```dart
SnackBarUtils.showNotification(context, '3 new orders waiting for assignment');
SnackBarUtils.showNotification(context, 'Delivery person assigned', customIcon: Icons.local_shipping);
```

### With Loading Dialog
```dart
SnackBarUtils.showSnackBar(
  context, 
  'Processing your request...', 
  showLoading: true
);
```

## Design Features

- **Consistent Colors**: Green for success, red for errors, orange for warnings, blue for info
- **Icons**: Each type has appropriate icons (check, error, warning, info)
- **Floating Behavior**: All snackbars float above content
- **Rounded Corners**: 12px border radius for modern look
- **Elevation**: 6px shadow for depth
- **Duration**: 3 seconds display time
- **Retry Actions**: Optional retry buttons for network/API errors

## Migration from Old Snackbars

### Before:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error message'),
    backgroundColor: Colors.red,
  ),
);
```

### After:
```dart
SnackBarUtils.showError(context, 'Error message');
```

## Color Scheme

- **Success**: `Color(0xFF2E7D32)` (Green)
- **Error**: `Color(0xFFD32F2F)` (Red)
- **Warning**: `Color(0xFFFF9800)` (Orange)
- **Info**: `Color(0xFF2196F3)` (Blue)

## Files Updated

- ✅ `lib/utils/snackbar_utils.dart` - Main utility class
- ✅ `lib/Customer/customerhomepage.dart` - Updated to use new design
- ✅ `lib/Customer/Cart.dart` - Updated to use new design

## Next Steps

Update remaining files in your project:
- `lib/Farmer/` - All farmer-related pages
- `lib/delivery/` - All delivery-related pages
- `lib/Admin/` - All admin-related pages
- `lib/auth/` - All authentication pages

Simply replace old `ScaffoldMessenger.of(context).showSnackBar()` calls with the appropriate `SnackBarUtils` method.