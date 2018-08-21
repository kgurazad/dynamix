console.log 'up!'
# first commit - read a default question (protobowl error lel)
wss = require('express')()
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

wss = new wsx.Server {port: process.env.PORT || 2020}

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

wss.broadcast = (data) ->
    wss.clients.forEach (ws) ->
        if ws.readyState == wsx.OPEN
            ws.send data
        return
    return
    
wss.on 'connection', (ws) ->
    ws.person = people.guest
    ws.room = ''
    ws.on 'message', (msg) ->
        rooms[ws.room].handle JSON.parse(msg), ws
        # so clean *fangirls about simplicity in code*
        # reader, you should have seen the old dynamix ws.onmessage function.
        return
    return
