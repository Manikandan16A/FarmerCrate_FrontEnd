// This is a utility script to help update all snackbars in the project
// Run this to see what files need to be updated

import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final filesToUpdate = <String>[];
  
  void scanDirectory(Directory dir) {
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = entity.readAsStringSync();
        if (content.contains('ScaffoldMessenger.of(context).showSnackBar') ||
            content.contains('SnackBar(')) {
          filesToUpdate.add(entity.path);
        }
      }
    }
  }
  
  scanDirectory(libDir);
  
  print('Files that need snackbar updates:');
  for (final file in filesToUpdate) {
    print('- $file');
  }
  
  print('\nTo update each file:');
  print('1. Add import: import "../utils/snackbar_utils.dart";');
  print('2. Replace ScaffoldMessenger calls with: SnackBarUtils.show(context, "message");');
}