<div
    id="downloadRecordsModal"
    class="modal hide fade"
    tabindex="-1"
    role="dialog"
    aria-labelledby="myModalLabel"
    aria-hidden="true"
>
    <aa:zone id="dialogZone">
        <div class="modal-header">
            <h3 id="myModalLabel">
                <g:message code="download.title" />
            </h3>
        </div>

        <div class="modal-body">
            <p>
                <g:message code="download.terms.01" />
                <a href="https://plutof.ut.ee/#/privacy-policy" target="_blank">
                    <g:message code="download.terms.02" />
                </a>
                <g:message code="download.terms.03" />
            </p>

            <br />

            <p>
                <g:message code="download.form.title" />
            </p>

            <g:form
                class="form-horizontal"
                controller="region"
                action="download"
                params="[regionType: region.type, regionName: region.regionName, regionFid: region.regionFid, regionPid: region.regionPid]"
            >
                <div class="form-group">
                    <label class="col control-label" for="email">
                        <g:message code="download.form.email.label" /> *
                    </label>

                    <div class="col">
                        <input
                            id="email"
                            type="text"
                            name="email"
                            value="${downloadParams.email}"
                            class="form-control"
                        />
                    </div>
                </div>

                <div class="form-group">
                    <label class="col control-label" for="fileName">
                        <g:message code="download.form.fileName.label" />
                    </label>

                    <div class="col">
                        <input
                            id="fileName"
                            type="text"
                            name="fileName"
                            value="${downloadParams.fileName ?: message(code: 'download.form.fileName.value')}"
                            class="form-control"
                        />
                    </div>
                </div>

                <div class="form-group">
                    <label class="col control-label" for="downloadReason">
                        <g:message code="download.form.reason.label" /> *
                    </label>

                    <div class="col">
                        <g:select
                            id="downloadReason"
                            name="downloadReason"
                            class="erk-select"
                            value="${downloadParams.downloadReason}"
                            noSelection="${['': message(code: 'download.form.reason.placeholder')]}"
                            from="${downloadReasons}"
                            optionKey="key"
                            optionValue="${{opt -> message(code: "download.form.reason.${opt.key}", default: "${opt.value}")}}"
                        >
                        </g:select>
                    </div>
                </div>

                <div class="form-group">
                    <label class="col control-label" for="downloadOption">
                        <g:message code="download.form.downloadType.label" />
                    </label>

                    <g:each in="${downloadOptions}">
                        <div class="col">
                            <label class="erk-radio-label">
                                <input
                                    type="radio"
                                    class="erk-radio-input"
                                    name="download-types"
                                    value="${it.key}"
                                    ${it.key==0 ? 'checked' : ''}
                                >
                                &nbsp;<g:message code="download.form.downloadType.${it.key}" default="${it.value}" />
                            </label>
                        </div>
                    </g:each>
                </div>
            </g:form>
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
                <g:message code="general.btn.download.label" />
            </button>
        </div>

        <script>
            $(document).ready(function() {
                // catch download submit button
                // Note Nick's unbind().bind() syntax - due to Jquery ready being inside <body> tag.

                // start download button
                $("#downloadStart").unbind("click").bind("click",function(e) {
                    e.preventDefault();
                    var downloadUrl;
                    var downloadReason = $("#downloadReason option:selected").val();
                    var downloadOption = $('input[name=download-types]:checked').val();
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
