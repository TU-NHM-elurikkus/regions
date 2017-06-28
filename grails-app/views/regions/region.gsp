<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="layout" content="${grailsApplication.config.skin.layout?:'main'}"/>

    <title>${region.name} | ${grailsApplication.config.orgNameLong}</title>

    <g:if test="${grailsApplication.config.google.apikey}">
        <script src="https://maps.googleapis.com/maps/api/js?key=${grailsApplication.config.google.apikey}" type="text/javascript"></script>
    </g:if>
    <g:else>
        <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    </g:else>

    <r:require modules="region, bootstrapSwitch"/>
</head>

<body class="nav-locations regions">
<g:set var="enableQueryContext" value="${grailsApplication.config.biocache.enableQueryContext?.toBoolean()}"></g:set>
<g:set var="enableHubData" value="${grailsApplication.config.hub.enableHubData?.toBoolean()}"></g:set>
<g:set var="hubState" value="${true}"></g:set>

<div class="page-header">
    <g:if test="${flash.message}">
        <div class="message">${flash.message}</div>
    </g:if>

    <h1 class="page-header__title">
        ${region.name}
    </h1>

    <div id="occurrenceRecords" class="page-header__subtitle">
        Occurrence records <span class="totalRecords"></span>

        <%-- XXX TODO Test the style of emblems. So far they have remained unseen. --%>
        <g:if test="${emblems}">
            <aa:zone id="emblems" href="${g.createLink(controller: 'region', action: 'showEmblems', params: [regionType: region.type, regionName: region.name, regionPid: region.pid])}">
                <i class="fa fa-cog fa-spin fa-2x"></i>
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
                    <strong>Notes on the map layer: </strong> ${region.notes}
                </g:if>
            </g:if>
        </div>
    </div>

    <div class="page-header-links">
        <a href="${g.createLink(uri: '/')}" class="page-header-links__link">
            Regions
        </a>

        <div id="viewRecords" class="erk-link page-header-links__link">
            View records <span class="totalRecords"></span>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-5">
        <ul class="nav nav-tabs" id="explorerTabs">
            <li class="nav-item">
                <a id="speciesTab" data-toggle="tab" href="#speciesTabContent" class="nav-link active">
                    Explore by species
                    <span class="fa fa-cog fa-spin fa-lg hidden"></span>
                </a>
            </li>

            <li class="nav-item">
                <a id="taxonomyTab" data-toggle="tab" href="#taxonomyTabContent" class="nav-link">
                    Explore by taxonomy
                    <span class="fa fa-cog fa-spin fa-lg hidden"></span>
                </a>
            </li>
        </ul>

        <div class="tab-content">
            <div class="tab-pane active" id="speciesTabContent">
                <div class="row no-gutters">
                    <div class="col-4">
                        <table id="groups"
                            tagName="tbody"
                            class="table table-condensed table-hover"
                            aa-href="${g.createLink(controller: 'region', action: 'showGroups', params: [regionFid: region.fid,regionType: region.type, regionName: region.name, regionPid: region.pid])}"
                            aa-js-before="setHubConfig();"
                            aa-js-after="regionWidget.groupsLoaded();"
                            aa-refresh-zones="groupsZone"
                            aa-queue="abort"
                        >
                            <thead>
                                <tr>
                                    <th class="text-center">Group</th>
                                </tr>
                            </thead>

                            <tbody id="groupsZone" tagName="tbody">
                                <tr class="spinner">
                                    <td class="spinner text-center">
                                        <i class="fa fa-cog fa-spin fa-2x"></i>
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
                                    <th>Species: Common Name</th>
                                    <th class="text-right">Records</th>
                                </tr>
                            </thead>

                            <aa:zone id="speciesZone" tag="tbody" jsAfter="regionWidget.speciesLoaded();">
                                <tr class="spinner">
                                    <td colspan="3" class="spinner text-center">
                                        <i class="fa fa-cog fa-spin fa-2x"></i>
                                    </td>
                                </tr>
                            </aa:zone>
                        </table>
                    </div>
                </div>
            </div>

            <div class="tab-pane" id="taxonomyTabContent">
                <div id="charts">
                    <span class="spinner fa fa-cog fa-spin fa-3x"></span>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-7">
        <div>
            <span class="fa fa-info-circle fa-lg"></span>
            How to use time control: drag handles to restrict date or play by decade.
        <span id="exploreButtons">
            <a href="${g.createLink(controller: 'region', action: 'showDownloadDialog')}"
               aa-refresh-zones="dialogZone" aa-js-before="regionWidget.showDownloadDialog();"
            >
                <button class="erk-button erk-button--light">
                    <span class="fa fa-download"></span>
                    Download Records
                </button>
            </a>
        </span>
        </div>

        <div id="region-map"></div>

        <div id="timeControls" class="text-center">
            <div id="timeButtons">
                <span class="timeControl link" id="playButton" title="Play timeline by decade" alt="Play timeline by decade"></span>
                <span class="timeControl link" id="pauseButton" title="Pause play" alt="Pause play"></span>
                <span class="timeControl link" id="stopButton" title="Stop" alt="Stop"></span>
                <span class="timeControl link" id="resetButton" title="Reset" alt="Reset"></span>
            </div>

            <div id="timeSlider">
                <div id="timeRange"><span id="timeFrom"></span> - <span id="timeTo"></span></div>
            </div>
        </div>

        <div id="opacityControls">
            <label class="checkbox">
                <input type="checkbox"name="occurrences" id="toggleOccurrences" checked> Occurrences
            </label>

            <div id="occurrencesOpacity"></div>

            <label class="checkbox">
                <input type="checkbox" name="region" id="toggleRegion" checked> Region
            </label>

            <div id="regionOpacity"></div>
        </div>
    </div>
</div>

<div id="downloadRecordsModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <aa:zone id="dialogZone">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
                    <h3 id="myModalLabel">Download Records</h3>
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
            <h2>Regions within ${region.name}</h2>

            <g:each in="${subRegions}" var="item">
                <h3>${item.key}</h3>

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

<g:if test="${documents.factSheets||documents.publications||documents.links}">
    <div class="row">
        <div class="col-12" id="docs">
            <h2>Documents and Links</h2>

            <g:if test="${documents.factSheets}">
                <h3>Fact sheets</h3>

                <ul>
                    <g:each in="${documents.factSheets}" var="d">
                        <li>
                            <a href="${d.url}" class="external">${d.linkText}</a>
                            ${d.otherText}
                        </li>
                    </g:each>
                </ul>
            </g:if>

            <g:if test="${documents.publications}">
                <h3>Publications</h3>

                <ul>
                    <g:each in="${documents.publications}" var="d">
                        <li>
                            <a href="${d.url}" class="external">${d.linkText}</a>
                            ${d.otherText}
                        </li>
                    </g:each>
                </ul>
            </g:if>

            <g:if test="${documents.links}">
                <h3>Links</h3>

                <ul>
                    <g:each in="${documents.links}" var="d">
                        <li>
                            <a href="${d.url}" class="external">${d.linkText}</a> ${d.otherText}
                        </li>
                    </g:each>
                </ul>
            </g:if>

            <g:link elementId="manage-doc-link" action="documents">Add or manage documents and links</g:link>
        </div>
    </div>
</g:if>

<r:script>
    google.load("visualization", "1", {packages:["corechart"]});
    var regionWidget;

    $(function() {
        $(document).on("click", "[aa-refresh-zones]", function(event) {
            event.stopPropagation()
            return false;
        });

        <g:if test="${enableHubData}">
            $("[name='hub-toggle']").bootstrapSwitch({
                size: "small",
                onText: "All",
                onColor: "primary",
                offText: "MDBA",
                offColor: "success",
                onSwitchChange: function(event, state) {
                    console.log("switch toggled", state);
                    if (!state) {
                        // MDBA visible
                        regionWidget.getCurrentState().showHubData = true
                    } else {
                        regionWidget.getCurrentState().showHubData = false
                    }
                    refreshSpeciesGroup();
                    taxonomyChart.load()
                }
            });
        </g:if>

        regionWidget = new RegionWidget({
            regionName: '${region.name}',
            regionType: '${region.type}',
            regionFid: '${region.fid}',
            regionPid: '${region.pid}',
            regionLayerName: '${region.layerName}',
            urls: {
                regionsApp: '${g.createLink(uri: '/', absolute: true)}',
                proxyUrl: '${g.createLink(controller: 'proxy', action: 'index')}',
                proxyUrlBbox: '${g.createLink(controller: 'proxy', action: 'bbox')}',
                speciesPageUrl: "${grailsApplication.config.bie.baseURL}/species/",
                biocacheServiceUrl: "${grailsApplication.config.biocacheService.baseURL}",
                biocacheWebappUrl: "${grailsApplication.config.biocache.baseURL}",
                spatialWmsUrl: "${grailsApplication.config.geoserver.baseURL}/ALA/wms?",
                spatialCacheUrl: "${grailsApplication.config.geoserver.baseURL}/gwc/service/wms?",
                spatialServiceUrl: "${grailsApplication.config.layersService.baseURL}/",
            },
            username: '${rg.loggedInUsername()}',
            q: '${region.q}'

            <g:if test="${enableQueryContext}">
                ,qc:"${URLEncoder.encode(grailsApplication.config.biocache.queryContext, "UTF-8")}"
            </g:if>

            <g:if test="${enableHubData}">
                ,hubFilter:"${URLEncoder.encode(grailsApplication.config.hub.hubFilter , "UTF-8")}"
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

    function setHubConfig(){
        <g:if test="${enableHubData}">
            AjaxAnywhere.dynamicParams = {
                showHubData:!$('[name="hub-toggle"]').is(":checked")
            }
        </g:if>
    }

    function refreshSpeciesGroup(){
        $('#groups').click()
    }
</r:script>
</body>
</html>
