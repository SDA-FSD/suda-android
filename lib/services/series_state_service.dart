import '../models/series_models.dart';
import '../models/user_models.dart';

/// S2 시리즈 플레이 컨텍스트를 메모리에 보관한다.
/// 다른 Series Overview 진입 시 [setSeriesOverview]로 refresh된다.
class SeriesStateService {
  SeriesStateService._();

  static final SeriesStateService instance = SeriesStateService._();

  int? _seriesId;
  RpS2SeriesOverviewDto? _overview;
  int? _selectedEpisodeId;
  UserDto? _user;
  RpS2SessionDto? _session;
  RpS2UserHistoryDto? _cachedUserHistory;
  bool _bestScoreRefreshPending = false;
  bool _profileHistoryRefreshPending = false;

  int? get seriesId => _seriesId;
  RpS2SeriesOverviewDto? get overview => _overview;
  int? get selectedEpisodeId => _selectedEpisodeId;
  UserDto? get user => _user;
  RpS2SessionDto? get session => _session;
  RpS2UserHistoryDto? get cachedUserHistory => _cachedUserHistory;
  String? get sessionId => _session?.sessionId;

  /// `overview.episodes` 배열 마지막 항목이 현재 선택 에피소드인지.
  bool get isLastEpisode {
    final episodes = _overview?.episodes;
    final episodeId = _selectedEpisodeId;
    if (episodes == null || episodes.isEmpty || episodeId == null) {
      return false;
    }
    return episodes.last.id == episodeId;
  }

  RpS2SeriesEpisodeDto? get selectedEpisode {
    final episodeId = _selectedEpisodeId;
    final episodes = _overview?.episodes;
    if (episodeId == null || episodes == null || episodes.isEmpty) {
      return null;
    }
    for (final episode in episodes) {
      if (episode.id == episodeId) return episode;
    }
    return null;
  }

  void setSeriesOverview({
    required int seriesId,
    required RpS2SeriesOverviewDto overview,
    UserDto? user,
  }) {
    if (_seriesId != seriesId) {
      _selectedEpisodeId = null;
      _session = null;
      _cachedUserHistory = null;
    }
    _seriesId = seriesId;
    _overview = overview;
    if (user != null) {
      _user = user;
    }
  }

  void setSelectedEpisodeId(int episodeId) {
    if (_selectedEpisodeId != episodeId) {
      _session = null;
      _cachedUserHistory = null;
    }
    _selectedEpisodeId = episodeId;
  }

  void setUser(UserDto? user) {
    _user = user;
  }

  void setSession(RpS2SessionDto session) {
    _session = session;
  }

  /// Try Again Retry 등 동일 에피소드 재시작 전 이전 세션·히스토리 캐시 제거.
  void clearPlaySession() {
    _session = null;
    _cachedUserHistory = null;
  }

  void setCachedUserHistory(RpS2UserHistoryDto? history) {
    _cachedUserHistory = history;
  }

  /// Roleplay 스택에서 Overview로 pop 직전에 설정. Overview [didPopNext]에서 소비.
  void markBestScoreRefreshPending() {
    _bestScoreRefreshPending = true;
  }

  bool consumeBestScoreRefreshPending() {
    if (!_bestScoreRefreshPending) return false;
    _bestScoreRefreshPending = false;
    return true;
  }

  /// Roleplay 종료 후 Profile History 목록 갱신용. Profile 탭 활성 시 소비.
  void markProfileHistoryRefreshPending() {
    _profileHistoryRefreshPending = true;
  }

  bool consumeProfileHistoryRefreshPending() {
    if (!_profileHistoryRefreshPending) return false;
    _profileHistoryRefreshPending = false;
    return true;
  }

  void clear() {
    _seriesId = null;
    _overview = null;
    _selectedEpisodeId = null;
    _user = null;
    _session = null;
    _cachedUserHistory = null;
    _bestScoreRefreshPending = false;
    _profileHistoryRefreshPending = false;
  }
}
