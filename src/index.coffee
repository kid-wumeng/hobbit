# CharacterStream = require("./CharacterStream")
# TokenStream     = require("./TokenStream")
# ASTParser       = require("./ASTParser")
# Environment     = require("./Environment")
# evaluate        = require("./evaluate")
#
#
# code = "sum = lambda(x, y) x + y; print(sum(2, 3));"
#
#
# charStream  = new CharacterStream(code)
# tokenStream = new TokenStream(charStream)
# astParser   = new ASTParser(tokenStream)
#
#
# ast = astParser.parse()
#
#
# globalEnv = new Environment()
#
# globalEnv.def "print", (txt) ->
#   console.log(txt)
#
# evaluate(ast, globalEnv)


Lexer = require('lex')
lexer = new Lexer

lexer.addRule /[a-z]+/i, (lexeme) ->
  return lexeme

lexer.addRule /[\d]+/i, (lexeme) ->
  return lexeme

result1 = lexer.setInput("as = 6; k = 7").lex()
result2 = lexer.setInput("as = 6; k = 7").lex()

console.log result1
console.log result2