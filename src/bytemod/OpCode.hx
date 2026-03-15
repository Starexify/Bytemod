package bytemod;

enum abstract OpCode(Int) from Int to Int {
  var PUSH_CONST:Int = 0;
  var PUSH_STR:Int = 1;
  var GET_VAR:Int = 2;
  var SET_VAR:Int = 3;
  var GET_PROPERTY:Int = 5;
  var SET_PROPERTY:Int = 4;
  var NEW:Int = 6;
  var ADD:Int = 7;
  var SUB:Int = 8;
  var MUL:Int = 9;
  var DIV:Int = 10;
  var IS:Int = 11;
  var RETURN:Int = 12;
  var PRINT:Int = 13;
  var CALL_NATIVE:Int = 14;

  public static function toString(op:Int):String {
    return switch (op) {
      case PUSH_CONST: "PUSH_CONST";
      case PUSH_STR: "PUSH_STR";
      case GET_VAR: "GET_VAR";
      case SET_VAR: "SET_VAR";
      case GET_PROPERTY: "GET_PROPERTY";
      case SET_PROPERTY: "SET_PROPERTY";
      case NEW: "NEW";
      case ADD: "ADD";
      case SUB: "SUB";
      case MUL: "SUB";
      case DIV: "SUB";
      case IS: "IS";
      case RETURN: "RETURN";
      case PRINT: "PRINT";
      case CALL_NATIVE: "CALL_NATIVE";
      default: "UNKNOWN_" + op;
    }
  }
}
