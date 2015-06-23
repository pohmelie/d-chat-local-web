#= require <bit32.coffee>
#= require <convert.coffee>


class construct

    @copy: (obj, visited=[]) ->

        if typeof(obj) isnt "object"
            return obj

        for [r, c] in visited
            if r is obj
                return c

        if obj instanceof Array
            c = []
            visited.push([obj, c])
            for v in obj
                c.push(@copy(v, visited))
        else
            c = {}
            visited.push([obj, c])
            for k, v of obj
                c[k] = @copy(v, visited)

        return c


    @linkify: (obj, owner=obj) ->

        if typeof(obj) is "object"

            if obj instanceof Array
                for v in obj
                    @linkify(v, owner)
            else
                obj["_"] = owner
                for k, v of obj
                    if v isnt owner
                        @linkify(v, obj)

        return obj


    class @DataIO

        constructor: (@data=[], @shift=0) ->

        read: () ->

            if @shift == @data.length
                throw new Error("DataReader: end of data")

            return @data[@shift++]


        tail: () ->

            return @data[@shift..]


        write: (bytes) ->

            @data.push(bytes...)
            return @data


    class @Base

        parse: (data) ->

            ctx = {}
            ctx["_"] = ctx
            return @__parse(new construct.DataIO(data), ctx)


        build: (data) ->

            return @__build(data, new construct.DataIO())


    class @_BaseInt extends @Base

        constructor: (@name, @size, @signed, @endian) ->

            if typeof(@size) isnt "number" or @size < 1
                throw new Error("BaseInt (name = '#{@name}'): bad size ('#{@size}')")

            if @signed not in ["signed", "unsigned"]
                throw new Error("BaseInt (name = '#{@name}'): bad sign ('#{@signed}')")

            if @endian not in ["little", "big"]
                throw new Error("BaseInt (name = '#{@name}'): bad endian ('#{@endian}')")


        @signification: (num, size) ->

            if num & Math.pow(2, size * 8 - 1)
                return bit32.make_unsigned(num) - Math.pow(2, size * 8)
            else
                return bit32.make_unsigned(num)


        __parse: (io) ->

            data = (io.read() for i in [1..@size])

            if @endian is "big"
                [head, tail, step] = [0, @size - 1, 1]
            else if @endian is "little"
                [head, tail, step] = [@size - 1, 0, -1]

            num = 0
            for i in [head..tail] by step
                if data[i]?
                    num = bit32.make_unsigned(bit32.shl(num, 8) | data[i])
                else
                    throw new Error("BaseInt (name = '#{@name}'), bad data")

            if @signed is "signed"
                num = _BaseInt.signification(num, @size)

            return num


        __build: (num, io) ->

            data = []
            num = bit32.make_unsigned(num)
            for i in [1..@size]
                data.push(num & 0xff)
                num = bit32.shr(num, 8)

            if @endian is "big"
                data.reverse()

            return io.write(data)


    class @_CString extends @Base

        constructor: (@name) ->

        __parse: (io) ->

            data = []
            try
                while (ch = io.read()) != 0
                    data.push(ch)

                return convert.bin2str(data)

            catch error
                throw new Error("CString, unexpected end of data")


        __build: (string, io) ->

            io.write(convert.str2bin(string))
            return io.write([0])


    class @_Struct extends @Base

        constructor: (@name, @objects...) ->

        __parse: (io, ctx) ->

            for object in @objects
                parsed = object.__parse(io, {"_":ctx})
                if object.name?
                    ctx[object.name] = parsed

            return ctx


        __build: (ctx, io) ->

            for object in @objects
                if object.name? and ctx[object.name]?
                    object.__build(ctx[object.name], io)
                else
                    object.__build(ctx, io)

            return io.data


    class @_Enum extends @Base

        constructor: (@object, @values) ->

            @name = @object.name


        __parse: (io) ->

            parsed = @object.__parse(io)

            if @values[parsed]?
                return @values[parsed]
            else
                throw new Error("Enum: value not in list (#{parsed})")


        __build: (value, io) ->

            for k, v of @values
                if value == v
                    return @object.__build(k, io)

            throw new Error("Enum: value not in list (#{ctx[@name]})")


    class @_Const extends @Base

        constructor: (@object, @value) ->
            @name = @object.name


        __parse: (io) ->

            parsed = @object.__parse(io)

            if parsed == @value
                return @value
            else
                throw new Error("Const: expect (#{@value}), but got (#{parsed})")

        __build: (nothing, io) ->

            return @object.__build(@value, io)


    class @_Switch extends @Base

        constructor: (@f, @objects) ->

        __parse: (io, ctx) ->

            ctx = ctx["_"]
            object = @objects[@f(ctx)] or @objects.default

            if object?
                if object.name? and ctx[object.name]?
                    return object.__parse(io, ctx[object.name])
                else
                    return object.__parse(io, ctx)
            else
                throw new Error("Switch: there is no (#{@f(ctx)}) key or 'default'")


        __build: (ctx, io) ->

            object = @objects[@f(ctx)] or @objects.default

            if object?
                if object.name? and ctx[object.name]?
                    return object.__build(ctx[object.name], io)
                else
                    return object.__build(ctx, io)
            else
                throw new Error("Switch: there is no (#{@f(ctx)}) key or 'default'")


    class @_Pass extends @Base

        __parse: (io, ctx) ->

            return ctx


        __build: (ctx, io) ->

            return io.data


    class @_OptionalGreedyRange extends @Base

        constructor: (@object) ->

            @name = @object.name


        __parse: (io, ctx) ->

            ctxs = []
            io_position = io.shift

            try
                while true
                    io_position = io.shift
                    ctxs.push(@object.__parse(io, construct.copy(ctx)))
                    if ctx["_"]?
                        ctxs[ctxs.length - 1]["_"] = ctx["_"]

            catch error
                io.shift = io_position

            return ctxs


        __build: (ctxs, io) ->

            for ctx in ctxs
                @object.__build(ctx, io)

            return io.data


    class @_Array extends @Base

        constructor: (cnt, @object) ->

            @name = @object.name

            if typeof(cnt) is "number"
                @count = () -> cnt
            else
                @count = cnt


        __parse: (io, ctx) ->

            ctxs = []

            for i in [1..@count(ctx)]
                ctxs.push(@object.__parse(io, construct.copy(ctx)))
                if ctx["_"]?
                    ctxs[ctxs.length - 1]["_"] = ctx["_"]

            return ctxs


        __build: (ctxs, io) ->

            if ctxs.length != @count(ctxs[0])
                throw new Error("Array: count of objects (#{ctxs.length}) doesn't matches #{@count()}")

            for ctx in ctxs
                @object.__build(ctx, io)

            return io.data


    class @_Adapter extends @Base

        constructor: (@object,  @parser, @builder) ->

        __parse: (io, ctx) ->

            return @parser(@object.__parse(io, ctx), ctx)


        __build: (ctx, io) ->

            return @object.build(@builder(ctx), io)


    class @_Optional extends @Base

        constructor: (@object) ->

            @name = @object.name


        __parse: (io, ctx) ->

            io_position = io.shift

            try
                ret = @object.__parse(io, construct.copy(ctx))
                if ctx["_"]?
                    ret["_"] = ctx["_"]
                return ret

            catch error
                io.shift = io_position
                return ctx


        __build: (ctx, io) ->

            ios = construct.copy(io)

            try
                return @object.__build(io, ctx)

            catch error
                io.data = ios.data

    # shorthands for similar creation of "base" classes and "complex" ones

    @BaseInt: (args...) -> new @_BaseInt(args...)
    @CString: (args...) -> new @_CString(args...)
    @Struct: (args...) -> new @_Struct(args...)
    @Enum: (args...) -> new @_Enum(args...)
    @Const: (args...) -> new @_Const(args...)
    @Switch: (args...) -> new @_Switch(args...)
    @Pass: (args...) -> new @_Pass(args...)
    @OptionalGreedyRange: (args...) -> new @_OptionalGreedyRange(args...)
    @Array: (args...) -> new @_Array(args...)
    @Adapter: (args...) -> new @_Adapter(args...)
    @Optional: (args...) -> new @_Optional(args...)

    @EmbedStruct: (objecsts...) -> @Struct(null, objecsts...)
    @Tail: (name="tail") -> @OptionalGreedyRange(@ULInt8(name))
    @Bytes: (name, count) -> @Array(count, @ULInt8(name))

    @ULInt8: (name) -> @BaseInt(name, 1, "unsigned", "little")
    @ULInt16: (name) -> @BaseInt(name, 2, "unsigned", "little")
    @ULInt32: (name) -> @BaseInt(name, 4, "unsigned", "little")

    @UBInt8: (name) -> @BaseInt(name, 1, "unsigned", "big")
    @UBInt16: (name) -> @BaseInt(name, 2, "unsigned", "big")
    @UBInt32: (name) -> @BaseInt(name, 4, "unsigned", "big")

    @SLInt8: (name) -> @BaseInt(name, 1, "signed", "little")
    @SLInt16: (name) -> @BaseInt(name, 2, "signed", "little")
    @SLInt32: (name) -> @BaseInt(name, 4, "signed", "little")

    @SBInt8: (name) -> @BaseInt(name, 1, "signed", "big")
    @SBInt16: (name) -> @BaseInt(name, 2, "signed", "big")
    @SBInt32: (name) -> @BaseInt(name, 4, "signed", "big")
