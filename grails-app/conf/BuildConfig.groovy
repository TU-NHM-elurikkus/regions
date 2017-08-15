import grails.util.Environment

grails.servlet.version = "2.5" // Change depending on target container compliance (2.5 or 3.0)
grails.project.class.dir = "target/classes"
grails.project.test.class.dir = "target/test-classes"
grails.project.test.reports.dir = "target/test-reports"
grails.project.target.level = 1.7
grails.project.source.level = 1.7
grails.project.war.file = "target/${appName}-${appVersion}.war"

grails.project.dependency.resolver = "maven"

//grails.plugin.location."ala-bootstrap2" = "../ala-bootstrap2"

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
        build ":tomcat:7.0.54"
        build ":release:3.0.1"
        build ":rest-client-builder:2.0.3"

        compile ":ajaxanywhere:1.0-SNAPSHOT"

        runtime (":ala-bootstrap2:2.4.5") {
            exclude "jquery"
        }

        if (Environment.current == Environment.PRODUCTION) {
            runtime ":zipped-resources:1.0.1"
            runtime ":cached-resources:1.1"
            compile ":cache-headers:1.1.7"
            runtime ":yui-minify-resources:0.1.5"
        }

        runtime ":ala-auth:1.3.4"
        runtime ":elurikkus-commons:0.2-SNAPSHOT"
        runtime ":resources:1.2.14"
        compile "org.grails.plugins:message-reports:0.1"
    }
}

reportMessages {
	// put all keys here, that should not show as unused, even if no code reference could be found
	// note that it is sufficient to provide an appropriate prefix to match a group of keys
	exclude = ["default", "typeMismatch"]

	// put all variable names here, that are used in dynamic keys and have a defined set of values
	// e.g. if you have a call like <c:message code="show.${prod}" /> and "prod" is used in many
	// pages to distinguish between "orange" and "apple" add a map to the list below:
	//     prod: ["orange", "apple"]
	dynamicKeys = [
	]
}
