# Flutter default ProGuard rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Rules for Firebase libraries
-keep class com.google.firebase.** { *; }
-keepnames class com.google.android.gms.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Rules for Google Play Core library used by Flutter
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep models and their fields (replace com.example.yourpackage.models.** if your models are elsewhere)
-keep class com.example.doctors_path_academy.models.** { *; }

# Keep custom views, if any
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
    public void set*(...);
}

# Keep a specific service if you have one
#-keep class com.example.MyService

# For libraries that use reflection
-keepattributes Signature

# For enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom annotations
-keep @interface com.google.firebase.database.PropertyName
-keep @interface com.google.firebase.firestore.PropertyName
