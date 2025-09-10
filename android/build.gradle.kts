allprojects {
    repositories {
        google()
        mavenCentral()
    }
     subprojects {
        afterEvaluate {
            plugins.withId("com.android.application") {
                extensions.configure<com.android.build.gradle.AppExtension>("android") {
                    if (namespace == null) {
                        namespace = project.name
                    }
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_11
                        targetCompatibility = JavaVersion.VERSION_11
                    }
                }
            }
            plugins.withId("com.android.library") {
                extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                    if (namespace == null) {
                        namespace = project.name
                    }
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_11
                        targetCompatibility = JavaVersion.VERSION_11
                    }
                }
            }
            
            // Force Kotlin JVM target for all projects
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
                kotlinOptions {
                    jvmTarget = "11"
                }
            }
        }
    }
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
        classpath("com.google.firebase:firebase-crashlytics-gradle:2.9.9")
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
