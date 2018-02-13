FALSE =
  type: "bool"
  value: false


PRECEDENCE =
  "=":  1
  "||": 2
  "&&": 3
  "<":  7
  ">":  7
  "<=": 7
  ">=": 7
  "==": 7
  "!=": 7
  "+": 10
  "-": 10
  "*": 20
  "/": 20
  "%": 20


module.exports = class ASTParser


  constructor: (input) ->
    @input = input


  parse: ->
    return @parse_toplevel()


  # 是标点符号
  is_punc: (ch) ->
    tok = @input.peek()
    if tok
      if tok.type is "punc"
        if !ch or tok.value is ch
          return tok
    return false


  # 是关键词
  is_kw: (kw) ->
    tok = @input.peek()
    if tok
      if tok.type is "kw"
        if !kw or tok.value is kw
          return tok
    return false


  # 是操作符
  is_op: (op) ->
    tok = @input.peek()
    if tok
      if tok.type is "op"
        if !op or tok.value is op
          return tok
    return false


  skip_punc: (ch) ->
    if @is_punc(ch)
      @input.next()
    else
      @input.throw("Expecting punctuation: \"" + ch + "\"")


  skip_kw: (kw) ->
    if @is_kw(kw)
      @input.next()
    else
      @input.throw("Expecting keyword: \"" + kw + "\"")


  skip_op: (op) ->
    if @is_op(op)
      @input.next()
    else
      @input.throw("Expecting operator: \"" + op + "\"")


  unexpected: ->
    @input.throw("Unexpected token: " + JSON.stringify(@input.peek()))


  maybe_binary: (left, my_prec) ->
    tok = @is_op()

    if tok
      his_prec = PRECEDENCE[tok.value]

      if his_prec > my_prec
        @input.next()

        return @maybe_binary({
          type: if tok.value is "=" then "assign" else "binary"
          operator: tok.value
          left: left
          right: @maybe_binary(@parse_atom(), his_prec)
        }, my_prec)

    return left


  delimited: (start, stop, separator, parser) ->
    a = []
    first = true

    @skip_punc(start)

    while !@input.eof()

      if @is_punc(stop)
        break

      if first
        first = false
      else
        @skip_punc(separator)

      if @is_punc(stop)
        break

      a.push(parser())

    @skip_punc(stop)
    return a


  parse_call: (func) ->
    return{
      type: "call"
      func: func
      args: @delimited("(", ")", ",", @parse_expression.bind(@))
    }


  parse_varname: ->
    name = @input.next()
    if name.type isnt "var"
      @input.throw("Expecting variable name")
    return name.value


  parse_if: ->
    @skip_kw("if")

    cond = @parse_expression()

    if !@is_punc("{")
      @skip_kw("then")

    _then = @parse_expression()

    ret = {
      type: "if"
      cond: cond
      then: _then
    }

    if @is_kw("else")
      @input.next()
      ret.else = @parse_expression()

    return ret


  parse_lambda: ->
    return{
      type: "lambda"
      vars: @delimited("(", ")", ",", @parse_varname.bind(this))
      body: @parse_expression()
    }


  parse_bool: ->
    return{
      type: "bool"
      value: @input.next().value is "true"
    }


  maybe_call: (expr) ->
    expr = expr()
    return if @is_punc("(") then @parse_call(expr) else expr


  parse_atom: ->
    return @maybe_call (()->

      if @is_punc("(")
        @input.next()
        exp = @parse_expression()
        @skip_punc(")")
        return exp

      if @is_punc("{")
        return @parse_prog()

      if @is_kw("if")
        return @parse_if()

      if @is_kw("true") or @is_kw("false")
        return @parse_bool()

      if @is_kw("lambda") or @is_kw("λ")
        @input.next()
        return @parse_lambda()

      tok = @input.next()
      if tok.type is "var" or tok.type is "num" or tok.type is "str"
        return tok

      @unexpected()

  ).bind(@)


  parse_toplevel: ->
    prog = []

    while !@input.eof()
      prog.push(@parse_expression())

      if !@input.eof()
        @skip_punc(";")

    return{
      type: "prog"
      prog: prog
    }


  parse_prog: ->
    prog = @delimited("{", "}", ";", @parse_expression.bind(@))

    if(prog.length is 0)
      return FALSE

    if(prog.length is 1)
      return prog[0]

    return{
      type: "prog"
      prog: prog
    }


  parse_expression: ->
    return @maybe_call (->
      return @maybe_binary(@parse_atom(), 0)
    ).bind(@)