# google_mlkit_text_recognition references the optional per-script ML Kit
# recognizer classes (Chinese/Japanese/Korean/Devanagari) generically,
# regardless of which TextRecognitionScript the app actually uses. This app
# only uses TextRecognitionScript.latin, so those optional artifacts are
# never added as dependencies — R8 can't find the classes and fails release
# minification unless told these references are safe to ignore.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
