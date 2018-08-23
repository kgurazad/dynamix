class Person
    constructor: (name) ->
        @name = name
        return
    
    @people = {
        guest: new Person 'guest'
    }
    @getPerson: (name) ->
        person = @people[name]
        if !person
            person = new Person name
            @people[name] = person
        return person
        
exports.Person = Person