#= require <ui.coffee>
#= require <bnet.coffee>
#= require <websocket-socket-bridge.coffee>
#= require <history.coffee>
#= require <autocomplete.coffee>
#= require <intro.coffee>
#= require <autotrade.coffee>
#= require <calc.coffee>
#= require <help.coffee>


class Dchat

    constructor: (@tabs_id, @chat_id, @user_list_id, @input_id, @commands_prefix="\\") ->

        @max_symbols = 199
        @min_autotrade_timeout = 120
        @min_autotrade_activity = 0
        @default_autotrade_timeout = 300
        @default_autotrade_activity = 10

        @nicknames = {}
        @users_count = 0
        @channel = null
        @connected = false

        if localStorage.hashed_password?

            try

                @hashed_password = JSON.parse(localStorage.hashed_password)

            catch

                localStorage.clear()

        @autoscroll = localStorage.autoscroll or true
        @autoreconnect = localStorage.autoreconnect or false
        @account = localStorage.account
        @tab_mode = localStorage.tab_mode or true

        @replacing_symbols = {
            ">":"&gt;",
            "<":"&lt;",
            " ":"&nbsp;<wbr>",
            "\n":"<br>",
        }

        @commands_list = [
            "echo",
            "connect",
            "disconnect",
            "reload",
            "autoscroll",
            "help",
            "tab-mode",
            "autotrade-message", "atm",
            "autotrade-timeout",
            "autotrade-activity",
            "autotrade-start",
            "autotrade-stop",
            "autotrade-info",
            "calc",
            "clear-local-storage",
            "clear-screen",
            "autoreconnect",
        ]
        @autocomplete = new Autocomplete(@commands_list.map((c) => @commands_prefix + c))

        if isNaN(localStorage.autotrade_activity) or (localStorage.autotrade_activity < @min_autotrade_activity)

            localStorage.autotrade_activity = @default_autotrade_activity

        if isNaN(localStorage.autotrade_timeout) or (localStorage.autotrade_timeout < @min_autotrade_timeout)

            localStorage.autotrade_timeout = @default_autotrade_timeout

        @autotrade = new Autotrade(
            @common_message,
            localStorage.autotrade_msg or "N enigma free PLZ PLZ!!",
            localStorage.autotrade_activity,
            localStorage.autotrade_timeout
        )

        @history = new History()
        @tabs = new ui.Tabs(@tabs_id, @chat_id, @user_list_id, @input_id,
                            @render_phrases, @refresh_title)
        @tabs.set_active(@tabs.main)

        @websocket = new socket.WebSocketBridge()
        @bn = new bnet.Bnet(
            "rubattle.net",
            6112,
            @websocket.connect,
            @websocket.send,
            @login_error,
            @chat_event
        )

        @websocket.on_data = @bn.on_packet
        @websocket.on_error = @socket_error
        @websocket.on_disconnect = @reconnect_on_disconnection

        $(@input_id).on("keydown", @input_key)
        $(window).on("keydown", @global_key)

        @refresh_title()
        @show_intro()

        if @account? and @hashed_password?

            @command("connect")

        if localStorage.autotrade == "true"

            @command("autotrade-start")


    reconnect_on_disconnection: () =>

        if @reconnect or @autoreconnect and @connected

            @reconnect = false
            @command("connect")

        else

            @disconnect()


    render_phrases: (phrases...) =>

        html = ""
        for phrase in phrases

            if typeof(phrase) isnt "object"

                phrase = ["color-text", phrase]

            [color, msg, raw] = phrase

            if raw isnt true

                msg = @prepare_string(msg)

            html += "<span class='#{color}'>#{msg}</span>"

        return html


    echo: (phrases...) ->

        @tabs.echo(
            "<div>#{@render_phrases([['color-time', @time()]].concat(phrases)...)}</div>",
            @autoscroll
        )


    whisper: (username, phrases...) ->

        @tabs.whisper(
            username,
            "<div>#{@render_phrases([['color-time', @time()]].concat(phrases)...)}</div>",
            @autoscroll
        )


    login_error: (stage, reason) =>

        reasons = ["Account doesn't exists", "Wrong password"]

        if reasons[reason - 1]?
            @echo(["color-error", "Login failed. #{reasons[reason - 1]}."])
        else
            @echo(["color-error", "Login failed. (stage = #{stage}, reason = #{reason})."])

        @disconnect()


    socket_error: (msg) =>

        @echo(["color-error", "socket error: #{msg}"])
        @disconnect()


    connect: (acc, pass, hashed=false) =>

        @disconnect()

        if @websocket.websocket_ok

            @command("echo Connecting...")
            @bn.login(acc, pass, hashed)
            @connected = true

        else

            @websocket.reset()
            setTimeout((() => @connect(acc, pass, hashed)), 1000)


    disconnect: (@reconnect=false) =>

        if @connected

            @connected = false
            @websocket.disconnect()
            @command("echo Disconnected.")
            @users_count = 0
            @channel = null
            @refresh_title()
            @tabs.user_list.clear()

            for k, v of @nicknames

                @autocomplete.remove("*#{k}")

            @nicknames = {}


    refresh_title: () =>

        if @connected

            total_unread = @tabs.tabs.reduce(((u, t) -> u + t.unread), 0)

            if total_unread != 0

                title = "[#{total_unread}] #{@channel} (#{@users_count})"

            else

                title = "#{@channel} (#{@users_count})"

        else

            title = "d-chat-local-web"

        @tabs.main.set_title(title)
        $(document).attr("title", title)


    time: () ->

        d = new Date()
        s = [d.getHours(), d.getMinutes(), d.getSeconds()].map((x) ->
            if x < 10
                return "0" + x.toString()
            else
                return x.toString()
        ).join(":")

        return "[#{s}] "


    chat_event: (pack) =>

        switch pack.event_id

            when "ID_USER", "ID_JOIN", "ID_USERFLAGS"

                nickname = ""
                if pack.text.substring(0, 4) is "PX2D"
                    s = pack.text.split(",")
                    if s.length > 1
                        nickname = s[1]

                if not @nicknames[pack.username]?
                    @users_count += 1

                @nicknames[pack.username] = nickname
                @autocomplete.add("*#{pack.username}")
                @tabs.user_list.add(pack.username, nickname)
                @refresh_title()

            when "ID_LEAVE"

                delete @nicknames[pack.username]
                @autocomplete.remove("*#{pack.username}")
                @tabs.user_list.remove(pack.username)
                @users_count -= 1
                @refresh_title()

            when "ID_INFO"

                @echo(["color-system", pack.text])

            when "ID_ERROR"

                @echo(["color-error", pack.text])

            when "ID_TALK", "ID_EMOTE"

                @echo(
                    ["color-nickname", @nicknames[pack.username]],
                    ["color-delimiter", "*"],
                    ["color-nickname", pack.username],
                    ["color-delimiter", ": "],
                    ["color-text", pack.text]
                )
                @autotrade.trigger_activity()

            when "ID_CHANNEL"

                @channel = pack.text
                @users_count = 0

                for k, v of @nicknames

                    @autocomplete.remove("*#{k}")

                @nicknames = {}
                @tabs.user_list.clear()
                @refresh_title()

            when "ID_WHISPER"

                if @tab_mode

                    @whisper(
                        "*#{pack.username}",
                        ["color-nickname", (@nicknames[pack.username] or "")],
                        ["color-delimiter", "*"],
                        ["color-nickname", pack.username],
                        ["color-delimiter", ": "],
                        ["color-text", pack.text]
                    )

                else

                    @echo(
                        ["color-whisper-nickname", (@nicknames[pack.username] or "") + "*#{pack.username}"],
                        ["color-delimiter", " -> "],
                        ["color-whisper-nickname", "*#{@account}"],
                        ["color-delimiter", ": "],
                        ["color-whisper", pack.text]
                    )

            when "ID_WHISPERSENT"

                if @tab_mode

                    @whisper(
                        "*#{pack.username}",
                        ["color-delimiter", "*"],
                        ["color-nickname", @account],
                        ["color-delimiter", ": "],
                        ["color-text", pack.text]
                    )
                    @tabs.set_active(@tabs.get_tab("*#{pack.username}"))

                else

                    @echo(
                        ["color-whisper-nickname", "*#{@account}"],
                        ["color-delimiter", " -> "],
                        ["color-whisper-nickname", (@nicknames[pack.username] or "") + "*#{pack.username}"],
                        ["color-delimiter", ": "],
                        ["color-whisper", pack.text]
                    )

            when "ID_BROADCAST"

                @echo(
                    ["color-whisper-nickname", pack.username],
                    ["color-delimiter", ": "],
                    ["color-whisper", pack.text]
                )



    global_key: (e) =>

        if e.ctrlKey

            switch e.which

                when 39  # right

                    @tabs.next()
                    e.preventDefault()

                when 37  # left

                    @tabs.prev()
                    e.preventDefault()

                when 87  # 'w'

                    @tabs.remove()
                    e.preventDefault()

                when 83  # 's'

                    @toggle_autotrade()
                    e.preventDefault()

                when 82  # 'r'

                    @load_init_file()
                    e.preventDefault()

                when 68  # 'd'

                    @disconnect()
                    e.preventDefault()

                when 77  # 'm'

                    @tabs.set_active()
                    e.preventDefault()

                when 73  # 'i'

                    @command("autotrade-info")
                    e.preventDefault()

                when 67  # 'c'

                    if @connected

                        @disconnect(true)

                    else

                        @command("connect")

                    e.preventDefault()

        else if e.which == 112

            @show_help()
            e.preventDefault()

        # console.log(e.currentTarget, e.which, e.ctrlKey, e.altKey, e.shiftKey)


    toggle_autotrade: () ->

        if @autotrade.running

            @command("autotrade-stop")

        else

            @command("autotrade-start")


    toggle_autoscroll: () ->

        @autoscroll = not @autoscroll
        localStorage.autoscroll = @autoscroll
        @command("echo Autoscroll set to #{@autoscroll}.")

    toggle_autoreconnect: () ->

        @autoreconnect = not @autoreconnect
        localStorage.autoreconnect = @autoreconnect
        @command("echo Autoreconnect set to #{@autoreconnect}.")

    common_message: (msg) =>

        if msg isnt ""

            if msg[0] is @commands_prefix

                @command(msg.substring(1))

            else if @connected and @channel?

                smsg = msg
                while smsg != ""

                    @bn.say(smsg.substr(0, @max_symbols))
                    smsg = smsg.substr(@max_symbols)

                if msg[0] isnt "/"

                    @echo(
                        ["color-delimiter", "*"],
                        ["color-nickname", @account],
                        ["color-delimiter", ": "],
                        ["color-text", msg]
                    )


    input_key: (e) =>

        switch e.which

            when 13  # enter

                @history.add($(@input_id).val())
                @history.reset()

                msg = @tabs.active.prefix + $(@input_id).val().trim()
                $(@input_id).val("")
                @common_message(msg)

            when 9  # tab

                if not e.ctrlKey

                    msg = $(@input_id).val()
                    words = @autocomplete.filter(msg)
                    if words.length == 1

                        $(@input_id).val(msg + @autocomplete.cut(msg, words[0]))

                    else if words.length > 1

                        common = @autocomplete.cut(msg, @autocomplete.common(words))
                        $(@input_id).val(msg + common)

                        if common.length == 0

                            words.unshift("#{words.length} possibilities:")
                            @echo(["color-autocomplete", words.join("\n")])

                    e.preventDefault()

            when 38  # up

                if @history.length() > 0

                    $(@input_id).val(@history.up())

                e.preventDefault()

            when 40  # down

                if @history.length() > 0

                    $(@input_id).val(@history.down())

                e.preventDefault()


    command: (cmd) ->

        cmd = cmd.split(" ")

        switch cmd[0].toLowerCase()

            when "echo"

                if cmd.length > 1

                    @echo(["color-echo", cmd[1..-1].join(" ")])

            when "connect"

                [acc, pass] = cmd[1..-1].filter((x) -> x isnt "")

                if acc? and pass?

                    @connect(acc, pass)

                    if @bn.hashpass?

                        localStorage.hashed_password = JSON.stringify(@bn.hashpass)
                        localStorage.account = @account = acc


                else if localStorage.account? and localStorage.hashed_password?

                    @account = localStorage.account
                    @connect(localStorage.account, JSON.parse(localStorage.hashed_password), true)

                else

                    @command("echo Can't connect without account name and password. Type '#{@commands_prefix}help' for more information.")

            when "disconnect"

                @disconnect()

            when "reload"

                @load_init_file()

            when "autoscroll"

                @toggle_autoscroll()

            when "autoreconnect"

                @toggle_autoreconnect()

            when "help"

                @show_help()

            when "tab-mode"

                @toggle_tab_mode()

            when "autotrade-message", "atm"

                if cmd.length > 1

                    localStorage.autotrade_msg = @autotrade.msg = cmd[1..-1].join(" ")

                @command("echo Current autotrade message is '#{@autotrade.msg}'.")

            when "autotrade-timeout"

                if cmd.length > 1

                    t = parseInt(cmd[1])

                    if isNaN(t) or t < @min_autotrade_timeout

                        @command("echo Bad number '#{cmd[1]}' (must be greater or equal to #{@min_autotrade_timeout}).")

                    else

                        localStorage.autotrade_timeout = @autotrade.timeout = t

                @command("echo Current autotrade timeout is '#{@autotrade.timeout}'.")

            when "autotrade-activity"

                if cmd.length > 1

                    t = parseInt(cmd[1])

                    if isNaN(t) or t < @min_autotrade_activity

                        @command("echo Bad number '#{cmd[1]}' (must be greater or equal to #{@min_autotrade_activity}).")

                    else

                        localStorage.autotrade_activity = @autotrade.activity = t

                @command("echo Current autotrade activity is '#{@autotrade.activity}'.")

            when "autotrade-start"

                @command("echo Autotrade started with message = '#{@autotrade.msg}' and timeout = '#{@autotrade.timeout}'.")
                @autotrade.start()
                localStorage.autotrade = true

            when "autotrade-stop"

                @command("echo Autotrade stopped.")
                @autotrade.stop()
                localStorage.autotrade = false

            when "autotrade-info"

                @command("""
                echo Autotrade info:
                running = #{@autotrade.running}
                message = #{@autotrade.msg}
                time = #{@autotrade.current_time}/#{@autotrade.timeout}
                activity = #{@autotrade.activity}
                current activity = #{@autotrade.current_activity}
                """)

            when "calc"

                @command("echo #{Calculator.calc(cmd[1..-1])}")

            when "clear-local-storage"

                localStorage.clear()
                @command("echo Local storage erased.")

            when "clear-screen"

                @tabs.main.clear()
                @tabs.set_active()

            else

                @command("echo Unknown command '#{cmd[0].toLowerCase()}'.")


    toggle_tab_mode: () ->

        @tab_mode = not @tab_mode
        @command("echo Tab mode set to #{@tab_mode}.")

        if not @tab_mode

            @tabs.tabs.filter((t) -> t.closeable).forEach(@tabs.remove)
            @refresh_title()


    load_init_file: (data) =>

        if data?

            data.split("\n").map((x) -> x.trim()).forEach(@common_message)

        else

            $.get("init", @load_init_file, "text").error(() =>
                @command("echo Initialization file 'init' missing.")
            )


    show_help: () ->

        @command("echo #{help_message(@commands_prefix)}")


    prepare_string: (str) ->

        for find, replace of @replacing_symbols

            str = str.replace(new RegExp(find, 'g'), replace)

        return str


    show_intro: () ->

        @echo(["color-text", intro, true])


init = () ->

    dchat = new Dchat("#tabs", "#chat", "#user-list", "#input")


$(init)
