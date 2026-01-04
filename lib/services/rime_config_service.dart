import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class RimeConfigService {
  Future<({String path, String content})?> readConfig() async {
    String? configPath = _getConfigPath();
    if (configPath == null) {
      return null;
    }

    final file = File(configPath);
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        return (path: configPath, content: content);
      } catch (e) {
        debugPrint('Error reading config file: $e');
        return null;
      }
    }
    return null;
  }

  String? _getConfigPath() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home == null) return null;

      // Check custom first
      final customPath = p.join(home, 'Library/Rime/squirrel.custom.yaml');
      if (File(customPath).existsSync()) return customPath;

      return p.join(home, 'Library/Rime/squirrel.yaml');
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData == null) return null;

      // Check custom first
      final customPath = p.join(appData, 'Rime', 'weasel.custom.yaml');
      if (File(customPath).existsSync()) return customPath;

      return p.join(appData, 'Rime', 'weasel.yaml');
    }
    return null;
  }
}
