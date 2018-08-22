$(document).ready () ->
    url = new URL window.location.href
    name = url.searchParams.get('name') || "comrade popov"
    room = window.location.pathname.substring(1)
    ws = new WebSocket 'wss://dynamix.herokuapp.com/'
    $(document).keyup () ->
        if event.which == 13
        else if event.which == 83
            ws.send search()
        else if event.which == 67 || event.which == 191
            openchat()
        else if 
        return
    render = (msg) ->
        return    
    ws.onopen = () ->
        ws.send JSON.stringify {
            room: room,
            person: name,
            type: 'entry'
        }
        return
    ws.onmessage  = (msg) ->
        render msg
        return
    return