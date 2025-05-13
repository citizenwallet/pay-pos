import 'dart:convert';

import 'package:pay_pos/services/api/api.dart';
import 'package:pay_pos/services/config/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pay_pos/utils/date.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() {
    return _instance;
  }

  ConfigService._internal();

  static const String communityConfigFileName =
      kDebugMode ? 'communities.test' : 'communities';
  static const String communityConfigListS3FileName = 'communities';
  static const String communityDebugFileName = 'debug';
  static const int version = 4;

  void init(String endpoint) {}

  Future<Config?> getLocalConfig() async {
    try {
      final localConfig = jsonDecode(await rootBundle
          .loadString('assets/config/v$version/$communityConfigFileName.json'));

      final config = Config.fromJson(localConfig);

      return config;
    } catch (e) {
      debugPrint('Error fetching local config: $e');
      return null;
    }
  }

  Future<Config?> getRemoteConfig(String remoteConfigUrl) async {
    if (kDebugMode) {
      final debugConfig = jsonDecode(
          await rootBundle.loadString('assets/config/v$version/debug.json'));

      return Config.fromJson(debugConfig);
    }

    final remote = APIService(baseURL: remoteConfigUrl);

    try {
      final dynamic response =
          await remote.get(url: '?cachebuster=${generateCacheBusterValue()}');

      final config = Config.fromJson(response);

      return config;
    } catch (e, s) {
      debugPrint('Error fetching remote config: $e');
      debugPrint('Stacktrace: $s');

      return null;
    }
  }

  Future<bool> isCommunityOnline(String indexerUrl) async {
    final indexer = APIService(baseURL: indexerUrl, netTimeoutSeconds: 12);

    try {
      await indexer.get(url: '/health');
      return true;
    } catch (e, s) {
      debugPrint('indexerUrl: $indexerUrl');
      debugPrint('Error checking if community is online: $e, $indexerUrl');
      debugPrint('Stacktrace: $s, $indexerUrl');

      return false;
    }
  }
}
