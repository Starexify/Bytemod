package bytemod;

class BytemodPrinter {
  static inline function toHex(addr)return "0x" + StringTools.hex(addr, 4);

  public static function disassemble(code:Array<Int>, ?constants:Array<Dynamic>):Void {
    if (code == null) {
      Sys.println('No bytecode found.');
      return;
    }
    trace(constants);
    trace(code);

    var pc = 0;
    inline function read():Int return code[pc++];

    function getSym(id:Int):String {
      if (constants == null || id < 0 || id >= constants.length) return '#$id';
      var val:Dynamic = constants[id];

      if (val is String) return '"' + val + '"';
      if (val == true) return "true";
      if (val == false) return "false";

      var strVal = Std.string(val);
      if (!Math.isNaN(Std.parseFloat(strVal))) {
        return strVal;
      }

      // 4. Fallback for everything else (null, objects, etc)
      return strVal;
    }

    Sys.println('------- DISASSEMBLY -------');
    while (pc < code.length) {
      var addr:Int = pc; // Keep track of the current index
      var op:OpCode = read();

      var output = '[${toHex(addr)}] ${OpCode.toString(op)} ';
      switch (op) {
        // 3-Register Ops: R_dest, R_srcA, R_srcB
        case ADD | SUB | MUL | DIV | MOD | AND | OR | XOR | SHL | SHR | USHR | EQ | NEQ | LT | GT | LTE | GTE | IS:
          output += 'R${read()}, R${read()}, R${read()}';

        // 2-Register Ops: R_dest, R_src
        case MOV | NOT | BNOT | NEG | INC | DEC:
          output += 'R${read()}, R${read()}';

        // Constant/Immediate Ops: R_dest, Index
        case LDC:
          output += 'R${read()}, c[${getSym(read())}]';
        case LDI:
          output += 'R${read()}, #${read()}';

        // Static: R_dest, ID
        case GETS | SETS:
          output += 'R${read()}, Class[${read()}], .${getSym(read())}';

        // OOP Ops
        case NEW | NNEW:
          output += 'R${read()}, Class[${read()}], args:${read()}, from:R${read()}';

        case CALL | NCALL:
          output += 'R${read()}, R${read()}, .${getSym(read())}, args:${read()}, from:R${read()}';

        case GETP | SETP:
          output += 'R${read()}, R${read()}, .${getSym(read())}';

        // Control Flow
        case JMP:
          output += '-> ${toHex(read())}';

        case JZ | JNZ:
          output += 'R${read()} -> ${toHex(read())}';

        case JLT | JGT | JEQ:
          output += 'R${read()}, R${read()} -> ${toHex(read())}';

        case RET:
          output += 'R${read()}';

        default:
          output += ' (Unknown OpCode)';
      }
      Sys.println(output);
    }
    Sys.println('---------------------------');
  }
}
