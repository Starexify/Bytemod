package bytemod;

import haxe.ds.Vector;

class BytemodVM {
  public var symbols:Array<String> = [];
  public var memory:Vector<Float>;
  public var varCounter:Int = 0;

  public var nativeRegistry:Map<String, Dynamic> = new Map();

  public function registerNative(name:String, func:Dynamic) {
    nativeRegistry.set(name, func);
  }

  public function new() {}

  public function execute(bytecode:Array<Int>) {
    if (bytecode == null) return;

    if (memory == null) {
      memory = new Vector<Float>(varCounter);
      for(i in 0...varCounter) memory[i] = 0;
    }

    var pc = 0;
    var stack = new Vector<Float>(256);
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

        case SUB:
          var b = stack[--sp];
          var a = stack[--sp];
          stack[sp++] = a - b;

        case MUL:
          var b = stack[--sp];
          var a = stack[--sp];
          stack[sp++] = a * b;

        case DIV:
          var b = stack[--sp];
          var a = stack[--sp];
          stack[sp++] = a / b;

        case LT:
          var b = stack[--sp];
          var a = stack[--sp];
          stack[sp++] = (a < b) ? 1 : 0;

        case JUMP_IF_FALSE:
          var target = bytecode[pc++];
          if (stack[--sp] == 0) pc = target;

        case JUMP:
          pc = bytecode[pc++];

        case PRINT:
          var argCount = bytecode[pc++];
          var lineNum = bytecode[pc++];

          var args = [];
          for (i in 0...argCount) {
            args.push(stack[--sp]);
          }
          args.reverse();

          // Use Reflect to call Haxe's trace with the array of arguments
          haxe.Log.trace(args.join(", "), { fileName: "testTwo.hx", lineNumber: lineNum, className: "Bytemod", methodName: "script" });

        case CALL_NATIVE:
          var symbolId = bytecode[pc++];
          var path = symbols[symbolId];

          var parts = path.split(".");
          var methodName = parts.pop();
          var className = parts.join(".");

          var cls = Type.resolveClass(className);
          if (cls != null) {
            var result = Reflect.callMethod(cls, Reflect.field(cls, methodName), []);
            stack[sp++] = result;
          } else {
            trace("Error: Could not resolve class " + className);
          }

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