package au.org.ala.regions

import au.org.ala.regions.binding.DownloadParams
import au.org.ala.web.AuthService
import grails.converters.JSON
import grails.util.Holders
import grails.util.Metadata
import groovy.json.JsonSlurper
import groovyx.net.http.RESTClient
import groovyx.net.http.URIBuilder
import org.apache.commons.lang.StringEscapeUtils

import javax.annotation.PostConstruct

class MetadataService {

    static transactional = true

    /**
     * Cache for metadata about "objects" in "fields" (eg individual states within the "states" field).
     * This is populated by spatial services calls.
     */
    static regionCache = [:]
    static regionCacheLastRefreshed = [:]

    /**
     * Cache for metadata about region types (eg fid, layer name).
     * This is populated from external "static" config.
     */
    static regionsMetadataCache = null

    static defaultLoggerReasons = [
        0: "conservation management/planning",
        1: "biosecurity management",
        2: "environmental impact, site assessment",
        3: "education",
        4: "scientific research",
        5: "collection management",
        6: "other",
        7: "ecological research",
        8: "systematic research",
        9: "other scientific research",
        10: "testing"
    ]

    static logReasonCache = defaultLoggerReasons

    /* cache management */
    def clearCaches = {
        regionsMetadataCache = null
        regionCache = [:]

        logReasonCache = loadLoggerReasons()
        layersServiceFields = [:]
        layersServiceLayers = [:]
        menu = null
    }

    def grailsApplication

    def layersServiceLayers = [:]
    def layersServiceFields = [:]

    AuthService authService

    static final Map DOWNLOAD_OPTIONS = [
        0: "Download All Records",
        1: "Download Species Checklist"
    ]

    final static String WS_DATE_FROM_PREFIX = "-01-01T00:00:00Z"
    final static String WS_DATE_TO_PREFIX = "-12-31T23:59:59Z"
    final static String WS_DATE_FROM_DEFAULT = "1850"
    final static String PAGE_SIZE = "50"
    final static Map userAgent = ["User-Agent": "metadataService/2.5 (Regions:metadataService)"]

    String BIOCACHE_SERVICE_BACKEND_URL, LAYERS_SERVICE_BACKEND_URL
    String BIE_URL, BIE_SERVICE_URL, BIOCACHE_URL, BIOCACHE_SERVICE_URL, ALERTS_URL, DEFAULT_IMG_URL, QUERY_CONTEXT,
           HUB_FILTER, INTERSECT_OBJECT
    Boolean ENABLE_HUB_DATA, ENABLE_QUERY_CONTEXT, ENABLE_OBJECT_INTERSECTION
    String CONFIG_DIR

    @PostConstruct
    def init() {
        BIOCACHE_SERVICE_BACKEND_URL = grailsApplication.config.biocacheService.internal.url
        LAYERS_SERVICE_BACKEND_URL = grailsApplication.config.layersService.internal.url

        BIE_URL = grailsApplication.config.bie.ui.url
        BIE_SERVICE_URL = grailsApplication.config.bieService.ui.url
        BIOCACHE_URL = grailsApplication.config.occurrences.ui.url
        BIOCACHE_SERVICE_URL = grailsApplication.config.biocacheService.baseURL
        DEFAULT_IMG_URL = "${BIE_URL}/static/images/noImage85.jpg"
        ALERTS_URL = grailsApplication.config.alerts.baseURL
        CONFIG_DIR = grailsApplication.config.config_dir
        ENABLE_HUB_DATA = grailsApplication.config.hub.enableHubData?.toBoolean() ?: false
        HUB_FILTER = grailsApplication.config.hub.hubFilter
        ENABLE_QUERY_CONTEXT = grailsApplication.config.biocache.enableQueryContext?.toBoolean() ?: false
        QUERY_CONTEXT = grailsApplication.config.biocache.queryContext
        ENABLE_OBJECT_INTERSECTION = grailsApplication.config.layers.enableObjectIntersection?.toBoolean() ?: false
        INTERSECT_OBJECT = grailsApplication.config.layers.intersectObject
    }

    /**
     *
     * @param regionName
     * @return List<Map< with format: [[imgUrl: ...,<br/>
     * scientificName: ...,<br/>
     * commonName: ..., <br/>
     * speciesUrl: ..., <br/>
     * emblemType: ...], ...]
     */
    List<Map> getEmblemsMetadata(String regionName) {
        Map emblemGuids = [:]

        // lookup state emblems
        def emblems = getStateEmblems()[regionName]
        if (emblems) {
            ["animal", "plant", "marine", "bird"].each {
                if (emblems[it]) {
                    emblemGuids[it] = emblems."${it}".guid
                }
            }
        }

        List<Map> emblemMetadata = []

        emblemGuids.sort({it.key}).each {key, guid ->
            String emblemInfoUrl = "${BIE_SERVICE_URL}/species/moreInfo/${guid}.json"
            def emblemInfo = new RESTClient(emblemInfoUrl).get([headers: userAgent]).data
            emblemMetadata << [
                "imgUrl":  emblemInfo?.images && emblemInfo?.images[0]?.thumbnail ? emblemInfo?.images[0]?.thumbnail : DEFAULT_IMG_URL,
                "scientificName": emblemInfo?.taxonConcept?.nameString,
                "commonName": emblemInfo?.commonNames && emblemInfo?.commonNames?.size() > 0 ? emblemInfo?.commonNames[0]?.nameString : "",
                "speciesUrl": "${BIE_URL}/species/${guid}",
                "emblemType": "${key.capitalize()} emblem"
            ]
        }

        return emblemMetadata
    }

    /**
     *
     * @param regionFid
     * @param regionType
     * @param regionName
     * @return
     */
    List getGroups(String regionFid, String regionType, String regionName, String regionPid, Boolean showHubData = false) {
        def responseGroups = new RESTClient("${BIOCACHE_SERVICE_BACKEND_URL}/explore/hierarchy").get([headers: userAgent]).data
        Map subgroupsWithRecords = getSubgroupsWithRecords(regionFid, regionType, regionName, regionPid, showHubData)

        List groups = [] << [name: "ALL_SPECIES", commonName: "ALL_SPECIES"]
        responseGroups.each {group ->
            groups << [name: group.speciesGroup, commonName: group.common ?: group.speciesGroup, taxonRank: group.taxonRank]
            group.taxa.each {subgroup ->
                groups << [name: subgroup.name, commonName: subgroup.common, parent: group.speciesGroup,
                    taxonRank: subgroup.taxonRank ?: ""]
            }
        }
        return groups
    }

    /**
     *
     * @param regionFid
     * @param regionType
     * @param regionName
     * @return
     */
    Map getSubgroupsWithRecords(String regionFid, String regionType, String regionName, String regionPid, Boolean showHubData = false) {

        String url = new URIBuilder("${BIOCACHE_SERVICE_BACKEND_URL}/occurrences/search").with {
            Map params = [
                    q: buildRegionFacet(regionFid, regionType, regionName, regionPid),
                    facets: "species_subgroup",
                    flimit: "-1",
                    pageSize: 0
            ]

            if(ENABLE_QUERY_CONTEXT) {
                params << [qc: QUERY_CONTEXT]
            }

            if(showHubData && ENABLE_HUB_DATA) {
                params << [fq: HUB_FILTER]
            }

            query = params
            return it
        }.toString()

        def response = new RESTClient(url).get([headers: userAgent]).data

        Map subgroups = [:]
        if (response?.facetResults != null) {
            response.facetResults[0]?.fieldResult.each {subgroup ->
                subgroups << [(subgroup.label): subgroup.count]
            }
        }

        return subgroups
    }

    /**
     *
     * @param regionFid
     * @param regionType
     * @param regionName
     * @param groupName
     * @param isSubgroup
     * @param from
     * @param to
     * @return
     */
    def getSpecies(
            String regionFid, String regionType, String regionName, String regionPid, String groupName,
            Boolean isSubgroup = false, Boolean showHubData, String from = null, String to = null,
            String pageIndex = "0", String groupRank = "") {

        def searchUrl = buildBiocacheSearchOccurrencesWsUrl(
                regionFid, regionType, regionName, regionPid, groupName == "ALL_SPECIES" ? null : groupName, isSubgroup,
                from, to, pageIndex, showHubData, groupRank)

        def response = new RESTClient(searchUrl).get([headers: userAgent]).data

        return [
                totalRecords: response.totalRecords,
                records: response?.facetResults[0]?.fieldResult.findAll{ it.label.split("\\|").size() >= 2 }.collect {result ->
                    List info = Arrays.asList(result.label.split("\\|"))
                    return [
                            name: info.get(0),
                            guid: info.get(1),
                            commonName: info.size() == 5 ? info.get(2) : "",
                            count: result.count
                    ]
                }
        ]
    }

    /**
     *
     * @param region
     * @return
     */
    String buildAlertsUrl(Map region) {
        URLDecoder.decode(new URIBuilder("${ALERTS_URL}/webservice/createBiocacheNewRecordsAlert").with {
            Map params = [
                    webserviceQuery: "/occurrences/search?q=${buildRegionFacet(region.fid, region.type, region.name, region.pid)}",
                    uiQuery: "/occurrences/search?q=${buildRegionFacet(region.fid, region.type, region.name, region.pid)}",
                    queryDisplayName: region.name,
                    baseUrlForWS: "${BIOCACHE_SERVICE_URL}",
                    baseUrlForUI: "${BIOCACHE_URL}&resourceName=Atlas"
            ]

            if(ENABLE_QUERY_CONTEXT) {
                params.webserviceQuery += "&qc=" + QUERY_CONTEXT
                params.uiQuery += "&qc=" + QUERY_CONTEXT
            }

            if(ENABLE_HUB_DATA) {
                params.webserviceQuery += "&fq=" + HUB_FILTER
                params.uiQuery += "&fq=" + HUB_FILTER
            }

            query = params
            return it
        }.toString(), "UTF-8")
    }

    /**
     *
     * @param guid
     * @param regionFid
     * @param regionType
     * @param regionName
     * @param from
     * @param to
     * @return
     */
    String buildSpeciesRecordListUrl(String guid, String regionFid, String regionType, String regionName, String regionPid, String from, String to, Boolean showHubData) {
        StringBuilder sb = new StringBuilder("${BIOCACHE_URL}/occurrences/search?q=lsid:\"${guid}\"" +
                "&fq=${buildRegionFacet(regionFid, regionType, regionName, regionPid)}")
        if (isValidTimeRange(from, to)) {
            " AND ${buildTimeFacet(from, to)}"
        }

        if(ENABLE_QUERY_CONTEXT) {
            // when using qc, biocache search fails. AtlasOfLivingAustralia/biocache-hubs#176
            sb.append("&fq=${URLEncoder.encode(QUERY_CONTEXT, 'UTF-8')}")
        }

        if(showHubData && ENABLE_HUB_DATA) {
            sb.append("&fq=${URLEncoder.encode(HUB_FILTER, 'UTF-8')}")
        }

        return sb.toString()
    }

    /**
     *
     * @param downloadParams
     * @return
     */
    String buildDownloadRecordsUrl(DownloadParams downloadParams, String regionFid, String regionType, String regionName, String regionPid, String groupName = null, Boolean isSubgroup = false, String from = null, String to = null) {
        String url
        Map params = buildCommonDownloadRecordsParams(regionFid, regionType, regionName, regionPid, groupName, isSubgroup, from, to)
        String wsUrl
        switch (downloadParams.downloadOption) {
            case "0":
                // Download All Records
                wsUrl = "${BIOCACHE_SERVICE_URL}/occurrences/index/download"
                params << [
                        email: downloadParams.email,
                        reasonTypeId: downloadParams.downloadReason,
                        file: downloadParams.fileName
                ]
                break
            case "1":
                // Download Species Checklist
                wsUrl = "${BIOCACHE_SERVICE_URL}/occurrences/facets/download"
                params << [
                        facets: "species_guid",
                        lookup: true,
                        file: downloadParams.fileName
                ]
                break

            case "2":
                // Download Species FieldGuide
                wsUrl = "${BIOCACHE_URL}/occurrences/fieldguide/download"
                params << [
                        facets: "species_guid"
                ]
                break
        }

        url = new URIBuilder(wsUrl).with {
            query = params
            return it
        }.toString()
        return url
    }

    /**
     *
     * @return
     */
    String buildDownloadRecordsUrlPrefix(int option, String regionFid, String regionType, String regionName, String regionPid, String groupName = null, Boolean isSubgroup = false, String from = null, String to = null, Boolean showHubData = false) {
        String url
        Map params = buildCommonDownloadRecordsParams(regionFid, regionType, regionName, regionPid, groupName, isSubgroup, from, to, showHubData)
        String wsUrl
        switch (option) {
            case "0":
                // Download All Records
                wsUrl = "${BIOCACHE_SERVICE_URL}/occurrences/index/download"
                break
            case "1":
                // Download Species Checklist
                wsUrl = "${BIOCACHE_SERVICE_URL}/occurrences/facets/download"
                params << [
                        facets: "species_guid",
                        lookup: true
                ]
                break

            case "2":
                // Download Species FieldGuide
                wsUrl = "${BIOCACHE_URL}/occurrences/fieldguide/download"
                params << [
                        facets: "species_guid"
                ]
                break
        }

        url = new URIBuilder(wsUrl).with {
            query = params
            return it
        }.toString()
        return url
    }

    /**
     *
     * @param regionFid
     * @param regionType
     * @param regionName
     * @param groupName
     * @param isSubgroup
     * @param from
     * @param to
     * @return
     */
    private Map buildCommonDownloadRecordsParams(String regionFid, String regionType, String regionName, String regionPid, String groupName = null, Boolean isSubgroup = false, String from = null, String to = null, Boolean showHubData = false) {
        Map params = [
                q : buildRegionFacet(regionFid, regionType, regionName, regionPid),
                fq: "rank:(species OR subspecies)",
        ]

        if (groupName && isSubgroup) {
            params << [fq: params.fq + " AND " + "species_subgroup:\"${groupName}\""]
        } else if (groupName && groupName != "ALL_SPECIES") {
            params << [fq: params.fq + " AND " + "species_group:\"${groupName}\""]
        }

        if (isValidTimeRange(from, to)) {
            params << [fq: params.fq + " AND " + params.fq + " AND " + buildTimeFacet(from, to)]
        }

        if(ENABLE_QUERY_CONTEXT) {
            params << [qc: QUERY_CONTEXT]
        }

        if(showHubData && ENABLE_HUB_DATA) {
            params << [fq: params.fq + " AND " + HUB_FILTER]
        }

        return params
    }

    /**
     *
     * @param regionFid
     * @param regionType
     * @param regionName
     * @param groupName
     * @param isSubgroup
     * @param from
     * @param to
     * @param pageIndex
     * @return
     */
    String buildBiocacheSearchOccurrencesWsUrl(
            String regionFid, String regionType, String regionName, String regionPid,
            String groupName = null, Boolean isSubgroup = false, String from = null, String to = null,
            String pageIndex = "0", Boolean showHubData = false, String groupRank = "") {

        String url = new URIBuilder("${BIOCACHE_SERVICE_BACKEND_URL}/occurrences/search").with {
            query = buildSearchOccurrencesWsParams(regionFid, regionType, regionName, regionPid, groupName, isSubgroup,
                from, to, pageIndex, showHubData, groupRank)
            return it
        }.toString()
        return url
    }


    /**
     *
     * @param regionFid
     * @param regionType
     * @param regionName
     * @param groupName
     * @param isSubgroup
     * @param from
     * @param to
     * @param pageIndex
     * @return
     */
    private Map buildSearchOccurrencesWsParams(
            String regionFid, String regionType, String regionName, String regionPid, String groupName = null,
            Boolean isSubgroup = false, String from = null, String to = null, String pageIndex = "0",
            Boolean showHubData = false, String groupRank = "") {

        Map params =  [
                q : buildRegionFacet(regionFid, regionType, regionName, regionPid),
                facets: "names_and_lsid",
                fsort: "taxon_name",
                pageSize : 0,
                flimit: PAGE_SIZE,
                foffset: Integer.parseInt(pageIndex) * Integer.parseInt(PAGE_SIZE),
                fq: "rank:(species OR subspecies)"
        ]

        if (groupName && isSubgroup) {
            params << [fq: "${params.fq} AND species_subgroup:\"${groupName}\""]
        } else if (groupName) {
            params << [fq: "${params.fq} AND ${groupRank}:\"${groupName}\""]
        }

        if (isValidTimeRange(from, to)) {
            params << [fq: params.fq + " AND " + buildTimeFacet(from, to)]
        }

        if(ENABLE_QUERY_CONTEXT) {
            params << [qc: QUERY_CONTEXT]
        }

        if(showHubData && ENABLE_HUB_DATA) {
            params << [fq: params.fq + " AND " + HUB_FILTER]
        }

        return params
    }

    private boolean isValidTimeRange(String from, String to) {
        return from && to && (from != WS_DATE_FROM_DEFAULT|| to != Calendar.getInstance().get(Calendar.YEAR).toString())
    }

    /**
     *
     * @param regionFid
     * @param regionType
     * @param regionName
     * @return
     */
    public String buildRegionFacet(String regionFid, String regionType, String regionName, String regionPid) {
        //unescape regionName for q term creation
        def name = StringEscapeUtils.unescapeHtml(regionName)

        regionPid == null || regionPid.isEmpty() ? "-${regionFid}:n/a AND ${regionFid}:*" : "${regionFid}:\"${name}\""
    }

    /**
     *
     * @param from
     * @param to
     * @return
     */
    public String buildTimeFacet(String from, String to) {
        from = from.equals(WS_DATE_FROM_DEFAULT) ? "*" : from + WS_DATE_FROM_PREFIX
        to = to.equals(Calendar.getInstance().get(Calendar.YEAR).toString()) ? "*" : to + WS_DATE_TO_PREFIX
        "occurrence_year:[${from} TO ${to}]"
    }

    static def loadLoggerReasons() {
        String url = "${Holders.config.loggerService.internal.url}/service/logger/reasons"
        def conn = new URL(url).openConnection()
        def map = [:]

        try {
            conn.setConnectTimeout(5000)
            conn.setReadTimeout(5000)
            def json = conn.content.text
            def result = JSON.parse(json)
            result.each{
                map[it.id] = it.name
            }
        } catch (Exception e) {
            //load the default
            return defaultLoggerReasons
        }
        return map
    }

    /**
     * Get some metadata for a region (top level menu).
     *
     * If name is defined then just return metadata for that named region
     * else for all regions of the specified type.
     *
     * @param type type of region
     * @param name optional name of the region (the "object")
     * @return name, area, pid and bbox as a map for the named region or a map of all objects if no name supplied
     */
    def regionMetadata(type, name) {
        def fid = fidFor(type)
        def regionMd = getRegionMetadata(fid)
        if (name) {
            // if a specific region is named, then return that
            return regionMd[name]
        }
        else if (regionMd.values().size == 1) {
            // if there is only one object in the field, return it
            return regionMd.values().iterator().next()
        }
        else {
            // return all objects in the field
            return regionMd
        }
    }

    /**
     * Return metadata for the specified field.
     * Use cached metadata if available and fresh.
     *
     * @param fid
     * @return
     */
    def getRegionMetadata(fid) {
        if (!regionCache[fid] || new Date().after(regionCacheLastRefreshed[fid] + 2)) {
            regionCache[fid] = new TreeMap() // clear any stale content
            regionCacheLastRefreshed[fid] = new Date()
            if(ENABLE_OBJECT_INTERSECTION){
                def url = "${LAYERS_SERVICE_BACKEND_URL}/intersect/object/${fid}/${INTERSECT_OBJECT}"
                def conn = new URL(url).openConnection()
                try {
                    conn.setConnectTimeout(10000)
                    conn.setReadTimeout(50000)
                    def json = conn.content.text
                    def result = JSON.parse(json)
                    result.each {
                        regionCache[fid].put it.name,
                                [name: it.name, pid: it.pid, bbox: parseBbox(it.bbox), area_km: it.area_km]
                    }
                } catch (SocketTimeoutException e) {
                    def message = "Timed out looking up pid. URL= ${url}."
                    log.warn message
                    return [error: true, errorMessage: message]
                } catch (Exception e) {
                    def message = "Failed to lookup pid. ${e.getClass()} ${e.getMessage()} URL= ${url}."
                    log.warn message
                    return [error: true, errorMessage: message]
                }
            } else {
                def url = "${LAYERS_SERVICE_BACKEND_URL}/field/${fid}"
                def conn = new URL(url).openConnection()
                try {
                    conn.setConnectTimeout(10000)
                    conn.setReadTimeout(50000)
                    def json = conn.content.text
                    def result = JSON.parse(json)
                    result.objects.each {
                        regionCache[fid].put it.name,
                                [name: it.name, pid: it.pid, bbox: parseBbox(it.bbox), area_km: it.area_km]
                    }
                } catch (SocketTimeoutException e) {
                    def message = "Timed out looking up pid. URL= ${url}."
                    log.warn message
                    return [error: true, errorMessage: message]
                } catch (Exception e) {
                    def message = "Failed to lookup pid. ${e.getClass()} ${e.getMessage()} URL= ${url}."
                    log.warn message
                    return [error: true, errorMessage: message]
                }
            }
        }
        return regionCache[fid]
    }

    /**
     * Get the fid (field id) of the layer that represents the specified region type.
     * @param regionType
     * @return
     */
    def fidFor(regionType) {
        return getRegionsMetadata()[regionType]?.fid
    }

    /**
     * Get the bounding box for the specified region if known
     * else a sensible default.
     *
     * @param regionType
     * @param regionName
     * @return
     */
    Map lookupBoundingBox(regionType, regionName) {
        def bbox = regionMetadata(regionType, regionName)?.bbox
        return bbox ?: [minLat: 57.8, minLng: 21.795833, maxLat: 59.5, maxLng: 28.883333]
    }

    /**
     * Returns list of types of regions.
     * @return
     */
    def getRegionTypes() {
        return getRegionsMetadata().collect {k,v -> v.name}
    }

    /**
     * Return metadata for region types.
     *
     * Uses cache if available
     * else external config
     * else the default set.
     * @return
     */
    def getRegionsMetadata() {
        // use cache if loaded
        if (regionsMetadataCache != null) {
            return regionsMetadataCache
        }

        //update
        def md = [:]
        int i = 0
        getMenu().each{ v ->
            md.put(v.label, [
                    name: v.label,
                    layerName: v.layerName,
                    fid: v.fid,
                    bieContext: "not in use",
                    order: i
            ])

            i++
        }
        regionsMetadataCache = md
        return regionsMetadataCache
    }

    def getObjectByPid(pid){
        def url = "${LAYERS_SERVICE_BACKEND_URL}/object/${pid}"
        def js = new JsonSlurper()
        js.parseText(new URL(url).text)
    }

    def getLayersServiceLayers() {
        if (layersServiceLayers.size() > 0) {
            return layersServiceLayers
        }

        def results = [:]
        def url = "${LAYERS_SERVICE_BACKEND_URL}/layers"
        def conn = new URL(url).openConnection()
        try {
            conn.setConnectTimeout(10000)
            conn.setReadTimeout(50000)
            def json = conn.content.text
            def result = JSON.parse(json)
            def map = [:]
            result.each { v ->
                map.put String.valueOf(v.id), v
            }
            layersServiceLayers = map
        } catch (SocketTimeoutException e) {
            log.warn "Timed out looking up fid. URL= ${url}."
        } catch (Exception e) {
            log.warn "Failed to lookup fid. ${e.getClass()} ${e.getMessage()} URL= ${url}."
        }

        return layersServiceLayers
    }


    def getLayersServiceFields() {
        if (layersServiceFields.size() > 0) {
            return layersServiceFields
        }

        def results = [:]
        def url = "${LAYERS_SERVICE_BACKEND_URL}/fields"
        def conn = new URL(url).openConnection()
        try {
            conn.setConnectTimeout(10000)
            conn.setReadTimeout(50000)
            def json = conn.content.text
            def result = JSON.parse(json)
            def map = [:]
            result.each { v ->
                map.put v.id, v
            }
            layersServiceFields = map
        } catch (SocketTimeoutException e) {
            log.warn "Timed out looking up fid. URL= ${url}."
        } catch (Exception e) {
            log.warn "Failed to lookup fid. ${e.getClass()} ${e.getMessage()} URL= ${url}."
        }

        return layersServiceFields
    }

    /**
     * Returns the metadata for region types as json.
     * @return
     */
    def getRegionsMetadataAsJson() {
        return getRegionsMetadata() as JSON
    }

    /**
     * Returns the metadata for regions as a javascript object literal.
     * @return
     */
    def getRegionsMetadataAsJavascript() {
        return "var REGIONS = {metadata: " + getRegionsMetadataAsJson() + "}"
    }

    def getStateEmblems() {
        if(new File(CONFIG_DIR + "/state-emblems.json").exists()){
            JSON.parse(new FileInputStream(CONFIG_DIR + "/state-emblems.json"), "UTF-8")
        } else {
            []
        }
    }

    /**
     * Get a list of the objects in a layer and the available metadata.
     *
     * @param fid id of the "field" (type of region)
     * @return name, area, pid and bbox as a map for all objects
     */
   def getObjectsForALayer(fid) {
        def results = [:]
        def url = "${LAYERS_SERVICE_BACKEND_URL}/field/${fid}"
        def conn = new URL(url).openConnection()
        try {
            conn.setConnectTimeout(10000)
            conn.setReadTimeout(50000)
            def json = conn.content.text
            def result = JSON.parse(json)
            result.objects.each {
                results.put it.name,
                        [name: it.name, pid: it.pid, bbox: parseBbox(it.bbox), area_km: it.area_km]
            }
        } catch (SocketTimeoutException e) {
            log.warn "Timed out looking up fid. URL= ${url}."
        } catch (Exception e) {
            log.warn "Failed to lookup fid. ${e.getClass()} ${e.getMessage()} URL= ${url}."
        }
        return results
    }

    /**
     * Converts a bounding box from a polygon format to min/max*lat/lng format.
     *
     * @param bbox as polygon eg bbox: POLYGON((158.684997558594 -55.116943359375,158.684997558594 -54.4854164123535,
     * 158.950012207031 -54.4854164123535,158.950012207031 -55.116943359375,158.684997558594 -55.116943359375))
     * @return
     */
    def parseBbox(String bbox) {
        if (!bbox) {
            return [:]
        } else if (bbox.startsWith("POINT")) {
            def coords = bbox[6..-2]
            def (lng, lat) = coords.tokenize(" ")
            return [minLat: lat, minLng: lng, maxLat: lat, maxLng: lng]
        } else {
            def coords = bbox[9..-3]
            def corners = coords.tokenize(",")
            def sw = corners[0].tokenize(" ")
            def ne = corners[2].tokenize(" ")
            return [minLat: sw[1], minLng: sw[0], maxLat: ne[1], maxLng: ne[0]]
        }
    }

    /**
     * Returns the PID for a named region.
     * @param regionType
     * @param regionName
     * @return
     */
    def lookupPid(regionType, regionName) {
        if (regionType == "layer") {
            return ""
        }
        return regionMetadata(regionType, regionName)?.pid
    }

    def getLayerNameForFid(String fid) {
        def layerName = null
        def layer = getLayerForFid(fid)
        if (layer != null) {
            layerName = layer.name
        }
        layerName
    }

    def getLayerForFid(String fid) {
        def layer = null
        def lsf = getLayersServiceFields().get(fid)
        if (lsf != null) {
            layer = getLayersServiceLayers().get(lsf.spid)
        }
        layer
    }

    def menu
    def getMenu() {
        if (menu == null) {
            // use external file if available
            def md = new File(CONFIG_DIR + "/menu-config.json")?.text
            if (!md) {
                //use default resource
                md = new File(this.class.classLoader.getResource("default/menu-config.json").toURI())?.text
            }
            if (md) {
                menu = JSON.parse(md)

                menu.each { v ->
                    def layerName = getLayerNameForFid(v.fid)

                    if (layerName == null) {
                        log.warn "Failed to find layer name for fid= ${v.fid}"
                        layerName = v.label.replace(" ", "")
                    }

                    v.layerName = layerName
                }
            }
        }

        menu
    }

    def getMenuItems(type) {
        def map = [:]

        //init
        getMenu()

        menu.each { v ->
            if (v.label.equals(type)) {
                if (v.fid) {
                    def objects = getRegionMetadata(v.fid)
                    if (v.exclude) {
                        objects.each{ k, o ->
                            if (!v.exclude.contains(k)) {
                                map.put(k, o)
                            }
                        }
                    } else {
                        map = objects
                    }
                } else if (v.submenu) {
                    v.submenu.each { v2 ->
                        if (v2.fid) {
                            def layer = getLayerForFid(v2.fid)

                            if (layer == null) {
                                def message = "Failed to find layer for fid=" + v2.fid
                                log.warn message
                            } else {
                                map.put(v2.label, [
                                        name : v2.label, layerName: layer.name, id: layer.id, fid: v2.fid,
                                        bbox : parseBbox(layer.bbox),
                                        source: null,
                                        notes: "todo: notes"
                                ])
                            }
                        }
                    }
                }
            }
        }

        map
    }
}
