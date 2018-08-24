{Question} = require './question'
{Person} = require './person'

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
        @personCurrentlyBuzzing = null
        @questionFinished = false
        return
        
    next: () ->
        @personCurrentlyBuzzing = null
        @questionFinished = false
        self = this
        @interval = global.setInterval () ->
            if self.pause
                return
            self.wss.broadcast JSON.stringify {
                room: self.name,
                type: 'word',
                value: self.questionText[self.word]
            }
            self.word++
            if self.word == self.questionText.length
                self.wss.broadcast JSON.stringify {
                    room: self.name,
                    type: 'endedQuestion',
                    timeout: self.timeout
                }
                global.clearInterval self.interval
                global.setTimeout () ->
                    self.finishQuestion()
                , self.timeout
            # read word and increment
            # don't forget finishing and whatnot
            return
        , @readSpeed
        return  
        
    refreshQuestion: () ->
        @question = new Question();
        @questionText = @question.text.question.split ' '
        @word = 0
        return
        
    finishQuestion: () ->
        console.log 'finishing'
        @wss.broadcast JSON.stringify {
            room: @name,
            type: 'finishQuestion',
            question: @question
        }
        global.clearInterval @interval
        @questionFinished = true
        return
        
    handle: (msg, ws) ->
        toFinish = false
        if ws.person != Person.getPerson msg.person
            ws.close()
            return
        if msg.type == 'next'
            @refreshQuestion()
            meta = {tournament: @question.tournament, difficulty: @question.difficulty, category: @question.category, subcategory: @question.subcategory}
            msg.meta = meta
            @next()
        else if msg.type == 'pauseOrPlay'
            @pause = !@pause
        else if msg.type == 'openbuzz'
            if @personCurrentlyBuzzing || @questionFinished
                msg.approved = false
            else
                @personCurrentlyBuzzing = Person.getPerson msg.person
                msg.approved = true
                @pause = true
            #
        else if msg.type == 'buzz'
            @pause = false
            if !@personCurrentlyBuzzing
                return
            if @personCurrentlyBuzzing.name != msg.person # fix this
                return
            toFinish = true
            @personCurrentlyBuzzing = null 
        @wss.broadcast JSON.stringify msg
        @finishQuestion() if toFinish
        return
        
exports.Room = Room
