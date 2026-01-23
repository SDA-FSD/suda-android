import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:suda/services/suda_api_client.dart';
import 'package:suda/services/token_storage.dart';
import 'package:suda/services/app_dialog_service.dart';
import 'package:suda/config/app_config.dart';

/// 버전 체크 서비스
/// 
/// 앱 실행 시 최신 버전 정보를 확인하고 강제 업데이트 여부를 판단
class VersionCheckService {
  /// 버전 비교 (1: version1 > version2, 0: 같음, -1: version1 < version2)
  static int compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    
    for (int i = 0; i < maxLength; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;
      
      if (v1Part > v2Part) return 1;
      if (v1Part < v2Part) return -1;
    }
    
    return 0;
  }

  /// 강제 업데이트 필요 여부 확인
  /// 
  /// latestVersion > appVersion && forceUpdateYn == "Y" 인 경우 true 반환
  static bool shouldForceUpdate(String latestVersion, String forceUpdateYn) {
    return compareVersions(latestVersion, AppConfig.appVersion) > 0 &&
        forceUpdateYn.toUpperCase() == 'Y';
  }

  /// 버전 체크 실행
  /// 
  /// 최신 버전 정보를 조회하고 강제 업데이트 여부를 확인
  /// 강제 업데이트가 필요한 경우 팝업을 표시하고 앱을 종료
  /// 버전 체크 실패 시 Network Error 팝업을 표시하고 앱을 종료
  /// 
  /// 반환값: 버전 체크 통과 여부 (true: 통과, false: 실패 또는 강제 업데이트 필요)
  static Future<bool> checkVersion(GlobalKey<NavigatorState> navigatorKey) async {
    try {
      // 1) 버전 체크 API 호출
      final versionInfo = await SudaApiClient.getLatestVersion();
      
      // 최신 버전 정보를 영구 저장 영역에 저장
      await TokenStorage.saveLatestVersion(versionInfo.latestVersion);
      
      // 버전 비교: latestVersion > appVersion && forceUpdateYn == "Y"
      final shouldUpdate = shouldForceUpdate(versionInfo.latestVersion, versionInfo.forceUpdateYn);
      
      if (shouldUpdate) {
        // 강제 업데이트 필요 시 스플래시 제거 후 팝업 표시 및 앱 종료
        FlutterNativeSplash.remove();
        await AppDialogService.showForceUpdateDialog(navigatorKey);
        return false;
      }
      
      // 버전 체크 통과
      return true;
    } catch (error, stackTrace) {
      // 버전 체크 실패 시 (모든 예외 포함) 스플래시 제거 후 Network Error 팝업 표시 및 앱 종료
      FlutterNativeSplash.remove();
      try {
        await AppDialogService.showNetworkErrorDialog(navigatorKey);
      } catch (e) {
        // 팝업 표시 실패 시에도 앱 종료 보장
        SystemNavigator.pop();
      }
      return false;
    }
  }
}

