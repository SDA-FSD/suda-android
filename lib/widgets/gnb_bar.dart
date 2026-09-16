import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/user_models.dart';

/// Main Screen 하단 GNB. 본문 위에 오버레이, 투명+블러 배경.
/// 아이콘: Home 12.5% / Alarm 37.5% / Rank 62.5% / Profile 87.5% (각 아이콘 중심).
/// 탭 영역: 4등분. 아이콘 레이어는 IgnorePointer로 터치가 하단 탭 영역으로 전달.
class GnbBar extends StatelessWidget {
  const GnbBar({
    super.key,
    required this.isHomeActive,
    required this.isAlarmActive,
    required this.isRankActive,
    required this.isProfileActive,
    this.showNotiboxUnreadBadge = false,
    this.onHomeTap,
    this.onAlarmTap,
    this.onRankTap,
    this.onProfileTap,
    this.user,
  });

  final bool isHomeActive;
  final bool isAlarmActive;
  final bool isRankActive;
  final bool isProfileActive;
  final bool showNotiboxUnreadBadge;
  final VoidCallback? onHomeTap;
  final VoidCallback? onAlarmTap;
  final VoidCallback? onRankTap;
  final VoidCallback? onProfileTap;
  final UserDto? user;

  /// 본문 아이콘 영역 고정 높이 (GNB가 본문을 덮을 때 리스트 하단 inset 등에 사용).
  static const double contentHeight = 56;

  /// 오버레이 공통: BackdropFilter sigma 6 + Color(0x59000000)
  /// GNB 상단(본문과 맞닿는 쪽) 좌·우 radius 10 둥근 처리
  static const BorderRadius _topCornerRadius = BorderRadius.only(
    topLeft: Radius.circular(10),
    topRight: Radius.circular(10),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _topCornerRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x59000000),
            borderRadius: _topCornerRadius,
            border: Border(
              top: BorderSide(
                color: Colors.grey[800]!,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: SizedBox(
              height: contentHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  const double iconSize = 24;
                  const double profileAvatarSize = 28;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 탭 영역: Home | Alarm | Rank | Profile (각 25%)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onHomeTap,
                              child: const SizedBox.expand(),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onAlarmTap,
                              child: const SizedBox.expand(),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onRankTap,
                              child: const SizedBox.expand(),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onProfileTap,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                      // 아이콘 레이어: 터치 판정 제외(IgnorePointer)
                      IgnorePointer(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Home: 12.5%
                            Positioned(
                              left: w * 0.125 - iconSize / 2,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Image.asset(
                                  isHomeActive
                                      ? 'assets/images/icons/gnb_home_pressed.png'
                                      : 'assets/images/icons/gnb_home.png',
                                  width: iconSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            // Alarm: 37.5%
                            Positioned(
                              left: w * 0.375 - iconSize / 2,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Image.asset(
                                      isAlarmActive
                                          ? 'assets/images/icons/gnb_alarm_pressed.png'
                                          : 'assets/images/icons/gnb_alarm.png',
                                      height: iconSize,
                                      fit: BoxFit.contain,
                                    ),
                                    if (showNotiboxUnreadBadge)
                                      Positioned(
                                        right: -2,
                                        top: -3,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF5252),
                                            shape: BoxShape.circle,
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x66FF5252),
                                                blurRadius: 3,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Rank: 62.5%
                            Positioned(
                              left: w * 0.625 - iconSize / 2,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Image.asset(
                                  isRankActive
                                      ? 'assets/images/icons/gnb_ranking_pressed.png'
                                      : 'assets/images/icons/gnb_ranking.png',
                                  width: iconSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            // Profile: 87.5%
                            Positioned(
                              left: w * 0.875 - profileAvatarSize / 2,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _GnbProfileAvatar(
                                  profileImgUrl: user?.profileImgUrl,
                                  isActive: isProfileActive,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// GNB용 프로필 아바타: 비활성 28x28 원형, 활성 24x24 원형 + 흰색 테두리 2
class _GnbProfileAvatar extends StatelessWidget {
  const _GnbProfileAvatar({
    this.profileImgUrl,
    required this.isActive,
  });

  static const String _defaultProfileImage =
      'assets/images/icons/default_profile_image.png';

  final String? profileImgUrl;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    const double inactiveSize = 28;
    const double activeInnerSize = 24;
    const double activeBorderWidth = 2;

    if (isActive) {
      return Container(
        width: activeInnerSize + (activeBorderWidth * 2),
        height: activeInnerSize + (activeBorderWidth * 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: activeBorderWidth),
        ),
        child: ClipOval(
          child: SizedBox(
            width: activeInnerSize,
            height: activeInnerSize,
            child: _image(activeInnerSize),
          ),
        ),
      );
    }

    return SizedBox(
      width: inactiveSize,
      height: inactiveSize,
      child: ClipOval(
        child: _image(inactiveSize),
      ),
    );
  }

  Widget _image(double size) {
    return (profileImgUrl != null && profileImgUrl!.isNotEmpty)
        ? CachedNetworkImage(
            imageUrl: profileImgUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => _placeholder(size),
          )
        : _placeholder(size);
  }

  Widget _placeholder(double size) {
    return Image.asset(
      _defaultProfileImage,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
