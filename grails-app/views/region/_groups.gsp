<%@ page import="org.springframework.context.i18n.LocaleContextHolder" %>

<g:set var="locale" value="${LocaleContextHolder.getLocale().toString()}" />

<tbody id="groupsZone" aa-queue="abort">
    <g:each in="${groups}" var="group">
        <tr
            id="${group.parent ? '' : 'main-'}${group.name}-row"
            class="group-row link"
            href="${g.createLink(controller: 'region', action: 'showSpecies')}"
            ${group.parent ? "parent=main-${group.parent.replaceAll(/[^A-Za-z\\d_]/, "")}-row style=display:none;" : ""}
            aa-refresh-zones="speciesZone"
            aa-js-before="regionWidget.selectGroupHandler('${group.name.encodeAsJs()}', ${group.parent ? true : false}, '${group.taxonRank}');"
            aa-js-after="regionWidget.speciesLoaded();"
            aa-queue="abort"
        >
            <td class="level${group.parent ? '1' : '0'}">
                <g:if test="${!group.parent}">
                    <span class="fa fa-chevron-right"></span>
                </g:if>

                <g:if test="${group.name == 'ALL_SPECIES'}">
                    <g:message code="groups.dynamic.group.ALL_SPECIES" />
                </g:if>
                <g:elseif test="${locale == 'et'}">
                    ${group.commonName}
                </g:elseif>
                <g:else>
                    ${group.name}
                </g:else>
            </td>
        </tr>
    </g:each>
</tbody>
