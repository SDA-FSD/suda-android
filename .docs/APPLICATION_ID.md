# ApplicationId와 applicationIdSuffix 동작 방식

## 개요
Android Gradle Plugin이 `applicationIdSuffix`를 어떻게 처리하는지 설명합니다.

## applicationIdSuffix 적용 위치

### 1. 빌드 시점 처리
`applicationIdSuffix`는 **Android Gradle Plugin이 빌드 시점에 자동으로 처리**합니다.

**처리 순서:**
1. `defaultConfig.applicationId` (기본값): `kr.sudatalk.app`
2. `productFlavors[flavor].applicationIdSuffix` (추가): `.local`
3. **최종 applicationId**: `kr.sudatalk.app.local`

### 2. 실제 적용 위치

#### build.gradle.kts에서의 설정
```kotlin
defaultConfig {
    applicationId = "kr.sudatalk.app"  // 기본값
}

productFlavors {
    create("local") {
        applicationIdSuffix = ".local"  // suffix 추가
    }
}
```

#### Android Gradle Plugin 내부 처리
Android Gradle Plugin은 빌드 시점에 다음을 수행합니다:

1. **Variant 생성 시점** (`VariantManager`)
   - `defaultConfig.applicationId` + `flavor.applicationIdSuffix` + `buildType.applicationIdSuffix` (있는 경우)
   - 최종 applicationId 계산: `kr.sudatalk.app` + `.local` = `kr.sudatalk.app.local`

2. **매니페스트 병합 시점** (`ManifestMerger`)
   - 생성된 매니페스트에 최종 applicationId 적용
   - 위치: `build/intermediates/merged_manifests/{variant}/AndroidManifest.xml`

3. **APK 패키징 시점** (`PackageApplication`)
   - 최종 applicationId로 APK 패키징
   - 위치: `build/app/outputs/apk/{variant}/app-{variant}.apk`

### 3. 확인 방법

#### 방법 1: 빌드된 매니페스트 확인
```bash
# 빌드 후 생성된 매니페스트 확인
find build/app/intermediates/merged_manifests/localDebug -name "AndroidManifest.xml" | xargs grep "package="
```

#### 방법 2: APK 정보 확인
```bash
# APK의 패키지명 확인
aapt dump badging build/app/outputs/flutter-apk/app-local-debug.apk | grep "package:"
```

#### 방법 3: Gradle 빌드 정보 확인
```bash
# 빌드 시 applicationId 출력
cd android
./gradlew :app:assembleLocalDebug --info | grep -i "applicationId"
```

#### 방법 4: Flutter 빌드 정보 확인
```bash
# Flutter 빌드 시 패키지명 확인
flutter build apk --flavor local --debug
# 빌드 로그에서 패키지명 확인
```

### 4. 실제 적용되는 위치

**최종 applicationId가 사용되는 곳:**
1. **AndroidManifest.xml** (병합된 최종 매니페스트)
   - `build/app/intermediates/merged_manifests/{variant}/AndroidManifest.xml`
   - `<manifest package="kr.sudatalk.app.local">`

2. **APK 파일**
   - `build/app/outputs/flutter-apk/app-{variant}.apk`
   - APK 내부의 AndroidManifest.xml에 최종 패키지명 저장

3. **R 클래스 생성**
   - `build/app/generated/source/r/{variant}/kr/sudatalk/app/local/R.java`
   - 패키지 구조가 최종 applicationId를 따름

4. **Google Sign-In 인식**
   - Google Play Services가 APK의 패키지명을 읽어서
   - Google Console에 등록된 패키지명과 비교

### 5. 현재 프로젝트 설정

**Local 환경:**
- 기본: `kr.sudatalk.app`
- Suffix: `.local`
- **최종**: `kr.sudatalk.app.local`

**Dev 환경:**
- 기본: `kr.sudatalk.app`
- Suffix: `.dev`
- **최종**: `kr.sudatalk.app.dev`

**Prd 환경:**
- 기본: `kr.sudatalk.app`
- Suffix: 없음
- **최종**: `kr.sudatalk.app`

### 6. 중요 사항

- `applicationIdSuffix`는 **빌드 시점에만 적용**됩니다
- 소스 코드의 패키지명(`namespace`)과는 별개입니다
- `namespace`는 코드 내부에서 사용되고, `applicationId`는 APK의 실제 패키지명입니다
- Google Sign-In은 **APK의 실제 패키지명**(최종 applicationId)을 사용합니다

