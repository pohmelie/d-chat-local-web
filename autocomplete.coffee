class Autocomplete

    constructor: (@words = []) ->

        @words.sort()


    add: (word) ->

        if not (word in @words)

            @words.push(word)
            @words.sort()


    remove: (word) ->

        @words = @words.filter((w) -> w != word)


    filter: (msg) ->

        word = msg.split(" ").pop()
        return @words.filter((w) -> w.indexOf(word) == 0 and w isnt word)


    common: (words) ->

        return words.reduce((c, w) ->

            rw = ""
            for i in [0...Math.min(c.length, w.length)]

                if c[i] == w[i]

                    rw += c[i]

                else

                    return rw

            return rw
        )


    cut: (msg, word) ->

        return word[msg.split(" ").pop().length..-1]
