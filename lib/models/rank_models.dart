import 'common_models.dart';

DateTime? _parseInstant(dynamic v) {
  if (v == null) return null;
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return null;
    try {
      return DateTime.parse(t).toUtc();
    } catch (_) {
      return null;
    }
  }
  if (v is num) {
    final n = v.toInt();
    if (n <= 0) return null;
    // epoch milli vs second
    final ms = n > 100000000000 ? n : n * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
  return null;
}

/// GET /v1/rank/period/current
class RankPeriodDto {
  final int? periodId;
  final String? phase; // "COLLECT" | "ANNOUNCE"
  final DateTime? collectStartsAt;
  final DateTime? collectEndsAt;
  final DateTime? nextCollectStartsAt;
  final DateTime? phaseEndsAt;
  final DateTime? serverNow;
  final int liveRankSize;

  const RankPeriodDto({
    this.periodId,
    this.phase,
    this.collectStartsAt,
    this.collectEndsAt,
    this.nextCollectStartsAt,
    this.phaseEndsAt,
    this.serverNow,
    this.liveRankSize = 0,
  });

  factory RankPeriodDto.fromJson(Map<String, dynamic> json) {
    return RankPeriodDto(
      periodId: (json['periodId'] as num?)?.toInt(),
      phase: json['phase'] as String?,
      collectStartsAt: _parseInstant(json['collectStartsAt']),
      collectEndsAt: _parseInstant(json['collectEndsAt']),
      nextCollectStartsAt: _parseInstant(json['nextCollectStartsAt']),
      phaseEndsAt: _parseInstant(json['phaseEndsAt']),
      serverNow: _parseInstant(json['serverNow']),
      liveRankSize: (json['liveRankSize'] as num?)?.toInt() ?? 0,
    );
  }
}

/// RankEntryDto.
class RankEntryDto {
  final int rank;
  final int? userId;
  final String? name;
  final String? imgPath;
  final int weeklyLike;
  final String subscribedYn; // "Y" | "N"
  final int level;
  final bool isMe;

  const RankEntryDto({
    required this.rank,
    this.userId,
    this.name,
    this.imgPath,
    this.weeklyLike = 0,
    this.subscribedYn = 'N',
    this.level = 0,
    this.isMe = false,
  });

  factory RankEntryDto.fromJson(Map<String, dynamic> json) {
    return RankEntryDto(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt(),
      name: json['name'] as String?,
      imgPath: json['imgPath'] as String?,
      weeklyLike: (json['weeklyLike'] as num?)?.toInt() ?? 0,
      subscribedYn: sudaYnFromJson(json['subscribedYn']),
      level: (json['level'] as num?)?.toInt() ?? 0,
      isMe: json['isMe'] == true,
    );
  }

  RankEntryDto copyWith({
    int? rank,
    int? userId,
    String? name,
    String? imgPath,
    int? weeklyLike,
    String? subscribedYn,
    int? level,
    bool? isMe,
  }) {
    return RankEntryDto(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imgPath: imgPath ?? this.imgPath,
      weeklyLike: weeklyLike ?? this.weeklyLike,
      subscribedYn: subscribedYn ?? this.subscribedYn,
      level: level ?? this.level,
      isMe: isMe ?? this.isMe,
    );
  }
}

/// GET /v1/rank/entries
class RankEntryPageDto {
  final int? periodId;
  final String? snapshotMinute;
  final int pageNum;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasMore;
  final int? nextPageNum;
  final List<RankEntryDto> entries;

  const RankEntryPageDto({
    this.periodId,
    this.snapshotMinute,
    this.pageNum = 0,
    this.pageSize = 50,
    this.total = 0,
    this.totalPages = 0,
    this.hasMore = false,
    this.nextPageNum,
    this.entries = const [],
  });

  factory RankEntryPageDto.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'];
    final List<RankEntryDto> entries = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => RankEntryDto.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const [];
    final pageNum = (json['pageNum'] as num?)?.toInt() ?? 0;
    final pageSize = (json['pageSize'] as num?)?.toInt() ?? 50;
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final totalPages = (json['totalPages'] as num?)?.toInt() ?? 0;
    final parsedNext = (json['nextPageNum'] as num?)?.toInt();
    // hasMore: 서버 값 우선. 없을 때만 total/totalPages로 추론.
    // entries.length == pageSize 만으로는 추론하지 않음 (total==pageSize인 마지막 page와 구분 불가)
    final hasMore = json['hasMore'] == true ||
        parsedNext != null ||
        (totalPages > 0 && pageNum + 1 < totalPages) ||
        (total > 0 && (pageNum + 1) * pageSize < total);
    final nextPageNum = parsedNext ?? (hasMore ? pageNum + 1 : null);
    return RankEntryPageDto(
      periodId: (json['periodId'] as num?)?.toInt(),
      snapshotMinute: json['snapshotMinute'] as String?,
      pageNum: pageNum,
      pageSize: pageSize,
      total: total,
      totalPages: totalPages,
      hasMore: hasMore,
      nextPageNum: nextPageNum,
      entries: entries,
    );
  }
}

/// 랭킹 탭 화면용. /period/current + /entries 를 합친다.
class RankScreenDto {
  final RankPeriodDto? period;
  final int snapVersion;
  final int total;
  final int? nextFromRank;
  final List<RankEntryDto> topEntries;
  final RankEntryDto? myEntry;
  final String? snapshotMinute;
  final bool hasMore;
  final int? nextPageNum;
  final List<RankEntryDto> listEntries;

  const RankScreenDto({
    this.period,
    this.snapVersion = 0,
    this.total = 0,
    this.nextFromRank,
    this.topEntries = const [],
    this.myEntry,
    this.snapshotMinute,
    this.hasMore = false,
    this.nextPageNum,
    this.listEntries = const [],
  });

  factory RankScreenDto.fromPeriodAndPage({
    required RankPeriodDto? period,
    required RankEntryPageDto page,
    int? meUserId,
  }) {
    final sorted = [...page.entries]..sort((a, b) => a.rank.compareTo(b.rank));
    RankEntryDto? myEntry;
    for (final e in sorted) {
      if (e.isMe || (meUserId != null && e.userId == meUserId)) {
        myEntry = e.copyWith(isMe: true);
        break;
      }
    }
    return RankScreenDto(
      period: period,
      snapVersion: 0,
      total: page.total,
      nextFromRank: page.hasMore ? 11 : null,
      topEntries: sorted.where((e) => e.rank >= 1 && e.rank <= 10).toList(),
      myEntry: myEntry,
      snapshotMinute: page.snapshotMinute,
      hasMore: page.hasMore,
      nextPageNum: page.nextPageNum,
      listEntries: sorted.where((e) => e.rank >= 4).toList(),
    );
  }
}
