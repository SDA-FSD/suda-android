import 'package:flutter_test/flutter_test.dart';
import 'package:suda/models/rank_models.dart';
import 'package:suda/services/rank_like_overlay.dart';

void main() {
  const snap = '202001010000';

  RankEntryDto row(int rank, int like) {
    return RankEntryDto(
      rank: rank,
      userId: rank,
      weeklyLike: like,
    );
  }

  setUp(RankLikeOverlay.debugReset);

  tearDown(RankLikeOverlay.debugReset);

  test('tail window places a first entry below its top score', () {
    RankLikeOverlay.recordSessionLike(historyId: 1, delta: 15);
    final placement = RankLikeOverlay.resolveEntry(
      collect: true,
      snapshotMinute: snap,
      window: [row(101, 30), row(102, 20), row(103, 10)],
      windowStartRank: 101,
      coversRankOne: false,
      total: 103,
    );
    expect(placement?.rank, 103);
    expect(placement?.weeklyLike, 15);
  });

  test('score below everyone is total + 1', () {
    RankLikeOverlay.recordSessionLike(historyId: 1, delta: 5);
    final placement = RankLikeOverlay.resolveEntry(
      collect: true,
      snapshotMinute: snap,
      window: [row(101, 30), row(102, 20), row(103, 10)],
      windowStartRank: 101,
      coversRankOne: false,
      total: 103,
    );
    expect(placement?.rank, 104);
    expect(placement?.weeklyLike, 5);
  });

  test('score at or above the tail top stays unresolved', () {
    RankLikeOverlay.recordSessionLike(historyId: 1, delta: 30);
    expect(
      RankLikeOverlay.resolveEntry(
        collect: true,
        snapshotMinute: snap,
        window: [row(101, 30), row(102, 20)],
        windowStartRank: 101,
        coversRankOne: false,
        total: 102,
      ),
      isNull,
    );

    RankLikeOverlay.debugReset();
    RankLikeOverlay.recordSessionLike(historyId: 2, delta: 31);
    expect(
      RankLikeOverlay.resolveEntry(
        collect: true,
        snapshotMinute: snap,
        window: [row(101, 30), row(102, 20)],
        windowStartRank: 101,
        coversRankOne: false,
        total: 102,
      ),
      isNull,
    );
  });

  test('full board can place first and inside the list', () {
    RankLikeOverlay.recordSessionLike(historyId: 1, delta: 40);
    expect(
      RankLikeOverlay.resolveEntry(
        collect: true,
        snapshotMinute: snap,
        window: [row(1, 30), row(2, 20), row(3, 10)],
        windowStartRank: 1,
        coversRankOne: true,
        total: 3,
      )?.rank,
      1,
    );

    RankLikeOverlay.debugReset();
    RankLikeOverlay.recordSessionLike(historyId: 2, delta: 25);
    expect(
      RankLikeOverlay.resolveEntry(
        collect: true,
        snapshotMinute: snap,
        window: [row(1, 30), row(2, 20), row(3, 10)],
        windowStartRank: 1,
        coversRankOne: true,
        total: 3,
      )?.rank,
      2,
    );
  });

  test('empty board is rank 1, a gap is unresolved', () {
    RankLikeOverlay.recordSessionLike(historyId: 1, delta: 8);
    expect(
      RankLikeOverlay.resolveEntry(
        collect: true,
        snapshotMinute: snap,
        window: const [],
        windowStartRank: 1,
        coversRankOne: true,
        total: 0,
      )?.rank,
      1,
    );

    RankLikeOverlay.debugReset();
    RankLikeOverlay.recordSessionLike(historyId: 2, delta: 8);
    expect(
      RankLikeOverlay.resolveEntry(
        collect: true,
        snapshotMinute: snap,
        window: [row(101, 10), row(103, 4)],
        windowStartRank: 101,
        coversRankOne: false,
        total: 103,
      ),
      isNull,
    );
  });

  test('an existing ranker still does not use the entry path', () {
    RankLikeOverlay.recordSessionLike(historyId: 1, delta: 10);
    final me = row(8, 12);
    final board = [row(1, 40), me, row(9, 11)];
    final personalization = RankLikeOverlay.resolve(
      collect: true,
      snapshotMinute: snap,
      me: me.copyWith(isMe: true),
      board: board,
    );
    expect(personalization, isNotNull);
    expect(personalization!.nowLike, 22);
  });
}
