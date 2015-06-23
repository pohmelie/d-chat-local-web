import asyncio
import json
import webbrowser

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
        ws.send_str(s)


@asyncio.coroutine
def websocket_handler(request):

    ws = web.WebSocketResponse()
    ws.start(request)
    reader = writer = None
    while True:

        msg = yield from ws.receive()
        if msg.tp != MsgType.text:

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

    yield from loop.create_server(app.make_handler(), "127.0.0.1", 8888)
    print("Server started at http://127.0.0.1:8888")


loop = asyncio.get_event_loop()
loop.run_until_complete(init(loop))
try:

    webbrowser.open("http://127.0.0.1:8888")
    loop.run_forever()

except KeyboardInterrupt:

    loop.close()

print("done")
