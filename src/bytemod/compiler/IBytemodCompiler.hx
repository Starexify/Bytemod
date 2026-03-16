package bytemod.compiler;

/**
 * An interface used for base compilers.
 *
 * @note This is not a enforced for all the compilers, this is only for templates!
 */
interface IBytemodCompiler {
  /**
   * Function used for compiling
   *
   * @param tokens An array of tokens from the file contents
   * @return The result of the compilation
   */
  public function compile(tokens:Array<Token>):CompileResult;

  /**
   * Parses a constant from a string of constants.
   *
   *  Example:
   *
   * @param tokens An array of tokens from the file contents
   * @return An array of constants
   */
  public function parseConstants(tokens:Array<Token>):Array<Dynamic>;

  /**
   * Parses a class
   *
   *  Example:
   *
   * @param tokens An array of tokens from the file contents
   * @return The class properties
   */
  public function parseClass(tokens:Array<Token>):ClassDefinition;

  /**
   * Parses an enum
   *
   *  Example:
   *
   * @param tokens An array of tokens from the file contents
   * @return The enum properties
   */
  public function parseEnum(tokens:Array<Token>):EnumDefinition;

  /**
   * Parses a field
   *
   *  Example:
   *
   * @param tokens An array of tokens from the file contents
   * @return The field properties
   */
  public function parseField(tokens:Array<Token>):FieldDefinition;

  /**
   * Parses a function
   *
   *  Example:
   * ```
   * public static function test() {
   *   ...
   * }
   * ```
   * Output:
   * ```
   * function:
   *   - name: #ID
   *     flags: 0x05
   *     start_address: 0x0000
   * ```
   *
   * @param tokens An array of tokens from the file contents
   * @return The function properties
   */
  public function parseFunction(tokens:Array<Token>):FunctionDefinition;

  /**
   * Parses bytecode from stringified bytecode format.
   *
   *  Example:
   *
   * `0x0001 PUSH #ID -> [0, <#ID>]`
   *
   * @param tokens An array of tokens from the file contents
   * @return The instructions in array of integers that we can interpret later
   */
  public function parseBytecode(tokens:Array<Token>):Array<Int>;

  /**
   * Parses and handles statements
   *
   *  Example:
   *
   * `token == if -> parseIf();`
   *
   * @param tokens An array of tokens from the file contents
   */
  public function parseStatement(tokens:Array<Token>):Void;

  /**
   * Parses types
   *
   *  Example:
   *
   * `token == :Type -> <ID from constants>`
   *
   * @param tokens An array of tokens from the file contents
   * @return The #ID from the constants map
   */
  public function parseType(tokens:Array<Token>):Int;

  /**
   * Parses logic and math operations to the bytecode stack.
   *
   *  Example:
   *
   * `1 + 1 -> [0, 1, 0, 1, 10]`
   *
   * @param tokens An array of tokens from the file contents
   * @return The
   */
  public function parseExpression(tokens:Array<Token>):Void;

  /**
   * Helper function for tokenizing the contents of a script file.
   *
   * @param content The file content in String format
   * @return The array of tokens
   */
  public function tokenize(content:String):Array<Token>;
}

typedef CompileResult = {
  constants:Array<Dynamic>,
  classes:Array<ClassDefinition>,
  enums:Array<EnumDefinition>,
  bytecode:Array<Int>
}

typedef ClassDefinition = {
  id:Int,
  nameID:Int,
  extendsID:Int,
  interfaces:Array<Int>,
  fields:Array<FieldDefinition>,
  functions:Array<FunctionDefinition>,
  flags:Int
}

typedef EnumDefinition = {
  id:Int,
  nameID:Int,
  fields:Array<{nameID:Int, args:Array<Int>}>
}

typedef FunctionDefinition = {
  nameID:Int,
  startAddress:Int,
  flags:Int,
  args:Array<{typeID:Int, opt:Bool, defaultID:Null<Int>}>,
  retID:Int
}

typedef FieldDefinition = {
  nameID:Int,
  typeID:Int,
  flags:Int,
  getterID:Null<Int>,
  setterID:Null<Int>
}

typedef Token = {text:String, line:Int}