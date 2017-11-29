grails.servlet.version = "3.0"
grails.project.class.dir = "target/classes"
grails.project.test.class.dir = "target/test-classes"
grails.project.test.reports.dir = "target/test-reports"
grails.project.target.level = 1.8
grails.project.source.level = 1.8
grails.project.war.file = "target/${appName}-${appVersion}.war"

grails.project.fork = [
    test: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256, daemon:true], // configure settings for the test-app JVM
    run: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256], // configure settings for the run-app JVM
    war: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256], // configure settings for the run-war JVM
    console: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256] // configure settings for the Console UI JVM
]

grails.project.dependency.resolver = "maven"

grails.project.dependency.resolution = {
    // inherit Grails' default dependencies
    inherits("global") {
        // uncomment to disable ehcache
        // excludes 'ehcache'
    }
    log "warn" // log level of Ivy resolver, either 'error', 'warn', 'info', 'debug' or 'verbose'
    repositories {
        mavenLocal()
        mavenRepo ("http://nexus.ala.org.au/content/groups/public/") {
            updatePolicy "always"
        }
    }
    dependencies {
        // specify dependencies here under either 'build', 'compile', 'runtime', 'test' or 'provided' scopes eg.
        compile "org.codehaus.groovy.modules.http-builder:http-builder:0.7.1"
    }

    plugins {
        build ":release:3.0.1"
        build ":rest-client-builder:2.0.3"
        build ":tomcat:7.0.70"
        build ":codenarc:1.0"

        compile ":jquery:1.11.1"
        compile ":ajaxanywhere:1.0-SNAPSHOT"
        compile ":ala-auth:1.3.4"
        compile ":asset-pipeline:2.14.1"
        compile ":cache-headers:1.1.7"
        compile ":elurikkus-commons:0.2-SNAPSHOT"

        runtime ":resources:1.2.14"  // Need this or else ajaxanywhere plugin throws errors during build
    }
}
