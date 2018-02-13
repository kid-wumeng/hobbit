module.exports = class TokenStream



  constructor: (charStream) ->
    @charStream = charStream
    @current    = null
    @keywords   = " if then else lambda λ true false "



  # 单词是不是「关键词」
  isKeyword: (word) =>
    return @keywords.indexOf(" " + word + " ") >= 0



  # 字符是不是「数字」
  isDigit: (ch) =>
    return /[0-9]/i.test(ch)



  # 字符是不是「标识符」的第一位
  isIDStart: (ch) =>
    return /[a-z_]/i.test(ch)



  # 字符是不是「标识符」
  isID: (ch) =>
    return @isIDStart(ch) or "0123456789".indexOf(ch) >= 0



  # 字符是不是「运算符」
  isOp: (ch) =>
    return "+-*/%=&|<>!".indexOf(ch) >= 0



  # 字符是不是「标点」
  isPunc: (ch) =>
    return ",;(){}[]".indexOf(ch) >= 0



  # 字符是不是「空白符」
  isWhiteSpace: (ch) =>
    return " \t\n".indexOf(ch) >= 0



  # 读取一段字符流，用 belongToken 识别并返回合规的字符串
  # 举个栗子，比如有语句 int age = 18;
  # 当前 charStream 已经读到 int 之后了
  # 当 readNextToken() 认定 a 是标识符的开头，则往 readString() 中注入 isID（识别标识符的迭代器）
  # 迭代器会判断 a g e 符合标识符的规则，直到碰到空格才返回 false
  # 至此一次 readString() 结束，返回 age
  readString: (belongToken) =>

    str = ""

    while !@charStream.eof()
      if belongToken(@charStream.peek())
        str += @charStream.next()
      else
        break

    return str



  # 读取一组「数字」记号
  readNumberToken: =>

    # 小数点的个数，初始为0
    dot = 0

    belongNumber = (ch) =>
      # 小数点，检查是否多于1个
      if ch is "."
        if dot is 0
          dot = 1
          return true
        else
          return false
      else
        # 非小数点，判断是不是数字
        return @isDigit(ch)

    number = @readString(belongNumber)

    return
      type: "num"
      value: parseFloat(number)



  # 读取一组「标识符」记号
  readIDToken: =>
    id = @readString(@isID)

    return
      type:  if @isKeyword(id) then "kw" else "var"
      value: id


  # 读取一组转义过的字符串
  # 比如 charStream 中有一段 i\'m kid
  # 结果返回 i'm kid
  readEscapeString: (end) =>
    escaped = false
    str     = ""

    # 跳过起始的双引号
    @charStream.next()

    while !@charStream.eof()
      ch = @charStream.next()

      # escaped 标志位：表示当前字符的前面是转义字符
      # 假设有 i\'
      # 读取 i 后，escaped = false
      # 读取 \ 后，escaped = true
      # 读取 ' 后，escaped = false
      if escaped
        str += ch
        escaped = false
      else if ch is "\\"
        escaped = true
      else if ch is end
        break
      else
        str += ch

    return str



  # 读取一组「字符串」记号
  readStringToken: =>
    return
      type: "str"
      value: @readEscapeString('"')



  # 跳过注释直到行末
  skipComment: =>
    @readString((ch) => ch isnt "\n")
    @charStream.next()



  # 根据一段串的起始字符，读取下一个记号
  readNextToken: =>

    # 跳过空白符
    @readString(@isWhiteSpace.bind(@))

    if @charStream.eof()
      return null

    ch = @charStream.peek()

    if ch is "#"
      @skipComment()
      return @readNextToken()

    if ch is '"'
      return @readStringToken()

    if @isDigit(ch)
      return @readNumberToken()

    if @isIDStart(ch)
      return @readIDToken()

    if @isPunc(ch)
      return
        type:  "punc"
        value: @charStream.next()

    if @isOp(ch)
      return
        type:  "op"
        value: @readString(@isOp)

    @charStream.throw("Can't handle character: " + ch)



  peek: =>
    return @current or (@current = @readNextToken())



  next: =>
    token = @current
    @current = null
    return token or @readNextToken()



  eof: =>
    return @peek() is null



  throw: (msg) =>
    @charStream.throw(msg)