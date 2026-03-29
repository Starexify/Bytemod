package bytemod.compiler;

import bytemod.compiler.IBytemodCompiler;
import Type.ValueType;

using StringTools;

class BytemodHaxeCompiler implements IBytemodCompiler {
  public var fileName:Null<String> = null;
  private var tokens:Array<Token> = [];
  private var cursor:Int = 0;

  private var constants:Array<Dynamic>;
  private var classes:Array<ClassDefinition>;
  private var enums:Array<EnumDefinition>;
  private var bytecode:Array<Int>;

  private var constantIDs:Map<String, Int>;

  private var currentClassName:String = "";
  private var currentFields:Map<String, {id:Int, flags:Modifier}> = new Map();

  public var packageName:String;
  private var importMap:Map<String, String>;
  private var usingList:Array<String>;

  private var registerCount:Int = 0;
  private var registerValues:Map<Int, Dynamic>;
  private var localVariables:Map<String, Int>;

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
    var startTime = haxe.Timer.stamp();
    if (tokens != null) this.tokens = tokens;
    this.cursor = 0;

    this.classes = [];
    this.enums = [];
    this.constants = [];
    this.bytecode = [];
    this.constantIDs = new Map<String, Int>();
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

      var result = createResult(true);
      #if debug
      trace('Compilation took: ${haxe.Timer.stamp() - startTime}s');
      if (result.success && result.classes.length > 0) {
        for (cls in result.classes) {
          for (func in cls.functions) {
            var code = result?.bytecode.slice(func.startAddress);
            trace(constants[func.nameID], code);
            BytemodPrinter.disassemble(code, result.constants);
          }
        }
      }
      #end

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
    this.currentClassName = name;
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
          case 'dynamic': read();
          case 'override': read();
          case 'final': read(); flags = flags.set(Modifier.Final);
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
            } else {
              var unknown = read();
              fatal('Unexpected token "$unknown" inside class body.');
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

    currentFields.set(name, {id: nameID, flags: flags});

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
    var returnTypeID:Int = -1;

    this.registerCount = 0;
    this.localVariables = new Map<String, Int>();
    this.registerValues = new Map();

    // Parse Arguments (a:T, b:T)
    expect('(');
    var args:Array<ArgumentDefinition> = [];
    while (cursor < tokens.length && peek() != ')') {
      var isOpt = match('?');

      var argName = read();
      localVariables.set(argName, nextRegister());
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
      ensureEmitted(reg);

      // [OpCode.RET, Register]
      this.bytecode.push(OpCode.RET);
      this.bytecode.push(reg); // push R1

      match(";");
      return;
    }

    if (match("var")) {
      var name = read();
      var reg = nextRegister();

      // Register the variable name to this register ID
      localVariables.set(name, reg);

      if (match(":")) {
        parseType(); // We skip the type for now as we are dynamic
      }

      if (match("=")) {
        var exprReg = parseExpression();

        if (registerValues.exists(exprReg)) {
          var val = registerValues.get(exprReg);
          // Emit LDI/LDC specifically into OUR variable register
          if (val is Int) {
            this.bytecode.push(OpCode.LDI);
            this.bytecode.push(reg);
            this.bytecode.push(val);
          }
          else {
            this.bytecode.push(OpCode.LDC);
            this.bytecode.push(reg);
            this.bytecode.push(getConstantID(val));
          }
          registerValues.remove(exprReg);
        }
        else {
          this.bytecode.push(OpCode.MOV);
          this.bytecode.push(reg);
          this.bytecode.push(exprReg);
        }
      }
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

  public function parseExpression(minPrecedence:Int = 0):Int {
    var leftReg = parsePrimary();

    while (true) {
      if (cursor >= tokens.length) break;

      var op = peek();
      var prec = getPrecedence(op);

      // If not an operator or lower priority exit this level
      if (prec <= minPrecedence) break;

      read();
      var rightReg = parseExpression(prec);

      ensureEmitted(leftReg);
      ensureEmitted(rightReg);

      var destReg = nextRegister();
      var opcode:Int = switch (op) {
        case "+": OpCode.ADD;
        case "-": OpCode.SUB;
        case "*": OpCode.MUL;
        case "/": OpCode.DIV;
        case "==": OpCode.EQ;
        case "<": OpCode.LT;
        case ">": OpCode.GT;
        default: fatal("Unsupported operator: " + op);
      };

      this.bytecode.push(opcode);
      this.bytecode.push(destReg);
      this.bytecode.push(leftReg);
      this.bytecode.push(rightReg);

      leftReg = destReg;
    }

    return leftReg;
  }

  private function ensureEmitted(reg:Int):Void {
    if (registerValues.exists(reg)) {
      var val = registerValues.get(reg);
      if (val is Int) {
        this.bytecode.push(OpCode.LDI);
        this.bytecode.push(reg);
        this.bytecode.push(val);
      }
      else {
        this.bytecode.push(OpCode.LDC);
        this.bytecode.push(reg);
        this.bytecode.push(getConstantID(val));
      }
      registerValues.remove(reg);
    }
  }

  private function parsePrimary():Int {
    var t = peek();

    // Check for groups
    if (match("(")) {
      var groupReg = parseExpression(0);
      expect(")");
      return groupReg;
    }

    // Check for local variables
    if (localVariables.exists(t)) {
      read();
      return localVariables.get(t);
    }

    // Check for class fields
    if (currentFields.exists(t)) {
      var fieldData = currentFields.get(t);
      read(); // eat name

      var reg = nextRegister();
      if (fieldData.flags.has(Modifier.Static)) {
        this.bytecode.push(OpCode.GETS);
        this.bytecode.push(reg);
        this.bytecode.push(getConstantID(this.currentClassName));
        this.bytecode.push(fieldData.id);
      }
      else {
        // Otherwise, it's an instance property (this.field)
        this.bytecode.push(OpCode.GETP);
        this.bytecode.push(reg);
        this.bytecode.push(0); // R0 is 'this'
        this.bytecode.push(fieldData.id);
      }

      return reg;
    }

    var reg = nextRegister();

    // Check for numbers
    if (~/^[0-9]*\.?[0-9]+$/.match(t)) {
      read();
      var val:Float = Std.parseFloat(t);
      registerValues.set(reg, (val == Std.int(val)) ? Std.int(val) : val);
      return reg;
    }

    // Check for booleans and use constants to store them
    if (t == "true" || t == "false") {
      read();
      registerValues.set(reg, (t == "true"));
      return reg;
    }

    // Check for strings
    if (t.startsWith('"')) {
      read();
      registerValues.set(reg, t.substring(1, t.length - 1));
      return reg;
    }

    if (~/^[a-zA-Z_][a-zA-Z0-9_]*$/.match(t)) {
      var name = read();

      if (match(".")) {
        var fieldName = read();
        var reg = nextRegister();

        this.bytecode.push(OpCode.GETS);
        this.bytecode.push(reg);
        this.bytecode.push(getConstantID(name));
        this.bytecode.push(getConstantID(fieldName));
        return reg;
      }
      fatal("Unknown identifier: " + name);
    }

    fatal("Expected a value or variable, but found: " + t);
    return -1;
  }

  private function getPrecedence(op:String):Int {
    return switch (op) {
      case "||": 1;
      case "&&": 2;
      case "==" | "!=": 3;
      case "<" | ">" | "<=" | ">=": 4;
      case "+" | "-": 5;
      case "*" | "/" | "%": 6;
      default: 0;
    }
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
    var key:String = "";
    var type = Type.typeof(value);

    switch (type) {
      case TInt: key = "i_" + value;
      case TFloat: key = "f_" + value;
      case TBool: key = "b_" + (value ? "true" : "false");
      case TClass(String): key = "s_" + value;
      default: key = "v_" + Std.string(value);
    }

    if (this.constantIDs.exists(key)) return this.constantIDs.get(key);

    var id = this.constants.length;
    this.constants.push(value);
    this.constantIDs.set(key, id);
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
