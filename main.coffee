console.log 'up!'
# first commit - read a default question (protobowl error lel)
app = require('express')()
wss = require('express-ws')(app)

# mongoose = require 'mongoose'
# mongoose.connect process.env.DB
{Room} = require './room'
{Question} = require './question'
{Person} = require './person'

app.ws '/', (ws, req) ->
    ws.person = Person.getPerson 'guest'
    ws.room = ''
    ws.on 'message', (msg) ->
        if msg == "ping"
            ws.send "pong"
            return
        rooms[ws.room].handle JSON.parse(msg), ws
        # so clean *fangirls about simplicity in code*
        # reader, you should have seen the old dynamix ws.onmessage function.
        return
    ws.on 'close', () ->
        rooms[ws.room].handle {room: ws.room, person: ws.person.name, type: 'exit'}, ws
    return

app.get '/', (req, res) ->
    res.send 'homepage coming soon! basically go to any path on this server and you\'ll make yourself a nice room which you can share.'
    return

app.get '/style.css', (req, res) ->
    res.sendFile __dirname+'/style.css'
    return

app.get '/client.js', (req, res) ->
    res.sendFile __dirname+'/client.js'
    return

app.get '/:room', (req, res) ->
    res.sendFile __dirname+'/index.html'
    return

rooms = {}

rooms[''] = { # a root handler, yay
    handle: (msg, ws) ->
        try
            if msg.type == 'entry'
                ws.person = Person.getPerson(msg.person) || Person.getPerson('guest')
                ws.room = msg.room
                if !rooms[msg.room]
                    args = {name: msg.room, wss: wss}
                    rooms[msg.room] = new Room args 
                rooms[msg.room][Person.getPerson(msg.person) || Person.getPerson('guest')] = 0
                wss.broadcast JSON.stringify {
                    timestamp: msg.timestamp,
                    room: msg.room,
                    person: msg.person,
                    type: 'entry'
                }
            return
        catch e
            # don't even do anything
            return
        return
    # tabs
}

htmlEncode = (text) -> # beware, messy regexes ahead
    rx = [
        [/&/g, '&amp;']
        [/</g, '&lt;']
        [new RegExp("'", 'g'), '&#39;']
        [new RegExp('"', 'g'), '&quot;']
    ]
    for r in rx
        text=text.replace r[0], r[1]
    return text

wss.broadcast = (data) ->
    data[person] = htmlEncode data[person] if data[person]
    data[value] = htmlEncode data[value] if data[value]
    wss.getWss().clients.forEach (ws) ->
        ws.send data
        return
    return
    
    
app.listen process.env.PORT || 2020, () ->
    console.log 'listening on ' + process.env.PORT || 2020
