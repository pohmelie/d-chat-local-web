class socket

    class @WebSocketBridge

        constructor: (@on_data, @on_error) ->

            @websocket_ok = false
            @socket = new WebSocket("ws://localhost:8888/bin")
            @socket.onopen = () => @websocket_ok = true
            @socket.onclose = () => @websocket_ok = false
            @socket.onmessage = (e) => @on_data(e.data)

        connect: (address, port) =>

            console.log("connect", address, port)
            @socket.send(
                JSON.stringify({
                    "type": "CONNECT",
                    "address": address,
                    "port": port
                })
            )
            return true

        disconnect: () =>

            console.log("disconnect")
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
