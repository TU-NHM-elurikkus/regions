<div
    id="downloadRecordsModal"
    class="modal hide fade"
    tabindex="-1"
    role="dialog"
    aria-labelledby="myModalLabel"
    aria-hidden="true"
>
    <aa:zone id="dialogZone">
        <g:form
            class="form-horizontal"
            controller="region"
            action="download"
            params="[regionType: region.type, regionName: region.regionName, regionFid: region.regionFid, regionPid: region.regionPid]"
        >
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">
                    ×
                </button>
                <h3 id="myModalLabel">
                    <g:message code="download.title" />
                </h3>
            </div>
            <div class="modal-body">
                <p>
                    <g:message code="download.termsOfUse.desc.01" />
                    <a href="https://plutof.ut.ee/#/privacy-policy" target="_blank">
                        <g:message code="download.termsOfUse.desc.02" />
                    </a>
                    <g:message code="download.termsOfUse.desc.03" />.
                    <br />
                    <br />
                    <g:message code="download.form.title" />:
                </p>

                <div class="control-group ${g.hasErrors(bean: downloadParams, field: 'email', 'error')}">
                    <label class="control-label" for="email">
                        <g:message code="download.form.field.email.label" /> *
                    </label>
                    <div class="controls">
                        <g:textField id="email" name="email" value="${downloadParams.email}"/>
                    </div>
                </div>

                <br />

                <div class="control-group ${g.hasErrors(bean: downloadParams, field: 'fileName', 'error')}">
                    <label class="control-label" for="fileName">
                        <g:message code="download.form.field.fileName.label" />
                    </label>
                    <div class="controls">
                        <g:textField
                            id="fileName"
                            name="fileName"
                            value="${downloadParams.fileName ?: message(code: 'download.form.field.fileName.value')}"
                        />
                    </div>
                </div>

                <br />

                <div class="control-group ${g.hasErrors(bean: downloadParams, field: 'downloadReason', 'error')}">
                    <label class="control-label" for="downloadReason">
                        <g:message code="download.form.field.reason.label" /> *
                    </label>

                    <div class="controls">
                        <g:select
                            id="downloadReason"
                            name="downloadReason"
                            value="${downloadParams.downloadReason}"
                            noSelection="${['': message(code: 'download.form.field.reason.placeHolder')]}"
                            from="${downloadReasons}"
                            optionKey="key"
                            optionValue="${{opt -> message(code: "download.form.field.reason.option.${opt.key}", default: "${opt.key}")}}"
                        >
                        </g:select>
                    </div>
                </div>

                <br />

                <div class="control-group ${g.hasErrors(bean: downloadParams, field: 'downloadOption', 'error')}">
                    <label class="control-label" for="downloadOption">
                        <g:message code="download.form.field.downloadType.label" /> *
                    </label>

                    <g:each in="${downloadOptions}">
                        <div id="download-types">
                            <label class="erk-radio-label">
                                <input
                                    type="radio"
                                    class="erk-radio-input"
                                    name="download-types"
                                    value="${it.key}"
                                    ${it.key==0 ? 'checked' : ''}
                                >
                                &nbsp;<g:message code="download.form.field.downloadType.option.${it.key}" default="${it.value}" />
                            </label>
                        </div>
                    </g:each>
                </div>
            </div>

            <div class="modal-footer">
                <button class="erk-button erk-button--light" data-dismiss="modal" aria-hidden="true">
                    <g:message code="general.btn.close" />
                </button>
                <button
                    id='downloadStart'
                    class="erk-button erk-button--light"
                    aa-refresh-zones="dialogZone"
                    js-before="AjaxAnywhere.dynamicParams=regionWidget.getCurrentState();"
                >
                    <span class="fa fa-download"></span>
                    <g:message code="download.btn.label" />
                </button>
            </div>
        </g:form>

        <script>
            $(document).ready(function() {
                // catch download submit button
                // Note the unbind().bind() syntax - due to Jquery ready being inside <body> tag.

                // start download button
                $("#downloadStart").unbind("click").bind("click",function(e) {
                    e.preventDefault();
                    var downloadUrl;
                    var downloadReason = $("#downloadReason option:selected").val();
                    var downloadOption = $('#download-types input[name=download-types]:checked').val()
                    var commonData = "&email=" + $("#email").val() +
                        "&reasonTypeId=" + $("#downloadReason").val() +
                        "&file=" + $("#fileName").val();

                    if (validateForm()) {
                        if (downloadOption == "1") {
                            downloadUrl = decodeURIComponent('${downloadChecklistUrl}') + commonData;
                            window.location.href = downloadUrl;
                        } else {  // (downloadOption == "0")
                            downloadUrl = decodeURIComponent('${downloadRecordsUrl}') +
                                commonData +  // for some parsing reasons, common must be in the middle...
                                "&extra=dataResourceUid,dataResourceName.p";
                            window.location.href = downloadUrl;
                        }

                        $('#downloadRecordsModal').modal('hide');
                    }
                });
            });

            function validateForm() {
                var isValid = true;
                var downloadReason = $("#downloadReason option:selected").val();
                var email = $("#email").val()

                if (!downloadReason) {
                    $("#downloadReason").focus();
                    $("label[for='downloadReason']").css("color", "red");
                    isValid = false;
                } else {
                    $("label[for='downloadReason']").css("color", "inherit");
                }

                if (!email) {
                    $("#email").focus();
                    $("label[for='email']").css("color", "red");
                    isValid = false;
                } else {
                    $("label[for='email']").css("color", "inherit");
                }

                return isValid;
            }
        </script>
    </aa:zone>
</div>
