class convert

    @utf8_encode: (s) ->

        bytes = []

        for i in [0...s.length]

            code = s.charCodeAt(i)

            if code < 0x80
                bytes.push(code)
                continue

            bits_per_first = 6
            sub = []

            while code > (bit32.shl(1, bits_per_first) - 1)

                sub.push(0x80 | (code & (bit32.shl(1, 6) - 1)))
                code = bit32.shr(code, 6)
                bits_per_first -= 1

            sub.push(code | (bit32.shl(0xff, bits_per_first + 1) & 0xff))
            bytes = bytes.concat(sub.reverse())

        return bytes


    @utf8_decode: (b) ->

        char_codes = []
        i = 0

        while i < b.length

            byte = b[i++]
            shifts = 0

            while byte & 0x80
                byte = bit32.shl(byte, 1) & 0xff
                shifts += 1

            code = bit32.shr(byte, shifts)
            if shifts != 0
                for j in [1...shifts]
                    code = bit32.shl(code, 6) | (b[i++] & (bit32.shl(1, 6) - 1))

            char_codes.push(code)

        return String.fromCharCode(char_codes...)


    @bin2str: (bin) ->

        return convert.utf8_decode(bin)


    @str2bin: (str) ->

        return convert.utf8_encode(str)


    @bin2hex: (bin) ->

        sizer = (s) ->
            if s.length == 1
                return "0" + s
            else
                return s

        return bin.map((x) -> sizer(x.toString(16))).join(" ")


    @hex2bin: (hex) ->

        return hex.split(" ").map((x) -> parseInt(x, 16))
