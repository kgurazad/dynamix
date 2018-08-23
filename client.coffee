window.addEventListener 'keydown', (e) ->
    # stop that nasty autoscroll *shudder*
    if e.keyCode == 32 and e.target == document.body
        e.preventDefault()
    return

$(document).ready () ->
    $('.hide-on-start').hide()
    buzzing = false
    chatting = false
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
    winsow.setInterval () ->
        ws.send "ping"
        return
    , 30000
    openbuzz = () ->
        $('#main-input').attr 'placeholder', 'buzz...'
        $('#main-input').val ''
        $('#main-input').show()
        window.setTimeout () ->
            $('#main-input').focus()
            return
        , 30
        buzzing = true
        return JSON.stringify {
            room: room,
            person: name,
            type: 'openbuzz'
        }
        return
    openchat = () ->
        $('#main-input').attr 'placeholder', 'buzz...'
        $('#main-input').show()
        window.setTimeout () ->
            $('#main-input').focus()
            return
        , 30
        chatting = true
        return JSON.stringify {
            room: room,
            person: name,
            type: 'openchat'
        }
    getInputVal = () ->
        val = $('#main-input').val()
        $('#main-input').hide()
        window.setTimeout () ->
            $('body').focus()
            return
        , 30
        if buzzing
            val = {
                room: room,
                person: name, 
                type: 'buzz',
                value: val
            }
        else if chatting
            val = {
                room: room,
                person: name, 
                type: 'chat',
                value: val
            }
        else
            val = {}
        buzzing = false
        chatting = false
        return JSON.stringify val
    $(document).keyup () ->
        if event.which == 13
            if buzzing || chatting
                ws.send getInputVal()
            else
                # eh
        if document.activeElement.tagName != 'BODY'
            return
        else if event.which == 32
            ws.send openbuzz()
        else if event.which == 67 || event.which == 191
            ws.send openchat()
        else if event.which == 83
            ws.send search()
        else if event.which == 78
            ws.send next()
        else if event.which == 80
            ws.send pauseOrPlay()
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