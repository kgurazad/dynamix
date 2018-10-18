window.addEventListener 'keydown', (e) ->
    # stop that nasty autoscroll *shudder*
    if e.keyCode == 32 and e.target == document.body
        e.preventDefault()
    return
    
buzzing = false
chatting = false
word = 0

openbuzz = () ->
    $('#main-input').attr 'placeholder', 'buzz...'
    $('#main-input').val ''
    $('#main-input').show()
    
    window.setTimeout () ->
        $('#main-input').focus()
        return
    , 30
    
    buzzing = true
    JSON.stringify {room: window.room, person: window.name, type: 'openbuzz'}
    
openchat = () ->
    $('#main-input').attr 'placeholder', 'chat...'
    $('#main-input').val ''
    $('#main-input').show()
    
    window.setTimeout () ->
        $('#main-input').focus()
        return
    , 30
    
    chatting = true
    JSON.stringify {room: window.room, person: window.name, type: 'openchat'}
    
getInputVal = () ->
    val = $('#main-input').val()
    $('#main-input').hide()
    
    window.setTimeout () ->
        $('body').focus()
        return
    , 30
    
    val = {room: window.room, person: window.name, type: 'buzz', value: val} if buzzing
    val = {room: window.room, person: window.name, type: 'chat', value: val} if chatting
    val = {} if !buzzing && !chatting
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
    JSON.stringify {room: window.room, person: window.name, type: 'search', searchParameters: searchParameters}
    
next = () ->
    JSON.stringify {room: window.room, person: window.name, type: 'next', readSpeed: Number($('#readSpeed').val())}
        
pauseOrPlay = () ->
    JSON.stringify {room: window.room, person: window.name, type: 'pauseOrPlay'}
        
$(document).ready () ->
    $('.hide-on-start').hide()
    
    url = new URL window.location.href
    window.name = url.searchParams.get('name') || "comrade popov"
    window.room = window.location.pathname.substring(1)
    window.ws = new WebSocket 'wss://dynamix.herokuapp.com/'
    
    $('#s').click () ->
        window.ws.send search()
        return
    $('#c').click () ->
        window.ws.send openchat()
        return
    $('#n').click () ->
        window.ws.send next()
        return
    $('#p').click () ->
        window.ws.send pauseOrPlay()
        return
    $('#b').click () ->
        window.ws.send openbuzz()
        return
    $('#button-controller').click () ->
        $('.btn-block').toggle()
        return    
    
    window.setInterval () ->
        ws.send "ping"
        return
    , 30000
    
    $(document).keyup () ->
        if event.which == 13
            window.ws.send getInputVal() if buzzing || chatting
            return
        if document.activeElement.tagName != 'BODY'
            return
        else if event.which == 32
            window.ws.send openbuzz()
        else if event.which == 67 || event.which == 191
            window.ws.send openchat()
        else if event.which == 83
            window.ws.send search()
        else if event.which == 78
            window.ws.send next()
        else if event.which == 80
            window.ws.send pauseOrPlay()
        return
        
    render = (msg) ->
        if msg.type == 'entry'
            $('#answer').after '<div><i>' + msg.person + ' entered the room</i></div>'
        else if msg.type == 'exit'
            $('#answer').after '<div><i>' + msg.person + ' left the room</i></div>'
        else if msg.type == 'openbuzz'
            if msg.approved
                $('#question').append '(#) '
                $('#answer').after '<div><i>' + msg.person + ' buzzed</i></div>'
            else
                $('#answer').after '<div><i>' + msg.person + ' attempted an invalid buzz</i></div>'
        else if msg.type == 'buzz'
            $('#answer').after '<div><strong>' + msg.person + '</strong> ' + msg.value + '</div>'
        else if msg.type == 'word'
            $('#question').append msg.value + ' '
            word++
        else if msg.type == 'next'
            word = 0
            $('#question').text ''
            $('#metadata').empty()
            $('#metadata').append('<li class="breadcrumb-item">'+msg.meta.tournament.year+' '+msg.meta.tournament.name+'</li>')
            $('#metadata').append('<li class="breadcrumb-item">Difficulty Level '+msg.meta.difficulty+'</li>')
            $('#metadata').append('<li class="breadcrumb-item">'+msg.meta.category+'</li>')
            $('#metadata').append('<li class="breadcrumb-item">'+msg.meta.subcategory+'</li>')
            $('#metadata').append('<li class="breadcrumb-item">QuizDB ID #'+msg.meta.id+'</li>')
            $('#answer').text 'Press [space] to buzz.'
        else if msg.type == 'search'
            $('#answer').after '<div><i>' + msg.person + ' searched for questions</i></div>'
        else if msg.type == 'chat'
            $('#answer').after '<div><strong>' + msg.person + '</strong> ' + msg.value + '</div>'
        else if msg.type == 'pauseOrPlay'
            $('#question').append '(+) '
        else if msg.type == 'finishQuestion'
            console.log msg
            text = msg.question.text.question.split ' '
            while word < text.length
                $('#question').append text[word] + ' '
                word++
            $('#answer').text msg.question.text.answer.original
        return
        
    window.ws.onmessage  = (event) ->
        render JSON.parse event.data if event.data != 'pong'
        return    
        
    window.ws.onopen = () ->
        ws.send JSON.stringify {
            room: room,
            person: name,
            type: 'entry'
        }
        return
        
    window.ws.onclose = () ->
        $('#answer').after '<div class="alert alert-danger">kurwa, yuo have been disconnected from the server!</div>'
    return