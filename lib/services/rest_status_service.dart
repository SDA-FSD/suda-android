/// 서비스 점검 대응용 restYn, restStartsAt, restEndsAt을 전역 보관.
/// GET /v1/home/contents 응답 시 초기화/업데이트되며, 어떤 스크린에서도 접근 가능.
class RestStatusService {
  RestStatusService._();

  static final RestStatusService instance = RestStatusService._();

  /// null이면 'N'으로 처리. 서비스 점검 여부.
  String _restYn = 'N';

  /// notibox 미읽음 존재 시 Y (GET /v1/home/contents 동기화)
  String _notiboxUnreadYn = 'N';

  /// 서비스 점검 시작 시각 (향후 지침에 따라 활용)
  DateTime? _restStartsAt;

  /// 서비스 점검 종료 시각 (향후 지침에 따라 활용)
  DateTime? _restEndsAt;

  String get restYn => _restYn;
  String get notiboxUnreadYn => _notiboxUnreadYn;
  DateTime? get restStartsAt => _restStartsAt;
  DateTime? get restEndsAt => _restEndsAt;

  /// HomeDto 수신 시 호출하여 값 갱신
  void update({
    required String restYn,
    DateTime? restStartsAt,
    DateTime? restEndsAt,
    String? notiboxUnreadYn,
  }) {
    _restYn = restYn;
    _restStartsAt = restStartsAt;
    _restEndsAt = restEndsAt;
    if (notiboxUnreadYn != null) {
      _notiboxUnreadYn = notiboxUnreadYn;
    }
  }

  /// Overview 진입 전 휴식 안내 레이어 노출 여부 판단.
  /// true 반환 시 레이어 노출, false 시 Overview로 진행.
  bool shouldShowRestOverlay() {
    if (_restYn == 'Y') return true;
    if (_restYn != 'N') return false;
    final start = _restStartsAt;
    final end = _restEndsAt;
    if (start == null || end == null) return false;
    final nowUtc = DateTime.now().toUtc();
    if (nowUtc.isBefore(start) || nowUtc.isAfter(end)) return false;
    update(restYn: 'Y', restStartsAt: start, restEndsAt: end);
    return true;
  }
}
