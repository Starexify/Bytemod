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

  public var packageName:String;
  private var importMap:Map<String, String>;
  private var usingList:Array<String>;

  private var registerCount:Int = 0;

  private inline function nextRegister():Int return registerCount++;

  // Map used to check the types for collision
  private var definedTypes:Map<String, String>;

  private inline function read():String return tokens[cursor++].text;

  private inline function peek():String return tokens[cursor].text;

  private function match(text:String):Bool {
    if (cursor < tokens.length && peek() == text) {
      cursor++;
      return true;
    }
    return false;
  }

  private function expect(text:String, ?customMsg:String):Void {
    if (!match(text)) fatal(customMsg ?? 'Expected "$text" but found "${peek()}"');
  }

  public function new(?fileName:String) {
    this.fileName = fileName ?? 'unknown';
    resetImportMap();
  }

  public function compile(?tokens:Array<Token>):CompileResult {
    if (tokens != null) this.tokens = tokens;
    this.cursor = 0;

    this.classes = [];
    this.enums = [];
    this.constants = [];
    this.bytecode = [];
    this.constantIDs = new Map<Dynamic, Int>();
    resetImportMap();
    this.definedTypes = new Map();
    this.usingList = [];
    this.packageName = '';

    try {
      // Parse the header of the file (imports, usings, packages)
      while (cursor < this.tokens.length) {
        var t = peek();
        if (t == 'import' || t == 'using' || t == 'package') parseHeader();
        else break;
      }

      // Parse the objects of the file (class, enum) (excluding fake classes such as interfaces, abstracts and typedefs)
      while (cursor < this.tokens.length) {
        if (match(';')) continue;

        var meta:Array<MetadataEntry> = [];
        while (cursor < this.tokens.length && peek().startsWith('@')) {
          meta.push(parseMetadata());
        }

        if (cursor >= this.tokens.length) break;

        var t = peek();
        switch (t) {
          case 'class': classes.push(parseClass(meta));
          case 'enum': enums.push(parseEnum(meta));
          case 'interface', 'typedef', 'abstract': skipTypeDefinition();
          default: fatal('Unexpected token "$t" at top level.');
        }
      }
      return createResult(true);

    } catch (e:String) {
      if (e == '__BYTEMOD_FATAL__') return createResult(false);
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
    var t = read(); // eat 'package' 'import' or 'using'
    var path = '';

    while (cursor < tokens.length && peek() != ';') {
      path += read();
    }

    expect(';');

    switch (t) {
      case 'import':
        var parts = path.split('.');
        var alias = parts[parts.length - 1];
        importMap.set(alias, path);

      case 'using':
        usingList.push(path);

      case 'package':
        if (this.packageName != '') {
          fatal('Only one package declaration is allowed.');
        }
        packageName = path;
    }
  }

  public function parseConstants(?tokens:Array<Token>):Array<Dynamic> {
    return null;
  }

  public function parseClass(meta:Array<MetadataEntry>):ClassDefinition {
    expect('class');

    var name = read();
    checkDuplicateType(name, 'class');
    var nameID = getConstantID(name);
    var pkgID = getConstantID(this.packageName);

    var classDef:ClassDefinition = {
      id: this.classes.length,
      nameID: nameID,
      pkg: pkgID,
      metadata: meta,
      extendsID: -1,
      interfaces: [],
      fields: [],
      functions: [],
      flags: 0
    };

    expect('{');
    while (cursor < tokens.length && peek() != '}') {
      if (match(';')) continue;

      var memberMeta:Array<MetadataEntry> = [];
      while (cursor < tokens.length && peek().startsWith('@')) {
        memberMeta.push(parseMetadata());
      }

      var flags:Modifier = Modifier.None;
      var collecting = true;
      while (cursor < tokens.length && collecting) {
        var t = peek();
        switch (t) {
          case 'public': read(); flags = flags.set(Modifier.Public);
          case 'private': read(); flags = flags.set(Modifier.Private);
          case 'static': read(); flags = flags.set(Modifier.Static);
          case 'inline': read(); flags = flags.set(Modifier.Inline);
          case 'dynamic': read(); flags = flags.set(Modifier.Dynamic);
          case 'override': read();
          case 'final':
            read();
            flags = flags.set(Modifier.Final);
            var next = peek();
            if (next != 'var' && next != 'function') {
              classDef.fields.push(parseField(memberMeta, flags));
              collecting = false;
            }

          case 'var':
            classDef.fields.push(parseField(memberMeta, flags));
            collecting = false;

          case 'function':
            classDef.functions.push(parseFunction(memberMeta, flags));
            collecting = false;

          default:
            if (flags != Modifier.None) {
              classDef.fields.push(parseField(memberMeta, flags));
            }
            collecting = false;
        }
      }
    }
    expect('}');

    return classDef;
  }

  public function parseEnum(meta:Array<MetadataEntry>):EnumDefinition {
    expect('enum');
    var name = read();
    checkDuplicateType(name, 'enum');
    var nameID = getConstantID(name);
    var pkgID = getConstantID(this.packageName);

    var enumDef:EnumDefinition = {
      id: this.enums.length,
      nameID: nameID,
      pkg: pkgID,
      metadata: meta,
      constructors: []
    };

    expect('{');
    while (cursor < tokens.length && peek() != '}') {
      // TODO: Add fields parsing here
      read();
    }
    expect('}');

    return enumDef;
  }

  public function parseField(meta:Array<MetadataEntry>, flags:Modifier):VariableDefinition {
    match('var'); // check 'var'

    var name = read();
    var nameID = getConstantID(name);
    var typeID:Int = -1;

    if (match(':')) typeID = parseType();

    // Parse the value
    if (match('=')) {
      while (cursor < tokens.length && peek() != ';') {
        read();
      }
    }

    expect(';');

    return {
      metadata: meta,
      nameID: nameID,
      flags: flags,
      typeID: typeID,
      getterID: null,
      setterID: null
    };
  }

  public function parseFunction(meta:Array<MetadataEntry>, flags:Modifier):FunctionDefinition {
    expect('function');

    var name = read();
    var nameID = getConstantID(name);
    var args:Array<ArgumentDefinition> = [];
    var returnTypeID:Int = -1;

    // Parse Arguments (a:Int, b:String)
    expect('(');
    while (cursor < tokens.length && peek() != ')') {
      var isOpt = match('?');

      var argName = read();
      var argNameID = getConstantID(argName);
      var argTypeID = -1;
      var defaultID = -1;

      if (match(':')) argTypeID = parseType();
      if (match('=')) {
        isOpt = true;
        var defaultValue = read();
        defaultID = getConstantID(defaultValue);
      }

      args.push({
        nameID: argNameID,
        typeID: argTypeID,
        opt: isOpt,
        defaultID: defaultID
      });

      if (peek() == ',') read(); // eat ','
    }
    expect(')');

    if (match(':')) returnTypeID = parseType();

    var startAddress = this.bytecode.length;
    this.registerCount = 0;

    if (peek() == '{') {
      parseFunctionBody(true);
    }
    else if (peek() != ';') {
      parseFunctionBody(false);
    }
    else {
      match(';');
      startAddress = -1;
    }

    trace(startAddress);
    trace(bytecode);
    return {
      metadata: meta,
      nameID: nameID,
      flags: flags,
      startAddress: startAddress,
      args: args,
      retID: returnTypeID
    };
  }

  public function parseFunctionBody(isBlock:Bool) {
    if (isBlock) {
      expect('{');
      // Parse block later
      while (cursor < tokens.length && peek() != "}") {
        if (match(";")) continue;
        parseStatement();
      }
      expect('}');
    }
    else {
      parseStatement();
    }
  }

  public function parseStatement(?tokens:Array<Token>):Void {
    if (match("return")) {
      var reg = parseExpression();

      // [OpCode.RET, Register]
      this.bytecode.push(OpCode.RET);
      this.bytecode.push(reg); // Pushes 0

      match(";");
      return;
    }

    // Nothing else is yet allowed so we just read it forever untill reaching the end of the field/function
    while (cursor < this.tokens.length && peek() != ';' && peek() != '}') {
      read();
    }
  }

  public function parseType(?tokens:Array<Token>):Int {
    var typeName = read();
    return getConstantID(typeName);
  }

  public function parseExpression(?tokens:Array<Token>):Int {
    var t = read();
    var targetReg = nextRegister();

    if (t == "true") {
      this.bytecode.push(OpCode.LDI);
      this.bytecode.push(targetReg);
      this.bytecode.push(1);

      return targetReg;
    }

    return targetReg;
  }

  public function parseBytecode(?tokens:Array<Token>):Array<Int> {
    return null;
  }

  public function parseMetadata():MetadataEntry {
    var t = read(); // eat @:<meta>
    var name = t.substring(1);

    var args:Array<String> = [];

    if (match('(')) {
      while (cursor < tokens.length && peek() != ')') {
        args.push(read());
        if (peek() == ',') read();
      }
      expect(')');
    }

    return {
      nameID: getConstantID(name),
      args: args.map(arg -> getConstantID(arg))
    };
  }

  private function checkDuplicateType(name:String, type:String):Void {
    if (definedTypes.exists(name)) {
      var existingType = definedTypes.get(name);
      fatal('Cannot define $type "$name" because it is already defined as a $existingType.');
    }
    definedTypes.set(name, type);
  }

  /**
     * Function that returns the ID of a constant.
     *
     * @param value The value of the constant
     * @return The ID of the constant if it exists already, or a new constant ID if newly added.
     */
  private function getConstantID(value:Dynamic):Int {
    if (this.constantIDs.exists(value)) return this.constantIDs.get(value);

    this.constants.push(value);
    var id = this.constants.length - 1;

    this.constantIDs.set(value, id);

    return id;
  }

  public function tokenize(content:String):Array<Token> {
    // Take comments out first
    content = Constants.COMMENT_REGEX.map(content, e -> {
      var match = e.matched(0);
      if (match.startsWith('"')) return match;
      return '';
    });

    var lines:Array<String> = content.split('\n');

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

  private function resetImportMap():Void {
    this.importMap = new Map<String, String>();

    // Restore the default imports every time we compile a new file
    for (key in Bytemod.DEFAULT_IMPORTS.keys()) {
      var clazz = Bytemod.DEFAULT_IMPORTS.get(key);
      var fullPath = Type.getClassName(clazz);
      this.importMap.set(key, fullPath);
    }
  }

  private function fatal(msg:String):Null<Dynamic> {
    var line = (cursor < tokens.length) ? tokens[cursor].line : 0;

    BytemodErrorHandler.report(CompileError(msg), fileName, line);

    throw '__BYTEMOD_FATAL__';
    return null;
  }

  private function skipTypeDefinition():Void {
    read(); // eat 'interface' 'typedef' or 'abstract'

    // Now parse through the whole object till the end } or typedefs
    while (cursor < tokens.length && peek() != '{' && peek() != '=') {
      read();
    }

    if (match('=')) {
      if (peek() == '{') {
        skipBraces();
      } else {
        while (cursor < tokens.length && peek() != ';') {
          var next = peek();
          if (next == 'class' || next == 'enum' || next.startsWith('@')) break;
          read();
        }
        match(';');
      }
    } else if (peek() == '{') {
      skipBraces();
    }
  }

  private function skipBraces():Void {
    var depth = 0;
    if (match('{')) {
      depth = 1;
      while (cursor < tokens.length && depth > 0) {
        var t = read();
        if (t == '{') depth++;
        if (t == '}') depth--;
      }
    }
  }
}
