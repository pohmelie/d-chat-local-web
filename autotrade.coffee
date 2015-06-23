class Autotrade

    constructor: (@say, @msg="N enigma free PLZ PLZ!!", @activity=10, @timeout=300) ->

        @running = false
        @current_time = 0
        @current_activity = 0


    timer: () =>

        if @running

            if @msg == ""

                @stop()
                return

            if @current_time == @timeout - 1

                if @current_activity >= @activity

                    @current_time = 0
                    @current_activity = 0
                    @say(@msg)

            else

                @current_time += 1

            setTimeout(@timer, 1000)


    trigger_activity: () ->

        @current_activity = Math.min(@current_activity + 1, @activity)


    start: () ->

        @current_time = 0
        @running = true
        @current_activity = 0
        setTimeout(@timer, 1000)


    stop: () ->

        @running = false
