window.addEventListener 'keydown', (e) ->
    # stop that nasty autoscroll *shudder*
    if e.keyCode == 32 and e.target == document.body
        e.preventDefault()
    return
    
buzzing = false
chatting = false

openbuzz = () ->
    $('#main-input').attr 'placeholder', 'buzz...'
    $('#main-input').val ''
    $('#main-input').show()
    
    window.setTimeout () ->
        $('#main-input').focus()
        return
    , 30
    
    buzzing = true
    JSON.stringify {room: room, person: name, type: 'openbuzz'}
    
openchat = () ->
    $('#main-input').attr 'placeholder', 'buzz...'
    $('#main-input').val ''
    $('#main-input').show()
    
    window.setTimeout () ->
        $('#main-input').focus()
        return
    , 30
    
    chatting = true
    JSON.stringify {room: room, person: name, type: 'openchat'}
    
getInputVal = () ->
    val = $('#main-input').val()
    $('#main-input').hide()
    
    window.setTimeout () ->
        $('body').focus()
        return
    , 30
    
    val = {room: room, person: name, type: 'buzz', value: val} if buzzing
    val = {room: room, person: name, type: 'chat', value: val} else if chatting
    val = {} else
    buzzing = false
    chatting = false
    JSON.stringify val
    
search = () ->
    searchParameters = {
        query: $('#query').val(),
        categories: $('#categories').val(),
        subcategories: $('#subcategories').val(),
        difficulties: $('#difficulties').val(),
        tournaments: $('#tournaments').val(),
        searchType: $('#searchType').find(':selected').val()
    }
    JSON.stringify {room: room, person: name, type: 'search', searchParameters: searchParameters}
    
next = () ->
    JSON.stringify {room: room, person: name, type: 'next'}
        
pauseOrPlay = () ->
    JSON.stringify {room: room, person: name, type: 'pauseOrPlay'}
        
$(document).ready () ->
    $('.hide-on-start').hide()
    $('#button-controller').click () ->
        $('.btn-block').toggle()
        return    
    
    url = new URL window.location.href
    name = url.searchParams.get('name') || "comrade popov"
    room = window.location.pathname.substring(1)
    ws = new WebSocket 'wss://dynamix.herokuapp.com/'
    
    window.setInterval () ->
        ws.send "ping"
        return
    , 30000
    
    $(document).keyup () ->
        if event.which == 13
            ws.send getInputVal() if buzzing || chatting
            return
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
        
    ws.onclose = () ->
        $('#answer').after '<div class="alert alert-danger">kurwa, yuo have been disconnected from the server!</div>'
    return