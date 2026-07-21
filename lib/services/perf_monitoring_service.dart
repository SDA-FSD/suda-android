import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Firebase Performance Monitoring 헬퍼.
///
/// - **dev / prd**: 수집 ON (flavor별 `google-services.json` → 각 Firebase 프로젝트).
/// - **local / stg**: 수집 OFF (분석·유지보수 불필요).
/// - iOS plist 미연동 상태에서도 Dart API는 동일. 훗날 iOS 연동 시 이 서비스를 재사용.
class PerfMonitoringService {
  PerfMonitoringService._();

  static final PerfMonitoringService instance = PerfMonitoringService._();

  static bool get isCollectionEnabled => AppConfig.isDev || AppConfig.isPrd;

  final Map<String, Trace> _active = {};

  Future<void> configure() async {
    try {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        isCollectionEnabled,
      );
    } catch (e, st) {
      debugPrint('[DEBUG] PerfMonitoring configure failed: $e\n$st');
    }
  }

  Future<void> start(
    String name, {
    Map<String, String>? attributes,
  }) async {
    if (!isCollectionEnabled) return;
    try {
      await stop(name);
      final trace = FirebasePerformance.instance.newTrace(name);
      trace.putAttribute('env', AppConfig.env);
      attributes?.forEach(trace.putAttribute);
      _active[name] = trace;
      await trace.start();
    } catch (e, st) {
      debugPrint('[DEBUG] PerfMonitoring start($name) failed: $e\n$st');
    }
  }

  Future<void> stop(String name) async {
    if (!isCollectionEnabled) return;
    final trace = _active.remove(name);
    if (trace == null) return;
    try {
      await trace.stop();
    } catch (e, st) {
      debugPrint('[DEBUG] PerfMonitoring stop($name) failed: $e\n$st');
    }
  }

  /// [action] 구간을 하나의 트레이스로 측정. 예외가 나도 stop 보장.
  Future<T> trace<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String>? attributes,
  }) async {
    await start(name, attributes: attributes);
    try {
      return await action();
    } finally {
      await stop(name);
    }
  }
}
