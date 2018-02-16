<!DOCTYPE html>
<html>
    <head>
        <meta name="layout" content="elurikkus" />

        <title>
            ${region.name}
        </title>

        <asset:javascript src="region" />
        <asset:stylesheet src="region" />
    </head>

    <body class="nav-locations regions">
        <g:set var="enableQueryContext" value="${grailsApplication.config.biocache.enableQueryContext?.toBoolean()}"></g:set>
        <g:set var="enableHubData" value="${grailsApplication.config.hub.enableHubData?.toBoolean()}"></g:set>
        <g:set var="hubState" value="${true}"></g:set>

        <div class="page-header">
            <g:if test="${flash.message}">
                <div class="message">
                    ${flash.message}
                </div>
            </g:if>

            <h1 class="page-header__title">
                ${region.name}
            </h1>

            <div id="occurrenceRecords" class="page-header__subtitle">
                <g:message code="region.body.subTitle" args="${[region.name]}" />
                <span class="totalRecords"></span>

                <%-- XXX TODO Test the style of emblems. So far they have remained unseen. --%>
                <g:if test="${emblems}">
                    <aa:zone
                        id="emblems"
                        href="${g.createLink(controller: 'region', action: 'showEmblems', params: [regionType: region.type, regionName: region.name, regionPid: region.pid])}"
                    >
                        <span class="fa fa-cog fa-spin fa-2x"></span>
                    </aa:zone>
                </g:if>

                <%-- XXX TODO Test the style of description. So far it have remained unseen. --%>
                <div>
                    <g:if test="${region.description || region.notes}">
                        <g:if test="${region.description}">
                            <p>
                                ${raw(region.description)}
                            </p>
                        </g:if>

                        <g:if test="${region.notes}">
                            <strong>
                                <g:message code="region.region.notes" />:
                            </strong>
                            ${region.notes}
                        </g:if>
                    </g:if>
                </div>
            </div>

            <div class="page-header-links">
                <a href="${g.createLink(uri: '/')}" class="page-header-links__link">
                    <span class="fa fa-arrow-left"></span>
                    <g:message code="region.navBar.regions" />
                </a>
            </div>
        </div>

        <div class="row">
            <%-- Filters info --%>
            <div class="col-sm-12 col-md-6 col-lg-5">
                <div class="column-reverse">
                    <p>
                        <span class="fa fa-info-circle"></span>
                        <g:message code="region.map.info.filterspecies" />
                    </p>
                </div>
            </div>

            <%-- Filter, graph tabs --%>
            <div class="col-sm-12 col-md-6 col-lg-5 order-md-3">
                <div class="tabbable">
                    <ul class="nav nav-tabs" id="explorerTabs">
                        <li class="nav-item">
                            <a id="species-tab" data-toggle="tab" href="#species-tab-content" class="nav-link active">
                                <g:message code="region.speciesTab.header.table" />
                                <span class="fa fa-cog fa-spin fa-lg hidden"></span>
                            </a>
                        </li>

                        <li class="nav-item">
                            <a id="taxonomy-tab" data-toggle="tab" href="#taxonomy-tab-content" class="nav-link">
                                <g:message code="region.speciesTab.header.chart" />
                                <span class="fa fa-cog fa-spin fa-lg hidden"></span>
                            </a>
                        </li>
                    </ul>
                </div>

                <div class="tab-content">
                    <div class="tab-pane active" id="species-tab-content">
                        <div class="row no-gutters">
                            <div class="col-4">
                                <table
                                    id="groups"
                                    class="table table-condensed table-hover"
                                    aa-href="${g.createLink(controller: 'region', action: 'showGroups', params: [regionFid: region.fid,regionType: region.type, regionName: region.name, regionPid: region.pid])}"
                                    aa-js-before="setHubConfig();"
                                    aa-js-after="regionWidget.groupsLoaded();"
                                    aa-refresh-zones="groupsZone"
                                    aa-queue="abort"
                                >
                                    <thead>
                                        <tr>
                                            <th class="text-center">
                                                <g:message code="region.speciesTab.table.speciesGroup" />
                                            </th>
                                            <th class="text-right">
                                                #
                                            </th>
                                        </tr>
                                    </thead>

                                    <tbody id="groupsZone">
                                        <tr class="spinner">
                                            <td class="spinner text-center">
                                                <span class="fa fa-cog fa-spin fa-2x"></span>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>

                            <div class="col-8">
                                <table class="table table-condensed table-hover" id="species">
                                    <thead>
                                        <tr>
                                            <th></th>
                                            <th>
                                                <g:message code="region.speciesTab.table.taxonList" />
                                            </th>
                                            <th class="text-right">
                                                <g:message code="region.speciesTab.table.recordsCount" />
                                            </th>
                                        </tr>
                                    </thead>

                                    <aa:zone id="speciesZone" tag="tbody" jsAfter="regionWidget.speciesLoaded();">
                                        <tr class="spinner">
                                            <td colspan="3" class="spinner text-center">
                                                <span class="fa fa-cog fa-spin fa-2x"></span>
                                            </td>
                                        </tr>
                                    </aa:zone>
                                </table>
                            </div>
                        </div>
                    </div>

                    <div class="tab-pane" id="taxonomy-tab-content">
                        <div id="charts">
                            <span class="spinner fa fa-cog fa-spin fa-3x"></span>
                        </div>
                    </div>
                </div>
            </div>

            <%-- Buttons & info --%>
            <div class="col-sm-12 col-md-6 col-lg-7 order-md-2">
                <div class="row">
                    <div class="col-md-12 col-lg-8 col-xl-7 order-lg-2">
                        <div class="inline-controls inline-controls--right">
                            <div class="inline-controls__group">
                                <button id="viewRecords" class="erk-button erk-button--dark">
                                    <span class="fa fa-list"></span>
                                    <g:message code="species.results.recordList" />
                                    <span class="totalRecords"></span>
                                </button>
                            </div>

                            <div class="inline-controls__group">
                                <a
                                    href="${g.createLink(controller: 'region', action: 'showDownloadDialog')}"
                                    aa-refresh-zones="dialogZone"
                                    aa-js-before="regionWidget.showDownloadDialog();"
                                    class="erk-button erk-button--light erk-button-link"
                                >
                                    <span class="fa fa-download"></span>
                                    <g:message code="general.btn.download.label" />
                                </a>
                            </div>
                        </div>
                    </div>

                    <div class="col">
                        <div class="column-reverse">
                            <p>
                                <span class="fa fa-info-circle"></span>
                                <g:message code="region.playBack.desc" />
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <%-- Map and controls--%>
            <div class="col-sm-12 col-md-6 col-lg-7 order-md-3">
                <div id="region-map" class="regions-map"></div>

                <div id="time-controls" class="text-center">
                    <div id="time-buttons">
                        <button
                            id="playButton"
                            class="time-control link"
                            title="${message(code: 'region.playBack.btn.play')}"
                        ></button>
                        <button
                            id="pauseButton"
                            class="time-control link"
                            title="${message(code: 'region.playBack.btn.pause')}"
                        ></button>
                        <button
                            id="stopButton"
                            class="time-control link"
                            title="${message(code: 'region.playBack.btn.stop')}"
                        ></button>
                        <button
                            id="resetButton"
                            class="time-control link"
                            title="${message(code: 'region.playBack.btn.reset')}"
                        ></button>
                    </div>
                </div>

                <div id="timeSlider"></div>

                <div id="time-range">
                    <span id="timeFrom"></span> - <span id="timeTo"></span>
                </div>

                <div id="opacityControls">
                    <label class="checkbox" for="toggleOccurrences">
                        <input type="checkbox" name="occurrences" id="toggleOccurrences" checked />
                        <g:message code="region.map.control.show.occurrences" />
                    </label>

                    <p id="occurrencesOpacity"></p>

                    <label class="checkbox" for="toggleRegion">
                        <input type="checkbox" name="region" id="toggleRegion" checked />
                        <g:message code="region.map.control.show.region" />
                    </label>

                    <p id="regionOpacity"></p>
                </div>
            </div>
        </div>

        <div
            id="downloadRecordsModal"
            class="modal hide fade"
            tabindex="-1"
            role="dialog"
            aria-labelledby="myModalLabel"
            aria-hidden="true"
        >
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <aa:zone id="dialogZone">
                        <div class="modal-header">
                            <h3 id="myModalLabel">
                                <g:message code="download.title" />
                            </h3>
                        </div>

                        <div class="modal-body text-center">
                            <span class="fa fa-cog fa-spin fa-2x"></span>
                        </div>
                    </aa:zone>
                </div>
            </div>
        </div>

        <g:if test="${subRegions.size() > 0}">
            <div class="row">
                <div class="col" id="subRegions">
                    <h2>
                        <g:message code="region.subRegions.title" args="${[region.name]}" />
                    </h2>

                    <g:each in="${subRegions}" var="item">
                        <h3>
                            ${item.key}
                        </h3>

                        <ul>
                            <g:each in="${item.value.list}" var="r">
                                <li>
                                    <g:link action="region" params="[regionType:item.value.name,regionName:r,parent:region.name]">
                                        ${r}
                                    </g:link>
                                </li>
                            </g:each>
                        </ul>
                    </g:each>
                </div>
            </div>
        </g:if>

        <g:if test="${documents.factSheets || documents.publications || documents.links}">
            <div class="row">
                <div class="col-12" id="docs">
                    <h2>
                        <g:message code="region.info.documents" />
                    </h2>

                    <g:if test="${documents.factSheets}">
                        <h3>
                            <g:message code="region.info.factSheets" />
                        </h3>

                        <ul>
                            <g:each in="${documents.factSheets}" var="d">
                                <li>
                                    <a href="${d.url}" class="external">
                                        ${d.linkText}
                                    </a>
                                    ${d.otherText}
                                </li>
                            </g:each>
                        </ul>
                    </g:if>

                    <g:if test="${documents.publications}">
                        <h3>
                            <g:message code="region.info.publications" />
                        </h3>

                        <ul>
                            <g:each in="${documents.publications}" var="d">
                                <li>
                                    <a href="${d.url}" class="external">
                                        ${d.linkText}
                                    </a>
                                    ${d.otherText}
                                </li>
                            </g:each>
                        </ul>
                    </g:if>

                    <g:if test="${documents.links}">
                        <h3>
                            <g:message code="region.info.links" />
                        </h3>

                        <ul>
                            <g:each in="${documents.links}" var="d">
                                <li>
                                    <a href="${d.url}" class="external">
                                        ${d.linkText}
                                    </a>
                                    ${d.otherText}
                                </li>
                            </g:each>
                        </ul>
                    </g:if>

                    <g:link elementId="manage-doc-link" action="documents">
                        <g:message code="region.info.edit" />
                    </g:link>
                </div>
            </div>
        </g:if>

        <script>
            google.load("visualization", "1", {packages:["corechart"]});
            var regionWidget;

            $(function() {
                $(document).on("click", "[aa-refresh-zones]", function(event) {
                    event.stopPropagation()
                    return false;
                });

                regionWidget = new RegionWidget({
                    regionName: "${region.name}",
                    regionType: "${region.type}",
                    regionFid: "${region.fid}",
                    regionPid: "${region.pid}",
                    regionLayerName: "${region.layerName}",
                    urls: {
                        regionsApp: "${g.createLink(uri: '/', absolute: true)}",
                        spatialProxy: "${g.createLink(controller: 'proxy', action: 'spatial')}",
                        biocacheProxy: "${g.createLink(controller: 'proxy', action: 'biocache')}",
                        proxyUrlBbox: "${g.createLink(controller: 'proxy', action: 'bbox')}",
                        speciesPageUrl: "${grailsApplication.config.bie.baseURL}/species/",
                        biocacheServiceUrl: "${grailsApplication.config.biocacheService.baseURL}",
                        biocacheWebappUrl: "${grailsApplication.config.biocache.baseURL}",
                        spatialWmsUrl: "${grailsApplication.config.geoserver.baseURL}/ALA/wms?",
                        spatialCacheUrl: "${grailsApplication.config.geoserver.baseURL}/gwc/service/wms?",
                    },
                    username: '${rg.loggedInUsername()}',
                    q: '${region.q}'

                    <g:if test="${enableQueryContext}">
                        ,qc: "${URLEncoder.encode(grailsApplication.config.biocache.queryContext, 'UTF-8')}"
                    </g:if>

                    <g:if test="${enableHubData}">
                        ,hubFilter: "${URLEncoder.encode(grailsApplication.config.hub.hubFilter , 'UTF-8')}"
                        ,showHubData: ${hubState}
                    </g:if>
                });

                regionWidget.setMap(new RegionMap({
                    bbox: {
                        sw: {lat: ${region.bbox?.minLat}, lng: ${region.bbox?.minLng}},
                        ne: {lat: ${region.bbox?.maxLat}, lng: ${region.bbox?.maxLng}}
                    },
                    useReflectService: ${useReflect},
                    enableRegionOverlay: ${enableRegionOverlay != null ? enableRegionOverlay : 'true'}
                }));

                regionWidget.setTimeControls(new RegionTimeControls());

                google.setOnLoadCallback(function() {
                    regionWidget.setTaxonomyWidget(new TaxonomyWidget());
                });

                refreshSpeciesGroup();
            });

            function setHubConfig() {
                <g:if test="${enableHubData}">
                    AjaxAnywhere.dynamicParams = {
                        showHubData:!$('[name="hub-toggle"]').is(":checked")
                    }
                </g:if>
            }

            function refreshSpeciesGroup(){
                $('#groups').click()
            }
        </script>
    </body>
</html>
