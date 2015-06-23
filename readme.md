#d-chat-local-web
Almost pure client-side rubattle.net chat client. «Almost», cause we still need real sockets.

##Reasons:
* Crossplatform
* Browser application
* Utf-8
* Tabbed interface
* Autotrade
* Autocomplete
* Calculator

## Requirements
###Bundle
* Firefox/Chrome

###Source
* Firefox/Chrome
* Python3.4+
* aiohttp

Some parts of this project can be used in other ones. Like:
* bit32 — subset of lua bit32 library for 'proper' bit shifts (no, js shifts is **not** good ones)
* construct — subset of python construct library (python construct is just awesome!)
* convert — utf-8 <-> bin <-> hex string convertion library (it's just for real-socket <-> js bridge)
