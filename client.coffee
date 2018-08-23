$(document).ready () ->
    buzzing = false
    chatting = false
    $('.btn-block').hide()
    $('#button-controller').click () ->
        if $('.btn-block').is(':hidden')
            $('.btn-block').show()
            return
        $('.btn-block').hide()
        return    
    url = new URL window.location.href
    name = url.searchParams.get('name') || "comrade popov"
    room = window.location.pathname.substring(1)
    ws = new WebSocket 'wss://dynamix.herokuapp.com/'
    $(document).keyup () ->
        if event.which == 13
            if buzzing
                ws.send buzz()
            else if chatting
                ws.send chat()
            else
                # eh
        else if event.which = 32
            openbuzz()
        else if event.which == 83
            ws.send search()
        else if event.which == 67 || event.which == 191
            openchat()
        return
    render = (msg) ->
        return
    ws.onmessage  = (event) ->
        $('#answer').after '<div class="msg">'+event.data+'</div>'
        return    
    ws.onopen = () ->
        ws.send JSON.stringify {
            room: room,
            person: name,
            type: 'entry'
        }
        return
    return