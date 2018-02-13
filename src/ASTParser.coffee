FALSE =
  type: "bool"
  value: false


# 运算符优先级
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


  constructor: (tokenStream) ->
    @tokenStream = tokenStream


  parse: =>
    return @parse_toplevel()


  # 记号是不是某种「标点」
  isPunc: (punc) =>
    token = @tokenStream.peek()
    if token
      if token.type is "punc"
        if !punc or token.value is punc
          return token
    return false


  # 记号是不是某种「关键词」
  isKeyword: (keyword) =>
    tok = @tokenStream.peek()
    if tok
      if tok.type is "keyword"
        if !keyword or tok.value is keyword
          return tok
    return false


  # 是操作符
  is_op: (op) =>
    tok = @tokenStream.peek()
    if tok
      if tok.type is "op"
        if !op or tok.value is op
          return tok
    return false


  skip_punc: (ch) =>
    if @isPunc(ch)
      @tokenStream.next()
    else
      @tokenStream.throw("Expecting punctuation: \"" + ch + "\"")


  skip_kw: (kw) =>
    if @isKeyword(kw)
      @tokenStream.next()
    else
      @tokenStream.throw("Expecting keyword: \"" + kw + "\"")


  skip_op: (op) =>
    if @is_op(op)
      @tokenStream.next()
    else
      @tokenStream.throw("Expecting operator: \"" + op + "\"")


  unexpected: =>
    @tokenStream.throw("Unexpected token: " + JSON.stringify(@tokenStream.peek()))


  maybe_binary: (left, my_prec) =>
    tok = @is_op()

    if tok
      his_prec = PRECEDENCE[tok.value]

      if his_prec > my_prec
        @tokenStream.next()

        return @maybe_binary({
          type: if tok.value is "=" then "assign" else "binary"
          operator: tok.value
          left: left
          right: @maybe_binary(@parse_atom(), his_prec)
        }, my_prec)

    return left


  delimited: (start, stop, separator, parser) =>
    a = []
    first = true

    @skip_punc(start)

    while !@tokenStream.eof()

      if @isPunc(stop)
        break

      if first
        first = false
      else
        @skip_punc(separator)

      if @isPunc(stop)
        break

      a.push(parser())

    @skip_punc(stop)
    return a


  parse_call: (func) =>
    return{
      type: "call"
      func: func
      args: @delimited("(", ")", ",", @parse_expression.bind(@))
    }


  parse_varname: =>
    name = @tokenStream.next()
    if name.type isnt "var"
      @tokenStream.throw("Expecting variable name")
    return name.value


  parse_if: =>
    @skip_kw("if")

    cond = @parse_expression()

    if !@isPunc("{")
      @skip_kw("then")

    _then = @parse_expression()

    ret = {
      type: "if"
      cond: cond
      then: _then
    }

    if @isKeyword("else")
      @tokenStream.next()
      ret.else = @parse_expression()

    return ret


  parse_lambda: =>
    return
      type: "lambda"
      vars: @delimited("(", ")", ",", @parse_varname.bind(this))
      body: @parse_expression()


  parse_bool: =>
    return{
      type: "bool"
      value: @tokenStream.next().value is "true"
    }


  maybe_call: (expr) =>
    expr = expr()
    return if @isPunc("(") then @parse_call(expr) else expr


  parse_atom: =>
    return @maybe_call (()=>

      if @isPunc("(")
        @tokenStream.next()
        exp = @parse_expression()
        @skip_punc(")")
        return exp

      if @isPunc("{")
        return @parse_prog()

      if @isKeyword("if")
        return @parse_if()

      if @isKeyword("true") or @isKeyword("false")
        return @parse_bool()

      if @isKeyword("lambda") or @isKeyword("λ")
        @tokenStream.next()
        return @parse_lambda()

      tok = @tokenStream.next()
      if tok.type is "var" or tok.type is "num" or tok.type is "str"
        return tok

      @unexpected()

  ).bind(@)


  parse_toplevel: =>
    prog = []

    while !@tokenStream.eof()
      prog.push(@parse_expression())

      if !@tokenStream.eof()
        @skip_punc(";")

    return{
      type: "prog"
      prog: prog
    }


  parse_prog: =>
    prog = @delimited("{", "}", ";", @parse_expression.bind(@))

    if(prog.length is 0)
      return FALSE

    if(prog.length is 1)
      return prog[0]

    return{
      type: "prog"
      prog: prog
    }


  parse_expression: =>
    return @maybe_call (=>
      return @maybe_binary(@parse_atom(), 0)
    ).bind(@)