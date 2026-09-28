import '../models/rank_models.dart';

/// 스냅샷 캡처 이후 확정된 세션 Like로, 내 주간 Like·등수만 느슨하게 보정한다.
///
/// 캡처 시각은 스냅샷 공개 분(`yyyyMMddHHmm` UTC) − 1분.
/// 그 시각 이후 세션만 더한다. 등수는 1위부터 빈틈없이 로드된 구간에
/// 내가 들어 있고, 새 점수가 그 구간 밖으로 동점 묶음을 남기지 않을 때만 바꾼다.
class RankLikeOverlay {
  RankLikeOverlay._();

  static final List<_PendingLike> _pending = [];
  static String? _presented;

  static void recordSessionLike({
    required int historyId,
    required int delta,
  }) {
    if (historyId <= 0 || delta <= 0) return;
    if (_pending.any((e) => e.historyId == historyId)) return;
    _pending.add(
      _PendingLike(
        historyId: historyId,
        delta: delta,
        observedAtUtc: DateTime.now().toUtc(),
      ),
    );
  }

  static void markPresented(List<int> historyIds) {
    if (historyIds.isEmpty || historyIds.any((id) => id <= 0)) return;
    final ids = [...historyIds]..sort();
    _presented = ids.join(',');
  }

  /// COLLECT가 아니거나 더할 세션이 없으면 null.
  /// 등수를 확신하지 못하면 [RankPersonalization.rankChanged]는 false이고 Like만 올린다.
  static RankPersonalization? resolve({
    required bool collect,
    required String? snapshotMinute,
    required RankEntryDto? me,
    required List<RankEntryDto> board,
  }) {
    if (!collect || me == null) return null;
    final capture = captureAt(snapshotMinute);
    if (capture == null) return null;
    _pending.removeWhere((e) => !e.observedAtUtc.isAfter(capture));
    if (_pending.isEmpty) return null;
    final delta = _pending.fold<int>(0, (sum, e) => sum + e.delta);
    if (delta <= 0) return null;
    final ids = _pending.map((e) => e.historyId).toList()..sort();
    final nowLike = me.weeklyLike + delta;
    final nowRank = _confidentRank(board: board, me: me, nowLike: nowLike);
    final rankChanged = nowRank != null && nowRank < me.rank;
    final signature = ids.join(',');
    return RankPersonalization(
      asIsRank: me.rank,
      asIsLike: me.weeklyLike,
      nowRank: nowRank ?? me.rank,
      nowLike: nowLike,
      rankChanged: rankChanged,
      animate: rankChanged && signature != _presented,
      historyIds: ids,
    );
  }

  /// 공개 분보다 1분 앞선 캡처 시각. 형식이 아니면 null.
  static DateTime? captureAt(String? snapshotMinute) {
    if (snapshotMinute == null || snapshotMinute.length != 12) return null;
    for (final unit in snapshotMinute.codeUnits) {
      if (unit < 0x30 || unit > 0x39) return null;
    }
    final year = int.parse(snapshotMinute.substring(0, 4));
    final month = int.parse(snapshotMinute.substring(4, 6));
    final day = int.parse(snapshotMinute.substring(6, 8));
    final hour = int.parse(snapshotMinute.substring(8, 10));
    final minute = int.parse(snapshotMinute.substring(10, 12));
    final effective = DateTime.utc(year, month, day, hour, minute);
    return effective.subtract(const Duration(minutes: 1));
  }

  static int? _confidentRank({
    required List<RankEntryDto> board,
    required RankEntryDto me,
    required int nowLike,
  }) {
    if (nowLike <= me.weeklyLike) return null;
    final sorted = [...board]..sort((a, b) => a.rank.compareTo(b.rank));
    final prefix = <RankEntryDto>[];
    var expect = 1;
    for (final entry in sorted) {
      if (entry.rank != expect) break;
      prefix.add(entry);
      expect++;
    }
    RankEntryDto? mine;
    for (final entry in prefix) {
      if (_sameUser(entry, me)) {
        mine = entry;
        break;
      }
    }
    if (mine == null) return null;
    // nowLike가 구간 최저보다 커야 같은 점수 묶음이 다음 페이지로 이어지지 않는다.
    if (nowLike <= prefix.last.weeklyLike) return null;
    var ahead = 0;
    for (final entry in prefix) {
      if (_sameUser(entry, me)) continue;
      if (entry.weeklyLike >= nowLike) ahead++;
    }
    final rank = ahead + 1;
    if (rank >= mine.rank) return null;
    return rank;
  }

  static List<RankEntryDto> reorder({
    required List<RankEntryDto> board,
    required RankEntryDto me,
    required int nowRank,
    required int nowLike,
  }) {
    final asIs = me.rank;
    final next = <RankEntryDto>[];
    for (final entry in board) {
      if (_sameUser(entry, me)) continue;
      if (entry.rank >= nowRank && entry.rank < asIs) {
        next.add(entry.copyWith(rank: entry.rank + 1, isMe: false));
      } else {
        next.add(entry.copyWith(isMe: false));
      }
    }
    next.add(
      me.copyWith(rank: nowRank, weeklyLike: nowLike, isMe: true),
    );
    next.sort((a, b) => a.rank.compareTo(b.rank));
    return next;
  }

  static bool _sameUser(RankEntryDto entry, RankEntryDto me) {
    final id = me.userId;
    if (id != null && entry.userId == id) return true;
    return entry.isMe && me.isMe;
  }
}

class RankPersonalization {
  const RankPersonalization({
    required this.asIsRank,
    required this.asIsLike,
    required this.nowRank,
    required this.nowLike,
    required this.rankChanged,
    required this.animate,
    required this.historyIds,
  });

  final int asIsRank;
  final int asIsLike;
  final int nowRank;
  final int nowLike;
  final bool rankChanged;
  final bool animate;
  final List<int> historyIds;
}

/// Lab 목데이터. 실스냅샷·세션 Like와 무관하게 같은 애니만 재생한다.
class RankBumpPreview {
  const RankBumpPreview({
    required this.fromRank,
    required this.toRank,
    required this.fromLike,
    required this.toLike,
  });

  final int fromRank;
  final int toRank;
  final int fromLike;
  final int toLike;

  /// 9위 → 4위. 리스트 상단에 둘 다 보인다.
  static const onScreen = RankBumpPreview(
    fromRank: 9,
    toRank: 4,
    fromLike: 140,
    toLike: 260,
  );

  /// 24위 → 18위. 스크롤 맨 위에서는 행이 화면 밖이고 sticky만 보인다.
  static const sticky = RankBumpPreview(
    fromRank: 24,
    toRank: 18,
    fromLike: 48,
    toLike: 96,
  );
}

class _PendingLike {
  const _PendingLike({
    required this.historyId,
    required this.delta,
    required this.observedAtUtc,
  });

  final int historyId;
  final int delta;
  final DateTime observedAtUtc;
}
