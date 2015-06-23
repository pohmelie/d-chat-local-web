#= require <bit32.coffee>


class Calculator

    @runes = ["pul", "um", "mal", "ist", "gul", "vex", "ohm", "lo", "sur", "ber", "jah"]
    @per_train = (16 + 8 + 4 + 2 + 1) * 7 / 11

    @pp: (stack, highest="jah") ->

        result = []
        n = Calculator.runes.indexOf(highest)

        while stack != 0

            puls_per_rune = bit32.shl(1, n)

            if stack >= puls_per_rune

                result.push("#{Math.floor(stack / puls_per_rune)} #{Calculator.runes[n]}")
                stack %= puls_per_rune

            n -= 1

        if result.length == 0

            return "stack is empty."

        else

            return result.join(", ")


    @calc: (words) ->

        words = words.map((w) -> w.toLowerCase()).filter((w) -> w != "")
        count = 1
        stack = 0
        result = []

        i = 0

        while i < words.length

            switch words[i]

                when "to"

                    i += 1
                    if (i < words.length) and (words[i] in Calculator.runes)

                        result.push(Calculator.pp(stack, words[i]))

                    else

                        return result.join("\n")

                when "t"

                    result.push("Trains count: #{Math.ceil(stack / Calculator.per_train)}")

                when "c"

                    stack = 0

                when "p"

                    result.push(Calculator.pp(stack))

                else

                    if isNaN(parseInt(words[i])) or (words[i][words[i].length - 1] == "%")

                        if words[i] in Calculator.runes

                            stack += count * bit32.shl(1, Calculator.runes.indexOf(words[i]))
                            count = 1

                        else if words[i][words[i].length - 1] == "%"

                            p = words[i][0...(words[i].length - 1)]

                            if isNaN(parseInt(p))

                                return result.join("\n")

                            else

                                p = parseInt(p)
                                result.push("#{p}% of stack = #{Calculator.pp(Math.round(stack * p / 100))}")

                    else

                        count = parseInt(words[i])

            i += 1

        result.push("Stack: " + Calculator.pp(stack))
        return result.join("\n")
