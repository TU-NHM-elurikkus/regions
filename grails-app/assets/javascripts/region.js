//= require jquery-ui-1.11.2-no-autocomplete
//= require jquery-ui-slider-pips
//= require charts2
//= require number-functions
//= require keydragzoom
//= require wms
//= require aa

var regionWidget; // Populated by region.gsp

var region = {
    /**
     * Builds the query as a map that can be passed directly as data in an ajax call
     * @param regionType
     * @param regionName
     * @param regionFid
     * @param start [optional] start parameter for paging results
     * @returns {{q: *, pageSize: number}}
     */
    buildBiocacheQuery: function(q, start) {
        var params = { q: q, pageSize: 50 },
            timeFacet = region.buildTimeFacet();
        if(start) {
            params.start = start;
        }

        if(timeFacet) {
            params.fq = timeFacet;
        }
        return params;
    },

    /**
     * Builds the query phrase for a range of dates - returns nothing for the default date range.
     */
    buildTimeFacet: function() {
        if(!regionWidget.isDefaultFromYear() || !regionWidget.isDefaultToYear()) {
            var fromPhrase = regionWidget.isDefaultFromYear() ? '*' : regionWidget.getCurrentState().from + '-01-01T00:00:00Z';
            var toPhrase = regionWidget.isDefaultToYear() ? '*' : regionWidget.getCurrentState().to + '-12-31T23:59:59Z';
            return 'occurrence_year:[' + fromPhrase + ' TO ' + toPhrase + ']';
        } else {
            return '';
        }
    },

    queryString: function() {
        if(!this.isInit()) { return ''; }
        var fromPhrase = this.from() === this.defaultFrom ? '*' : this.from() + '-01-01T00:00:00Z',
            toPhrase = this.to() === this.defaultTo ? '*' : (this.to() - 1) + '-12-31T23:59:59Z';
        return 'occurrence_year:[' + fromPhrase + ' TO ' + toPhrase + ']';
    },

    /**
     * Formats numbers as human readable. Handles numbers in the millions.
     * @param count the number
     */
    format: function(count) {
        if(count >= 1000000) {
            return count.numberFormat('#,#0,,.00 million');
        } else {
            return count.toLocaleString(GLOBAL_LOCALE_CONF.locale);
        }
    }
};

// This function has to be in the global scope for the chart to work
function taxonChartChange(rank, name) {
    regionWidget.getMap().reloadRecordsOnMap();
}

function RegionWidget(config) {

    var defaultFromYear = 1850;
    var defaultToYear = new Date().getFullYear();
    var defaultTab = 'species-tab';
    var regionMap;
    var timeControls;
    var taxonomyWidget;

    /**
     * Essential values to maintain the state of the widget when the user interacts with it
     * @type {{regionName: string, regionType: string, regionFid: string, regionPid: string, regionLayerName: string, group: string, subgroup: string, guid: string, from: string, to: string, tab: string}}
     */
    var state = {
        regionName: '',
        regionType: '',
        regionFid: '',
        regionPid: '',
        regionLayerName: '',
        group: '',
        subgroup: '',
        guid: '',
        from: '',
        to: '',
        tab: '',
        q: '',
        qc: '',
        hubFilter: '',
        showHubData: false,
        groupRank: ''
    };

    var urls = {};

    /**
     * Constructor
     * @param config
     */
    function init(config) {
        state.regionName = config.regionName;
        state.regionType = config.regionType;
        state.regionFid = config.regionFid;
        state.regionPid = config.regionPid;
        state.regionLayerName = config.regionLayerName;

        state.group = state.group ? state.group : 'ALL_SPECIES';
        state.from = state.from ? state.from : defaultFromYear;
        state.to = state.to ? state.to : defaultToYear;
        state.tab = state.tab ? state.tab : defaultTab;
        state.qc = config.qc || '';
        state.q = config.q;
        state.showHubData = config.showHubData || false;
        state.hubFilter = config.hubFilter || '';

        urls = config.urls;

        initializeTabs();

        // Initialize Ajax activity indicators
        $(document).ajaxStart(
            function(e) {
                showTabSpinner();
            }
        ).ajaxComplete(function() {
            hideTabSpinner();
        });

        // Initialize click events on individual species
        $(document).on('click', '#species tbody tr.link', function() {
            selectSpecies(this);
        });

        // Initialize info message
        $('#timeControlsInfo').popover();

        initializeViewRecordsButton();

        // Initialize `nload records dialog
        $('#downloadRecordsModal').modal({ show: false });
    }

    /**
     *
     */
    function initializeTabs() {
        // Initialize tabs
        $('#explorerTabs a').on('show', function(e) {
            var tabId = $(e.target).attr('id');
            updateState({ tab: tabId });
        });
        $('#' + state.tab).click();

    }

    /**
     *
     */
    function initializeViewRecordsButton() {
        $('#viewRecords').click(function(event) {
            event.preventDefault();
            // check what group is active
            var url = urls.biocacheWebappUrl + '/occurrences/search?q=' + decodeURI(state.q) +
                '&fq=rank:(species OR subspecies)';
            if(!regionWidget.isDefaultFromYear() || !regionWidget.isDefaultToYear()) {
                url += '&fq=' + region.buildTimeFacet();
            }
            if(state.group !== 'ALL_SPECIES') {
                url += '&fq=' + state.groupRank + ':"' + state.group + '"';
            }

            if(state.qc) {
                // when using qc, biocache search fails. AtlasOfLivingAustralia/biocache-hubs#176
                url += '&fq=' + state.qc;
            }

            if(state.showHubData) {
                url += '&fq=' + state.hubFilter;
            }

            document.location.href = url;
        });
    }

    /**
     * Updates state with new values and preserve state for when reloading page
     * @param newPartialState
     */
    function updateState(newPartialState) {
        $.extend(state, newPartialState);
    }

    /**
     * Function called when the user selects a species
     * @param row
     */
    function selectSpecies(row) {
        $('#species tbody tr.link').removeClass('speciesSelected');
        $('#species tbody tr.infoRowLinks').hide();
        var nextTr = $(row).next('tr');
        $(row).addClass('speciesSelected');
        $(nextTr).addClass('speciesSelected');
        $(row).next('tr').show();
        // Update state
        updateState({ guid: $(row).attr('id') });
        regionMap.reloadRecordsOnMap();
    }

    /**
     * Hides the tab spinners
     * @param tabId
     */
    function hideTabSpinner(tabId) {
        if($.active === 1) {
            if(tabId) {
                $('#' + tabId + ' span').addClass('hidden');
            } else {
                $('#' + state.tab + ' span').addClass('hidden');
            }
        }
    }

    /**
     * Shows the tab spinners
     * @param tabId
     */
    function showTabSpinner(tabId) {
        if(tabId) {
            $('#' + tabId + ' span').removeClass('hidden');
        } else {
            $('#' + state.tab + ' span').removeClass('hidden');
        }
    }

    /** Code to execute when a group is selected **/
    function selectGroup(group, taxonRank) {
        $('.group-row').removeClass('groupSelected');
        $('tr[parent]').hide();
        if(group !== state.group) {
            $('#main-' + state.group + '-row span').removeClass('fa-chevron-down').addClass('fa-chevron-right');
        }
        var groupId = 'main-' + group.replace(/[^A-Za-z0-9\\d_]/g, '') + '-row';

        var isAlreadyExpanded = $('#' + groupId + ' span').hasClass('fa-chevron-down');
        if(isAlreadyExpanded) {
            $('tr[parent=\'' + groupId + '\']').hide();
            $('#' + groupId + ' span').removeClass('fa-chevron-down').addClass('fa-chevron-right');
        } else {
            var subgroupRows = $('tr[parent=\'' + groupId + '\']');
            $('tr[parent=\'' + groupId + '\']').show();
            $('#' + groupId + ' span').removeClass('fa-chevron-right').addClass('fa-chevron-down');

            // Populate sub-group counts
            getTaxonCount(subgroupRows);
        }

        // Update widget state
        updateState({ group: group, subgroup: '', guid: '', groupRank: taxonRank });
        // Mark as selected
        $('#' + groupId).addClass('groupSelected');

        // Last
        if(regionMap) {
            regionMap.reloadRecordsOnMap();
        }
        AjaxAnywhere.dynamicParams = state;
    }

    /* Finds taxon counts for all the given rows */
    function getTaxonCount(tableRows) {
        var urls = regionWidget.getUrls();

        tableRows.each(function(index, row) {
            var taxonName = row.dataset.taxonname;
            var taxonRank = row.dataset.taxonrank;
            var countQuery = 'explore/counts/group/ALL_SPECIES/';

            if(taxonName === 'ALL_SPECIES') {
                countQuery += '?fq=' + state.regionFid + ':"' + state.regionName + '"';
            } else {
                countQuery += '?fq=(' + taxonRank + ':"' + taxonName + '" AND ' + state.regionFid + ':"' + state.regionName + '")';
            }

            $.ajax({
                url: urls.biocacheProxy,
                dataType: 'json',
                data: {
                    'url': encodeURI(countQuery)
                },
                success: function(data) {
                    $(row.children[1]).html(data[1]);
                },
            });
        });
    }

    /**
     * Code to execute when a subgroup is selected
     * @param subgroup
     */
    function selectSubgroup(subgroup, taxonRank) {
        $('.group-row').removeClass('groupSelected');
        var subgroupId = subgroup.replace(/[^A-Za-z\\d_]/g, '') + '-row';

        // Update widget state
        updateState({ group: subgroup, guid: '', groupRank: taxonRank });
        // Mark as selected
        $('#' + subgroupId).addClass('groupSelected');

        // Last
        if(regionMap) {
            regionMap.reloadRecordsOnMap();
        }
        AjaxAnywhere.dynamicParams = state;
    }

    function getGroupId() {
        return state.group.replace(/[^A-Za-z0-9\\d_]/g, '') + '-row';
    }

    function getSubgroupId() {
        return state.subgroup.replace(/[^A-Za-z0-9\\d_]/g, '') + '-row';
    }

    var _public = {

        isDefaultFromYear: function() {
            return state.from === defaultFromYear;
        },

        isDefaultToYear: function() {
            return state.to === defaultToYear;
        },

        getDefaultFromYear: function() {
            return defaultFromYear;
        },

        getDefaultToYear: function() {
            return defaultToYear;
        },

        getTimeControls: function() {
            return timeControls;
        },

        updateDateRange: function(from, to) {
            updateState({
                from: from,
                to: to
            });
            if(state.subgroup) {
                $('#' + getSubgroupId()).click();
            } else {
                $('#main-' + getGroupId()).click();
            }
            // Update taxonomy chart
            if(taxonomyChart && taxonomyWidget) {
                taxonomyChart.updateQuery(taxonomyWidget.getQuery() + '&fq=' + region.buildTimeFacet());
            }
        },

        getUrls: function() {
            return urls;
        },

        getCurrentState: function() {
            return state;
        },

        groupsLoaded: function() {
            $('#groups').effect('highlight', { color: 'rgba(61, 200, 211, .66)' }, 2000);

            $('#main-' + getGroupId()).click();

            // Populate main taxon group counts
            var mainRows = $('#groups tr[id^="main-"]');
            getTaxonCount(mainRows);
        },

        selectGroupHandler: function(group, isSubgroup, taxonRank) {
            if(isSubgroup) {
                selectSubgroup(group, taxonRank);
            } else {
                selectGroup(group, taxonRank);
            }
        },

        speciesLoaded: function() {
            $('#species').effect('highlight', { color: 'rgba(61, 200, 211, .66)' }, 2000);

            var totalRecords = $('#moreSpeciesZone').attr('totalRecords');

            if(isNaN(totalRecords)) {
                $('.totalRecords').text('');
            } else {
                $('.totalRecords').text('(' + region.format(parseInt($('#moreSpeciesZone').attr('totalRecords'))) + ')');
            }

            $('#occurrenceRecords').effect('highlight', { color: 'rgba(61, 200, 211, .66)' }, 2000);
        },

        showMoreSpecies: function() {
            $('#showMoreSpeciesButton').html('<span class="fa fa-cog fa-spin"></span>');
            AjaxAnywhere.dynamicParams = this.getCurrentState();
        },

        setMap: function(map) {
            regionMap = map;
        },

        getMap: function() {
            return regionMap;
        },

        setTimeControls: function(tc) {
            timeControls = tc;
        },

        setTaxonomyWidget: function(tw) {
            taxonomyWidget = tw;
        },

        getTaxonomyWidget: function() {
            return taxonomyWidget;
        },

        showDownloadDialog: function() {
            AjaxAnywhere.dynamicParams = this.getCurrentState();
            $('#downloadRecordsModal').modal('show');
        }
    };

    init(config);
    return _public;
}

/**
 *
 * @param config
 * @returns {{}}
 * @constructor
 */
function RegionTimeControls(config) {

    var CONTROL_STATES = {
        PLAYING: 0,
        PAUSED: 1,
        STOPPED: 2
    };
    var state = CONTROL_STATES.STOPPED;
    var refreshInterval;
    var playTimeRange;

    function init(config) {
        $('#timeSlider').slider({
            min: regionWidget.getDefaultFromYear(),
            max: regionWidget.getDefaultToYear(),
            range: true,
            values: [regionWidget.getCurrentState().from, regionWidget.getCurrentState().to],
            create: function() {
                updateTimeRange($('#timeSlider').slider('values'));
            },
            slide: function(event, ui) {
                updateTimeRange(ui.values);
            },
            change: function(event, ui) {
                if(!(state === CONTROL_STATES.PLAYING)
                        || (ui.values[0] !== ui.values[1] && ui.values[1] - ui.values[0] <= 10)) {
                    regionWidget.updateDateRange(ui.values[0], ui.values[1]);
                }
                updateTimeRange(ui.values);
            }
        })

            .slider('pips', {
                rest: 'pip',
                step: 10
            })
            .slider('float', {});

        initializeTimeControlsEvents();
    }

    function initializeTimeControlsEvents() {
        // Initialize play button
        $('#playButton').on('click', function() {
            play();
        });

        // Initialize stop button
        $('#stopButton').on('click', function() {
            stop();
        });

        // Initialize pause button
        $('#pauseButton').on('click', function() {
            pause();
        });

        // Initialize reset button
        $('#resetButton').on('click', function() {
            reset();
        });

    }

    function increaseTimeRangeByADecade() {
        var incrementTo = (regionWidget.getDefaultToYear() - playTimeRange[1]) < 10 ? regionWidget.getDefaultToYear() - playTimeRange[1] : 10;
        if(incrementTo !== 0) {
            $('#timeSlider').slider('values', [playTimeRange[0] + 10, playTimeRange[1] + incrementTo]);
            playTimeRange = $('#timeSlider').slider('values');
        } else {
            stop();
        }
    }

    function play() {
        switch(state) {
            case CONTROL_STATES.STOPPED:
                // Start playing from the beginning
                // Update state before updating slider values
                state = CONTROL_STATES.PLAYING;
                $('#timeSlider').slider('values', [regionWidget.getDefaultFromYear(), regionWidget.getDefaultFromYear() + 10]);
                break;
            case CONTROL_STATES.PAUSED:
                // Resume playing
                // Update state before updating slider values
                state = CONTROL_STATES.PLAYING;
                $('#timeSlider').slider('values', [playTimeRange[0], playTimeRange[1]]);
                break;
        }

        // For SVG elements the addClass and removeClass jQuery method do not work
        $('#pauseButton').removeClass('selected').trigger('selected');
        $('#playButton').addClass('selected').trigger('selected');
        playTimeRange = $('#timeSlider').slider('values');
        refreshInterval = setInterval(function() {
            increaseTimeRangeByADecade();
        }, 4000);
    }

    function stop() {
        clearInterval(refreshInterval);
        $('#pauseButton').removeClass('selected').trigger('selected');
        $('#playButton').removeClass('selected').trigger('selected');
        state = CONTROL_STATES.STOPPED;
    }

    function pause() {
        if(state === CONTROL_STATES.PLAYING) {
            $('#pauseButton').addClass('selected').trigger('selected');
            $('#playButton').removeClass('selected').trigger('selected');
            clearInterval(refreshInterval);
            state = CONTROL_STATES.PAUSED;
        }
    }

    function reset() {
        $('#timeSlider').slider('values', [regionWidget.getDefaultFromYear(), regionWidget.getDefaultToYear()]);
        stop();
        regionWidget.updateDateRange(regionWidget.getDefaultFromYear(), regionWidget.getDefaultToYear());
        taxonomyChart.reset();
    }

    function updateTimeRange(values) {
        $('#timeFrom').text(values[0]);
        $('#timeTo').text(values[1]);
    }

    var _public = {

    };

    init(config);
    return _public;
}

function TaxonomyWidget(config) {

    var taxonomyChartOptions, query;

    function TaxonomyWidget(config) {
        var currentState = regionWidget.getCurrentState();
        query = currentState.q;

        taxonomyChartOptions = {
            query: query,
            qc: currentState.qc,
            currentState: currentState,
            subquery: region.buildTimeFacet(),
            rank: 'kingdom',
            width: 550,
            height: 420,
            clickThru: false,
            notifyChange: 'taxonChartChange',
            collectionsUrl: regionWidget.getUrls().regionsApp,
            biocacheServicesUrl: regionWidget.getUrls().biocacheServiceUrl,
            displayRecordsUrl: regionWidget.getUrls().biocacheWebappUrl,
        };

        taxonomyChart.load(taxonomyChartOptions);
    }

    var _public = {
        getQuery: function() {
            return query;
        }

    };

    TaxonomyWidget(config);
    return _public;
}

/**
 *
 * @param config
 * @returns
 * @constructor
 */
function RegionMap(config) {
    var map;
    var overlays = [null, null]; // first is the region, second is the occurrence data
    var defaultOccurrenceOpacity = 1.0;
    var defaultRegionOpacity = 0.2;
    var initialBounds;
    var infoWindow;
    var useReflectService = true;
    var overlayFormat = 'image/png';
    var enableRegionOverlay = true;

    function init(config) {
        initialBounds = new google.maps.LatLngBounds(
            new google.maps.LatLng(config.bbox.sw.lat, config.bbox.sw.lng),
            new google.maps.LatLng(config.bbox.ne.lat, config.bbox.ne.lng));

        useReflectService = config.useReflectService;
        enableRegionOverlay = config.enableRegionOverlay;

        var myOptions = {
            scrollwheel: false,
            streetViewControl: false,
            mapTypeControl: true,
            mapTypeControlOptions: {
                style: google.maps.MapTypeControlStyle.DROPDOWN_MENU
            },
            scaleControl: true,
            scaleControlOptions: {
                position: google.maps.ControlPosition.LEFT_BOTTOM
            },
            panControl: false,
            draggableCursor: 'crosshair',
            mapTypeId: google.maps.MapTypeId.TERRAIN /* google.maps.MapTypeId.TERRAIN */
        };

        map = new google.maps.Map(document.getElementById('region-map'), myOptions);
        map.fitBounds(initialBounds);
        map.enableKeyDragZoom();

        initializeOpacityControls();

        /** ***************************************\
         | Overlay the region shape
         \*****************************************/
        drawRegionOverlay();

        /** ***************************************\
         | Overlay the occurrence data
         \*****************************************/
        drawRecordsOverlay();

        google.maps.event.addListener(map, 'click', function(event) {
            info(event.latLng);
        });
    }

    /**
     * Set up opacity sliders
     */
    function initializeOpacityControls() {

        $('#occurrencesOpacity').slider({
            min: 0,
            max: 100,
            value: defaultOccurrenceOpacity * 100,
            change: function(event, ui) {
                drawRecordsOverlay();
            }
        });
        $('#regionOpacity').slider({
            min: 0,
            max: 100,
            value: defaultRegionOpacity * 100,
            change: function(event, ui) {
                drawRegionOverlay();
            }
        });

        $('#opacityControls a').on('click', function() {
            if($('#opacityControlsContent').hasClass('in')) {
                $('#opacityControls span').switchClass('fa-chevron-down', 'fa-chevron-right');
            } else {
                $('#opacityControls span').switchClass('fa-chevron-right', 'fa-chevron-down');
            }
        });

        // layer toggling
        $('#toggleOccurrences').click(function() {
            toggleOverlay(1, this.checked);
        });
        $('#toggleRegion').click(function() {
            toggleOverlay(0, this.checked);
        });
    }

    /**
    * Called when the overlays are loaded. Not currently used
    * @param numtiles
    */
    function wmsTileLoaded(numtiles) {
        $('#maploading').fadeOut('slow');
    }

    /**
     * Turns the overlay layers on or off
     * @param n index of the overlay in the overlays list
     * @param show true to show; false to hide
     */
    function toggleOverlay(n, show) {
        map.overlayMapTypes.setAt(n, show ? overlays[n] : null);
    }

    /**
    * Returns the value of the opacity slider for the region overlay.
    */
    function getRegionOpacity() {
        var opacity = $('#regionOpacity').slider('value');
        return isNaN(opacity) ? defaultRegionOpacity : opacity / 100;
    }

    /**
     * Returns the value of the opacity slider for the occurrence overlay.
     */
    function getOccurrenceOpacity() {
        var opacity = $('#occurrencesOpacity').slider('value');
        return isNaN(opacity) ? defaultOccurrenceOpacity : opacity / 100;
    }

    /**
     * Load the region as a WMS overlay.
     */
    function drawRegionOverlay() {

        if(enableRegionOverlay) {
            var currentState = regionWidget.getCurrentState();
            var urls = regionWidget.getUrls();

            if(currentState.q.indexOf('%3A*') === currentState.q.length - 4) {
                /* this draws the region as a WMS layer */
                var layerParams = [
                    'FORMAT=' + overlayFormat,
                    'LAYERS=ALA:' + currentState.regionLayerName,
                    'STYLES=polygon'
                ];
                overlays[0] = new WMSTileLayer(currentState.regionLayerName, urls.spatialCacheUrl, layerParams, wmsTileLoaded, getRegionOpacity());
                map.overlayMapTypes.setAt(0, overlays[0]);

            } else {
                var params = [
                    'FORMAT=' + overlayFormat,
                    'LAYERS=ALA:Objects',
                    'viewparams=s:' + currentState.regionPid,
                    'STYLES=polygon'
                ];
                overlays[0] = new WMSTileLayer(currentState.regionLayerName, urls.spatialWmsUrl, params, wmsTileLoaded, getRegionOpacity());
                map.overlayMapTypes.setAt(0, overlays[0]);
            }
        }
    }

    /**
     * Load occurrence data as a wms overlay based on the current selection:
     * - if taxa box is visible, show the selected species group or species
     * - if taxonomy chart is selected, show the current named rank
     * - use date restriction specified by the time slider
     */
    function drawRecordsOverlay() {

        var currentState = regionWidget.getCurrentState();
        var urls = regionWidget.getUrls();

        if(useReflectService) {
            drawRecordsOverlay2();
            return;
        }

        var customParams = [
            'FORMAT=' + overlayFormat,
            'colourby=3368652',
            'symsize=4'
        ];

        // Add query string params to custom params
        var query = region.buildBiocacheQuery(currentState.q, 0, true);
        var searchParam = encodeURI('?q=' + decodeURI(query.q) + '&fq=' + query.fq + '&fq=geospatial_kosher:true');

        var fqParam = '';
        if($('#taxonomy-tab').hasClass('active')) {
            // show records based on taxonomy chart
            if(taxonomyChart.rank && taxonomyChart.name) {
                fqParam = '&fq=' + taxonomyChart.rank + ':' + taxonomyChart.name;
            }
        } else {
            // show records based on taxa box
            if(currentState.guid) {
                fqParam = '&fq=taxon_concept_lsid:' + currentState.guid;
            } else if(currentState.group !== 'ALL_SPECIES') {
                if(currentState.subgroup) {
                    fqParam = '&fq=species_subgroup:' + currentState.subgroup;
                } else {
                    fqParam = '&fq=species_group:' + currentState.group;
                }
            }
        }

        searchParam += fqParam;

        if(currentState.qc) {
            searchParam += '&qc=' + currentState.qc;
        }

        if(currentState.showHubData) {
            searchParam += '&fq=' + currentState.hubFilter;
        }

        var pairs = searchParam.substring(1).split('&');
        for(var j = 0; j < pairs.length; j++) {
            customParams.push(pairs[j]);
        }
        overlays[1] = new WMSTileLayer('Occurrences',
            urlConcat(urls.biocacheServiceUrl, 'occurrences/wms?'), customParams, wmsTileLoaded, getOccurrenceOpacity());

        map.overlayMapTypes.setAt(1, $('#toggleOccurrences').is(':checked') ? overlays[1] : null);
    }

    function drawRecordsOverlay2() {
        var currentState = regionWidget.getCurrentState();
        var urls = regionWidget.getUrls();
        var url = urls.biocacheServiceUrl + '/mapping/wms/reflect?';
        var query = region.buildBiocacheQuery(currentState.q, 0, true);
        var prms = [
            'FORMAT=' + overlayFormat,
            'LAYERS=ALA%3Aoccurrences',
            'STYLES=',
            'BGCOLOR=0xFFFFFF',
            'q=' + query.q,
            'fq=geospatial_kosher:true',
            'fq=rank:(species OR subspecies)',
            'CQL_FILTER=',
            'symsize=3',
            'ENV=color:3dc8d3;name:circle;size:3;opacity:' + getOccurrenceOpacity(),
            'EXCEPTIONS=application-vnd.ogc.se_inimage'
        ];

        if(query.fq) {
            prms.push('fq=' + query.fq);
        }

        if($('#taxonomy-tab').hasClass('active')) {
            // show records based on taxonomy chart
            if(taxonomyChart.rank && taxonomyChart.name) {
                prms.push('fq=' + encodeURI(taxonomyChart.rank + ':' + taxonomyChart.name));
            }
        } else {
            // show records based on taxa box
            if(currentState.guid) {
                prms.push('fq=taxon_concept_lsid:' + encodeURI(currentState.guid));
            } else if(currentState.group !== 'ALL_SPECIES') {
                if(currentState.subgroup) {
                    prms.push('fq=species_subgroup:' + encodeURI('"' + currentState.subgroup + '"'));
                } else {
                    prms.push(encodeURI('fq=' + currentState.groupRank + ':"' + currentState.group + '"'));
                }
            }
        }

        if(currentState.qc) {
            prms.push('qc=' + currentState.qc);
        }

        if(currentState.showHubData) {
            prms.push('fq=' + currentState.hubFilter);
        }

        overlays[1] = new WMSTileLayer('Occurrences (by reflect service)', url, prms, wmsTileLoaded, 0.8);

        map.overlayMapTypes.setAt(1, $('#toggleOccurrences').is(':checked') ? overlays[1] : null);
    }

    /**
     * Show information about the current layer at the specified location.
     * @param location
     */
    function info(location) {
        var currentState = regionWidget.getCurrentState();
        var urls = regionWidget.getUrls();

        var geoQuery = 'intersect/pointradius/' + currentState.regionFid +
                       '/' + location.lat() + '/' + location.lng() + '/0.01/';
        $.ajax({
            url: urls.spatialProxy,
            dataType: 'json',
            data: {
                url: geoQuery,
            },
            success: function(data) {
                if(data.length === 0) {
                    return;
                }
                if(infoWindow) {
                    infoWindow.close();
                }

                if(data.length) {
                    var desc = '<ul class="erk-ulist">';
                    $.each(data, function(i, obj) {
                        desc += '<b>';
                        if(obj.pid === currentState.regionPid) {
                            desc += '<li>' + obj.name + '</li>';
                        } else {
                            var href = document.location.origin + '/regions/' + currentState.regionType + '/' + obj.name;
                            desc += '' +
                                '<li>' +
                                    '<a href="' + href + '">' +
                                        obj.name +
                                    '</a>' +
                                '</li>';
                        }
                        desc += '</b>';

                        if(obj.area_km) {
                            desc += '<li>' + $.i18n.prop('region.info.surfaceArea') + ': ' + obj.area_km.toFixed(1) + ' km&sup2;</li>';
                        }
                        desc += '<li>' + $.i18n.prop('region.info.desc') + ': ' + obj.description + '</li>';
                    });
                    desc += '</ul>';

                    infoWindow = new google.maps.InfoWindow({
                        content: '<div style="font-size:90%;padding-right:15px;">' + desc + '</div>',
                        position: location
                    });
                    infoWindow.open(map);
                }
            }
        });
    }

    var _public = {
        reloadRecordsOnMap: function() {
            drawRecordsOverlay();
        }
    };

    init(config);
    return _public;
}
