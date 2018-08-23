console.log 'up!'
# first commit - read a default question (protobowl error lel)
app = require('express')()
wss = require('express-ws')(app)

mongoose = require 'mongoose'
mongoose.connect process.env.DB
{Room} = require './room'
{Question} = require './question'
{Person} = require './person'

app.ws '/', (ws, req) ->
    console.log 'we got a ws!'
    ws.person = Person.getPerson 'guest'
    ws.room = ''
    ws.on 'message', (msg) ->
        console.log 'msg:'
        console.log msg
        if msg == "ping"
            ws.send "pong"
            return
        rooms[ws.room].handle JSON.parse(msg), ws
        # so clean *fangirls about simplicity in code*
        # reader, you should have seen the old dynamix ws.onmessage function.
        return
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
        if msg.type == 'entry'
            ws.person = people[msg.person] || people.guest
            ws.room = msg.room
            if !rooms[msg.room]
                args = {name: msg.room, wss: wss}
                rooms[msg.room] = new Room args 
            rooms[msg.room][Person.getPerson(msg.person)] || Person.getPerson('guest')] = 0
            wss.broadcast JSON.stringify {
                timestamp: msg.timestamp,
                room: msg.room,
                person: msg.person,
                type: 'entry'
            }
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
    for k, v of data
        data[k] = htmlEncode v
    wss.getWss().clients.forEach (ws) ->
        ws.send data
        return
    return
    
    
app.listen process.env.PORT || 2020, () ->
    console.log 'listening on ' + process.env.PORT || 2020
