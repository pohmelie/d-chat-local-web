help_message = (delimiter) -> """
d-chat-web help information.
Commands:

    #{delimiter}echo message
        Print message to screen without sending to battle.net.

    #{delimiter}connect account password
        Disconnect if connected and connect to battle.net.

    #{delimiter}disconnect
        Disconnect from battle.net.

    #{delimiter}reload
        Reloads 'init' file. 'init' file loads on start and simply executes like user input.

    #{delimiter}autoscroll
        Switch autoscroll on/off. Default 'on'.

    #{delimiter}help
        Show help information.

    #{delimiter}tab-mode
        Switch tab-mode on/off. Default 'on'.

    #{delimiter}autotrade-message message
    #{delimiter}atm message
        Set autotrade message.

    #{delimiter}autotrade-timeout timeout
        Set autotrade timeout in seconds. Default 300.

    #{delimiter}autotrade-activity count
        Set autotrade use-activity value. When use-activity mode is on, autotrade message won't appear before 'count' messages. This is good for 'not to spam' and 'be quiet'. Default 10.

    #{delimiter}autotrade-start
        Start autotrade loop.

    #{delimiter}autotrade-stop
        Stop autotrade loop.

    #{delimiter}autotrade-info
        Show current state of autotrade.

    #{delimiter}calc actions
        Stack oriented rune calculator without memory. 'actions' — space-separated sequence of commands. Available commands:

            count {'pul', ..., 'jah'}
                Put 'count' (1 if omitted) runes on stack. You can only use runes from 'pul' to 'jah'.

            p
                Print stack with \"highest\" rune 'jah'.

            to {'pul', ..., 'jah'}
                Print stack with specified \"highest\" rune.

            c
                Clear stack.

            t
                Show stack size in \"trains\" (7 mules average hellforge rune drop).

            count'%'
                Print 'count' percents of stack.

        Example:

            Input:
                #{delimiter}calc 15 pul um p -1 pul p to ist 25% t c t

            Output:
                1 gul, 1 pul
                1 gul
                2 ist
                25% of stack = 1 mal
                Trains count: 1
                Trains count: 0
                Stack: stack is empty.

    #{delimiter}clear-local-storage
        Erase local options.

    #{delimiter}clear-screen
        Clear main tab.


Shortcuts:

    ctrl + right/left
        Switch to next/previous tab.

    ctrl + w
        Close current tab.

    ctrl + s
        Switch autotrade on/off.

    ctrl + r
        Same as '#{delimiter}reload'.

    ctrl + d
        Same as '#{delimiter}disconnect'.

    ctrl + i
        Same as '#{delimiter}autotrade-info'.

    ctrl + m
        Switch to main tab.

    up/down
        Browse commands history.

    tab
        Request autocomplete. Autocompletes if there is one possibility, prints all possibilities else.
"""
