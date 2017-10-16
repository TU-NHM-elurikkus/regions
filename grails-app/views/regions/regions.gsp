<!DOCTYPE html>
<html>
    <head>
        <meta name="layout" content="elurikkus" />

        <title>
            <g:message code="regions.header.title" />
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
                <g:message code="regions.header.title" />
            </h1>

            <div class="page-header__subtitle">
                <g:message code="regions.body.title.desc" />
            </div>

            <div class="page-header-links">
                <a class="page-header-links__link" href="${grailsApplication.config.biocache.baseURL}/search#spatial-search">
                    <span class="fa fa-search"></span>
                    <g:message code="general.searchByPolygon" />
                </a>
                <a class="page-header-links__link" href="${grailsApplication.config.biocache.baseURL}/explore/your-area">
                    <span class="fa fa-search"></span>
                    <g:message code="general.exploreArea" />
                </a>
            </div>
        </div>

        <div class="row">
            <%-- Region selection info --%>
            <div class="col-sm-12 col-md-6 col-lg-5">
                <div class="column-reverse">
                    <p>
                        <span class="fa fa-info-circle"></span>
                        <g:message code="regions.regionsList.help" />
                    </p>
                </div>
            </div>

            <%-- Region selection menu --%>
            <div class="col-sm-12 col-md-6 col-lg-5 order-md-3">
                <!-- jQuery UI accordion -->
                <div id="accordion">
                    <g:each in="${menu}" var="item">
                        <h2 id="accordion-heading-${item.layerName}" class="accordion-heading">
                            <a href="#">
                                ${item.label}
                            </a>
                        </h2>

                        <div id="${item.layerName}" layer="${item.label}">
                            <span class="loading">
                                <g:message code="regions.regionsList.loading" />&hellip;
                            </span>
                        </div>
                    </g:each>
                </div>
            </div>

            <%-- MAP CONTROLS & INFO --%>
            <div class="col-sm-12 col-md-6 col-lg-7 order-md-2" id="rightPanel">
                <div class="row">
                    <div class="col-md-12 col-lg-9 col-xl-8 order-lg-2">
                        <%-- Buttons --%>
                        <div class="inline-controls inline-controls--right">
                            <div class="inline-controls__group hidden">
                                <a
                                    id="show-region"
                                    class="erk-button erk-button-link erk-button--dark"
                                    href=""
                                    title="${message(code: 'regions.map.showRegion')}"
                                ></a>
                            </div>

                            <div class="inline-controls__group hidden">
                                <button id="zoomTo" class="erk-button erk-button--light">
                                    <g:message code="regions.map.btn.zoom" />
                                </button>
                            </div>

                            <div class="inline-controls__group hidden">
                                <button class="erk-button erk-button--light" id="extra"></button>
                            </div>

                            <div class="inline-controls__group">
                                <button id="reset-map" class="erk-button erk-button--light">
                                    <g:message code="regions.map.btn.reset" />
                                </button>
                            </div>
                        </div>
                    </div>

                    <%-- Info --%>
                    <div class="col-md-12 col-lg-3 col-xl-4">
                        <div class="column-reverse">
                            <p>
                                <span class="fa fa-info-circle"></span>
                                <g:message code="regions.map.help" />
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <%-- MAP --%>
            <div class="col-sm-12 col-md-6 col-lg-7 order-md-3">
                <div id="map-canvas" class="regions-map"></div>

                <div id="map-controls">
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

        <script>
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
