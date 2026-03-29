package bytemod.compiler;

/**
 * An interface used for base compilers.
 *
 * @note This is not a enforced for all the compilers, this is only for templates!
 */
interface IBytemodCompiler {

  // Fields used during the compilation process
  private var tokens:Array<Token>;
  private var cursor:Int;

  private var constants:Array<Dynamic>;
  private var classes:Array<ClassDefinition>;
  private var enums:Array<EnumDefinition>;
  private var bytecode:Array<Int>;

  private var constantIDs:Map<String, Int>;

  /**
   * Function used for compiling
   *
   * @param tokens An array of tokens from the file contents
   * @return The result of the compilation
   */
  public function compile(?tokens:Array<Token>):CompileResult;

  /**
   * Parses a constant from a string of constants.
   *
   *  Example:
   *
   * `tokens = ["10", "+", "20"] -> [10, 20]`
   *
   * @param tokens An array of tokens from the file contents
   * @return An array of constants
   */
  public function parseConstants(?tokens:Array<Token>):Array<Dynamic>;

  /**
   * Parses a class
   *
   *  Example:
   * ```
   * package com.example;
   * @:meta
   * class ExampleClass extends ParentClass implements IClass {
   *   ...
   * }
   * ```
   * Output:
   * ```
   * class:
   *   id: 0
   *   metadata: [#ID]
   *   name: #ID
   *   extends: #ID
   *   interfaces: [#ID]
   *   flags: 0x01
   *   pkg: #ID
   * ```
   * @param meta An array of metadata associated to the class
   * @return The class properties
   */
  public function parseClass(meta:Array<MetadataEntry>):ClassDefinition;

  /**
   * Parses an enum
   *
   *  Example:
   * ```
   * enum ExampleEnum {
   *   Field;
   *   FieldWithArgs(a:Int, b:Bool);
   * }
   * ```
   * Output:
   * ```
   * enum:
   *   id: #ID
   *   name: #ID
   *     fields:
   *       - name: #ID
   *       - name: #ID
   *         args: [#IntID, #BoolID]
   * ```
   * @param meta An array of metadata associated to the enum
   * @return The enum properties
   */
  public function parseEnum(meta:Array<MetadataEntry>):EnumDefinition;

  /**
   * Parses a field
   *
   *  Example:
   * ```
   * @:meta(0)
   * static var field = true;` -> - name: #ID
   *                                flags: 0x04
   *                                meta: [#ID]
   * ```
   * @param meta An array of metadata associated to the field
   * @param flags The field flags
   * @return The field properties
   */
  public function parseField(meta:Array<MetadataEntry>, flags:Modifier):VariableDefinition;

  /**
   * Parses a function
   *
   *  Example:
   * ```
   * @:meta(0)
   * public static function test():Void {
   *   ...
   * }
   * ```
   * Output:
   * ```
   * function:
   *   - name: #ID
   *     metadata: [#ID]
   *     flags: 0x05
   *     ret: #VoidID
   *     start_address: 0x0000
   * ```
   * @param meta An array of metadata associated to the function
   * @param flags The function flags
   * @return The function properties
   */
  public function parseFunction(meta:Array<MetadataEntry>, flags:Modifier):FunctionDefinition;

  /**
   * Parses and handles statements
   *
   *  Example:
   *
   * `token == if -> parseIf();`
   *
   * @param tokens An array of tokens from the file contents
   */
  public function parseStatement(?tokens:Array<Token>):Void;

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
  public function parseType(?tokens:Array<Token>):Int;

  /**
   * Parses logic and math operations to the bytecode stack.
   *
   *  Example:
   *
   * `1 + 1 -> [14, 0, 1, 14, 1, 1, 0, 2, 0, 1]`
   *
   * @param tokens An array of tokens from the file contents
   * @return The ID in the register
   */
  public function parseExpression(minPrecedence:Int = 0):Int;

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
  public function parseBytecode(?tokens:Array<Token>):Array<Int>;

  /**
   * Helper function for tokenizing the contents of a script file.
   *
   * @param content The file content in String format
   * @return The array of tokens
   */
  public function tokenize(content:String):Array<Token>;
}

typedef CompileResult = {
  success:Bool,
  packageName:String,
  constants:Array<Dynamic>,
  classes:Array<ClassDefinition>,
  enums:Array<EnumDefinition>,
  bytecode:Array<Int>,
  importMap:Map<String, String>,
  usingList:Array<String>
}

typedef ObjectDefinition = {
  id:Int,
  nameID:Int,
  pkg:Int,
  metadata:Array<MetadataEntry>
}

typedef ClassDefinition = {
  >ObjectDefinition,
  extendsID:Int,
  interfaces:Array<Int>,
  fields:Array<FieldDefinition>,
  functions:Array<FunctionDefinition>,
  flags:Modifier
}

typedef EnumDefinition = {
  >ObjectDefinition,
  constructors:Array<EnumConstructor>
}

typedef EnumConstructor = {
  nameID:Int,
  index:Int,
  args:Array<Int>
}

typedef FieldDefinition = {
  metadata:Array<MetadataEntry>,
  nameID:Int,
  flags:Modifier,
}

typedef FunctionDefinition = {
  >FieldDefinition,
  startAddress:Int,
  args:Array<ArgumentDefinition>,
  retID:Int
}

typedef ArgumentDefinition = {
  nameID:Int,
  typeID:Int,
  opt:Bool,
  defaultID:Null<Int>
}

typedef VariableDefinition = {
  >FieldDefinition,
  typeID:Int,
  getterID:Null<Int>,
  setterID:Null<Int>
}

typedef MetadataEntry = {
  nameID:Int,
  args:Array<Int>
}

typedef Token = {text:String, line:Int}