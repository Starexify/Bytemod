package bytemod;

using StringTools;

class BytemodCompiler {
  public var variableMap:Map<String, Int> = new Map();
  public var varCounter:Int = 0;

  var tokens:Array<String>;
  var i:Int = 0;

  public function new() {}

  function consume() return tokens[i++];

  function peek() return tokens[i];

  function parseStatement(bytes:Array<Int>) {
    var name = consume();
    if (consume() == "=") {
      var next = peek();

      // If it's a simple assignment: i = 10;
      if (tokens[i + 1] == ";") {
        bytes.push(OpCode.PUSH_INT);
        bytes.push(Std.parseInt(consume()));
        consume(); // ";"
      }
        // If it's math: i = i + 1;
      else {
        var leftHand = consume(); // "i"
        var op = consume(); // "+"
        var rightHand = consume(); // "1"
        consume(); // ";"

        bytes.push(OpCode.GET_VAR);
        bytes.push(getVarId(leftHand));
        bytes.push(OpCode.PUSH_INT);
        bytes.push(Std.parseInt(rightHand));
        bytes.push(OpCode.ADD);
      }

      bytes.push(OpCode.SET_VAR);
      bytes.push(getVarId(name));
    }
  }


  /**
   * Function that compiles tokens into bytecode.
   *
   * @param tokens The tokens of a script
   * @return The compiled bytecode
   */
  public function compile(tokens:Array<String>):CompileResult {
    this.tokens = tokens;
    this.i = 0;
    var result:CompileResult = {
      main: [],
      functions: new Map()
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
      else parseExpr(result.main);
    }

    // No longer needed, free memory
    this.tokens = null;
    this.i = 0;

    return result;
  }

  function parseExpr(bytes:Array<Int>) {
    var t = consume();

    if (t == "if") {
      if (consume() == "(") {
        var left:String = consume();
        var op:String = consume();
        var right:String = consume();
        consume(); // ")"

        // Push condition to bytecode
        var leftNum = Std.parseInt(left);
        if (leftNum != null) {
          bytes.push(OpCode.PUSH_INT);
          bytes.push(leftNum);
        } else {
          bytes.push(OpCode.GET_VAR);
          bytes.push(getVarId(left));
        }

        var rightNum = Std.parseInt(right);
        if (rightNum != null) {
          bytes.push(OpCode.PUSH_INT);
          bytes.push(rightNum);
        } else {
          bytes.push(OpCode.GET_VAR);
          bytes.push(getVarId(right));
        }

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
    else {
      i--;
      parseStatement(bytes);
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
  public static function tokenize(code:String):Array<String> {
    var r:EReg = ~/([ \t\n\r]+|[0-9]+|[a-zA-Z_]+|==|<=|>=|<|>|\+|\-|\*|\/|[\(\)\{\};=])/g;
    var tokens = [];

    while (r.match(code)) {
      var token = r.matched(1).trim();
      if (token != "") tokens.push(token);
      code = r.matchedRight();
    }
    return tokens;
  }
}

typedef CompileResult = {main:Array<Int>, functions:Map<String, Array<Int>>}
