package bytemod;

enum abstract OpCode(Int) from Int to Int {
  var PUSH_INT:Int = 0;
  var GET_VAR:Int = 1;
  var SET_VAR:Int = 2;
  var ADD:Int = 3;
  var SUB:Int = 4;
  var MUL:Int = 5;
  var DIV:Int = 6;
  var LT:Int = 7;
  var GT:Int = 8;
  var EQ:Int = 9;
  var JUMP_IF_FALSE:Int = 10;
  var JUMP:Int = 11;
  var PRINT:Int = 12;
  var CALL_NATIVE:Int = 13;

  public static function toString(op:Int):String {
    return switch (op) {
      case PUSH_INT: "PUSH_INT";
      case GET_VAR: "GET_VAR";
      case SET_VAR: "SET_VAR";
      case ADD: "ADD";
      case SUB: "SUB";
      case MUL: "SUB";
      case DIV: "SUB";
      case LT: "LT";
      case GT: "GT";
      case EQ: "EQ";
      case JUMP_IF_FALSE: "JUMP_IF_FALSE";
      case JUMP: "JUMP";
      case PRINT: "PRINT";
      case CALL_NATIVE: "CALL_NATIVE";
      default: "UNKNOWN_" + op;
    }
  }
}
