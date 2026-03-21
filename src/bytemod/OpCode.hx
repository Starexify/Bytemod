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
  var NEG  = 12; // R1 = -R2 (Arithmetic)

  // Data Manipulation
  var LDC  = 13; // R1 = constants[i]
  var LDI  = 14; // R1 = integer_value
  var MOV  = 15; // R1 = R2

  // Global & Static Operations
  var GETG = 16; // R1 = Global[id]
  var SETG = 17; // Global[id] = R1
  var GETS = 18; // R1 = StaticClass.field
  var SETS = 19; // StaticClass.field = R1

  // Comparison Producers (Return 1 or 0)
  var EQ   = 20; // R1 = R2 == R3
  var NEQ  = 21; // R1 = R2 != R3
  var LT   = 22; // R1 = R2 < R3
  var GT   = 23; // R1 = R2 > R3
  var LTE  = 24; // R1 = R2 <= R3
  var GTE  = 25; // R1 = R2 >= R3
  var IS   = 26; // R1 = R2 is R3

  // OOP / Field Operations
  var NEW  = 27; // R1 = new Class(args...)
  var CALL = 28; // R1 = R2.method(args...)
  var GETP = 29; // R1 = R2.field
  var SETP = 30; // R1.field = R2

  // Control Flow (Jumps)
  var JMP  = 31; // pc = target
  var JZ   = 32; // if (!R1) pc = target
  var JNZ  = 33; // if (R1) pc = target
  var RET  = 34; // return R1 (Crucial for functions!)

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
      case CALL: "CALL";
      case GETP: "GETP";
      case SETP: "SETP";

      case JMP: "JMP";
      case JZ: "JZ";
      case JNZ: "JNZ";
      case RET: "RET";

      default: "UNKNOWN_" + op;
    }
  }
}
