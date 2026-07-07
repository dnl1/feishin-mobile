import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

/// Host-side half of `integration_test/theme_screenshots_test.dart` — run
/// via `flutter drive --driver=test_driver/integration_test.dart
/// --target=integration_test/theme_screenshots_test.dart -d DEVICE_ID`.
/// Writes each screenshot PNG to `screenshots/<name>.png` for the CI job to
/// upload as an artifact.
Future<void> main() async {
  final driver = await FlutterDriver.connect();
  await integrationDriver(
    driver: driver,
    onScreenshot: (name, bytes, [args]) async {
      final file = File('screenshots/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
