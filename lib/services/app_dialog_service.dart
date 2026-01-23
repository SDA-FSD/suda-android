import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 앱 전역 다이얼로그 서비스
/// 
/// 버전 체크 실패, 강제 업데이트 등 앱 전역에서 사용하는 다이얼로그를 관리
class AppDialogService {
  /// 강제 업데이트 팝업 표시
  /// 
  /// [navigatorKey]를 사용하여 MaterialApp의 Navigator에 접근
  /// 팝업 표시 실패 시 앱을 종료
  static Future<void> showForceUpdateDialog(GlobalKey<NavigatorState> navigatorKey) async {
    try {
      return showDialog<void>(
        context: navigatorKey.currentContext!,
        barrierDismissible: false, // 외부 터치로 닫을 수 없음
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Notification'),
            content: const Text('Please update SUDA app'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  // 앱 종료
                  SystemNavigator.pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // showDialog 실패 시 앱 종료
      SystemNavigator.pop();
    }
  }

  /// 네트워크 에러 팝업 표시
  /// 
  /// [navigatorKey]를 사용하여 MaterialApp의 Navigator에 접근
  /// 팝업 표시 실패 시 앱을 종료
  static Future<void> showNetworkErrorDialog(GlobalKey<NavigatorState> navigatorKey) async {
    try {
      return showDialog<void>(
        context: navigatorKey.currentContext!,
        barrierDismissible: false, // 외부 터치로 닫을 수 없음
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Notification'),
            content: const Text('Network Error'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  // 앱 종료
                  SystemNavigator.pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // showDialog 실패 시 앱 종료
      SystemNavigator.pop();
    }
  }
}

