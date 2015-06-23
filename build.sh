#!/bin/bash

coffeescript-concat -I . -o d-chat-web.compiled d-chat-web.coffee
coffee -c -o static d-chat-web.compiled

coffeescript-concat -I . -o check-revision-background.compiled check-revision-background/check-revision-background.coffee
coffee -c -o static check-revision-background.compiled

rm *.compiled
