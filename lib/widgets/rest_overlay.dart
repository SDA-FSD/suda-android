import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/rest_status_service.dart';
import '../utils/language_util.dart';

/// Overview 진입 전 휴식 안내 레이어.
/// restYn/restStartsAt/restEndsAt 확인 후 노출되며, 닫기 시 레이어만 제거.
class RestOverlay extends StatefulWidget {
  const RestOverlay({super.key});

  @override
  State<RestOverlay> createState() => _RestOverlayState();
}

class _RestOverlayState extends State<RestOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    if (RestStatusService.instance.restEndsAt == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final areaWidth = size.width * 0.8;
    final areaHeight = areaWidth * 1.5 + 60;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1) 전체 덮는 배경 (playing 슬라이더와 동일)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: const Color(0x59000000),
              ),
            ),
          ),
          // 2) 닫기 아이콘 (24x24, 좌상 30,60, 40x40 탭 영역)
          Positioned(
            left: 30,
            top: 60,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/icons/close.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
          ),
          // 3) 콘텐츠 영역 (가로 80%, 세로 width*1.5+60, 배경/radius 없음)
          Center(
            child: SizedBox(
              width: areaWidth,
              height: areaHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 4) 이미지 (top/bottom 30, 크기 areaWidth x 1.5, 타이틀/타이머에 가려짐)
                  Positioned(
                    top: 30,
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: _buildImage(areaWidth, areaWidth * 1.5),
                  ),
                  // 5) 상단 타이틀
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Center(
                      child: IntrinsicWidth(
                        child: _buildTitle(),
                      ),
                    ),
                  ),
                  // 6) 하단 타이머 (restEndsAt 있을 때만)
                  if (RestStatusService.instance.restEndsAt != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: Center(
                        child: IntrinsicWidth(
                          child: _buildTimer(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 이미지 요소: radius 30, 테두리 10·80D7CF, 테두리 안쪽 10px부터 그라데이션
  Widget _buildImage(double width, double height) {
    final lang = LanguageUtil.getCurrentLanguageCode();
    final asset = lang == 'pt'
        ? 'assets/images/rest_full_layer_pt.png'
        : 'assets/images/rest_full_layer_en.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 이미지
          Center(
            child: SizedBox(
              width: width,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A1A1A),
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          // 테두리 10, 80D7CF
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF80D7CF), width: 10),
              ),
            ),
          ),
          // 그라데이션: 테두리 안쪽 바로 시작, 검정 100% -> 0%
          Positioned(
            top: 10,
            bottom: 10,
            left: 10,
            right: 10,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned(top: 0, left: 0, right: 0, height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black, Colors.black.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(bottom: 0, left: 0, right: 0, height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black, Colors.black.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(top: 0, bottom: 0, left: 0, width: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.black, Colors.black.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(top: 0, bottom: 0, right: 0, width: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [Colors.black, Colors.black.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF80D7CF),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'THE REST DAY',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final endAt = RestStatusService.instance.restEndsAt;
    if (endAt == null) return const SizedBox.shrink();

    final nowUtc = DateTime.now().toUtc();
    Duration remaining = endAt.difference(nowUtc);
    if (remaining.isNegative) remaining = Duration.zero;

    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);
    final str = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0CABA8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          str,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

