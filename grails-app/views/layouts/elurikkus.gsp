<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <g:render template="/manifest" plugin="elurikkus-commons" />

        <title>
            <g:layoutTitle />
        </title>

        <r:require modules="jquery, bootstrap, menu" />

        <g:layoutHead />
        <r:layoutResources />

        <style>
            body {
                padding-top: 0;
            }
        </style>
    </head>

    <body>
        <g:render template="/menu" plugin="elurikkus-commons" />

        <div>
            <g:layoutBody />
        </div>

        <r:layoutResources />

        <g:render template="/footer" plugin="elurikkus-commons" />
    </body>
</html>
