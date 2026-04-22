allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)


subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.getByName("android") as? com.android.build.gradle.BaseExtension
            if (android != null) {
                // Auto-inject namespace if missing
                if (android.namespace == null) {
                    android.namespace = project.group.toString().ifEmpty { "com.kawach.fallback.${project.name.replace("-", "_")}" }
                }
                // Force minimum compileSdk 35 for AndroidX Core 1.18 compat
                val currentSdk = android.compileSdkVersion?.replace("android-", "")?.toIntOrNull() ?: 0
                if (currentSdk < 35) {
                    android.compileSdkVersion(35)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
