class @Stylist

    constructor: (@name="dynamic-stylist", @css={}) ->

        i = 0
        while $("#" + @name + i.toString()).length != 0
            i += 1

        @name += i.toString()
        $("head").append(@build())


    build: () ->

        s = "<style id='#{@name}'>\n"
        for k, v of @css
            s += "#{k} {\n"
            for ik, iv of v
                s += "    #{ik}"
                if iv?
                    s += ": #{iv}"
                s += ";\n"
            s += "}\n"
        s += "</style>"
        return s


    update: () ->

        $("#" + @name).replaceWith(@build())


    remove: () ->

        $("#" + @name).remove()
