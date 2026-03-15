package bytemod;

using StringTools;

class BytemodCompiler {
  public var variableMap:Map<String, Int> = new Map();
  public var varCounter:Int = 0;
  public var constants:Array<Dynamic> = [];

  var tokens:Array<Token>;
  var i:Int = 0;

  public function new() {}

  function consume():String return tokens[i++].text;

  function peek():String return tokens[i].text;

  function lastLine():Int return tokens[i - 1].line;

  function parseStatement(bytes:Array<Int>):Void {
    var name = consume();

    // Handle Types
    if (peek() == ":") {
      consume(); // eat ":"
      // Eat everything until we hit an assignment or end of statement
      while (i < tokens.length && peek() != "=" && peek() != ";" && peek() != ")") {
        consume();
      }
//      while (peek() == "." || peek() == "<") {
//        if (peek() == "<") {
//          // This is a simple way to skip generics;
//          // you'd need a loop to find the matching ">" for real ones
//          while (consume() != ">") {}
//        } else {
//          consume(); // eat "."
//          consume(); // eat next part
//        }
//      }
    }

    // Handle fields
    if (peek() == ".") {
      bytes.push(OpCode.GET_VAR);
      bytes.push(getVarId(name));

      while (peek() == ".") {
        consume(); // eat "."
        var field = consume();

        if (peek() == "=") {
          consume(); // eat "="
          parseExpression(bytes); // Push the value (20)

          if (peek() == ";") consume();

          bytes.push(OpCode.SET_PROPERTY);
          bytes.push(getConstantId(field));
          return;
        }
        else { // Handle chained fields
          bytes.push(OpCode.GET_PROPERTY);
          bytes.push(getConstantId(field));
        }
      }
    }

    // Handle assignment
    if (peek() == "=") {
      consume(); // "="
      parseExpression(bytes);
      if (peek() == ";") consume();

      bytes.push(OpCode.SET_VAR);
      bytes.push(getVarId(name));
    }
  }

  public var nativeSymbols:Array<String> = [];
  function getNativeId(path:String):Int {
    var id = nativeSymbols.indexOf(path);
    if (id == -1) {
      id = nativeSymbols.length;
      nativeSymbols.push(path);
    }
    return id;
  }

  function parseExpression(bytes:Array<Int>, isRoot:Bool = true) {
    var firstToken = consume();

    // Handling new class instancing
    if (firstToken == "new") {
      var className = consume();
      while (peek() == ".") {
        consume();
        className += "." + consume();
      }
      if (peek() == "(") {
        consume(); // "("
        consume(); // ")"
      }
      bytes.push(OpCode.NEW);
      bytes.push(getConstantId(className));
      return;
    }

    // Handle import paths (TODO: imports don't work for now)
    var path = firstToken;
    while (peek() == ".") {
      consume(); // eat "."
      path += "." + consume();
    }

    if (peek() == "(") {
      consume(); // eat "("

      // Support arguments!
      var argCount = 0;
      while (peek() != ")") {
        parseExpression(bytes, false);
        argCount++;
        if (peek() == ",") consume();
      }
      consume(); // eat ")"

      bytes.push(OpCode.CALL_NATIVE);
      bytes.push(getNativeId(path));
      bytes.push(argCount);
    } else {
      pushValue(bytes, path);
    }

    // Handle Math and Operators (+, -, is, etc)
    while (isRoot) {
      var op = peek();
      if (op == "+" || op == "-" || op == "*" || op == "/") {
        consume(); // eat the operator
        parseExpression(bytes, false);

        if (op == "+") bytes.push(OpCode.ADD);
        else if (op == "-") bytes.push(OpCode.SUB);
        else if (op == "*") bytes.push(OpCode.MUL);
        else if (op == "/") bytes.push(OpCode.DIV);
      }
      else if (op == "is") {
        consume(); // eat "is"
        var typeName = consume();

        while (i < tokens.length && peek() == ".") {
          consume(); // eat "."
          typeName += "." + consume();
        }

        bytes.push(OpCode.PUSH_STR);
        bytes.push(getConstantId(typeName));

        bytes.push(OpCode.IS);
      }
      else {
        break;
      }
    }
  }

  /**
   * Function that compiles tokens into bytecode.
   *
   * @param tokens The tokens of a script
   * @return The compiled bytecode
   */
  public function compile(tokens:Array<Token>):CompileResult {
    this.variableMap = new Map();
    this.varCounter = 0;

    this.tokens = tokens;
    this.i = 0;
    var result:CompileResult = {
      bytecode: [],
      constants: [],
      functions: new Map(),
      nativeSymbols: this.nativeSymbols
    };

    while (i < tokens.length) {
      var t = peek();
      if (t == "function") {
        consume(); // "function"
        var funcName = consume();
        consume(); // "("
        consume(); // ")"

        var funcBytes = [];
        if (consume() == "{") {
          while (peek() != "}") {
            parseExpr(funcBytes);
          }
          consume(); // "}"
        }
        result.functions.set(funcName, funcBytes);
      }
      else parseExpr(result.bytecode);
    }

    // No longer needed, free memory
    this.tokens = null;
    this.i = 0;

    return result;
  }

  function parseExpr(bytes:Array<Int>):Void {
    var t = peek();

    if (t == "var") {
      consume(); // eat var
      parseStatement(bytes);
      if (peek() == ";") consume();
    }
    else if (t == ";") {
      consume(); // Just a stray semicolon, skip it
    }
    else if (t == "trace") {
      consume(); // eat "trace"
      var lineNum = lastLine();
      consume(); // skip "("

      var argCount = 0;
      while (peek() != ")") {
        parseExpression(bytes);
        argCount++;
        if (peek() == ",") consume();
      }
      consume(); // ")"
      if (peek() == ";") consume();

      // Push the TRACE opcode followed by how many items to pop
      bytes.push(OpCode.PRINT);
      bytes.push(argCount);
      bytes.push(lineNum);
    }
    else {
      parseStatement(bytes);
      if (peek() == ";") consume();
    }
  }

  function pushValue(bytes:Array<Int>, token:String):Void {
    var valFloat = Std.parseFloat(token);

    if (!Math.isNaN(valFloat)) {
      // number
      bytes.push(OpCode.PUSH_CONST);
      bytes.push(getConstantId(valFloat));
    }
    else if (token.startsWith('"')) {
      // String
      var str = token.substring(1, token.length - 1);
      bytes.push(OpCode.PUSH_STR);
      bytes.push(getConstantId(str));
    }
    else {
      // Variable
      var parts = token.split(".");
      bytes.push(OpCode.GET_VAR);
      bytes.push(getVarId(parts[0]));

      // Property
      for (j in 1...parts.length) {
        bytes.push(OpCode.GET_PROPERTY);
        bytes.push(getConstantId(parts[j]));
      }
    }
  }

  // Function for adding or retrieving variables from the variableMap.
  function getVarId(varName:String):Int {
    if (variableMap.exists(varName)) return variableMap.get(varName);

    var newId = varCounter;
    variableMap.set(varName, newId);

    // Sys.println('Variable Registered: "$varName" at Index $newId');

    varCounter++;
    return newId;
  }

  // Function for adding or retrieving variables from constants.
  function getConstantId(value:Dynamic):Int {
    for (i in 0...constants.length) {
      if (constants[i] == value) return i;
    }
    constants.push(value);
    return constants.length - 1;
  }

  /**
   * Helper function for tokenizing the contents of a string.
   *
   * @param code The contents of the script
   * @return An array of tokens
   */
  public static function tokenize(code:String):Array<Token> {
    var commentRegex:EReg = ~/"[^"]*"|(\/\/[^\n]*)|(\/\*[\s\S]*?\*\/)/g;
    code = commentRegex.map(code, (e) -> {
      var match = e.matched(0);
      if (match.startsWith('"')) return match; // Keep strings
      return ""; // Replace comments with nothing
    });

    var tokens = [];
    var lines = code.split("\n");

    var r:EReg = ~/"[^"]*"|[0-9.]+|[a-zA-Z_]+|==|<=|>=|<|>|is|\+|\-|\*|\/|[\(\)\{\};=,.<>:]/g;

    for (i in 0...lines.length) {
      var lineText = lines[i];
      var pos = 0;
      while (r.matchSub(lineText, pos)) {
        var match = r.matched(0);
        tokens.push({ text: match, line: i + 1 });
        var p = r.matchedPos();
        pos = p.pos + p.len;
      }
    }
    return tokens;
  }
}

typedef Token = { text:String, line:Int };
typedef CompileResult = {bytecode:Array<Int>, constants:Array<Dynamic>, functions:Map<String, Array<Int>>, nativeSymbols:Array<String>}
