import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/user_models.dart';

/// Main Screen 하단 GNB. 본문 위에 오버레이, 투명+블러 배경.
/// 아이콘: Alarm 22% / Home 50% / Profile 78% (각 아이콘 중심이 해당 % 위치).
/// 탭 영역: 좌 33% / 중앙 34% / 우 33%. 아이콘 레이어는 IgnorePointer로 터치가 하단 탭 영역으로 전달.
class GnbBar extends StatelessWidget {
  const GnbBar({
    super.key,
    required this.isAlarmActive,
    required this.isHomeActive,
    required this.isProfileActive,
    this.onAlarmTap,
    this.onHomeTap,
    this.onProfileTap,
    this.user,
  });

  final bool isAlarmActive;
  final bool isHomeActive;
  final bool isProfileActive;
  final VoidCallback? onAlarmTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onProfileTap;
  final UserDto? user;

  /// playing 슬라이더와 동일: BackdropFilter sigma 6 + Color(0x598C8C8C)
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
            color: const Color(0x598C8C8C),
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
              height: 56,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  const double alarmIconSize = 24;
                  const double homeIconSize = 24;
                  const double profileAvatarSize = 28;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 탭 영역: 좌 33% / 중앙 34% / 우 33% (아이콘 터치도 이 영역에서 판정)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onAlarmTap,
                              child: const SizedBox.expand(),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onHomeTap,
                              child: const SizedBox.expand(),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onProfileTap,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                      // 아이콘 레이어: 터치 판정 제외(IgnorePointer) → 하단 탭 영역에서 처리
                      IgnorePointer(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Alarm: 22% 위치 (아이콘 중심)
                            Positioned(
                              left: w * 0.22 - alarmIconSize / 2,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Image.asset(
                                  isAlarmActive
                                      ? 'assets/images/icons/gnb_alarm_pressed.png'
                                      : 'assets/images/icons/gnb_alarm.png',
                                  height: alarmIconSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            // Home: 50% 위치 (아이콘 중심)
                            Positioned(
                              left: w * 0.5 - homeIconSize / 2,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Image.asset(
                                  isHomeActive
                                      ? 'assets/images/icons/gnb_home_pressed.png'
                                      : 'assets/images/icons/gnb_home.png',
                                  width: homeIconSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            // Profile: 78% 위치 (아바타 중심)
                            Positioned(
                              left: w * 0.78 - profileAvatarSize / 2,
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
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF1E1E1E),
      child: const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }
}
