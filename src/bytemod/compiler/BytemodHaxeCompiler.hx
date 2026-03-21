package bytemod.compiler;

import bytemod.compiler.IBytemodCompiler;

using StringTools;

class BytemodHaxeCompiler implements IBytemodCompiler {
  public var fileName:Null<String> = null;
  private var tokens:Array<Token> = [];
  private var cursor:Int = 0;

  private var constants:Array<Dynamic>;
  private var classes:Array<ClassDefinition>;
  private var enums:Array<EnumDefinition>;
  private var bytecode:Array<Int>;

  private var constantIDs:Map<Dynamic, Int>;

  public var packageName:String = "";
  private var importMap:Map<String, String> = new Map();
  private var usingList:Array<String> = [];

  private inline function read():String return tokens[cursor++].text;

  private inline function peek():String return tokens[cursor].text;

  public function new(?fileName:String) {
    this.fileName = fileName ?? "unknown";

    for (key in Bytemod.DEFAULT_IMPORTS.keys()) {
      var clazz = Bytemod.DEFAULT_IMPORTS.get(key);
      var fullPath = Type.getClassName(clazz);
      this.importMap.set(key, fullPath);
    }
  }

  public function compile(?tokens:Array<Token>):CompileResult {
    if (tokens != null) this.tokens = tokens;
    this.cursor = 0;

    this.classes = [];
    this.constants = [];
    this.packageName = "";

    try {
      // Parse the header of the file (imports, usings, packages)
      while (cursor < this.tokens.length) {
        var t = peek();
        if (t == "import" || t == "using" || t == "package") {
          parseHeader();
        }
        else {
          break;
        }
      }
      return createResult(true);

    } catch (e:String) {
      if (e == "__BYTEMOD_FATAL__") return createResult(false);
      // Throw the actual haxe error if it's not a compilation error.
      throw e;
    }
  }

  private function createResult(success:Bool):CompileResult {
    return {
      success: success,
      packageName: packageName,
      constants: success ? constants : [],
      classes: success ? classes : [],
      enums: success ? enums : [],
      bytecode: success ? bytecode : [],
      importMap: importMap,
      usingList: usingList
    };
  }

  public function parseHeader():Void {
    var t = read(); // eat "package" "import" or "using"
    var path = "";

    while (cursor < tokens.length && peek() != ";") {
      path += read();
    }

    switch (t) {
      case 'import':
        var parts = path.split(".");
        var alias = parts[parts.length - 1];
        importMap.set(alias, path);

      case 'using':
        usingList.push(path);

      case 'package':
        if (this.packageName != "") {
          fatal("Only one package declaration is allowed.");
        }
        packageName = path;
    }
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

  public function parseStatement(?tokens:Array<Token>):Void {

  }

  public function parseType(?tokens:Array<Token>):Int {
    return 0;
  }

  public function parseExpression(?tokens:Array<Token>):Void {

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
      while (Constants.HAXE_REGEX.matchSub(line.value, pos)) {
        var p = Constants.HAXE_REGEX.matchedPos();
        var matchText = Constants.HAXE_REGEX.matched(0);
        tokens.push({text: matchText, line: line.key});
        pos = p.pos + p.len;
      }
    }

    return tokens;
  }

  private function fatal(msg:String):Null<Dynamic> {
    var line = (cursor < tokens.length) ? tokens[cursor].line : 0;

    BytemodErrorHandler.report(CompileError(msg), fileName, line);

    throw "__BYTEMOD_FATAL__";
    return null;
  }
}
