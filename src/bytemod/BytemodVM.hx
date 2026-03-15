package bytemod;

import haxe.ds.Vector;

using StringTools;

class BytemodVM {
  public var constants:Array<Dynamic> = [];
  public var symbols:Array<String> = [];
  public var varCounter:Int = 0;

  // TODO: Add the ability to use native functions without ts
  public var nativeFunctions:Map<String, Dynamic> = [
    "haxe.Timer.stamp" => haxe.Timer.stamp,
    "Math.random" => Math.random,
    "Math.floor" => Math.floor
  ];

  public var memory:Vector<Float>;

  public var globalHeap:Map<Int, Dynamic> = new Map();
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
      for (i in 0...varCounter) memory[i] = 0;

      this.heapCounter = varCounter;
    }
    var snapshotCounter = this.heapCounter;

    var pc:Int = 0;
    var stack:Vector<Dynamic> = new Vector<Dynamic>(256);
    var sp:Int = 0;
    var len:Int = bytecode.length;

    Sys.println('--- STARTING EXECUTION ---');
    while (pc < len) {
      var op:OpCode = bytecode[pc++];

      switch (op) {
        case PUSH_CONST:
          var id = bytecode[pc++];
          stack[sp++] = constants[id];

        case PUSH_STR:
          var constId = bytecode[pc++];
          var str = constants[constId];

          var foundId:Int = -1;
          for (key in heap.keys()) {
            if (heap.get(key) == str) {
              foundId = key;
              break;
            }
          }
          if (foundId != -1) {
            stack[sp++] = foundId;
          } else {
            stack[sp++] = storeInHeap(str);
          }

        case GET_VAR:
          stack[sp++] = memory[bytecode[pc++]];

        case SET_VAR:
          var slot = bytecode[pc++];
          memory[slot] = stack[--sp];

        case GET_PROPERTY:
          var constId = bytecode[pc++];
          var fieldName:String = constants[constId];
          var objectId = stack[--sp];

          var instance = resolveObject(objectId);
          if (instance != null) {
            var val = Reflect.getProperty(instance, fieldName);
            if (val is Float || val is Int) {
              stack[sp++] = val;
            }
            else {
              stack[sp++] = storeInHeap(val);
            }
          }
          else {
            trace("Error: Accessing property " + fieldName + " on null");
            stack[sp++] = 0;
          }

        case SET_PROPERTY:
          var constId = bytecode[pc++];
          var fieldName:String = constants[constId];
          var val = stack[--sp];
          var objectId = stack[--sp];

          var instance = resolveObject(objectId);
          if (instance != null) {
            var value = heap.exists(Std.int(val)) ? heap.get(Std.int(val)) : val;
            try {
              Reflect.setProperty(instance, fieldName, value);
            } catch (e:Dynamic) {
              // Log a warning instead of crashing the whole VM
              trace('[Bytemod] Cannot set property "$fieldName" on ' + Type.getClassName(Type.getClass(instance)));
            }
          }

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

        case LT:
          var b:Float = stack[--sp];
          var a:Float = stack[--sp];
          stack[sp++] = (a < b) ? 1 : 0;

        case ADD:
          var b:Dynamic = stack[--sp];
          var a:Dynamic = stack[--sp];
          if (a is String || b is String) {
            stack[sp++] = Std.string(a) + Std.string(b);
          } else {
            stack[sp++] = (a : Float) + (b : Float);
          }

        case SUB:
          var b:Float = stack[--sp];
          var a:Float = stack[--sp];
          stack[sp++] = a - b;

        case MUL:
          var b:Float = stack[--sp];
          var a:Float = stack[--sp];
          stack[sp++] = a * b;

        case DIV:
          var b:Float = stack[--sp];
          var a:Float = stack[--sp];
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

        case JUMP:
          pc = bytecode[pc++];

        case JUMP_IF_FALSE:
          var target = bytecode[pc++];
          var condition = stack[--sp];
          if (condition == 0 || condition == 0.0) {
            pc = target;
          }

        case PRINT:
          var argCount = bytecode[pc++];
          var lineNum = bytecode[pc++];

          var args = [];
          for (i in 0...argCount) {
            var val = stack[--sp];
            var id = Std.int(val);
            if (heap.exists(id)) args.push(heap.get(id));
            else args.push(val);
          }
          args.reverse();
          haxe.Log.trace(args.join(", "), { fileName: "testTwo.hx", lineNumber: lineNum, className: "Bytemod", methodName: "script" });

        case CALL_NATIVE:
          var symbolId = bytecode[pc++];
          var argCount = bytecode[pc++];
          var path = symbols[symbolId];

          if (nativeFunctions.exists(path)) {
            var func = nativeFunctions.get(path);
            stack[sp++] = func();
          } else {

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
          }

        default:
          trace("Unknown OpCode: " + OpCode.toString(op));
      }
    }

    Sys.println('--- CONSTANTS ---');
    Sys.println(constants);
    Sys.println('--- SYMBOLS ---');
    Sys.println(symbols);
    Sys.println('--- HEAP BEFORE ---');
    Sys.println(heap.toString());
    var current = this.heapCounter;
    while (current > snapshotCounter) {
      current--;
      heap.remove(current);
    }
    this.heapCounter = snapshotCounter;

    Sys.println('--- EXECUTION FINISHED ---');
    Sys.println('--- STACK ---');
    Sys.println(stack);
    Sys.println('--- GLOBAL HEAP ---');
    Sys.println(globalHeap.toString());
    Sys.println('--- HEAP ---');
    Sys.println(heap.toString());
    Sys.println('--- MEMORY ---');
    Sys.println(memory);
    Sys.println('---------------------------');
  }

  public function fullReset() {
    this.heap = new Map();
    this.heapCounter = varCounter;
    this.memory = new Vector<Float>(varCounter);
    for (i in 0...varCounter) memory[i] = 0;
  }

  private function resolveObject(val:Dynamic):Null<Dynamic> {
    var id = Std.int(val);

    if (val == id) {
      if (heap.exists(id)) return heap.get(id);
      if (globalHeap.exists(id)) return globalHeap.get(id);
    }

    return null;
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