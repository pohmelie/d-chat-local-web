#= require <stylist.coffee>


class ui

    class @Tab

        constructor: (@title, @prefix, @username, @id, @closeable=true) ->

            @html = []
            @input = ""
            @unread = 0


        add: (html) ->

            @html.push(html)


        set_title: (@title) ->

            $(@id).html(@title)


        refresh_title: () ->

            if @unread != 0

                @set_title("[#{@unread}] #{@username}")

            else

                @set_title("#{@username}")


        clear: () ->

            @html = []
            @unread = 0


    class @Tabs

        constructor: (@tabs_id, @chat_id, @user_list_id, @input_id, @render_phrases, @refresh_main_title) ->

            @tabs_float_index = 0
            @stylist = new Stylist()
            @user_list = new ui.UserList(@user_list_id, @render_phrases, @input_id)

            @tabs = []
            @add("", "", "main", false)

            @main = @active = @tabs[0]

            line_height = $(@main.id).outerHeight(true)
            @stylist.css[@tabs_id] = {
                "line-height":"#{line_height + 2}px"
            }

            @stylist.update()
            @autosize()


        get_tab: (username="main") ->

            for tab in @tabs

                if tab.username == username

                    return tab


        whisper: (username, html, scroll_down=true) ->

            tab = @get_tab(username)

            if tab?

                tab.add(html)
                if tab is @active

                    $(@chat_id).append(html)

                else if tab isnt @main

                    tab.unread += 1

                if (scroll_down)

                    $(@chat_id).scrollTop($(@chat_id)[0].scrollHeight)

                if tab isnt @main

                    tab.refresh_title()
                    @refresh_main_title()

                return

            @add("", "/w #{username} ", username)
            @whisper(username, html, scroll_down)


        echo: (html, scroll_down=true) ->

            @whisper("main", html, scroll_down)


        add: (title, prefix, username, closeable=true) ->

            while $("#tab" + @tabs_float_index.toString()).length != 0
                @tabs_float_index += 1

            id = "tab" + @tabs_float_index.toString()
            tab = new ui.Tab(title, prefix, username, "##{id}", closeable)
            @tabs.push(tab)

            $(@tabs_id).append("<span id=#{id}></span> ")
            $("##{id}").addClass("tab border color-border color-text").html(title)

            $("##{id}").on(
                "mouseup",
                (e) =>

                    switch e.which

                        when 1
                            @set_active(tab)

                        when 2
                            @remove(tab)

                    e.preventDefault()
            )

            @autosize()


        set_active: (tab=@main) ->

            $(@active.id).removeClass("color-active-tab-back color-active-tab-fore")
            $(tab.id).addClass("color-active-tab-back color-active-tab-fore")

            @active.input = $(@input_id).val()
            @active = tab
            $(@input_id).val(@active.input)

            $(@chat_id).html(@active.html.join(""))
            $(@chat_id).scrollTop($(@chat_id)[0].scrollHeight)

            @active.unread = 0
            @active.refresh_title()
            @refresh_main_title()

            $(@input_id).focus()


        remove: (tab=@active) =>

            if tab.closeable == true

                @tabs = @tabs.filter((t) -> t isnt tab)

                if @active is tab

                    @set_active(@main)

                $(tab.id).off("mouseup")
                $(tab.id).remove()

                @autosize()


        autosize: () =>

            height = (
                $(@tabs_id).outerHeight(true) +
                $(@chat_id).outerHeight(true) +
                $(@input_id).outerHeight(true) -
                $(@chat_id).innerHeight() +
                30  # padding
            )

            for id in [@chat_id, @user_list_id]
                @stylist.css[id] = {
                    "height":"calc(100% - #{height}px)"
                }

            @stylist.update()


        index: (tab=@active) ->

            for i in [0...@tabs.length]

                if tab is @tabs[i]

                    return i


        next: () ->

            if @tabs.length > 1

                @set_active(@tabs[(@index() + 1) % @tabs.length])


        prev: () ->

            if @tabs.length > 1

                @set_active(@tabs[(@tabs.length + @index() - 1) % @tabs.length])


    class @UserList

        constructor: (@user_list_id, @render_phrases, @input_id) ->

            @clear()


        add: (username, nickname) ->

            if @mem[username]?

                return

            msgs = [
                ["color-delimiter", "*"],
                ["color-user-list-account", username]
            ]

            if nickname != ""

                msgs.push(
                    ["color-user-list-nickname", " (#{nickname})"]
                )

            msg = @render_phrases(msgs...)
            @mem[username] = @internal_id
            id = "#{@user_list_id.substr(1)}-member-#{@mem[username]}"
            html = "<div id='#{id}' class='user-list-member'>#{msg}</div>"

            if nickname != ""

                $(@user_list_id).append(html)

            else

                $(@user_list_id).prepend(html)

            $("##{id}").on(
                "mouseup",
                (e) =>

                    if e.which == 1

                        $(@input_id).val("/w *#{username} ")
                        $(@input_id).focus()

                    e.preventDefault()
            )

            @internal_id = @internal_id + 1


        remove: (username) ->

            if @mem[username]?

                $("#{@user_list_id}-member-#{@mem[username]}").off("mouseup")
                $("#{@user_list_id}-member-#{@mem[username]}").remove()
                delete @mem[username]


        clear: () ->

            $(@user_list_id).html("")
            @internal_id = 0
            @mem = {}
