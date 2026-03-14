package bytemod;

class BytemodPrinter {
  public static function disassemble(code:Array<Int>):Void {
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
        case PUSH_CONST | GET_VAR | SET_VAR:
          var arg = code[pc++];
          output += ' ($arg)';
        case PRINT:
          var count = code[pc++];
          var line = code[pc++];
          output += ' (args: $count, line: $line)';
        case CALL_NATIVE:
          var id = code[pc++];
          output += ' ($id)';

        default: // Math ops like ADD, LT, etc., don't have extra arguments
      }
      trace(output);
    }
    trace('---------------------------');
  }
}
