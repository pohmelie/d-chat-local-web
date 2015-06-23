@onmessage = (event) ->
    [seed_values, file_name] = JSON.parse(event.data)

    postMessage(
        JSON.stringify({
            done:false,
            result:null,
            percents:0,
        })
    )

    load_files(
        ["d2xp/Game.dll", "d2xp/Bnclient.dll", "d2xp/D2Client.dll"],
        ((d) => check_revision(seed_values, file_name, d))
    )


load_files = (fnames, on_ready, d=[], i=0, prev=null) ->

    if prev isnt null
        d.push(new Uint32Array(prev.response))

    if i < fnames.length
        t = new XMLHttpRequest()
        t.open("GET", fnames[i], true)
        t.responseType = "arraybuffer"
        t.onload = () -> load_files(fnames, on_ready, d, i + 1, t)
        t.send()

    else
        on_ready(d)


mpq_hash_codes = [
    0xE7F4CB62,
    0xF6A14FFC,
    0xAA5504AF,
    0x871FCDC2,
    0x11BF6A18,
    0xC57292E6,
    0x7927D27E,
    0x2FEC8733
]


make_unsigned = (n) ->

    return (n & 0xffffffff) >>> 0


check_revision = (formula, mpq, a) ->

    bin = new Uint32Array(a.reduce(((x, y) -> x + y.length), 0))
    offset = 0
    a.forEach((x) ->
        bin.set(x, offset)
        offset += x.length
    )

    mpq_hash = mpq_hash_codes[Number(mpq[9])]
    exprs = formula.split(" ")
    init = exprs[0..2].join(";") + ";"

    body = ""
    for i in [4...(4 + Number(exprs[3]))]
        [k, v] = exprs[i].split("=")
        body += "#{k}=make_unsigned(#{v});"

    A = B = C = S = i = 0
    step_count = 100
    step = Math.ceil(bin.length / step_count)
    body = "for(i = 0; i != bin.length; i++){S = bin[i];" + body
    tail = """
        if(i % step == 0)postMessage(
            JSON.stringify({
                done:false,
                result:null,
                percents:(i / step / step_count * 100)
            })
        );
    }
    """

    eval(init)
    A ^= mpq_hash
    eval(body + tail)

    return postMessage(
        JSON.stringify({
            done:true,
            result:C,
            percents:100
        })
    )
