console.log 'up!'
# first commit - read a default question (protobowl error lel)
app = require('express')()
wsx = require('express-ws')(app)

mongoose = require 'mongoose'
mongoose.connect process.env.DB
{Room} = require './room'
{Question} = require './question'
{Person} = require './person'

rooms = {}
people = {
    'guest': new Person 'guest'
}

rooms[''] = { # a root handler, yay
    handle: (msg, ws) ->
        if msg.type == 'entry'
            ws.person = people[msg.person] || people.guest
            ws.room = msg.room
            if !rooms[msg.room]
                args = {name: msg.room, wss: wss}
                rooms[msg.room] = new Room args 
            rooms[msg.room][people[msg.person] || people.guest] = 0
            wss.broadcast JSON.stringify {
                timestamp: msg.timestamp,
                room: msg.room,
                person: msg.person,
                type: 'entry'
            }
        return
    # tabs
}

app.broadcast = (data) ->
    app.clients.forEach (ws) ->
        if ws.readyState == wsx.OPEN
            ws.send data
        return
    return
    
app.ws '/', (req, ws) ->
    ws.person = people.guest
    ws.room = ''
    console.log 'we got a ws!'
    ws.on 'message', (msg) ->
        rooms[ws.room].handle JSON.parse(msg), ws
        # so clean *fangirls about simplicity in code*
        # reader, you should have seen the old dynamix ws.onmessage function.
        return
    return
    
app.listen process.env.PORT || 2020
