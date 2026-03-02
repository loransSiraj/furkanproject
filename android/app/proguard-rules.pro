# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Fonts
-keep class com.google.android.gms.** { *; }
-keep class androidx.core.provider.** { *; }
-keep class com.google.fonts.** { *; }
-keep class ** extends com.google.android.gms.common.internal.safeparcel.SafeParcelable { *; }

# OkHttp / HTTP client for Google Fonts
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Play Core (fix missing classes)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Timezone
-keep class org.threeten.** { *; }

# JSON / Serialization
-keepattributes *Annotation*
-keepattributes Signature
