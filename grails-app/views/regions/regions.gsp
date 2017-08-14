<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta name="layout" content="${grailsApplication.config.skin.layout?:'elurikkus'}" />

        <title>
            Regions | ${grailsApplication.config.orgNameLong}
        </title>

        <%-- Get regions metadata --%>
        <script src="${g.createLink(controller: 'data', action: 'regionsMetadataJavascript')}"></script>

        <g:if test="${grailsApplication.config.google.apikey}">
            <script src="https://maps.googleapis.com/maps/api/js?key=${grailsApplication.config.google.apikey}" type="text/javascript"></script>
        </g:if>
        <g:else>
            <script type="text/javascript" src="https://www.google.com/jsapi"></script>
        </g:else>

        <r:require modules="jquery, regions" />
    </head>

    <body class="nav-locations">
        <div class="page-header">
            <g:if test="${flash.message}">
                <div class="message">
                    ${flash.message}
                </div>
            </g:if>

            <h1 class="page-header__title">
                Select a region to explore
            </h1>

            <div class="page-header__subtitle">
                Select the type of region on the left. Click a name or click on the map to select a region.
                Use map controls or shift-drag with your mouse to zoom the map.
                <br />
                Click the region button
                to explore occurrence records, images and documents associated with the region.
            </div>
        </div>

        <div class="row">
            <div class="col-md-5">
                <p style="font-size:15px;padding-bottom:0;">
                    <span class="fa fa-info-circle"></span>
                    Click on a region name to select an area.
                </p>

                <div id="accordion">
                    <g:each in="${menu}" var="item">
                        <h2>
                            <a href="#">
                                ${item.label}
                            </a>
                        </h2>

                        <div id="${item.layerName}" layer="${item.label}">
                            <span class="loading">
                                Loading...
                            </span>
                        </div>
                    </g:each>
                </div>
            </div>

            <div class="col-md-7" id="rightPanel">
                <span id="click-info">
                    <span class="fa fa-info-circle"></span>
                    Click on the map to select an area.
                </span>

                <button id="reset-map" class="erk-button erk-button--light">
                    <span class="fa fa-refresh"></span>
                    Reset map
                </button>

                <div id="map">
                    <div id="map-container">
                        <div id="map_canvas"></div>
                    </div>

                    <div id="controls">
                        <label class="checkbox" for="toggleLayer">
                            <input type="checkbox" name="layer" id="toggleLayer" value="1" checked />
                            All regions
                        </label>

                        <p id="layerOpacity"></p>

                        <label class="checkbox" for="toggleRegion">
                            <input type="checkbox" name="region" id="toggleRegion" value="1" checked disabled />
                                Selected region
                            </label>
                        </div>

                        <p id="regionOpacity"></p>
                    </div>
                </div><!--close map-->
            </div>
        </div>

        <r:script>
            var altMap = true;
            $(function() {
                $('#dev-notes').dialog({autoOpen: false, show: 'blind', hide: 'blind'});
                $('#dev-notes-link').click(function() {
                    $('#dev-notes').dialog('open');
                    return false;
                });

                init_regions({
                    server: '${grailsApplication.config.grails.serverURL}',
                    spatialService: "${grailsApplication.config.layersService.baseURL}/",
                    spatialWms: "${grailsApplication.config.geoserver.baseURL}/ALA/wms?",
                    spatialCache: "${grailsApplication.config.geoserver.baseURL}/ALA/wms?",
                    accordionPanelMaxHeight: '${grailsApplication.config.accordion.panel.maxHeight}',
                    mapBounds: JSON.parse('${grailsApplication.config.map.bounds?:[]}'),
                    mapHeight: '${grailsApplication.config.map.height}',
                    mapContainer: 'map_canvas',
                    defaultRegionType: "${grailsApplication.config.default.regionType}",
                    defaultRegion: "${grailsApplication.config.default.region}",
                    showQueryContextLayer: ${grailsApplication.config.layers.showQueryContext},
                    queryContextLayer: {
                        name:"${grailsApplication.config.layers.queryContextName}",
                        shortName:"${grailsApplication.config.layers.queryContextShortName}",
                        fid:"${grailsApplication.config.layers.queryContextFid}",
                        bieContext:"${grailsApplication.config.layers.queryContextBieContext}",
                        order:"${grailsApplication.config.layers.queryContextOrder}",
                        displayName:"${grailsApplication.config.layers.queryContextDisplayName}"
                    }
                });
            })
        </r:script>
    </body>
</html>
