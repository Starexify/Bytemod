package bytemod;

import haxe.ds.Vector;

class BytemodVM {
  public var constants:Array<Dynamic> = [];
  public var symbols:Array<String> = [];
  public var varCounter:Int = 0;

  public var memory:Vector<Float>;

  public var heap:Map<Int, Dynamic> = new Map();
  private var heapCounter:Int = 0;

  public var globals:Map<String, Dynamic> = new Map();
  public function registerClass(name:String, obj:Dynamic) {
    var id = heapCounter++;
    heap.set(id, obj);
    globals.set(name, id);
  }

  public function new() {}

  public function execute(bytecode:Array<Int>) {
    if (bytecode == null) return;

    if (memory == null) {
      memory = new Vector<Float>(varCounter);
      for(i in 0...varCounter) memory[i] = 0;
    }

    var pc:Int = 0;
    var stack:Vector<Dynamic> = new Vector<Dynamic>(256);
    var sp:Int = 0;
    var len:Int = bytecode.length;

    trace('--- STARTING EXECUTION ---');
    while (pc < len) {
      var op:OpCode = bytecode[pc++];

      switch (op) {
        case PUSH_CONST:
          var id = bytecode[pc++];
          stack[sp++] = constants[id];

        case GET_VAR:
          stack[sp++] = memory[bytecode[pc++]];

        case SET_VAR:
          memory[bytecode[pc++]] = stack[--sp];

        case NEW:
          var classPath = stack[--sp];
          var cls = Type.resolveClass(classPath);

          if (cls != null) {
            var instance = Type.createInstance(cls, []);

            // Put the new instance in the heap!
            var id = heapCounter++;
            heap.set(id, instance);
            stack[sp++] = id; // Push the NEW ID to the stack
          } else {
            trace("Error: Could not resolve " + classPath);
            stack[sp++] = 0;
          }

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

        case IS:
          var target = stack[--sp];
          var value = stack[--sp];

          var classObj:Dynamic = heap.exists(Std.int(target)) ? heap.get(Std.int(target)) : target;
          var actualValue:Dynamic = heap.exists(Std.int(value)) ? heap.get(Std.int(value)) : value;

          var isMatch = Std.isOfType(actualValue, classObj);

          stack[sp++] = isMatch ? 1 : 0;

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