# Suda — R8 / ProGuard (Phase 1)
# 플러그인 AAR consumer rules가 대부분을 담당. 여기는 앱/Flutter 공통 최소 keep.

# Flutter embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Google Play Core (Flutter deferred components / split install 호환)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
