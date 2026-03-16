package bytemod;

enum abstract OpCode(Int) from Int to Int {
  var PUSH_CONST:Int = 0;
  var PUSH_STR:Int = 1;
  var GET_VAR:Int = 2;
  var SET_VAR:Int = 3;
  var GET_STATIC:Int = 4;
  var SET_STATIC:Int = 5;
  var GET_PROPERTY:Int = 6;
  var SET_PROPERTY:Int = 7;
  var NEW:Int = 8;
  var LT:Int = 9;
  var ADD:Int = 10;
  var SUB:Int = 11;
  var MUL:Int = 12;
  var DIV:Int = 13;
  var IS:Int = 14;
  var JUMP:Int = 15;
  var JUMP_IF_TRUE:Int = 16;
  var JUMP_IF_FALSE:Int = 17;
  var RETURN:Int = 18;
  var PRINT:Int = 19;
  var CALL_NATIVE:Int = 21;

  public static function toString(op:Int):String {
    return switch (op) {
      case PUSH_CONST: "PUSH_CONST";
      case PUSH_STR: "PUSH_STR";
      case GET_VAR: "GET_VAR";
      case SET_VAR: "SET_VAR";
      case GET_STATIC: "GET_STATIC";
      case SET_STATIC: "SET_STATIC";
      case GET_PROPERTY: "GET_PROPERTY";
      case SET_PROPERTY: "SET_PROPERTY";
      case NEW: "NEW";
      case LT: "LT";
      case ADD: "ADD";
      case SUB: "SUB";
      case MUL: "MUL";
      case DIV: "DIV";
      case IS: "IS";
      case JUMP: "JUMP";
      case JUMP_IF_FALSE: "JUMP_IF_FALSE";
      case JUMP_IF_TRUE: "JUMP_IF_TRUE";
      case RETURN: "RETURN";
      case PRINT: "PRINT";
      case CALL_NATIVE: "CALL_NATIVE";
      default: "UNKNOWN_" + op;
    }
  }
}
