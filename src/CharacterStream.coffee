module.exports = class CharacterStream


  constructor: (code) ->
    @code = code
    @pos  = 0
    @line = 1
    @col  = 0


  next: =>
    ch = @code.charAt(@pos++)

    if ch is "\n"
      @line++
      @col = 0
    else
      @col++

    return ch


  peek: =>
    return @code.charAt(@pos)


  eof: =>
    return @peek() is ""


  throw: (msg) =>
    throw new Error("#{msg} (#{@line}:#{@col})")