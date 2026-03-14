package bytemod;

enum abstract OpCode(Int) from Int to Int {
  var PUSH_CONST:Int = 0;
  var PUSH_STR:Int = 1;
  var GET_VAR:Int = 2;
  var SET_VAR:Int = 3;
  var NEW:Int = 4;
  var ADD:Int = 5;
  var SUB:Int = 6;
  var MUL:Int = 7;
  var DIV:Int = 8;
  var IS:Int = 9;
  var PRINT:Int = 10;
  var CALL_NATIVE:Int = 11;

  public static function toString(op:Int):String {
    return switch (op) {
      case PUSH_CONST: "PUSH_CONST";
      case PUSH_STR: "PUSH_STR";
      case GET_VAR: "GET_VAR";
      case SET_VAR: "SET_VAR";
      case NEW: "NEW";
      case ADD: "ADD";
      case SUB: "SUB";
      case MUL: "SUB";
      case DIV: "SUB";
      case IS: "IS";
      case PRINT: "PRINT";
      case CALL_NATIVE: "CALL_NATIVE";
      default: "UNKNOWN_" + op;
    }
  }
}
