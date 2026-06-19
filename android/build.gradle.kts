plugins {
  // Must be inside plugins {} in Kotlin DSL
  id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
  repositories {
    google()
    mavenCentral()
  }
}

// buildDir expects a File (not a String)
rootProject.buildDir = file("../build")

subprojects {
  project.buildDir = file("${rootProject.buildDir}/${project.name}")
  project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
  delete(rootProject.buildDir)
}
