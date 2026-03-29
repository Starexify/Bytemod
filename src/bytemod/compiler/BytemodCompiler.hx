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

  private var constantIDs:Map<String, Int>;

  private inline function read():String return tokens[cursor++].text;
  private inline function peek():Token return tokens[cursor];

  public function new() {}

  public function compile(?tokens:Array<Token>):CompileResult {
    return {
      success: false,
      packageName: null,
      constants: [],
      classes: [],
      enums: [],
      bytecode: [],
      importMap: new Map(),
      usingList: []
    };
  }

  public function parseConstants(?tokens:Array<Token>):Array<Dynamic> {
    return null;
  }

  public function parseClass(meta:Array<MetadataEntry>):ClassDefinition {
    return null;
  }

  public function parseEnum(meta:Array<MetadataEntry>):EnumDefinition {
    return null;
  }

  public function parseField(meta:Array<MetadataEntry>, flags:Modifier):VariableDefinition {
    return null;
  }

  public function parseFunction(meta:Array<MetadataEntry>, flags:Modifier):FunctionDefinition {
    return null;
  }

  public function parseStatement(?tokens:Array<Token>):Void {}

  public function parseType(?tokens:Array<Token>):Int {
    return 0;
  }

  public function parseExpression(minPrecedence:Int = 0):Int {
    return 0;
  }

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
        tokens.push({text: matchText, line: line.key});
        pos = p.pos + p.len;
      }
    }

    return tokens;
  }
}
