# Minification is off for both build types today; these rules exist so that
# turning it on later does not silently break serialization or Room.

# kotlinx.serialization keeps its generated serializers in companion objects
# that look unused to R8.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class com.noizu.timely.** {
    *** Companion;
}
-keepclasseswithmembers class com.noizu.timely.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Retrofit interfaces are reflected over.
-keep,allowobfuscation interface com.noizu.timely.data.remote.**
-keepattributes Signature, Exceptions, RuntimeVisibleAnnotations

# AppAuth reads its own configuration reflectively.
-keep class net.openid.appauth.** { *; }
