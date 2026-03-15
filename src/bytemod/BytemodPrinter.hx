package bytemod;

class BytemodPrinter {
  public static function disassemble(code:Array<Int>):Void {
    if (code == null) {
      Sys.println('No bytecode found.');
      return;
    }

    Sys.println('------- DISASSEMBLY -------');
    var pc = 0;
    while (pc < code.length) {
      var addr:Int = pc; // Keep track of the current index
      var op:OpCode = code[pc++];

      var hexAddr = "0x" + StringTools.hex(addr, 4);
      var output = '[$hexAddr] ' + OpCode.toString(op);

      // Some opcodes have "arguments" following them in the array
      switch (op) {
        case PUSH_CONST | GET_VAR | SET_VAR | PUSH_STR | GET_PROPERTY | SET_PROPERTY | CALL_NATIVE | NEW:
          var arg = code[pc++];
          output += ' ($arg)';
        case JUMP | JUMP_IF_FALSE:
          var target = code[pc++];
          var tgAdd = "0x" + StringTools.hex(target, 4);
          output += ' (target: $tgAdd)';

        case PRINT:
          var count = code[pc++];
          var line = code[pc++];
          output += ' (args: $count, line: $line)';

        default: // Math ops like ADD, LT, etc., don't have extra arguments
      }
      Sys.println(output);
    }
    Sys.println('---------------------------');
  }
}
