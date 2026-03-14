package bytemod;

import haxe.ds.Vector;

using StringTools;

class BytemodVM {
  public var constants:Array<Dynamic> = [];
  public var symbols:Array<String> = [];
  public var varCounter:Int = 0;

  public var memory:Vector<Float>;

  public var heap:Map<Int, Dynamic> = new Map();
  private var heapCounter:Int = 0;

  public function storeInHeap(obj:Dynamic):Int {
    var id = heapCounter++;
    heap.set(id, obj);
    return id;
  }

  public function new() {}

  public function execute(bytecode:Array<Int>) {
    if (bytecode == null) return;

    if (memory == null) {
      memory = new Vector<Float>(varCounter);
      for(i in 0...varCounter) memory[i] = 0;

      this.heapCounter = varCounter;
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

        case PUSH_STR:
          var constId = bytecode[pc++];
          var str = constants[constId];

          var id = heapCounter++;
          heap.set(id, str);
          stack[sp++] = id;

        case GET_VAR:
          stack[sp++] = memory[bytecode[pc++]];

        case SET_VAR:
          memory[bytecode[pc++]] = stack[--sp];

        case NEW:
          var constId = bytecode[pc++];
          var className:String = constants[constId];
          var cls = resolveClassSafe(className);

          // Set in heap
          if (cls != null) {
            var instance = Type.createInstance(cls, []);
            stack[sp++] = storeInHeap(instance);
          } else {
            trace("Error: Class not found -> " + className);
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
          var targetId = stack[--sp];
          var valueId = stack[--sp];

          var actualValue:Dynamic = heap.exists(Std.int(valueId)) ? heap.get(Std.int(valueId)) : valueId;
          var targetObj:Dynamic = heap.exists(Std.int(targetId)) ? heap.get(Std.int(targetId)) : targetId;

          var isMatch:Bool = false;

          if (Std.isOfType(targetObj, String)) {
            var cls = resolveClassSafe(targetObj);
            if (cls != null) {
              isMatch = Std.isOfType(actualValue, cls);
            } else {
              trace("Error: 'is' check failed - Class not found: " + targetObj);
            }
          }
          else if (Std.isOfType(targetObj, Class)) {
            isMatch = Std.isOfType(actualValue, targetObj);
          }
          else {
            isMatch = Std.isOfType(actualValue, targetObj);
          }

          stack[sp++] = isMatch ? 1.0 : 0.0;

        case PRINT:
          var argCount = bytecode[pc++];
          var lineNum = bytecode[pc++];

          var args = [];
          for (i in 0...argCount) {
            var val = stack[--sp];

            var id = Std.int(val);
            if (id > 0 && heap.exists(id)) args.push(heap.get(id));
            else args.push(val);
          }
          args.reverse();
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
    //trace("Final state of stack: " + stack);
    trace('--- HEAP ---');
    trace(heap);
    trace('--- MEMORY ---');
    trace(memory);
    trace('---------------------------');
  }

  private function resolveClassSafe(className:String):Null<Class<Dynamic>> {
    var cls = Type.resolveClass(className);
    if (cls != null) return cls;

    // Try the "Module_Subtype" format
    cls = Type.resolveClass(className.split(".").join("_"));
    if (cls != null) return cls;

    // Try just the class name (The "Last Name" after the dot)
    if (className.contains(".")) {
      var parts = className.split(".");
      cls = Type.resolveClass(parts[parts.length - 1]);
      if (cls != null) return cls;
    }

    // Check your manual globals or smth later
    return null;
  }
}