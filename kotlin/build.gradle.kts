plugins {
    kotlin("jvm") version "2.4.20"
    id("org.jlleitschuh.gradle.ktlint") version "14.2.0"
    id("com.vanniktech.maven.publish") version "0.37.0"
}

group = property("GROUP") as String
version = property("VERSION_NAME") as String

dependencies {
    api("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0")
    api("org.jetbrains.kotlinx:kotlinx-serialization-json:1.11.0")

    testImplementation(kotlin("test"))
    testImplementation(platform("org.junit:junit-bom:5.14.4"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

kotlin {
    jvmToolchain(17)
    explicitApi()
    // usable from projects on Kotlin 2.2 and later
    coreLibrariesVersion = "2.2.21"
    compilerOptions {
        apiVersion = org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_2
        languageVersion = org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_2
        allWarningsAsErrors = true
    }
}

ktlint {
    version = "1.8.0"
}

// -PtestJdk=21 runs the tests on another JDK (the library targets 17)
val testJdk = providers.gradleProperty("testJdk")

tasks.withType<Test>().configureEach {
    if (testJdk.isPresent) {
        javaLauncher = javaToolchains.launcherFor { languageVersion = JavaLanguageVersion.of(testJdk.get()) }
    }
    useJUnitPlatform {
        if (name == "integrationTest") includeTags("integration") else excludeTags("integration")
    }
    // shared known answers and test keys
    systemProperty("payway.specDir", rootDir.resolve("../spec").absolutePath)
    systemProperty("payway.version", version.toString())
    // integration tests read credentials from kotlin/.env or PAYWAY_ENV_FILE
    workingDir = projectDir
    testLogging {
        events("failed", "skipped")
        showStandardStreams = name == "integrationTest"
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
    }
}

// ./gradlew integrationTest: the sandbox tests (need kotlin/.env), not part of build
val integrationTest by tasks.registering(Test::class) {
    description = "Runs the PayWay sandbox integration tests (needs kotlin/.env or PAYWAY_ENV_FILE)."
    group = "verification"
    testClassesDirs =
        sourceSets.test
            .get()
            .output.classesDirs
    classpath = sourceSets.test.get().runtimeClasspath
    outputs.upToDateWhen { false }
}

mavenPublishing {
    // credentials and signing key come only from the environment:
    // ORG_GRADLE_PROJECT_mavenCentralUsername / _mavenCentralPassword,
    // ORG_GRADLE_PROJECT_signingInMemoryKey / _signingInMemoryKeyPassword
    publishToMavenCentral()
    // Maven Central needs signatures; local builds (publishToMavenLocal) without a key are unsigned
    if (providers.gradleProperty("signingInMemoryKey").isPresent) signAllPublications()
    coordinates(group.toString(), property("POM_ARTIFACT_ID") as String, version.toString())

    pom {
        name.set("payway-checkout")
        description.set("Kotlin/JVM client for the ABA PayWay Ecommerce Checkout API (server-side).")
        inceptionYear.set("2026")
        url.set("https://github.com/kechankrisna/payway-checkout")
        licenses {
            license {
                name.set("MIT License")
                url.set("https://opensource.org/licenses/MIT")
                distribution.set("repo")
            }
        }
        developers {
            developer {
                id.set("kechankrisna")
                name.set("Ke Chankrisna")
                url.set("https://github.com/kechankrisna")
            }
        }
        scm {
            url.set("https://github.com/kechankrisna/payway-checkout")
            connection.set("scm:git:https://github.com/kechankrisna/payway-checkout.git")
            developerConnection.set("scm:git:ssh://git@github.com/kechankrisna/payway-checkout.git")
        }
    }
}
