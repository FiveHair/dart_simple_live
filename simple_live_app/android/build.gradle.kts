import com.android.build.api.dsl.LibraryExtension

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
}
subprojects {
    project.evaluationDependsOn(":app")
    // flutter-ohos 3.41 的 gradle 插件不会替插件模块应用 kotlin-android
    // （官方新版会），新版插件因此不再自行声明 kotlin，其 Kotlin 源码不参与
    // 编译、注册类缺失（如 auto_orientation_v2 的 AutoOrientationPlugin）。
    // 这里统一补应用。
    pluginManager.withPlugin("com.android.library") {
        if (!pluginManager.hasPlugin("org.jetbrains.kotlin.android") &&
            !pluginManager.hasPlugin("kotlin-android")
        ) {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }
    }
}

subprojects {
    if (name == "auto_orientation_v2") {
        pluginManager.withPlugin("com.android.library") {
            extensions.configure<LibraryExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
