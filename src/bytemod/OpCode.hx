package bytemod;

enum abstract OpCode(Int) from Int to Int {
  var PUSH_CONST:Int = 0;
  var GET_VAR:Int = 1;
  var SET_VAR:Int = 2;
  var NEW:Int = 3;
  var ADD:Int = 4;
  var SUB:Int = 5;
  var MUL:Int = 6;
  var DIV:Int = 7;
  var IS:Int = 8;
  var PRINT:Int = 9;
  var CALL_NATIVE:Int = 10;

  public static function toString(op:Int):String {
    return switch (op) {
      case PUSH_CONST: "PUSH_CONST";
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
