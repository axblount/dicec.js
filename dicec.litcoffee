dicec.js
========

Dice combinators for javascript.

Distributed under the terms of the [Apache License 2.0](https://github.com/axblount/dicec/blob/master/LICENSE).

>  Copyright 2015 Alex Blount

>  Licensed under the Apache License, Version 2.0 (the "License");
>  you may not use this file except in compliance with the License.
>  You may obtain a copy of the License at

>      http://www.apache.org/licenses/LICENSE-2.0

>  Unless required by applicable law or agreed to in writing, software
>  distributed under the License is distributed on an "AS IS" BASIS,
>  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
>  See the License for the specific language governing permissions and
>  limitations under the License.

    global = this

Utilites
--------

Helper functions to make sorting easier.

    sortAsc = (a, b) -> +a - +b

    sortDesc = (a, b) -> +b - +a

Predicates.

    isNumber = (n) -> typeof n is 'number'

    isString = (s) -> typeof s is 'string'

    isFunction = (f) -> typeof f is 'function'

    isArray = (a) -> a instanceof Array

`val` is used to get the 'value' of an object, whatever it may be.

    val = (obj) ->
        if isFunction(obj)
            return obj()
        else if obj instanceof Die
            return obj.roll()
        else
            return obj

Die
===

`Die` does everything.

You have three options when constructing a `Die`.
* Passing in a positive integer will create a die that generates integers in [1, n].
* Passing in an array will create a die that picks elements from the array uniformly.
* When passed a function, the die will use that function as its `roll`.

All die methods return a new `Die` object, leaving the original unchanged.

To roll a die, just call `roll`.

    class Die

        constructor: (arg) ->
            if isNumber(arg) and arg > 0
                if arg == Math.floor(arg)
                    @roll = -> Math.floor(Math.random() * arg) + 1
                else
                    @roll = -> Math.random() * arg
            else if isArray(arg)
                @roll = -> arg[Math.floor(Math.random() * arg.length)]
            else if isFunction(arg)
                @roll = arg
            else
                throw new TypeError("dicec: I don't know how to roll that!")

Add/Subtract/Multiply/Divide a value or another die to the result.

        add: (others...) ->
            new Die =>
                result = @roll()
                result += val(d) for d in others

        sub: (other) ->
            new Die =>
                @roll() - val(other)

        mult: (others...) ->
            new Die =>
                result = @roll()
                result *= val(d) for d in others

        div: (other) ->
            new Die =>
                @roll() / val(other)

        neg: -> new Die => -@roll()

        binaryOp: (op, other) ->
            new Die =>
                op @roll(), val(other)

        unaryOp: (op) -> new Die => op @roll()

Repeat the die `n` times. The new die will return an array of the results.

        repeat: (n) ->
            new Die =>
                (@roll() for i in [1..n])

Concatenate the results of this die with any number of others.

        concat: (others...) ->
            new Die =>
                [@roll()].concat(d.roll() for d in others)

Set a threshold for the die, if the result is greater than or equal to the provided value,
return (1/true/yes/on), otherwise return (0/false/no/off).

        threshold: (t) ->
            new Die =>
                @roll() >= t

`reduce` the results of a die that returns an array (or any reduceable object).

        reduce: (f, init = null) ->
            new Die =>
                @roll().reduce(f, init)

        reduceRight: (f, init = null) ->
            new Die =>
                @roll().reduceRight(f, init)

        foldl: @::reduce

        foldr: @::reduceRight

        map: (f) ->
            new Die =>
                @roll().map f

Two common reductions.

        sum: ->
            @reduce (a, b) -> a + b

        product: ->
            @reduce (a, b) -> a * b

If the roll satisfies `cond`, roll it again, subject to the same condition.
The new die returns the results in an array, even if the die was only rolled once.

        rerollWhile: (cond) ->
            new Die =>
                result = [@roll()]
                while cond(result[result.length-1])
                    result.push(@roll())
                return result

        explode: (value) ->
            @rerollWhile((r) -> r >= value).sum()

        explodeSet: (values) ->
            @rerollWhile((r) -> r in values).sum()

Remove or keep high or low numbers.

        highest: (n = 1) ->
            new Die =>
                @roll().sort(sortDesc)[0...val(n)]

        lowest: (n = 1) ->
            new Die =>
                @roll().sort(sortAsc)[0...val(n)]

        dropHighest: (n = 1) ->
            new Die =>
                @roll().sort(sortDesc)[0...-val(n)]

        dropLowest: (n = 1) ->
            new Die =>
                @roll().sort(sortAsc)[0...-val(n)]

        keepHighest: @::highest

        keepLowest: @::lowest

Dice Pools
----------

A 'standard' dice pool. Roll the die `n` times, each roll greater than
or equal to `t` is a success. The new die returns the number of successes.

        pool: (n, t) ->
            @threshold(t).repeat(n).sum()

*One Roll Engine* (ORE) - this returns a object where the keys are the widths,
and the values are the heights.

        ore: (n) ->
            nd = @repeat(n)
            new Die =>
                result = {}
                for x in nd.roll()
                    result[x] = (result[x] ? 0) + 1
                for width, height of result
                    delete result[width] if width == 1

Wrap It Up
----------

This is the wrapper object. Right now it just constructs a Die object.
It may do more in the future, such as parsing a string (ex. `4d6+1`).

    d = (x) -> new Die(x)

Fudge dice.

    d.F = (n) ->
        d([-1,0,1]).repeat(n).sum()

D6 System.

    d.D = (n) ->
        d(6).repeat(n).sum()

Export
------

Export for CommonJS.

    if typeof(exports) != 'undefined'
        exports.d = d

Export to global scope.

    global.d = d

Examples
--------

### Random HTML colors

    # d(['1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']).repeat(6).sum()

