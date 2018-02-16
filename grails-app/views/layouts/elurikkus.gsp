<!DOCTYPE html>
<%@ page import="grails.util.Environment" %>

<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />

        <g:render template="/manifest" plugin="elurikkus-commons" />

        <title>
            <g:layoutTitle />
        </title>

        <script src="https://maps.googleapis.com/maps/api/js?v=3.29&key=AIzaSyBmpdTc4R7iLML5tHXpN0OzHsEm7duuPrg" type="text/javascript"></script>
        <script src="https://www.google.com/jsapi?type=js/key=AIzaSyBmpdTc4R7iLML5tHXpN0OzHsEm7duuPrg" type="text/javascript"></script>

        <script>
            var GRAILS_APP = {
                environment: "${Environment.current.name}",
                rollbarApiKey: "${grailsApplication.config.rollbar.postApiKey}"
            };
        </script>

        <asset:javascript src="region-main" />
        <asset:stylesheet src="region-main" />

        <g:layoutHead />
    </head>

    <body>
        <g:render template="/menu" plugin="elurikkus-commons" />

        <div>
            <g:layoutBody />
        </div>

        <g:render template="/footer" plugin="elurikkus-commons" />
    </body>
</html>
