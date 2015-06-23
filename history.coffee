class History

    constructor: (@max_length = 50, @none = "") ->

        @index = -1
        @mem = []


    length: () ->

        return @mem.length


    get: () ->

        if @length() > 0 and @index >= 0

            return @mem[@index]

        else

            return @none


    up: () ->

        @index = Math.min(@index + 1, @length() - 1)
        return @get()


    down: () ->

        @index = Math.max(@index - 1, -1)
        return @get()


    add: (msg) ->

        if not (msg in @mem)

            if @mem.unshift(msg) > @max_length

                @mem.pop()

        else

            @mem = @mem.filter((m) -> m != msg)
            @add(msg)


    reset: () ->

        @index = -1
