console.log 'up!'
# first commit - read a default question (protobowl error lel)
wsx = require 'ws'
mongoose = require 'mongoose'
mongoose.connect process.env.DB
{RootHandler} = require './roothandler'
{Room} = require './room'
{Question} = require './question'
{Person} = require './person'

rooms = {}
guest = new Person('guest')

wss = new wsx.Server {port: process.env.PORT || 2020}

wss.broadcast = (data) ->
    wss.clients.forEach (ws) ->
        if ws.readyState == wsx.OPEN
            ws.send data
        return
    return
    
wss.on 'connection', (ws) ->
    ws.person = guest
    ws.room = ''
    ws.on 'message', (msg) ->
        rooms[ws.room].handle JSON.parse(msg), ws
        # so clean *fangirls about simplicity in code*
        # reader, you should have seen the old dynamix ws.onmessage function.
        return
    return
exports.rooms = rooms
exports.guest = guest
exports.wss = wss
rooms[''] = new RootHandler()
console.log 'exports ' + exports.wss? + ' ' + exports.rooms? + ' ' + exports.guest?