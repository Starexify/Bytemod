package bytemod;

using StringTools;

class BytemodCompiler {
  public var variableMap:Map<String, Int> = new Map();
  public var varCounter:Int = 0;

  var tokens:Array<Token>;
  var i:Int = 0;

  public function new() {}

  function consume():String return tokens[i++].text;

  function peek():String return tokens[i].text;

  function lastLine():Int return tokens[i - 1].line;

  function parseStatement(bytes:Array<Int>):Void {
    var name = consume();

    // If the modder wrote "var i = 10", name is currently "var".
    // We need the ACTUAL name.
    if (name == "var") {
      name = consume(); // Now name is "k"
    }

    if (consume() == "=") {
      parseExpression(bytes);
      consume(); // ";"

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

  function parseExpression(bytes:Array<Int>) {
    var firstToken = consume();
    var next = peek();

    if (next == "(") {
      consume(); // "("
      // For now, let's assume 0 arguments for stamp()
      consume(); // ")"

      bytes.push(OpCode.CALL_NATIVE);
      bytes.push(getNativeId(firstToken));
    } else {
      pushValue(bytes, firstToken);
    }

    while (true) {
      var op = peek();
      if (op == "+" || op == "-" || op == "*" || op == "/") {
        consume(); // eat the operator
        var secondToken = consume();
        pushValue(bytes, secondToken);

        if (op == "+") bytes.push(OpCode.ADD);
        else if (op == "-") bytes.push(OpCode.SUB);
        else if (op == "*") bytes.push(OpCode.MUL);
        else if (op == "/") bytes.push(OpCode.DIV);
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
    this.tokens = tokens;
    this.i = 0;
    var result:CompileResult = {
      bytecode: [],
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
    var t = consume();

    if (t == "if") {
      if (consume() == "(") {
        var left:String = consume();
        var op:String = consume();
        var right:String = consume();
        consume(); // ")"

        // Push condition to bytecode
        pushValue(bytes, left);
        pushValue(bytes, right);

        bytes.push(OpCode.LT);
      }

      // 2. Setup Jump for "False"
      bytes.push(OpCode.JUMP_IF_FALSE);
      var jumpToElseIdx = bytes.length;
      bytes.push(0); // Placeholder

      // 3. Handle "{ a = 10; }" (The True Block)
      if (consume() == "{") {
        // For now, let's just parse until we hit "}"
        while (peek() != "}") {
          // Logic to handle "a = 10;"
          var name = consume(); // "a"
          consume(); // "="
          var v = consume(); // "10"
          consume(); // ";"

          bytes.push(OpCode.PUSH_INT);
          bytes.push(Std.parseInt(v));
          bytes.push(OpCode.SET_VAR);
          bytes.push(getVarId(name));
        }
        consume(); // consume "}"
      }

      // 4. Setup Jump to skip Else
      bytes.push(OpCode.JUMP);
      var jumpToExitIdx = bytes.length;
      bytes.push(0); // Placeholder

      // 5. PATCH the Else Jump
      bytes[jumpToElseIdx] = bytes.length;

      // 6. Handle "else { a = 0; }"
      if (peek() == "else") {
        consume(); // "else"
        consume(); // "{"
        while (peek() != "}") {
          var name = consume();
          consume();
          var v = consume();
          consume();

          bytes.push(OpCode.PUSH_INT);
          bytes.push(Std.parseInt(v));
          bytes.push(OpCode.SET_VAR);
          bytes.push(getVarId(name));
        }
        consume(); // "}"
      }

      // 7. PATCH the Exit Jump
      bytes[jumpToExitIdx] = bytes.length;
    }
    else if (t == "while") {
      var loopStart = bytes.length;

      if (consume() == "(") {
        var varName = consume();
        var op = consume();
        var val = consume();
        consume(); // ")"

        // --- 1. Condition ---
        bytes.push(OpCode.GET_VAR);
        bytes.push(getVarId(varName));
        bytes.push(OpCode.PUSH_INT);
        bytes.push(Std.parseInt(val));
        bytes.push(OpCode.LT);
      }

      bytes.push(OpCode.JUMP_IF_FALSE);
      var jumpToExitIdx = bytes.length;
      bytes.push(0); // Placeholder

      if (consume() == "{") {
        while (peek() != "}") {
          // (Call your statement parser here)
          parseStatement(bytes);
        }
        consume(); // "}"
      }

      bytes.push(OpCode.JUMP);
      bytes.push(loopStart);

      bytes[jumpToExitIdx] = bytes.length;
    }
    else if (t == "var" || t == ";") {
      return;
    }
    else if (t == "trace") {
      var lineNum = lastLine();
      consume(); // skip "("

      var argCount = 0;
      while (peek() != ")") {
        parseExpression(bytes);
        argCount++;
        if (peek() == ",") consume();
      }
      consume(); // ")"
      consume(); // ";"

      // Push the TRACE opcode followed by how many items to pop
      bytes.push(OpCode.PRINT);
      bytes.push(argCount);
      bytes.push(lineNum);
    }
    else {
      i--;
      parseStatement(bytes);
    }
  }

  function pushValue(bytes:Array<Int>, token:String):Void {
    var val = Std.parseInt(token);
    if (val != null) {
      bytes.push(OpCode.PUSH_INT);
      bytes.push(val);
    } else {
      bytes.push(OpCode.GET_VAR);
      bytes.push(getVarId(token));
    }
  }

  // Function for adding or retrieving variables from the variableMap.
  function getVarId(varName:String):Int {
    if (variableMap.exists(varName)) return variableMap.get(varName);

    var newId = varCounter;
    variableMap.set(varName, newId);

    varCounter++;
    return newId;
  }

  /**
   * Helper function for tokenizing the contents of a string.
   *
   * @param code The contents of the script
   * @return An array of tokens
   */
  public static function tokenize(code:String):Array<Token> {
    var tokens = [];
    var lines = code.split("\n");

    var r:EReg = ~/([0-9]+|[a-zA-Z_.]+|==|<=|>=|<|>|\+|\-|\*|\/|[\(\)\{\};=,])/g;

    for (i in 0...lines.length) {
      var lineText = lines[i];
      var pos = 0;
      while (r.matchSub(lineText, pos)) {
        var match = r.matched(1);
        tokens.push({ text: match, line: i + 1 }); // i + 1 because lines start at 1
        var p = r.matchedPos();
        pos = p.pos + p.len;
      }
    }
    return tokens;
  }
}

typedef Token = { text:String, line:Int };
typedef CompileResult = {bytecode:Array<Int>, functions:Map<String, Array<Int>>, nativeSymbols:Array<String>}
