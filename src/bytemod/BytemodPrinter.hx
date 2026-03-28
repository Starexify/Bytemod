package bytemod;

class BytemodPrinter {
  static inline function toHex(addr)return StringTools.hex(addr, 4);

  public static function disassemble(code:Array<Int>):Void {
    if (code == null) {
      Sys.println('No bytecode found.');
      return;
    }

    var pc = 0;
    inline function read():Int return code[pc++];

    Sys.println('------- DISASSEMBLY -------');
    while (pc < code.length) {
      var addr:Int = pc; // Keep track of the current index
      var op:OpCode = read();

      var output = '[0x${toHex(addr)}] ' + OpCode.toString(op);

      switch (op) {
        // 3-Register Ops: R_dest, R_srcA, R_srcB
        case ADD | SUB | MUL | DIV | MOD | AND | OR | XOR | SHL | SHR | USHR | EQ | NEQ | LT | GT | LTE | GTE | IS:
          output += 'R${read()}, R${read()}, R${read()}';

        // 2-Register Ops: R_dest, R_src
        case MOV | NOT | NEG:
          output += 'R${read()}, R${read()}';

        // Constant/Immediate Ops: R_dest, Index
        case LDC | LDI:
          output += 'R${read()}, #${read()}';

        // Global/Static: R_dest, ID
        case GETG | SETG:
          output += 'R${read()}, G[${read()}]';
        case GETS | SETS:
          output += 'R${read()}, Class[${read()}], Sym[${read()}]';

        // OOP Ops
        case GETP | SETP:
          output += 'R${read()}, R${read()}, Sym[${read()}]';

        case NEW | NNEW:
          output += 'R${read()}, Class[${read()}], Args: ${read()}, Start: R${read()}';

        case CALL | NCALL:
          output += 'R${read()}, R${read()}, Sym[${read()}], Args: ${read()}, Start: R${read()}';

        // Control Flow
        case JMP:
          output += 'target: 0x${toHex(read())}';

        case JZ | JNZ:
          output += 'R${read()}, target: 0x${toHex(read())}';

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
