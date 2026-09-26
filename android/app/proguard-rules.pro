# Project-specific R8/ProGuard rules.
# Release build has isMinifyEnabled/isShrinkResources enabled (build.gradle.kts).

# --- Flutter embedding -------------------------------------------------------
# The engine instantiates and calls into these packages reflectively/JNI
# (plugin registration, Dart<->platform channels, view/renderer plumbing).
# Stripping or renaming them crashes the release build at startup.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.internal.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# --- okhttp3 -----------------------------------------------------------------
# HTTP client for the Android home-screen widget (dependency in build.gradle.kts).
# Looks up its Platform/protocol implementation reflectively and carries Kotlin
# metadata, so it must not be renamed or stripped.
-keep class com.squareup.okhttp3.** { *; }
-keep interface com.squareup.okhttp3.** { *; }

# --- androidx.security:security-crypto --------------------------------------
# EncryptedSharedPreferences/MasterKey used for widget credential storage;
# Keystore algorithm classes are resolved at runtime.
-keep class androidx.security.crypto.** { *; }

# --- app_links ---------------------------------------------------------------
# Deep link plugin (com.llfbandit.app_links.AppLinksPlugin, see
# GeneratedPluginRegistrant). Registered by name and reached through platform
# channels / intent callbacks, so keep name and members.
-keep class com.llfbandit.app_links.** { *; }
