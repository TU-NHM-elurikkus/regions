<!DOCTYPE html>
<html>
    <head>
        <meta name="layout" content="${grailsApplication.config.skin.layout ?: 'elurikkus'}" />

        <title>
            <g:message code="regions.header.title" /> | ${grailsApplication.config.orgNameLong}
        </title>

        <%-- Get regions metadata --%>
        <script src="${g.createLink(controller: 'data', action: 'regionsMetadataJavascript')}"></script>

        <asset:javascript src="regions.js" />

    </head>

    <body class="nav-locations">
        <div class="page-header">
            <g:if test="${flash.message}">
                <div class="message">
                    ${flash.message}
                </div>
            </g:if>

            <h1 class="page-header__title">
                <g:message code="regions.body.title.label" />
            </h1>

            <div class="page-header__subtitle">
                <g:message code="regions.body.title.desc" />
            </div>
        </div>

        <div class="row">
            <div class="col-md-5">
                <div class="vertical-block">
                    <span class="fa fa-info-circle"></span>
                    <g:message code="regions.regionsList.help" />
                </div>

                <div id="accordion">
                    <g:each in="${menu}" var="item">
                        <h2>
                            <a href="#">
                                ${item.label}
                            </a>
                        </h2>

                        <div id="${item.layerName}" layer="${item.label}">
                            <span class="loading">
                                <g:message code="regions.regionsList.loading" />...
                            </span>
                        </div>
                    </g:each>
                </div>
            </div>

            <div class="col-md-7" id="rightPanel">
                <div class="row">
                    <div class="col vertical-block">
                        <span class="fa fa-info-circle"></span>
                        <g:message code="regions.map.help" />

                        <span class="float-right">
                            <span id="click-info">
                            </span>

                            <button id="reset-map" class="erk-button erk-button--light">
                                <g:message code="regions.map.btn.reset" />
                            </button>
                        </span>
                    </div>
                </div>

                <div id="map">
                    <div id="map-container">
                        <div id="map-canvas"></div>
                    </div>

                    <div id="controls">
                        <label class="checkbox" for="toggleLayer">
                            <input type="checkbox" name="layer" id="toggleLayer" value="1" checked />
                            <g:message code="regions.map.layer.allRegions" />
                        </label>

                        <p id="layerOpacity"></p>

                        <label class="checkbox" for="toggleRegion">
                            <input type="checkbox" name="region" id="toggleRegion" value="1" checked disabled />
                                <g:message code="regions.map.layer.selectedRegion" />
                            </label>
                        </div>

                        <p id="regionOpacity"></p>
                    </div>
                </div>
            </div>
        </div>

        <script>
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
                    mapContainer: 'map-canvas',
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
        </script>
    </body>
</html>
