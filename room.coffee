{Question} = require './question'

class Room

    createRoom: (args) ->
        return
        
    constructor: (args) ->
        # get or create from mongodb (one method, returns either the new or old)
        # ttl = 1 week
        @name = args.name
        @question = args.question || new Question()
        @readSpeed = args.readSpeed || 200
        @timeout = args.timeout || 6000
        @people = args.people || {}
        @wss = args.wss
        @word = 0
        @questionText = @question.text.question.split ' '
        @interval = null
        @currentlyBuzzing = null
        @questionFinished = false
        return
        
    refreshQuestion: () ->
        @question = new Question();
        @word = 0;        
        
    finishQuestion: () ->
        @wss.broadcast {
            room: @name,
            type: 'finishQuestion',
            answer: @question.text.answer
        }
        
    handle: (msg, ws) ->
        if msg.type == 'next'
            @refreshQuestion()
            self = this
            @interval = global.setInterval () ->
                self.wss.broadcast JSON.stringify {
                    room: self.name,
                    type: 'word',
                    text: self.questionText[self.word]
                }
                self.word++
                if self.word == self.questionText.length
                    self.wss.broadcast JSON.stringify {
                        room: self.name,
                        type: 'endedQuestion',
                        timeout: self.timeout
                    }
                    global.clearInterval self.interval
                    self.setTimeout () ->
                        self.finishQuestion()
                    , self.timeout
                # read word and increment
                # don't forget finishing and whatnot
                return
            , @readSpeed    
        @wss.broadcast JSON.stringify msg
        return
        
exports.Room = Room
