<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

        <title>
            <g:layoutTitle />
        </title>

        <r:require modules="bootstrap, ala"/>

        <r:layoutResources />
        <g:layoutHead />

        <style>
            body {
                padding-top: 0;
            }
        </style>
    </head>

    <body>
        <g:render template="/menu" plugin="elurikkus-commons" />

        <div class="container-fluid">
            <g:layoutBody />
        </div>

        <r:layoutResources />

        <g:render template="/footer" plugin="elurikkus-commons" />
    </body>
</html>
