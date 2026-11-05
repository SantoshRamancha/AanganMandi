# Release shrinking (R8) rules.

# google_mlkit_text_recognition can load Chinese, Devanagari, Japanese and Korean recognisers, but we only
# bundle the Latin one. Their option classes are referenced but absent, which is expected.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
