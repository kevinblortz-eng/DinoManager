# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Suppress warnings for ML Kit classes that may not be available
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# ---------------------------------------------------------------------------
# Fix Play Console : DEX obfuscation (R8 activé dans build.gradle.kts)
# Aucun -keep superflu : chaque classe gardée fait baisser le score
# d'obfuscation. N'ajouter des règles QUE si un crash Release l'exige.
# ---------------------------------------------------------------------------

# Ne pas renommer les classes pointées par le manifeste (déjà géré par R8/AAPT)
# Garde-fou générique : annotations conservées pour les plugins AndroidX
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Les plugins de ce projet (hive, provider, shared_preferences, camera,
# image_picker, permission_handler, device_info_plus...) n'utilisent pas
# de réflexion sur les classes Dart : rien à garder côté applicatif.
