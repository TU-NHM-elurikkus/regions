//= require he-0.5.0
//= require jquery-ui-1.11.2-no-autocomplete
//= require wms
//= require keydragzoom

$(document).ready(function() {
    $('.accordion-heading').on('click', function(e) {
        var anchor = $(e.currentTarget).attr('id').replace('accordion-heading-', '#');

        if(window.history) {
            window.history.replaceState({}, '', anchor);
        } else {
            window.location.hash = anchor;
        }
    });
});

(function(windows) {
    var
        // represents the map and its associated properties and events
        map,

        //  Urls are injected from config
        config = {},

        // the currently selected region type - an instance of RegionSet
        selectedRegionType,

        // restrict accordion regions to those which intersect bounds (optional)
        mapBounds,

        // the currently selected region - will be null if no region is selected else an instance of Region
        selectedRegion = null;

    // helper method
    function clearSelectedRegion() {
        if(selectedRegion) {
            selectedRegion.clear();
        }
    }

    /**
     * Returns the value of the opacity slider for the region overlay.
     */
    function getRegionOpacity() {
        var opacity = $('#regionOpacity').slider('value');
        return isNaN(opacity) ? map.defaultRegionOpacity : opacity / 100;
    }

    /**
     * Returns the value of the opacity slider for the region overlay.
     */
    function getLayerOpacity() {
        var opacity = $('#layerOpacity').slider('value');
        return isNaN(opacity) ? map.defaultLayerOpacity : opacity / 100;
    }

    /**
     * Disables the toggle and opacity slider for the regions overlay.
     */
    function disableRegionsSlider() {
        $('#toggleRegion').attr('disabled', true);
        $('#regionOpacity').slider('option', 'disabled', true);
    }

    /**
     * Enables the toggle and opacity slider for the regions overlay.
     */
    function enableRegionsSlider() {
        $('#toggleRegion').attr('disabled', false);
        $('#regionOpacity').slider('option', 'disabled', false);
    }

    /**
     * Clears all highlighted names in all region lists.
     */
    function clearHighlights() {
        $('li.regionLink').removeClass('selected');
    }

    /**
     * Removes region-specific info from the map title. Replaces with generic text.
     */
    function hideInfo() {
        $('#show-region').parent().addClass('hidden');
        $('#zoomTo').parent().addClass('hidden');
        $('#extra').parent().addClass('hidden');
    }

    /** * RegionSet represents a set of regions such as all states ********************************************************/
    // assumes this is a single field of a single layer
    function RegionSet(name, layerName, fid, bieContext, order, displayName) {
        this.name = name;
        this.layerName = layerName;
        this.fid = fid;
        this.bieContext = bieContext;
        this.order = order;
        this.displayName = displayName;
        this.objects = {};
        this.sortedList = [];
        this.error = null;
        this.other = fid === null;
    }

    RegionSet.prototype = {
        /* Set this instance as the selected set */
        set: function(callbacks) {
            selectedRegionType = this;

            // clear any selected region
            clearSelectedRegion();

            // show the selected layer
            if(this.other) {
                // there is no default layer to display in the 'other regions' group
                map.removeLayerOverlay();
            } else {
                this.drawLayer();
            }

            // add content to the region type pane if empty
            this.writeList(callbacks);
        },

        /* Return the number of regions in the set */
        size: function() {
            return this.sortedList.length;
        },

        /* Return the field id for this set (or the selected sub-set of 'other') */
        getFid: function() {
            return this.other ? (selectedRegion ? selectedRegion.id : '') : this.fid;
        },

        /* Return the pid for the specified object in this set (or for the subregion of a sub-set)
         * @param name of the object */
        getPid: function(name) {
            return this.other ? selectedRegion.subregionPid : (this.objects[name] ? this.objects[name].pid : null);
        },

        /* Return metadata for the region in this set with the specified name
         * @param name of the region */
        getRegion: function(name) {
            return this.objects[name.replace('&amp;', '&')];
        },

        /* Is the content loaded? */
        loaded: function() {
            return this.size() > 0;
        },

        /* Load the content asynchronously
         * @param callbackOnSuccess optional callback on complete
         * @param optional param for callback */
        load: function(callbackOnSuccess, callbackParam) {
            $.ajax({
                url: encodeURI(config.baseUrl + '/regions/regionList?type=' + this.name),
                context: this,
                dataType: 'json',
                success: function(data) {
                    // check for errors
                    if(data.error === true) {
                        this.error = data.errorMessage;
                        $('#' + this.name).html(this.error);
                    } else {
                        var areaNames = [];
                        if(mapBounds) {
                            areaNames = Object.keys(data).sort();
                            data.names = areaNames;
                            data.objects = data;
                        }
                        // add to cache
                        this.objects = data;
                        this.sortedList = areaNames;
                        this[callbackOnSuccess](callbackParam);
                    }
                },

                error: function(jqXHR, textStatus) {
                    this.error = textStatus;
                    $('#' + this.name).html(this.error);
                }
            });
        },

        /* Write the list of regions to the regionSet's DOM container - loading first if required
         * @param callbackOnComplete a global-scope function to call when the list is written */
        writeList: function(callbackOnComplete) {
            var $content = $('#' + layers[this.name].fid);
            var me = this;
            var id;
            var html = '<ul class="erk-ulist">';

            if(!this.loaded()) {
                // load content asynchronously and execute this method when complete
                this.load('writeList', callbackOnComplete);
                return;
            }

            if($content.find('ul').length === 0) {
                $.each(this.sortedList, function(i, name) {
                    id = 'region-item-' + me.objects[name].pid;
                    html += '<li class="erk-ulist__item regionLink" id="' + id + '">' + name + '</li>';
                });

                html += '</ul>';
                $content.find('span.loading').remove();
                $content.append(html);

                // Correctly size the content box based on the number of items.  We are relying on the max-height css
                // to stop it from growing too large.
                var itemHeight = $content.find('li').height();

                $content.height(this.sortedList.length * itemHeight);

                $content.on('click', '.regionLink', function() {
                    var name = $(this).html();

                    new Region(name).set();
                });
            }

            if(callbackOnComplete) {
                // assume global scope
                callbackOnComplete(); // TODO: fix this - pass in function itself?
            }
        },

        /* Draw the layer for this set (or sub-set) */
        drawLayer: function(colour, order) {
            var redraw = false;
            var layerParams;
            var sld_body = '' +
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld">' +
                    '<NamedLayer>' +
                        '<Name>' +
                            'ALA:LAYERNAME' +
                        '</Name>' +
                        '<UserStyle>' +
                            '<FeatureTypeStyle>' +
                                '<Rule>' +
                                    '<Title>' +
                                        'Polygon' +
                                    '</Title>' +
                                    '<PolygonSymbolizer>' +
                                        '<Fill>' +
                                            '<CssParameter name="fill">' +
                                                'COLOUR' +
                                            '</CssParameter>' +
                                        '</Fill>' +
                                        '<Stroke>' +
                                            '<CssParameter name="stroke">'+
                                                '#000000' +
                                            '</CssParameter>' +
                                            '<CssParameter name="stroke-width">' +
                                                '1' +
                                            '</CssParameter>' +
                                        '</Stroke>' +
                                    '</PolygonSymbolizer>' +
                                '</Rule>' +
                            '</FeatureTypeStyle>' +
                        '</UserStyle>' +
                    '</NamedLayer>' +
                    '</StyledLayerDescriptor>';

            colour = colour || '#FFFFFF';
            order = order === undefined ? 1 : order;

            var newOpacity = getLayerOpacity();

            if(this.other) {
                this.drawOtherLayers();
            } else {
                if(this.wms === undefined) {
                    redraw = true;
                } else {
                    redraw = (this.wms.opacity !== newOpacity);
                }

                if(redraw) {
                    var sld = sld_body.replace('LAYERNAME', this.layerName).replace('COLOUR', colour);
                    layerParams = [
                        'FORMAT=image/png8',
                        'LAYERS=ALA:' + this.layerName,
                        'STYLES=polygon',
                        'sld_body=' + encodeURIComponent(sld)
                    ];

                    this.wms = new WMSTileLayer(this.layerName, config.spatialCacheUrl, layerParams, map.wmsTileLoaded, newOpacity);
                }

                map.setLayerOverlay(this.wms, order);
            }
        },

        /* Draw the currently selected 'other' region as a layer */
        drawOtherLayers: function() {
            if(selectedRegion === null) {
                return;
            }
            var layerName = this.objects[selectedRegion.name].layerName;
            var layerParams = [
                'FORMAT=image/png8',
                'LAYERS=ALA:' + layerName,
                'STYLES=polygon'
            ];
            var wms = new WMSTileLayer(layerName, config.spatialCacheUrl, layerParams, map.wmsTileLoaded, getLayerOpacity());
            if($('#toggleLayer').is(':checked')) {
                map.setLayerOverlay(wms);
            }
        },
        /* Highlight the specified region name in the list of regions for this set
         * @param regionName the name to highlight */
        highlightInList: function(regionName) {
            // highlight the specified region
            var $selected = $('#' + this.name + ' li').filter(function(index) {
                return $(this).html() === regionName;
            });
            $selected.addClass('selected');
            // scroll to it
            /* $pane.animate({
                scrollTop: $selected.offset().top
            }, 2000);*/
        }
    };

    /* Create the regions sets to be displayed */
    var layers = {};

    // (name, layerName, fid, bieContext, order, displayName)
    function createRegionTypes() {
        if(REGIONS === undefined) {
            REGIONS = {};
        }

        for(var rtype in REGIONS.metadata) {
            if(REGIONS.metadata.hasOwnProperty(rtype)) {
                var md = REGIONS.metadata[rtype];
                layers[rtype] = new RegionSet(md.name, md.layerName, md.fid, md.bieContext, md.order, '');
            }
        }
    }

    /** * Region represents a single region *******************************************************************************\
     * May be an object in a field, eg an individual state, OR
     * a region in 'Other regions' which is really a layer/field with 1 or more sub-regions
     */
    function Region(name) {
        // the name of the region
        this.name = name;
        // the id - this may be a pid if it's an object in a field or a fid if it's an 'other' region
        this.id = null;
        // this represents the state of the selectedRegionType when the region is created
        this.other = selectedRegionType.other;
        // the selected 'sub-region' of an 'other' layer - will be null if no sub-region is selected
        this.subregion = null;
        // the pid of a selected 'sub-region'
        this.subregionPid = null;
    }

    Region.prototype = {
        /* Set this instance as the currently selected region */
        set: function() {
            clearSelectedRegion();
            selectedRegion = this;
            if(this.name.toLowerCase() !== 'n/a') {
                selectedRegionType.highlightInList(this.name);
            }
            this.setLinks();
            if(this.other) {
                this.id = layers[selectedRegionType.name].objects[this.name].fid;
                // other regions draw as a full layer
                layers[selectedRegionType.name].drawLayer();
            } else {
                this.id = selectedRegionType.getPid(this.name);
                if($('#toggleRegion').is(':checked')) {
                    this.displayRegion();
                }
                enableRegionsSlider();
            }
        },
        /* Deselect this instance and remove its screen artifacts */
        clear: function() {
            map.removeRegionOverlay();
            clearHighlights();
            disableRegionsSlider();
            selectedRegion = null;
            if(!this.other) {
                hideInfo();
            }
        },
        /* Set the selected sub-region for this region
         * @param region the name of the subregion
         * @param pid the pid of the subregion */
        // this has meaning when the region is a layer/field in the 'other' set and an object within that
        // layer has been selected.
        setSubregion: function(region, pid) {
            this.subregion = region;
            this.subregionPid = pid;
            this.displayRegion();
            this.setLinks(region);
            enableRegionsSlider();
        },
        /* Deselect the selected subregion for this region */
        clearSubregion: function() {
            map.removeRegionOverlay();
            disableRegionsSlider();
            $('#extra').html('');
            $('#extra').addClass('hidden');
        },
        /* Draw this region on the map */
        displayRegion: function() {
            var params = [
                    'FORMAT=image/png8',
                    'LAYERS=ALA:Objects',
                    'viewparams=s:' + (this.other ? this.subregionPid : this.id),
                    'STYLES=polygon'
                ],
                ov = new WMSTileLayer('regionLayer', config.spatialWmsUrl, params, map.wmsTileLoaded, getRegionOpacity());
            map.setRegionOverlay(ov);
        },
        /* Build the url to view the current region */
        urlToViewRegion: function() {
            return document.location.origin +
                   '/regions/' + encodeURI(selectedRegionType.name) +
                   '/' + encodeURIComponent(he.encode(encodeURIComponent(this.name))).replace('%3B', '%253B');
        },
        /* Write the region link and optional subregion name and zoom link at the top of the map.
         * @param subregion the name of the subregion */
        setLinks: function(subregion) {
            if(this.name.toLowerCase() !== 'n/a') {
                var regionName = this.name;
                var $showRegion = $('#show-region');

                $showRegion.attr('href', this.urlToViewRegion());
                $showRegion.attr('title', 'Go to ' + regionName);
                $showRegion.html(regionName);
                $showRegion.parent().removeClass('hidden');
                $('#zoomTo').parent().removeClass('hidden');

                if(this.other && subregion) {
                    var $subRegion = $('#extra');
                    $subRegion.html('(' + subregion + ')');
                    $subRegion.parent().removeClass('hidden');
                }

                $('#zoomTo').off('click'); // Unbind previos click event. Otherwise you're going to have a bad time
                $('#zoomTo').on('click', function() {
                    map.zoomToRegion(regionName);
                });
            }
        }
    };

    /** * map represents the map and its associated properties and events ************************************************/
    map = {
        // the google map object
        gmap: null,
        // the DOM contain to draw the map in
        containerId: 'some_default',
        // default opacity for the overlay showing the selected region
        defaultRegionOpacity: 0.8,
        // default opacity for the overlay showing the selected layer
        defaultLayerOpacity: 0.55,
        // the default bounds for the map
        initialBounds: new google.maps.LatLngBounds(
            new google.maps.LatLng(-41.5, 114),
            new google.maps.LatLng(-13.5, 154)),
        clickedRegion: '',
        init: function() {
            var options = {
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
                disableDoubleClickZoom: true,
                draggableCursor: 'pointer',
                mapTypeId: google.maps.MapTypeId.TERRAIN
            };

            this.gmap = new google.maps.Map(document.getElementById(this.containerId), options);
            this.gmap.fitBounds(this.initialBounds);
            this.gmap.enableKeyDragZoom();
            if(config.showQueryContextLayer) {
                var queryContextRegionSet = new RegionSet(config.queryContextLayer.name, config.queryContextLayer.shortName, config.queryContextLayer.fid, config.queryContextLayer.bieContext, config.queryContextLayer.order, config.queryContextLayer.displayName);
                queryContextRegionSet.drawLayer(config.queryContextLayerColour, config.queryContextLayerOrder);
            }

            google.maps.event.addListener(this.gmap, 'click', this.clickHandler);
        },
        /* Set the layer overlay */
        setLayerOverlay: function(wms, order) {
            order = order === undefined ? 1 : order;
            this.gmap.overlayMapTypes.setAt(order, wms);
        },
        /* Clear the layer overlay */
        removeLayerOverlay: function() {
            // this.gmap.overlayMapTypes.setAt(0, null);
            this.gmap.overlayMapTypes.clear();
        },
        /* Set the region overlay */
        setRegionOverlay: function(wms) {
            this.gmap.overlayMapTypes.setAt(2, wms);
            this.clickedRegion = null;
        },
        /* Clear the region overlay */
        removeRegionOverlay: function() {
            this.gmap.overlayMapTypes.setAt(2, null);
        },
        /* Reset the map to the default bounds */
        resetViewport: function() {
            this.gmap.fitBounds(this.initialBounds);
        },
        /* Zoom to the bbox of the specified region */
        zoomToRegion: function(regionName) {
            // lookup the bbox from the regions cache
            var bbox = selectedRegionType.getRegion(regionName).bbox;
            if(bbox !== undefined) {
                this.gmap.fitBounds(new google.maps.LatLngBounds(
                    new google.maps.LatLng(bbox.minLat, bbox.minLng),
                    new google.maps.LatLng(bbox.maxLat, bbox.maxLng)));
            }
        },
        /* Handle user clicks on the map */
        clickHandler: function(event) {
            var location = event.latLng;
            var fid = selectedRegionType.getFid();
            var that = this;

            this.clickedRegion = null;
            var geoQuery = 'intersect/pointradius/' + fid + '/' + location.lat() + '/' + location.lng() + '/0.01/';
            $.ajax({
                url: config.spatialProxy,
                dataType: 'json',
                data: {
                    url: geoQuery,
                },
                success: function(data) {
                    if(data.length === 0) {
                        if(selectedRegion && selectedRegion.other) {
                            selectedRegion.clearSubregion();
                        } else {
                            clearSelectedRegion();
                        }
                    } else {
                        var subRegion = data[0];

                        if(selectedRegion && selectedRegion.other) {
                            selectedRegion.setSubregion(subRegion.name, subRegion.pid);
                        } else {
                            that.clickedRegion = subRegion.name;
                            var name = subRegion.name;
                            if(selectedRegion !== null && name === selectedRegion.name && name.toLowerCase() !== 'n/a') {
                                document.location.href = selectedRegion.urlToViewRegion();
                            }

                            new Region(name).set();
                        }
                    }
                }
            });
        },
        /**
         * Called when the overlays are loaded. Currently does nothing.
         * @param numtiles
         */
        wmsTileLoaded: function() {
            // $('#maploading').fadeOut("slow");
        }

    };

    /**
     * A callback function to set the initial region once the data and lists are loaded.
     */
    function setDefaultRegion() {
        if(Region.initialRegion) {
            new Region(Region.initialRegion).set();
        }
    }

    /**
     * Get region layer by region layer name in the URL anchor.
     */
    function getRegionType(layers, layerName, defaultLayerName) {
        var regionTypes = Object.keys(layers).map(function(key) {
            return layers[key];
        });

        var foundLayer = regionTypes.find(function(layer) {
            return layer.layerName === layerName;
        });

        var defaultLayer = regionTypes.find(function(layer) {
            return layer.layerName === defaultLayerName;
        });

        return foundLayer || defaultLayer || regionTypes[0];
    }

    /**
     * Initialises everything including the map.
     *
     * @param options object specifier with the following members:
     * - server: url of the server the app is running on
     * - spatialWms:
     * - spatialCache:
     * - mapContainer: id of the html element to hold the map
     * - defaultRegionType: string containing the name of the top level menu item to select by default
     * - defaultRegion: string containing the name of the region within the defaultRegionType menu to select by default
     */
    function init(options) {
        config.proxyUrl = options.proxyUrl;
        config.spatialProxy = options.spatialProxy;
        config.baseUrl = options.server;
        config.spatialWmsUrl = options.spatialWms;
        config.spatialCacheUrl = options.spatialCache;
        config.showQueryContextLayer = options.showQueryContextLayer;
        config.queryContextLayer = options.queryContextLayer;
        config.queryContextLayerColour = options.queryContextLayerColour || '#8b0000';
        config.queryContextLayerOrder = options.queryContextLayerOrder || 0;

        /** ***************************************\
        | Create the region types from metadata
        \*****************************************/
        if(options.mapBounds && options.mapBounds.length === 4) {
            mapBounds = options.mapBounds;
        }
        createRegionTypes();

        /** ***************************************\
        | Set state from hash params or defaults
        \*****************************************/
        selectedRegionType = getRegionType(layers, document.location.hash.replace('#', ''), options.defaultRegionType);
        Region.initialRegion = options.defaultRegion;

        /** ***************************************\
        | Set up accordion and handle changes
        \*****************************************/
        $('#accordion').accordion({
            activate: function(event, ui) {
                layers[$(ui.newPanel).attr('data-layer')].set();
            },

            active: selectedRegionType.order
        });

        if(options.accordionPanelMaxHeight) {
            $('#accordion .ui-accordion-content').css('max-height', options.accordionPanelMaxHeight);
        }

        /** ***************************************\
         | Set up opacity sliders
         \*****************************************/
        $('#layerOpacity').slider({
            min: 0,
            max: 100,
            value: map.defaultLayerOpacity * 100,
            change: function() {
                if ($('#toggleLayer').is(':checked')) {
                    selectedRegionType.drawLayer();
                }
            }
        });
        $('#regionOpacity').slider({
            min: 0,
            max: 100,
            disabled: true,
            value: map.defaultRegionOpacity * 100,
            change: function() {
                if ($('#toggleRegion').is(':checked')) {
                    selectedRegion.displayRegion();
                }
            }
        });
        /** ***************************************\
        | Handle layer toggles
        \*****************************************/
        $('#toggleLayer').change(function() {
            if($(this).is(':checked')) {
                selectedRegionType.drawLayer();
            } else {
                map.removeLayerOverlay();
            }
        });
        $('#toggleRegion').change(function() {
            if($(this).is(':checked')) {
                selectedRegion.displayRegion();
            } else {
                map.removeRegionOverlay();
            }
        });

        /** ***************************************\
        | Create map
        \*****************************************/
        map.containerId = options.mapContainer;
        if(options.mapHeight) {
            $('#' + map.containerId).height(options.mapHeight);
        }
        if(options.mapBounds && options.mapBounds.length === 4) {
            map.initialBounds = new google.maps.LatLngBounds(
                new google.maps.LatLng(options.mapBounds[0], options.mapBounds[1]),
                new google.maps.LatLng(options.mapBounds[2], options.mapBounds[3]));
        }
        map.init();

        /** ***************************************\
        | Handle map reset
        \*****************************************/
        $('#reset-map').click(function() {
            map.resetViewport();
        });

        /** ***************************************\
        | Set the region type
        \*****************************************/
        // also sets the region from the hash params once the region type data has been retrieved
        selectedRegionType.set(setDefaultRegion);
    }

    windows.init_regions = init;
})(this);
