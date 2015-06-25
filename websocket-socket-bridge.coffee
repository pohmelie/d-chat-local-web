class socket

    class @WebSocketBridge

        constructor: (@on_data, @on_disconnect, @on_error) ->

            @reset()

        reset: () ->

            @websocket_ok = false
            @socket = new WebSocket("ws://localhost:#{location.port}/bin")
            @socket.onmessage = @receive
            @socket.onopen = () => @websocket_ok = true
            @socket.onclose = () =>

                @websocket_ok = false
                @on_disconnect?()

            @socket.onerror = (e) =>

                @websocket_ok = false
                @on_error?(e.message)
                @on_disconnect?()

        connect: (address, port) =>

            @socket.send(
                JSON.stringify({
                    "type": "CONNECT",
                    "address": address,
                    "port": port
                })
            )
            return true

        disconnect: () =>

            @socket.send(JSON.stringify({"type": "DISCONNECT"}))
            return true

        send: (d) =>

            @socket.send(
                JSON.stringify({
                    "type": "DATA",
                    "data": d
                })
            )
            return true

        receive: (e) =>

            o = JSON.parse(e.data)
            switch o["type"]

                when "DATA"

                    @on_data?(o["data"])

                when "DISCONNECT"

                    @on_disconnect?()
