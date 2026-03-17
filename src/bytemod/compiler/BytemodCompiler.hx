package bytemod.compiler;

import bytemod.compiler.IBytemodCompiler;

class BytemodCompiler implements IBytemodCompiler {

  public private var constants:Array<Dynamic>;
  public private var classes:Array<ClassDefinition>;
  public private var enums:Array<EnumDefinition>;
  public private var bytecode:Array<Int>;

  public private var classByName:Map<String, Int>;
  public private var constantIDs:Map<Dynamic, Int>;

  public function compile(tokens:Array<Token>):CompileResult {
  }

  public function parseConstants(tokens:Array<Token>):Array<Dynamic> {
  }

  public function parseClass(tokens:Array<Token>):ClassDefinition {
  }

  public function parseEnum(tokens:Array<Token>):EnumDefinition {
  }

  public function parseField(tokens:Array<Token>):FieldDefinition {
  }

  public function parseFunction(tokens:Array<Token>):FunctionDefinition {
  }

  public function parseStatement(tokens:Array<Token>):Void {
  }

  public function parseType(tokens:Array<Token>):Int {
  }

  public function parseExpression(tokens:Array<Token>):Void {
  }

  public function parseBytecode(tokens:Array<Token>):Array<Int> {
  }

  public function tokenize(content:String):Array<Token> {
  }
}
