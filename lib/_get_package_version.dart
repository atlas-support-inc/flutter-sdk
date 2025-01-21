import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

Future<String> getPackageVersion() async {
  try {
    final content = await rootBundle.loadString('packages/atlas_support_sdk/pubspec.yaml');
    final yamlMap = loadYaml(content);
    if (yamlMap is Map) {
      return yamlMap['version'] ?? 'unknown';
    } else {
      return 'unknown';
    }
  } catch (error) {
    return 'unknown';
  }
}
