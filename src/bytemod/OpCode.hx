package bytemod;

enum abstract OpCode(Int) from Int to Int {
  // Arithmetic Operations
  var ADD  = 0;  // R1 = R2 + R3
  var SUB  = 1;  // R1 = R2 - R3
  var MUL  = 2;  // R1 = R2 * R3
  var DIV  = 3;  // R1 = R2 / R3
  var MOD  = 4;  // R1 = R2 % R3

  // Bitwise Operations (Integers)
  var AND  = 5;  // R1 = R2 & R3
  var OR   = 6;  // R1 = R2 | R3
  var XOR  = 7;  // R1 = R2 ^ R3
  var SHL  = 8;  // R1 = R2 << R3
  var SHR  = 9;  // R1 = R2 >> R3
  var USHR = 10; // R1 = R2 >>> R3

  // Unary Operations
  var NOT  = 11; // R1 = !R2 (Logical)
  var BNOT = 12; // R1 = ~R2 (Binary)
  var NEG  = 13; // R1 = -R2 (Arithmetic)

  // Data Manipulation
  var LDC  = 14; // R1 = constants[i]
  var LDI  = 15; // R1 = i_value
  var MOV  = 16; // R1 = R2

  // Global & Static Operations
  var GETG = 17; // R1 = Global[id]
  var SETG = 18; // Global[id] = R1
  var GETS = 19; // R1 = StaticClass.field
  var SETS = 20; // StaticClass.field = R1

  // Comparison Producers (Return 1 or 0)
  var EQ   = 21; // R1 = R2 == R3
  var NEQ  = 22; // R1 = R2 != R3
  var LT   = 23; // R1 = R2 < R3
  var GT   = 24; // R1 = R2 > R3
  var LTE  = 25; // R1 = R2 <= R3
  var GTE  = 26; // R1 = R2 >= R3
  var IS   = 27; // R1 = R2 is R3

  // OOP / Field Operations
  var NEW  = 28; // R1 = new ScriptClass(args...) // Script
  var NNEW = 29; // R1 = new Class(args...) // Native
  var CALL = 30; // R1 = R2.method(args...) // Script
  var NCALL= 31; // R1 = Reflect.method(R2, args...) // Native
  var GETP = 32; // R1 = R2.field
  var SETP = 33; // R1.field = R2

  // Control Flow (Jumps)
  var JMP  = 34; // pc = target
  var JZ   = 35; // if (!R1) pc = target
  var JNZ  = 36; // if (R1) pc = target
  var JLT  = 37; // if (R1 < R2) pc = target
  var JGT  = 38; // if (R1 > R2) pc = target
  var JEQ  = 39; // if (R1 == R2) pc = target
  var RET  = 40; // return R1

  // Optimization Ops
  var INC  = 41; // R1++
  var DEC  = 42; // R1--

  public static function toString(op:Int):String {
    return switch (op) {
      case ADD: "ADD";
      case SUB: "SUB";
      case MUL: "MUL";
      case DIV: "DIV";
      case MOD: "MOD";

      case AND: "AND";
      case OR: "OR";
      case XOR: "XOR";
      case SHL: "SHL";
      case SHR: "SHR";
      case USHR: "USHR";

      case NOT: "NOT";
      case BNOT: "BNOT";
      case NEG: "NEG";

      case LDC: "LDC";
      case LDI: "LDI";
      case MOV: "MOV";

      case GETG: "GETG";
      case SETG: "SETG";
      case GETS: "GETS";
      case SETS: "SETS";

      case EQ: "EQ";
      case NEQ: "NEQ";
      case LT: "LT";
      case GT: "GT";
      case LTE: "LTE";
      case GTE: "GTE";
      case IS: "IS";

      case NEW: "NEW";
      case NNEW: "NNEW";
      case CALL: "CALL";
      case NCALL: "NCALL";
      case GETP: "GETP";
      case SETP: "SETP";

      case JMP: "JMP";
      case JZ: "JZ";
      case JNZ: "JNZ";
      case JLT: "JLT";
      case JGT: "JGT";
      case JEQ: "JEQ";
      case RET: "RET";

      case INC: "INC";
      case DEC: "DEC";

      default: "UNKNOWN_" + op;
    }
  }
}
