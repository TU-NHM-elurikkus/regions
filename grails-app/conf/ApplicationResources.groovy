// resource bundles
modules = {

    regions {
        dependsOn  'jquery', 'jqueryUi', 'jqueryBbq', 'map', 'font-awesome', 'he'

        resource url: '/js/regions.js'
        resource url: [dir:'css', file:'regions.css']
    }

    region {
        dependsOn 'jquery', 'jqueryUi', 'jqueryUiSliderPips', 'jqueryBbq', 'ajaxanywhere', 'map', 'charts', 'numberFunctions', 'font-awesome'

        resource url: '/js/region.js'
        resource url: [dir:'css', file:'regions.css']
    }

    leaflet {
        resource url:[dir:'js/leaflet', file:'leaflet.css'], attrs: [ media: 'all' ]
        resource url:[dir:'js/leaflet', file:'leaflet.js']
    }

    jquery {
        resource url: '/vendor/jquery/jquery-1.11.2.js', disposition: 'head'
    }

    jqueryUi {
        dependsOn 'jquery'

        resource url: '/vendor/jquery-ui/jquery-ui-1.11.2-no-autocomplete.js'
        resource url: '/vendor/jquery-ui/themes/smoothness/jquery-ui.css', attrs:[media:'all']
    }

    jqueryUiSliderPips {
        resource url: '/vendor/jquery-ui-slider-pips/jquery-ui-slider-pips.js'
        resource url: '/vendor/jquery-ui-slider-pips/jquery-ui-slider-pips.css', attrs:[media:'all']
    }

    jqueryBbq {
        dependsOn 'jquery'

        resource url: '/vendor/jquery-bbq/jquery.ba-bbq-1.2.1.js'
    }

    map {
        resource url: '/js/keydragzoom.js'
        resource url: '/js/wms.js'
    }

    charts {
        resource url: 'https://www.google.com/jsapi', attrs: [type: 'js']
        resource url: '/js/charts2.js'
    }

    numberFunctions {
        resource url: '/vendor/number-functions/number-functions.js'
    }

    he {
        resource url: '/vendor/he/he-0.5.0.js'
    }

    // Used by the mdba skin
    mdba {
        resource url: [dir:'css', file:'mdba-styles.css']
    }

    bootstrapSwitch{
        resource url: [dir:'/vendor/bootstrap-switch', file:'bootstrap-switch.css']
        resource url: [dir:'/vendor/bootstrap-switch', file:'bootstrap-switch.min.js']
    }
}
