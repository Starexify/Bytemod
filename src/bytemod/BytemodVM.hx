package bytemod;

import haxe.ds.Vector;

class BytemodVM {
  public var memory:Vector<Int>;
  public var varCounter:Int = 0;

  public function new() {}

  public function execute(bytecode:Array<Int>) {
    if (bytecode == null) return;

    if (memory == null) {
      memory = new Vector<Int>(varCounter);
      for(i in 0...varCounter) memory[i] = 0;
    }

    var pc = 0;
    var stack = new Vector<Int>(256);
    var sp = 0;
    var len = bytecode.length;

    trace('--- STARTING EXECUTION ---');
    while (pc < len) {
      var op:OpCode = bytecode[pc++];

      switch (op) {
        case PUSH_INT:
          stack[sp++] = bytecode[pc++];

        case GET_VAR:
          stack[sp++] = memory[bytecode[pc++]];

        case SET_VAR:
          memory[bytecode[pc++]] = stack[--sp];

        case ADD:
          var b = stack[--sp];
          var a = stack[--sp];
          stack[sp++] = a + b;

        case LT:
          var b = stack[--sp];
          var a = stack[--sp];
          stack[sp++] = (a < b) ? 1 : 0;

        case JUMP_IF_FALSE:
          var target = bytecode[pc++];
          if (stack[--sp] == 0) pc = target;

        case JUMP:
          pc = bytecode[pc++];

        default:
          trace("Unknown OpCode: " + OpCode.toString(op));
      }
    }

    trace('--- EXECUTION FINISHED ---');
    // Trace variable 'a' (ID 0) to see the result
    //trace("Final state of stack: " + stack);
    trace("Final state of memory: " + memory);
  }
}