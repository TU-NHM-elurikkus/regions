<g:if test="${!pageIndex || pageIndex == 0}">
    <tbody id="speciesZone">
</g:if>

<g:if test="${species.totalRecords == 0}">
    <tr>
        <td colspan="3">
            <g:message code="species.results.noRecords" />
        </td>
    </tr>
</g:if>

<g:each in="${species.records}" var="singleSpecies" status="i">
    <tr class="link" id="${singleSpecies.guid}">
        <td>
            ${(pageIndex * 50) + i + 1}.
        </td>
        <td>
            ${singleSpecies.name}${singleSpecies.commonName ? " : ${singleSpecies.commonName}" : ""}
        </td>
        <td class="text-right">
            ${g.formatNumber(number: singleSpecies.count, type: 'number')}
        </td>
    </tr>
    <tr class="infoRowLinks" style="display: none;">
        <td>
            &nbsp;
        </td>
        <td colspan="2">
            <a
                href="${speciesPageUrl}/${singleSpecies.guid}"
                title="${message(code: 'species.results.speciesProfile.title')}"
                class="species-list-button"
            >
                <i class="fa fa-tag"></i>
                <g:message code="species.results.speciesProfile" />
            </a>

            &nbsp; | &nbsp;

            <a href="${rg.speciesRecordListUrl([guid: singleSpecies.guid, regionFid: regionFid, regionName: regionName, regionType: regionType, regionPid: regionPid, from: from, to: to, showHubData: showHubData])}"
               title="${message(code: 'species.results.recordList.title')}"
               class="species-list-button"
            >
                <i class="fa fa-list"></i>
                <g:message code="species.results.recordList" />
            </a>
        </td>
    </tr>
</g:each>

<tr id="moreSpeciesZone" totalRecords="${species.totalRecords}" style="${species.records.size() > 0 && species.records.size() % 50 == 0 ? "" : "display:none;"}">
    <td colspan="2">
        <a aa-refresh-zones="moreSpeciesZone" id="showMoreSpeciesButton"
           href="${g.createLink(controller: 'region', action: 'showSpecies', params: [pageIndex: pageIndex ? pageIndex + 1 : '1'])}"
           aa-js-before="regionWidget.showMoreSpecies();"
           aa-js-after="regionWidget.speciesLoaded();"
           aa-queue="abort"
        >
            <g:message code="species.results.showMore" />&hellip;
        </a>
    </td>
    <td></td>
</tr>

<g:if test="${!pageIndex || pageIndex == 0}">
    </tbody>
</g:if>
