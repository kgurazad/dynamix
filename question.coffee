mongoose = require 'mongoose'
mongoose.connect process.env.DB
schema = mongoose.Schema({
    text: Object,
    difficulty: Number,
    tournament: Object,
    category: String,
    subcategory: String
})
model = mongoose.model('qs',schema,'raw-quizdb-clean')

split = (str, separator) ->  
    if str.length == 0
        return []
    str.split separator

mergeSpaces = (arr) ->
    res = ''
    for str in arr
        res += ' '
        res += str
    return res.slice 1


escapeRegExp = (str) ->
    str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, '\\$&'

class Question
    constructor: (args) ->
        # I swear I don't care
        return
        
    @getQuestions: (initSearchParams, room) ->
        queryString = escapeRegExp initSearchParams.query
        query = {}
        categories = split initSearchParams.categories, ','
        subcategories = split initSearchParams.subcategories, ','
        difficulties = split initSearchParams.difficulties, ','
        tournamentsRaw = split initSearchParams.tournaments, ','
        tournaments = {$or: []} # as it is in the mongodb
        searchType = initSearchParams.searchType
        # basically get the same setup as in quizbug2
        searchParams = {$and: []}

        for k,v of difficulties
          difficulties[k] = Number v
    
        if tournamentsRaw.length == 0
            tournaments = {'tournament': {$exists: true}}
        for tournament in tournamentsRaw
            tSplit = split tournament, ' '
            console.log tSplit
            try
                year = Number tSplit[0]
                if !year
                    throw "nan"
                if tSplit.length == 1
                    tournaments.$or.push {'tournament.year': year, 'tournament.name': {$exists: true} }
                else
                    tournaments.$or.push {'tournament.year': year, 'tournament.name': mergeSpaces tSplit.slice 1 }
            catch e
                tournaments.$or.push {'tournament.year': {$exists: true}, 'tournament.name': mergeSpaces tSplit }
    
        if tournamentsRaw.length == 1
            tournaments = tournaments.$or[0]
    
        if searchType == 'qa'
            query.$or = []
            query.$or.push {'text.question': {$regex: new RegExp(queryString, 'i')}}
            query.$or.push {'text.answer': {$regex: new RegExp(queryString, 'i')}}
        else if searchType == 'q'
            query = {'text.question': {$regex: new RegExp(queryString, 'i')}}
        else
            query = {'text.answer': {$regex: new RegExp(queryString, 'i')}}
        if queryString == ''
            query = {'text': {$exists: true}}

        searchParams.$and.push query
        searchParams.$and.push tournaments
        searchParams['difficulty'] = {$in: difficulties}
        searchParams['category'] = {$in: categories}
        searchParams['subcategory'] = {$in: subcategories}
    
        if difficulties.length == 0
            delete searchParams['difficulty']
          
        if categories.length == 0
            delete searchParams['category']
          
        if subcategories.length == 0
            delete searchParams['subcategory']
        # yay
        model.count searchParams, (err, count) ->
            if count > 1331
                aggregateParams = [{$match: searchParams}, {$sample: {size: 1331}}]
                model.aggregate aggregateParams, (err, data) ->
                    if err?
                        console.log err.stack
                        return
                    room.questions = data
                    room.question = null
                    room.finishQuestion()
                    room.next()
                    return
                # comment
            else
                model.find searchParams, (err, data) ->
                    if err?
                        console.log err.stack
                        return
                    room.questions = data
                    room.question = null
                    room.finishQuestion()
                    room.next()
                    return
                # comment
            return
        return

        
        
exports.Question = Question