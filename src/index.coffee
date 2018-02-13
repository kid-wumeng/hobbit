CharacterStream = require("./CharacterStream")
TokenStream     = require("./TokenStream")
ASTParser       = require("./ASTParser")
Environment     = require("./Environment")
evaluate        = require("./evaluate")


code = "sum = lambda(x, y) x + y; print(sum(2, 3));"


charStream  = new CharacterStream(code)
tokenStream = new TokenStream(charStream)
astParser   = new ASTParser(tokenStream)


ast = astParser.parse()


globalEnv = new Environment()

globalEnv.def "print", (txt) ->
  console.log(txt)

evaluate(ast, globalEnv)