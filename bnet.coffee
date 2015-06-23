#= require <construct.coffee>
#= require <convert.coffee>
#= require <xsha1.coffee>
#= require <bnutil.coffee>
#= require <packets.coffee>


class bnet

    class @Bnet

        constructor: (@host, @port, @connect, _send, @login_error=(() ->), @chat_event=(() ->)) ->

            @send = (data) -> _send(convert.bin2hex(data))
            @lock = false


        login: (@username, password, hashed) =>

            if hashed

                @hashpass = password

            else

                @hashpass = xsha1.bsha1(convert.str2bin(password))

            @head = []

            if not @connect(@host, @port)

                @login_error("Connecting to server")
                return

            @send([1])
            @send(
                packets.spacket.build(
                    construct.linkify({
                        packet_id:"SID_AUTH_INFO",
                        protocol_id:0,
                        platform_id:convert.str2bin('68XI'),
                        product_id:convert.str2bin('PX2D'),
                        version_byte:13,
                        product_language:convert.str2bin('SUne'),
                        local_ip:[192, 168, 0, 100],
                        time_zone:-300,
                        locale_id:1049,
                        language_id:1049,
                        country_abreviation:'RUS',
                        country:'Russia',
                    })
                )
            )

        say: (msg) ->
            @send(
                packets.spacket.build(
                    construct.linkify({
                        packet_id:"SID_CHATCOMMAND",
                        text:msg,
                    })
                )
            )

        on_packet: (msg) =>

            unparsed = packets.rpackets.parse(@head.concat(convert.hex2bin(msg)))
            @head = unparsed.tail

            for pack in unparsed.rpackets

                switch pack.packet_id

                    when "SID_PING"

                        @send(packets.spacket.build(pack))

                    when "SID_AUTH_INFO"

                        @client_token = 666
                        @server_token = pack.server_token

                        [clpub, clhash] = bnutil.hash_d2key(
                            "DPTGEGHRPH4EB7EV",
                            @client_token,
                            @server_token
                        )

                        [lodpub, lodhash] = bnutil.hash_d2key(
                            "KFE6H7RPTRTHDEJE",
                            @client_token,
                            @server_token
                        )

                        w = new Worker("check-revision-background.js")
                        w.onmessage = (event) =>
                            info = JSON.parse(event.data)
                            if info.done
                                @send(
                                    packets.spacket.build(
                                        construct.linkify({
                                            packet_id:"SID_AUTH_CHECK",
                                            client_token:@client_token,
                                            exe_version:0x01000d00,
                                            exe_hash:info.result,
                                            number_of_cd_keys:2,
                                            spawn_cd_key:0,
                                            cd_keys:[
                                                {
                                                    key_length:16,
                                                    cd_key_product:6,
                                                    cd_key_public:clpub,
                                                    hash:clhash,
                                                },
                                                {
                                                    key_length:16,
                                                    cd_key_product:12,
                                                    cd_key_public:lodpub,
                                                    hash:lodhash,
                                                },
                                            ],
                                            exe_info:"Game.exe 10/18/11 20:48:14 65536",
                                            cd_key_owner:"yoba",
                                        })
                                    )
                                )
                                w.terminate()

                        w.postMessage(JSON.stringify([pack.seed_values, pack.file_name]))

                        ###
                        @send(
                            packets.spacket.build(
                                construct.linkify({
                                    packet_id:"SID_AUTH_CHECK",
                                    client_token:@client_token,
                                    exe_version:0x01000d00,
                                    exe_hash:bnutil.check_revision(
                                        pack.seed_values,
                                        pack.file_name
                                    ),
                                    number_of_cd_keys:2,
                                    spawn_cd_key:0,
                                    cd_keys:[
                                        {
                                            key_length:16,
                                            cd_key_product:6,
                                            cd_key_public:clpub,
                                            hash:clhash,
                                        },
                                        {
                                            key_length:16,
                                            cd_key_product:12,
                                            cd_key_public:lodpub,
                                            hash:lodhash,
                                        },
                                    ],
                                    exe_info:"Game.exe 10/18/11 20:48:14 65536",
                                    cd_key_owner:"yoba",
                                })
                            )
                        )
                        ###

                    when "SID_AUTH_CHECK"

                        if pack.result != 0

                            @login_error(pack.packet_id, pack.result)

                        else

                            @send(
                                packets.spacket.build(
                                    construct.linkify({
                                        packet_id:"SID_LOGONRESPONSE2",
                                        client_token:@client_token,
                                        server_token:@server_token,
                                        hash:bnutil.sub_double_hash(
                                            @client_token,
                                            @server_token,
                                            @hashpass
                                        ),
                                        username:@username,
                                    })
                                )
                            )

                    when "SID_LOGONRESPONSE2"

                        if pack.result != 0

                            @login_error(pack.packet_id, pack.result)

                        else

                            @send(
                                packets.spacket.build(
                                    construct.linkify({
                                        packet_id:"SID_ENTERCHAT",
                                        username:@username,
                                        statstring:"",
                                    })
                                )
                            )

                    when "SID_ENTERCHAT"

                        @send(
                            packets.spacket.build(
                                construct.linkify({
                                    packet_id:"SID_JOINCHANNEL",
                                    unknown:5,
                                    channel_name:"Diablo II",
                                })
                            )
                        )

                    when "SID_CHATEVENT"

                        @chat_event(pack)

                    else

                        console.log(pack)

            return
