package bytemod.compiler;

import bytemod.compiler.IBytemodCompiler;

using StringTools;

class BytemodCompiler implements IBytemodCompiler {
  private var tokens:Array<Token> = [];
  private var cursor:Int = 0;

  private var constants:Array<Dynamic>;
  private var classes:Array<ClassDefinition>;
  private var enums:Array<EnumDefinition>;
  private var bytecode:Array<Int>;

  private var constantIDs:Map<Dynamic, Int>;

  private inline function read():String return tokens[cursor++].text;
  private inline function peek():Token return tokens[cursor];

  public function new() {}

  public function compile(?tokens:Array<Token>):CompileResult {
    if (read() == "constants") {
      parseConstants(tokens);
    }

    return null;
  }

  public function parseConstants(?tokens:Array<Token>):Array<Dynamic> {
    return null;
  }

  public function parseClass(?tokens:Array<Token>):ClassDefinition {
    return null;
  }

  public function parseEnum(?tokens:Array<Token>):EnumDefinition {
    return null;
  }

  public function parseField(?tokens:Array<Token>):FieldDefinition {
    return null;
  }

  public function parseFunction(?tokens:Array<Token>):FunctionDefinition {
    return null;
  }

  public function parseStatement(?tokens:Array<Token>):Void {}

  public function parseType(?tokens:Array<Token>):Int {
    return 0;
  }

  public function parseExpression(?tokens:Array<Token>):Void {}

  public function parseBytecode(?tokens:Array<Token>):Array<Int> {
    return null;
  }

  public function tokenize(content:String):Array<Token> {
    // Take comments out first
    content = Constants.COMMENT_REGEX.map(content, e -> {
      var match = e.matched(0);
      if (match.startsWith('"')) return match;
      return "";
    });

    var lines:Array<String> = content.split("\n");

    for (line in lines.keyValueIterator()) {
      var pos = 0;
      while (Constants.BYTEMOD_REGEX.matchSub(line.value, pos)) {
        var p = Constants.BYTEMOD_REGEX.matchedPos();
        var matchText = Constants.BYTEMOD_REGEX.matched(0);
        tokens.push({
          text: matchText,
          line: line.key
        });
        pos = p.pos + p.len;
      }
    }

    return [];
  }
}
