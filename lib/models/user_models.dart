import 'common_models.dart';

/// GET /v1/users/energy/detail 응답
class UserEnergyDto {
  final int energyCount;
  final int maxEnergyCount;
  final DateTime? lastAutoChargedAt;
  final DateTime? unlimitedEndsAt;
  final String subscribedYn;
  final DateTime? subscriptionExpiredAt;
  final String showUnlimitedPurchaseYn;
  final String showCapacity6PurchaseYn;
  final String showCapacity7PurchaseYn;

  const UserEnergyDto({
    required this.energyCount,
    required this.maxEnergyCount,
    this.lastAutoChargedAt,
    this.unlimitedEndsAt,
    this.subscribedYn = 'N',
    this.subscriptionExpiredAt,
    this.showUnlimitedPurchaseYn = 'N',
    this.showCapacity6PurchaseYn = 'N',
    this.showCapacity7PurchaseYn = 'N',
  });

  factory UserEnergyDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseInstant(dynamic v) {
      if (v == null) return null;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return UserEnergyDto(
      energyCount: json['energyCount'] as int? ?? 0,
      maxEnergyCount: json['maxEnergyCount'] as int? ?? 0,
      lastAutoChargedAt: parseInstant(json['lastAutoChargedAt']),
      unlimitedEndsAt: parseInstant(json['unlimitedEndsAt']),
      subscribedYn: json['subscribedYn'] as String? ?? 'N',
      subscriptionExpiredAt: parseInstant(json['subscriptionExpiredAt']),
      showUnlimitedPurchaseYn: json['showUnlimitedPurchaseYn'] as String? ?? 'N',
      showCapacity6PurchaseYn: json['showCapacity6PurchaseYn'] as String? ?? 'N',
      showCapacity7PurchaseYn: json['showCapacity7PurchaseYn'] as String? ?? 'N',
    );
  }

  UserEnergyDto copyWith({
    int? energyCount,
    int? maxEnergyCount,
    DateTime? lastAutoChargedAt,
    DateTime? unlimitedEndsAt,
    String? subscribedYn,
    DateTime? subscriptionExpiredAt,
    String? showUnlimitedPurchaseYn,
    String? showCapacity6PurchaseYn,
    String? showCapacity7PurchaseYn,
  }) {
    return UserEnergyDto(
      energyCount: energyCount ?? this.energyCount,
      maxEnergyCount: maxEnergyCount ?? this.maxEnergyCount,
      lastAutoChargedAt: lastAutoChargedAt ?? this.lastAutoChargedAt,
      unlimitedEndsAt: unlimitedEndsAt ?? this.unlimitedEndsAt,
      subscribedYn: subscribedYn ?? this.subscribedYn,
      subscriptionExpiredAt:
          subscriptionExpiredAt ?? this.subscriptionExpiredAt,
      showUnlimitedPurchaseYn:
          showUnlimitedPurchaseYn ?? this.showUnlimitedPurchaseYn,
      showCapacity6PurchaseYn:
          showCapacity6PurchaseYn ?? this.showCapacity6PurchaseYn,
      showCapacity7PurchaseYn:
          showCapacity7PurchaseYn ?? this.showCapacity7PurchaseYn,
    );
  }

  bool isUnlimitedActiveAt(DateTime nowUtc) {
    final endsAt = unlimitedEndsAt;
    if (endsAt == null) return false;
    return endsAt.isAfter(nowUtc);
  }

  /// 서버 `subscribedYn` + 로컬 만료 시각. 만료 후 재조회 전까지도 아이콘을 바로 전환.
  bool isSubscribedActiveAt(DateTime nowUtc) {
    if (subscribedYn != 'Y') return false;
    final exp = subscriptionExpiredAt;
    if (exp == null) return true;
    return exp.isAfter(nowUtc);
  }

  bool needsSubscriptionExpiryWatch(DateTime nowUtc) {
    if (subscribedYn != 'Y') return false;
    final exp = subscriptionExpiredAt;
    if (exp == null) return false;
    return exp.isAfter(nowUtc);
  }

  bool get showUnlimitedPurchase => showUnlimitedPurchaseYn == 'Y';
  bool get showCapacity6Purchase => showCapacity6PurchaseYn == 'Y';
  bool get showCapacity7Purchase => showCapacity7PurchaseYn == 'Y';
}

/// POST /v1/purchases/verify 응답
class PurchaseVerifyResultDto {
  final String successYn;
  final String pendingYn;

  const PurchaseVerifyResultDto({
    required this.successYn,
    required this.pendingYn,
  });

  factory PurchaseVerifyResultDto.fromJson(Map<String, dynamic> json) {
    return PurchaseVerifyResultDto(
      successYn: json['successYn'] as String? ?? 'N',
      pendingYn: json['pendingYn'] as String? ?? 'N',
    );
  }

  bool get isSuccess => successYn == 'Y';
  bool get isPending => pendingYn == 'Y';
}

/// PUT /v1/users/push-agreement 응답
class QuestResultDto {
  final String completeYn;

  const QuestResultDto({
    required this.completeYn,
  });

  factory QuestResultDto.fromJson(Map<String, dynamic> json) {
    return QuestResultDto(
      completeYn: json['completeYn'] as String? ?? 'N',
    );
  }
}

class ProfileDto {
  final UserDto userDto;
  final int currentLevel;
  final double progressPercentage;

  /// 레벨업까지 남은 Like 수. 서버가 `GET /v1/users/profile`에 내려줄 때만 채워짐.
  final int? likesToNextLevel;

  const ProfileDto({
    required this.userDto,
    required this.currentLevel,
    required this.progressPercentage,
    this.likesToNextLevel,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final rawLikes = json['likesToNextLevel'];
    int? likesToNext;
    if (rawLikes is int) {
      likesToNext = rawLikes;
    } else if (rawLikes is num) {
      likesToNext = rawLikes.round();
    }

    return ProfileDto(
      userDto: UserDto.fromJson(json['userDto'] as Map<String, dynamic>),
      currentLevel: json['currentLevel'] as int? ?? 0,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0,
      likesToNextLevel: likesToNext,
    );
  }
}

class UserDto {
  final int id;
  final String? provider;
  final String? sub;
  final String? name;
  final String? email;
  final String? profileImgUrl;
  final int? roleplayCount;
  final int? wordsSpokenCount;
  final int? likePoint;
  final String? createdAt;
  final String? updatedAt;
  final List<SudaJson>? metaInfo;

  const UserDto({
    required this.id,
    this.provider,
    this.sub,
    this.name,
    this.email,
    this.profileImgUrl,
    this.roleplayCount,
    this.wordsSpokenCount,
    this.likePoint,
    this.createdAt,
    this.updatedAt,
    this.metaInfo,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int? ?? 0,
      provider: json['provider'] as String?,
      sub: json['sub'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      profileImgUrl: json['profileImgUrl'] as String?,
      roleplayCount: json['roleplayCount'] as int?,
      wordsSpokenCount: json['wordsSpokenCount'] as int?,
      likePoint: json['likePoint'] as int?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      metaInfo: json['metaInfo'] == null
          ? null
          : (json['metaInfo'] as List<dynamic>)
              .map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }

  UserDto copyWith({
    int? id,
    String? provider,
    String? sub,
    String? name,
    String? email,
    String? profileImgUrl,
    int? roleplayCount,
    int? wordsSpokenCount,
    int? likePoint,
    String? createdAt,
    String? updatedAt,
    List<SudaJson>? metaInfo,
  }) {
    return UserDto(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      sub: sub ?? this.sub,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImgUrl: profileImgUrl ?? this.profileImgUrl,
      roleplayCount: roleplayCount ?? this.roleplayCount,
      wordsSpokenCount: wordsSpokenCount ?? this.wordsSpokenCount,
      likePoint: likePoint ?? this.likePoint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metaInfo: metaInfo ?? this.metaInfo,
    );
  }
}

extension UserDtoMetaInfoX on UserDto {
  /// Upserts a metaInfo entry (key/value). Keeps other entries untouched.
  /// If [metaInfo] is null/empty, it creates a new list with the given pair.
  UserDto upsertMetaInfo({
    required String key,
    required String value,
  }) {
    final current = metaInfo ?? const <SudaJson>[];
    final updated = <SudaJson>[
      ...current.where((m) => m.key != key),
      SudaJson(key: key, value: value),
    ];
    return copyWith(metaInfo: updated);
  }

  bool hasMetaInfoValue({
    required String key,
    required String value,
  }) {
    final current = metaInfo;
    if (current == null || current.isEmpty) return false;
    return current.any((m) => m.key == key && m.value == value);
  }
}

class NotificationDto {
  final int id;
  final List<SudaJson>? title;
  final List<SudaJson>? content;
  final String? imgPath;
  final String? appPath;
  final String? sendFinishedAt;
  final String readYn;

  const NotificationDto({
    required this.id,
    this.title,
    this.content,
    this.imgPath,
    this.appPath,
    this.sendFinishedAt,
    this.readYn = 'N',
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    int id;
    if (idRaw is int) {
      id = idRaw;
    } else if (idRaw is num) {
      id = idRaw.toInt();
    } else if (idRaw is String) {
      id = int.tryParse(idRaw.trim()) ?? 0;
    } else {
      id = 0;
    }
    return NotificationDto(
      id: id,
      title: (json['title'] as List<dynamic>?)
          ?.map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
          .toList(),
      content: (json['content'] as List<dynamic>?)
          ?.map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
          .toList(),
      imgPath: json['imgPath'] as String?,
      appPath: json['appPath'] as String?,
      sendFinishedAt: json['sendFinishedAt'] as String?,
      readYn: sudaYnFromJson(
        json['readYn'] ??
            json['read_yn'] ??
            json['readYN'] ??
            json['notifReadYn'],
      ),
    );
  }

  NotificationDto copyWith({
    int? id,
    List<SudaJson>? title,
    List<SudaJson>? content,
    String? imgPath,
    String? appPath,
    String? sendFinishedAt,
    String? readYn,
  }) {
    return NotificationDto(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imgPath: imgPath ?? this.imgPath,
      appPath: appPath ?? this.appPath,
      sendFinishedAt: sendFinishedAt ?? this.sendFinishedAt,
      readYn: readYn ?? this.readYn,
    );
  }
}

/// GET /v1/notice, GET /v1/notice/{noticeId} 응답
class AppNoticeDto {
  final int id;
  final String? type;
  final List<SudaJson>? title;
  final List<SudaJson>? content;
  final String? publishedAt;
  final String? createdAt;
  final String? updatedAt;

  const AppNoticeDto({
    required this.id,
    this.type,
    this.title,
    this.content,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AppNoticeDto.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final id = idValue is int
        ? idValue
        : (idValue is num ? idValue.toInt() : 0);
    return AppNoticeDto(
      id: id,
      type: json['type'] as String?,
      title: (json['title'] as List<dynamic>?)
          ?.map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
          .toList(),
      content: (json['content'] as List<dynamic>?)
          ?.map((item) => SudaJson.fromJson(item as Map<String, dynamic>))
          .toList(),
      publishedAt: json['publishedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}
