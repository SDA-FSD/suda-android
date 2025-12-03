# 키스토어 및 SHA-1 관리 가이드

## 개요
Android 앱 배포 시 사용할 키스토어와 Google 서비스 연동을 위한 SHA-1 지문 관리 방법

## 1. 디버그 키스토어 (개발용)
- **위치**: `~/.android/debug.keystore`
- **비밀번호**: `android`
- **용도**: 개발 중 테스트용
- **SHA-1 지문**: `FF:10:83:3C:21:C9:53:93:6C:45:0A:BA:B6:13:60:8D:5D:74:85:97`
- **등록 위치**: 디버그 계정 Google Cloud 프로젝트

## 2. 릴리스 키스토어 (배포용)
### 생성 방법

```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

생성 시 입력 정보:
- **키스토어 비밀번호**: 안전한 비밀번호 입력 (기억해야 함!)
- **키 별칭(alias)**: `upload` (또는 원하는 이름)
- **키 비밀번호**: 키스토어 비밀번호와 동일하거나 별도 설정
- **이름/조직**: 실제 정보 입력 (나중에 변경 불가)

### 키스토어 설정 파일 생성

1. `android/key.properties.example` 파일을 복사:
```bash
cp android/key.properties.example android/key.properties
```

2. `android/key.properties` 파일을 열어 실제 값 입력:
```
storePassword=실제_키스토어_비밀번호
keyPassword=실제_키_비밀번호
keyAlias=upload
storeFile=../app/upload-keystore.jks
```

### 릴리스 키스토어의 SHA-1 확인

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

SHA-1 지문을 복사하여 Google 콘솔에 등록합니다.

**현재 상용 SHA-1 지문**: `BB:07:71:52:8D:E1:11:1C:6D:05:FF:09:5D:12:CD:70:47:DF:5F:AC`

## 3. Google 콘솔 SHA-1 등록

### 별개의 Google Cloud 프로젝트 사용 시
디버그 계정과 상용 계정이 완전히 별개의 Google Cloud 프로젝트인 경우:
- **디버그 계정 프로젝트**: 디버그 키스토어 SHA-1만 등록
- **상용 계정 프로젝트**: 릴리스 키스토어 SHA-1만 등록

각 프로젝트는 독립적으로 관리되므로 해당하는 SHA-1만 등록하면 됩니다.

### 등록 위치:
- Google Cloud Console → API 및 서비스 → 사용자 인증 정보
- 또는 Firebase Console → 프로젝트 설정 → Android 앱

### 환경별 Google 콘솔 설정:
- **local/dev/stg 환경**: 
  - 디버그 계정 프로젝트 사용
  - 디버그 키스토어 SHA-1만 등록
  - 패키지명: `kr.sudatalk.app.{env}`
  
- **prd 환경 (릴리스 빌드)**:
  - 상용 계정 프로젝트 사용
  - 릴리스 키스토어 SHA-1만 등록
  - 패키지명: `kr.sudatalk.app`
  - 상용 SHA-1: `BB:07:71:52:8D:E1:11:1C:6D:05:FF:09:5D:12:CD:70:47:DF:5F:AC`
  - 상용 Client ID: `12033207645-tos8um06qs9599iqi1oubibll459889g.apps.googleusercontent.com`

## 4. 키스토어와 빌드 타입
- **디버그 빌드**: 항상 디버그 키스토어 사용
- **릴리스 빌드**: key.properties가 있으면 릴리스 키스토어 사용, 없으면 디버그 키스토어 사용

## 5. 키스토어 보안

- ⚠️ **절대 Git에 커밋하지 마세요!**
- `key.properties`와 `*.jks`, `*.keystore` 파일은 `.gitignore`에 포함되어 있습니다
- 키스토어 파일은 안전한 곳에 백업하세요 (분실 시 복구 불가능)
- 팀 공유 시 안전한 비밀 관리 도구 사용 권장

## 6. 빌드 명령어

### 디버그 빌드 (디버그 키스토어 사용):
```bash
flutter build apk --debug --flavor prd
```

### 릴리스 빌드 (릴리스 키스토어 사용):
```bash
flutter build apk --release --flavor prd --dart-define=ENV=prd
```

