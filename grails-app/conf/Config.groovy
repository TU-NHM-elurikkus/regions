import org.apache.log4j.Level
import grails.util.Environment
// from /commons/lib/
import com.nextdoor.rollbar.RollbarLog4jAppender


default_config = "/data/${appName}/config/${appName}-config.properties"
config_dir = "/data/${appName}/config/"
commons_config = "/data/commons/config/commons-config.properties"
env_config = "config/${Environment.current.name}/Config.groovy"

grails.config.locations = [
    "file:${env_config}",
    "file:${commons_config}",
    "file:${default_config}"
]

def prop = new Properties()
def rollbarServerKey = ""

// Load rollbar key from commons config file.
try {
    File fileLocation = new File(commons_config)
    prop.load(new FileInputStream(fileLocation))
    rollbarServerKey = prop.getProperty("rollbar.postServerKey") ?: ""
} catch(IOException e) {
    e.printStackTrace()
}

if(!new File(env_config).exists()) {
    println "ERROR - [${appName}] Couldn't find environment specific configuration file: ${env_config}"
}
if(!new File(default_config).exists()) {
    println "ERROR - [${appName}] No external configuration file defined. ${default_config}"
}
if(!new File(commons_config).exists()) {
    println "ERROR - [${appName}] No external commons configuration file defined. ${commons_config}"
}
if(rollbarServerKey.isEmpty()) {
    println "ERROR - [${appName}] No Rollbar key."
}

println "[${appName}] (*) grails.config.locations = ${grails.config.locations}"


/******************************************************************************\
 *  RELOADABLE CONFIG
 \******************************************************************************/
//reloadable.cfgPollingFrequency = 1000 * 60 * 60 // 1 hour
//reloadable.cfgPollingRetryAttempts = 5
reloadable.cfgs = ["file:" + default_config, "file:" + commons_config]

/******************************************************************************\
 *  SKINNING
 \******************************************************************************/
if (!ala.skin) {
    ala.skin = 'ala2';
}
// Defaults used for the breadcrumb if the skin doesn't override them
// Skins should use the prefix: skin.breadcrumb instead of breadcrumb.default.  They can also
// supply a skin.homeURL which will be used as a prefix for the paths.
breadcrumb.default.level1.title='Home'
breadcrumb.default.level1.path=''
breadcrumb.default.level2.title='Explore'
breadcrumb.default.level2.path='/explore/'


grails.project.groupId = 'au.org.ala' // change this to alter the default package name and Maven publishing destination

// The ACCEPT header will not be used for content negotiation for user agents containing the following strings (defaults to the 4 major rendering engines)
grails.mime.disable.accept.header.userAgents = ['Gecko', 'WebKit', 'Presto', 'Trident']
grails.mime.types = [ // the first one is the default format
                      all          : '*/*', // 'all' maps to '*' or the first available format in withFormat
                      atom         : 'application/atom+xml',
                      css          : 'text/css',
                      csv          : 'text/csv',
                      form         : 'application/x-www-form-urlencoded',
                      html         : ['text/html', 'application/xhtml+xml'],
                      js           : 'text/javascript',
                      json         : ['application/json', 'text/json'],
                      multipartForm: 'multipart/form-data',
                      rss          : 'application/rss+xml',
                      text         : 'text/plain',
                      hal          : ['application/hal+json', 'application/hal+xml'],
                      xml          : ['text/xml', 'application/xml']
]

// URL Mapping Cache Max Size, defaults to 5000
//grails.urlmapping.cache.maxsize = 1000

// Legacy setting for codec used to encode data with ${}
grails.views.default.codec = "html"

// The default scope for controllers. May be prototype, session or singleton.
// If unspecified, controllers are prototype scoped.
grails.controllers.defaultScope = 'singleton'

// GSP settings
grails {
    views {
        gsp {
            encoding = 'UTF-8'
            htmlcodec = 'xml' // use xml escaping instead of HTML4 escaping
            codecs {
                expression = 'html' // escapes values inside ${}
                scriptlet = 'html' // escapes output from scriptlets in GSPs
                taglib = 'none' // escapes output from taglibs
                staticparts = 'none' // escapes output from static template parts
            }
        }
        // escapes all not-encoded output at final stage of outputting
        // filteringCodecForContentType.'text/html' = 'html'
    }
}


grails.converters.encoding = "UTF-8"
// scaffolding templates configuration
grails.scaffolding.templates.domainSuffix = 'Instance'

// Set to false to use the new Grails 1.2 JSONBuilder in the render method
grails.json.legacy.builder = false
// enabled native2ascii conversion of i18n properties files
grails.enable.native2ascii = true
// packages to include in Spring bean scanning
grails.spring.bean.packages = []
// whether to disable processing of multi part requests
grails.web.disable.multipart = false

// request parameters to mask when logging exceptions
grails.exceptionresolver.params.exclude = ['password']

// configure auto-caching of queries by default (if false you can cache individual queries with 'cache: true')
grails.hibernate.cache.queries = false

// configure passing transaction's read-only attribute to Hibernate session, queries and criterias
// set "singleSession = false" OSIV mode in hibernate configuration after enabling
grails.hibernate.pass.readonly = false
// configure passing read-only to OSIV session by default, requires "singleSession = false" OSIV mode
grails.hibernate.osiv.readonly = false


def logging_dir = System.getProperty("catalina.base") ? System.getProperty("catalina.base") + "/logs" : "/var/log/tomcat7"
if(!new File(logging_dir).exists()) {
    logging_dir = "/tmp"
}

println "INFO - [${appName}] logging_dir: ${logging_dir}"

log4j = {
    def logPattern = pattern(conversionPattern: "%d %-5p [%c{1}] %m%n")

    def rollbarAppender = new RollbarLog4jAppender(
        name: "rollbar",
        layout: logPattern,
        threshold: org.apache.log4j.Level.ERROR,
        environment: Environment.current.name,
        accessToken: rollbarServerKey
    )

    def tomcatLogAppender = rollingFile(
        name: "tomcatLog",
        maxFileSize: "10MB",
        file: "${logging_dir}/specieslist.log",
        threshold: org.apache.log4j.Level.WARN,
        layout: logPattern
    )

    appenders {
        environments {
            production {
                appender(tomcatLogAppender)
                appender(rollbarAppender)
            }
            test {
                appender(tomcatLogAppender)
                appender(rollbarAppender)
            }
            development {
                console(
                    name: "stdout",
                    layout: logPattern,
                    threshold: org.apache.log4j.Level.DEBUG)
            }
        }
    }

    root {
        error "tomcatLog", "rollbar"
        warn "tomcatLog"
    }

    warn    'au.org.ala.cas.client',
            'grails.spring.BeanBuilder',
            'grails.plugin.webxml',
            'grails.plugin.cache.web.filter'
    debug   'grails.app'
}


// app specific config
// switch this on to query hub specific data
hub.enableHubData=false
// add hub id here eg. "data_hub_uid:dh10"
hub.hubFilter=""

// switch on query context
biocache.enableQueryContext=false
// add query context eg. 'cl2110:"Murray-Darling Basin Boundary"'
biocache.queryContext=""

// show only regions that intersect with an ALA OBJECT
layers.enableObjectIntersection=false
layers.intersectObject=""

// configuration to show a default layer on the map. This layer is on top of the layers selected from accordion.
// helpful for regions app implementation for a hub.
layers.showQueryContext=false
layers.queryContextName=''
layers.queryContextShortName=''
layers.queryContextDisplayName=''
layers.queryContextFid=''
layers.queryContextBieContext=''
layers.queryContextOrder=''
