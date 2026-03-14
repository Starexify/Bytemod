package bytemod;

enum abstract OpCode(Int) from Int to Int {
  var PUSH_INT:Int = 0;
  var GET_VAR:Int = 1;
  var SET_VAR:Int = 2;
  var ADD:Int = 3;
  var SUB:Int = 4;
  var LT:Int = 5;
  var GT:Int = 6;
  var EQ:Int = 7;
  var JUMP_IF_FALSE:Int = 8;
  var JUMP:Int = 9;

  public static function toString(op:Int):String {
    return switch (op) {
      case PUSH_INT: "PUSH_INT";
      case GET_VAR: "GET_VAR";
      case SET_VAR: "SET_VAR";
      case ADD: "ADD";
      case SUB: "SUB";
      case LT: "LT";
      case GT: "GT";
      case EQ: "EQ";
      case JUMP_IF_FALSE: "JUMP_IF_FALSE";
      case JUMP: "JUMP";
      default: "UNKNOWN_" + op;
    }
  }
}
