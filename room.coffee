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
        @readSpeed = args.readSpeed || 120
        @timeout = args.timeout || 6000
        @people = args.people || {}
        @wss = args.wss
        @word = 0
        @questions = null
        @question = null
        @questionText = null
        @interval = null
        @personCurrentlyBuzzing = null
        @questionFinished = false
        @pause = false
        @alreadyBuzzed = []
        @inPower = false;
        return
        
    next: () ->
        console.log @people
        @finishQuestion()
        @questionEnded = false
        @alreadyBuzzed = []
        @word = 0
        qIndex = @questions.indexOf @question
        qIndex++
        qIndex = qIndex % @questions.length
        @question = @questions[qIndex]
        @inPower = true if @question.text.question.includes '*'
        @questionText = @question.text.question.split ' '
        @wss.broadcast JSON.stringify {
            room: @name,
            type: 'next',
            meta: {tournament: @question.tournament, difficulty: @question.difficulty, category: @question.category, subcategory: @question.subcategory}
        }
        @personCurrentlyBuzzing = null
        @questionFinished = false
        @finishTimeout = null
        self = this
        @interval = global.setInterval () ->
            if self.pause || self.questionFinished
                return
            toSend = self.questionText[self.word]
            self.inPower = false if toSend.includes '*'
            self.wss.broadcast JSON.stringify {
                room: self.name,
                type: 'word',
                value: toSend
            }
            self.word++
            if self.word == self.questionText.length
                self.wss.broadcast JSON.stringify {
                    room: self.name,
                    type: 'endedQuestion',
                    timeout: self.timeout
                }
                self.questionEnded = true
                global.clearInterval self.interval
                self.finishTimeout = global.setTimeout () ->
                    self.finishQuestion()
                , self.timeout
            # read word and increment
            # don't forget finishing and whatnot
            return
        , @readSpeed
        return  
        
    finishQuestion: () ->
        @pause = false
        global.clearInterval @interval
        @questionFinished = true
        if !@question
            return
        @wss.broadcast JSON.stringify {
            room: @name,
            type: 'finishQuestion',
            question: @question
        }
        return
        
    handle: (msg, ws) ->
       try
            console.log msg.type + " thonk"
            if msg.type == 'entry'
                @people[msg.person] = 0
                console.log 'added ' + msg.person
                console.log @people
            else if msg.type == 'next'
                @readSpeed = msg.readSpeed
                msg = {}
                @next()
            else if msg.type == 'pauseOrPlay'
                @pause = !@pause
            else if msg.type == 'search'
                Question.getQuestions msg.searchParameters, this
            else if msg.type == 'openbuzz'
                if @personCurrentlyBuzzing? || @questionFinished || (@alreadyBuzzed.indexOf(msg.person) != -1)
                    console.log @personCurrentlyBuzzing?
                    console.log @questionFinished
                    console.log @alreadyBuzzed.indexOf msg.person
                    msg.approved = false
                else
                    @personCurrentlyBuzzing = msg.person
                    @alreadyBuzzed.push msg.person
                    msg.approved = true
                    @pause = true
                    self = this
                    @buzzTimeout = global.setTimeout () ->
                        if self.personCurrentlyBuzzing == @x
                            msg.verdict = 3
                            if !self.questionEnded
                                self.people[self.personCurrentlyBuzzing] = self.people[self.personCurrentlyBuzzing] - 5
                            self.wss.broadcast JSON.stringify {room: self.name, person: self.personCurrentlyBuzzing, type: 'buzz', value: '', verdict: 3}
                            self.personCurrentlyBuzzing = null
                            self.pause = false
                        return
                    , @timeout
                    @buzzTimeout.x = @personCurrentlyBuzzing
                #
            else if msg.type == 'buzz'
                @pause = false
                if !@personCurrentlyBuzzing
                    return
                if @personCurrentlyBuzzing != msg.person # fix this
                    return
                toFinish = true
                msg.verdict = Question.match @question, msg.value
                if msg.verdict == 0
                    if @inPower
                        @people[@personCurrentlyBuzzing] = @people[@personCurrentlyBuzzing] + 15
                    else
                        @people[@personCurrentlyBuzzing] = @people[@personCurrentlyBuzzing] + 10
                    #
                else if msg.verdict == 1
                    @people[@personCurrentlyBuzzing] -= 5 if !@questionEnded
                @personCurrentlyBuzzing = null 
            @wss.broadcast JSON.stringify msg
            @finishQuestion() if toFinish
        catch e
            console.log e.stack
            @wss.broadcast 'temporary error'
        return
        
exports.Room = Room
