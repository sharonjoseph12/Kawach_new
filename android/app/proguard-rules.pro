# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# TFLite
-keep class org.tensorflow.lite.** { *; }

# Supabase / PostgREST / GoTrue
-keep class io.supabase.** { *; }

# Isar
-keep class isar.** { *; }

# Sentry
-keep class io.sentry.** { *; }

# Google Play Core (optional, referenced by Flutter Engine for deferred components)
-dontwarn com.google.android.play.core.**

# TFLite GPU delegate (optional runtime dependency)
-dontwarn org.tensorflow.lite.gpu.**

# Custom models
-keep class com.kawach.kawach.features.**.models.** { *; }
