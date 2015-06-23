class bit32

    @make_signed: (n) ->

        return (n & 0xffffffff) << 0


    @make_unsigned: (n) ->

        return (n & 0xffffffff) >>> 0


    @shr: (n, s) ->

        if s >= 32
            return 0
        else
            return @make_unsigned(n >>> s)


    @shl: (n, s) ->

        if s >= 32
            return 0
        else
            return @make_unsigned(n << s)


    @ror: (n, s) ->

        return @make_unsigned(@shr(n, s % 32) | @shl(n, 32 - (s % 32)))


    @rol: (n, s) ->

        return @make_unsigned(@shr(n, 32 - (s % 32)) | @shl(n, s % 32))
