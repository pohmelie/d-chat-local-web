"""d-chat-local-web

Usage: d-chat-local-web [options]

Options:
    --host=host             host for binding
    --port=port             port for binding [default: 8080]
"""
import asyncio
import json
import webbrowser

import docopt

from aiohttp import web, MsgType


@asyncio.coroutine
def base_handler(request):

    return web.Response(body=open("static/index.html", "rb").read())


@asyncio.coroutine
def socket_reader(ws, reader):

    while True:

        data = yield from reader.read(8192)
        if not data:

            break

        s = str.join(" ", map(lambda x: str.format("{:0>2x}", x), data))
        ws.send_str(json.dumps({"type": "DATA", "data": s}))

    if not ws.closed:

        ws.send_str(json.dumps({"type": "DISCONNECT"}))


@asyncio.coroutine
def websocket_handler(request):

    ws = web.WebSocketResponse()
    ws.start(request)
    reader = writer = None
    while not ws.closed:

        msg = yield from ws.receive()
        if msg.tp != MsgType.text:

            if writer:

                writer.close()

            break

        o = json.loads(msg.data)
        if o["type"] == "CONNECT":

            address, port = o["address"], int(o["port"])
            reader, writer = yield from asyncio.open_connection(address, port)
            asyncio.async(socket_reader(ws, reader))

        elif o["type"] == "DISCONNECT":

            if writer:

                writer.close()

            reader = writer = None

        elif o["type"] == "DATA":

            s = o["data"]
            bs = bytes(map(lambda x: int(x, 16), str.split(s)))
            writer.write(bs)

    return ws


@asyncio.coroutine
def init(loop):

    app = web.Application(loop=loop)
    app.router.add_route("GET", "/", base_handler)
    app.router.add_route("GET", "/bin", websocket_handler)
    app.router.add_static("/", "static")

    server = yield from loop.create_server(
        app.make_handler(),
        args["--host"],
        int(args["--port"]),
    )
    host, port = server.sockets[0].getsockname()

    print(str.format("Server started at {}:{}", host, port))
    webbrowser.open(str.format("http://127.0.0.1:{}", port))


args = docopt.docopt(__doc__)
loop = asyncio.get_event_loop()
loop.run_until_complete(init(loop))
try:

    loop.run_forever()

except KeyboardInterrupt:

    loop.close()

print("done")
