class Question
    constructor: (args) ->
        this = args
        return
        
    @getQuestions: (searchParams, room) ->
        model.count searchParams, (err, count) ->
        console.log 'there are ' + count  + ' documents found'
        if count > 1331
            console.log 'aggregating!'
            aggregateParams = [{$match: searchParams}, {$sample: {size: 1331}}]
            console.log JSON.stringify aggregateParams
            model.aggregate aggregateParams, (err, data) ->
                console.log 'there are ' + data.length + ' documents to be sent'
                if err?
                    console.log err.stack
                    return
                room.questions = data
                room.question = null
                room.next()
                return
            # comment
        else
            console.log 'regular finding!'
            model.find searchParams, (err, data) ->
                console.log 'there are ' + data.length + ' documents to be sent'
                if err?
                    console.log err.stack
                    return
                room.questions = data
                room.question = null
                room.next()
                return
            # comment
        return

        
        
exports.Question = Question