package bytemod;

class BytemodPrinter {
  public static function disassemble(code:Array<Int>) {
    if (code == null) {
      trace('No bytecode found.');
      return;
    }

    trace('--- DISASSEMBLY ---');
    var pc = 0;
    while (pc < code.length) {
      var addr:Int = pc; // Keep track of the current index
      var op:OpCode = code[pc++];

      var hexAddr = "0x" + StringTools.hex(addr, 4);
      var output = '[$hexAddr] ' + OpCode.toString(op);

      // Some opcodes have "arguments" following them in the array
      switch (op) {
        case PUSH_INT | GET_VAR | SET_VAR | JUMP_IF_FALSE | JUMP:
          var arg = code[pc++];
          output += ' ($arg)';
        default: // Math ops like ADD, LT, etc., don't have extra arguments
      }
      trace(output);
    }
    trace('---------------------------');
  }
}
