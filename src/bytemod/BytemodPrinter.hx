package bytemod;

class BytemodPrinter {
  static inline function toHex(addr)return StringTools.hex(addr, 4);
  public static function disassemble(code:Array<Int>):Void {
    if (code == null) {
      Sys.println('No bytecode found.');
      return;
    }

    Sys.println('------- DISASSEMBLY -------');
    var pc = 0;
    inline function read():Int return code[pc++];
    while (pc < code.length) {
      var addr:Int = pc; // Keep track of the current index
      var op:OpCode = read();

      var output = '[0x${toHex(addr)}] ' + OpCode.toString(op);

      switch (op) {
        case PUSH_CONST | GET_STATIC | SET_STATIC | GET_VAR | SET_VAR | PUSH_STR | GET_PROPERTY | SET_PROPERTY | NEW: output += ' (${read()})';
        case JUMP | JUMP_IF_FALSE | JUMP_IF_TRUE: output += ' (target: 0x${toHex(read())})';
        case CALL_NATIVE: output += ' (id: ${read()}, args: ${read()})';
        case PRINT: output += ' (args: ${read()}, line: ${read()})';
        default:
      }
      Sys.println(output);
    }
    Sys.println('---------------------------');
  }
}
