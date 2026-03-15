package bytemod;

import haxe.ds.Vector;

using StringTools;

class BytemodVM {
  // TODO: Add the ability to use native functions without ts
  public final nativeFunctions:Map<String, Dynamic> = ["haxe.Timer.stamp" => haxe.Timer.stamp];

  public var constants:Array<Dynamic> = [];
  public var symbols:Array<String> = [];
  public var varCounter:Int = 0;

  public var memory:Vector<Float>;
  public var heap:Map<Int, Dynamic> = new Map();
  public var globalHeap:Map<Int, Dynamic> = new Map();
  private var heapCounter:Int = 0;

  public function new() {}

  public function storeInHeap(obj:Dynamic):Int {
    var id = heapCounter++;
    heap.set(id, obj);
    return id;
  }

  // Variables used in execution
  var bytecode:Array<Int> = [];
  var stack:Vector<Float> = new Vector<Float>(256);
  var sp:Int = 0;
  var pc:Int = 0;
  inline function read():Int return bytecode[pc++];
  inline function push(val:Float):Void stack[sp++] = val;
  inline function pop():Float return stack[--sp];

  public function execute(code:Array<Int>) {
    this.bytecode = code;
    if (bytecode == null) return;
    this.pc = 0;
    this.sp = 0;

    if (memory == null) {
      memory = new Vector<Float>(varCounter);
      for (i in 0...varCounter) memory[i] = 0;

      this.heapCounter = varCounter;
    }

    var snapshotCounter = this.heapCounter;

    Sys.println('--- STARTING EXECUTION ---');
    while (pc < bytecode.length) {
      var op:OpCode = read();

      switch (op) {
        case PUSH_CONST: push(constants[read()]);
        case PUSH_STR:
          var str = constants[read()];
          var foundId:Int = -1;
          for (key in heap.keys()) {
            if (heap.get(key) == str) {
              foundId = key;
              break;
            }
          }
          if (foundId != -1) push(foundId);
          else push(storeInHeap(str));

        case GET_VAR: push(memory[read()]);
        case SET_VAR: memory[read()] = pop();

        case GET_PROPERTY:
          var fieldName:String = constants[read()];
          var instance = resolveObject(pop());
          if (instance != null) {
            var val = Reflect.getProperty(instance, fieldName);
            push((val is Float || val is Int) ? val : storeInHeap(val));
          }
          else {
            trace("Error: Accessing property " + fieldName + " on null");
            push(0);
          }

        case SET_PROPERTY:
          var fieldName:String = constants[read()];
          var val = pop();
          var instance = resolveObject(pop());
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
          var className:String = constants[read()];
          var cls = resolveClassSafe(className);

          // Set in heap
          if (cls != null) {
            var instance = Type.createInstance(cls, []);
            push(storeInHeap(instance));
          } else {
            trace("Error: Class not found -> " + className);
            push(0);
          }

        case LT:
          var b:Float = pop();
          var a:Float = pop();
          push((a < b) ? 1 : 0);

        case ADD:
          var b = pop();
          var a = pop();

          var valA = heap.get(Std.int(a));
          var valB = heap.get(Std.int(b));

          if (valA is String || valB is String)) {
            var strA = (valA != null) ? Std.string(valA) : Std.string(a);
            var strB = (valB != null) ? Std.string(valB) : Std.string(b);

            push(storeInHeap(strA + strB));
          } else push(a + b);

        case SUB:
          var b:Float = pop();
          var a:Float = pop();
          push(a - b);

        case MUL:
          var b:Float = pop();
          var a:Float = pop();
          push(a * b);

        case DIV:
          var b:Float = pop();
          var a:Float = pop();
          push(a / b);

        case IS:
          var targetId = pop();
          var valueId = pop();

          var actualValue:Dynamic = heap.exists(Std.int(valueId)) ? heap.get(Std.int(valueId)) : valueId;
          var targetObj:Dynamic = heap.exists(Std.int(targetId)) ? heap.get(Std.int(targetId)) : targetId;

          var isMatch:Bool = false;

          if (targetObj is String) {
            var cls = resolveClassSafe(targetObj);
            if (cls != null) isMatch = Std.isOfType(actualValue, cls);
            else trace("Error: 'is' check failed - Class not found: " + targetObj);
          }
          else if (targetObj is Class) {
            isMatch = Std.isOfType(actualValue, targetObj);
          }
          else {
            isMatch = Std.isOfType(actualValue, targetObj);
          }
          push(isMatch ? 1 : 0);

        case JUMP: pc = read();

        case JUMP_IF_FALSE:
          var target = read();
          var condition:Dynamic = pop();
          if (condition == false || condition == 0 || condition == null) pc = target;

        case PRINT:
          var argCount = read();
          var lineNum = read();

          var args = [];
          for (i in 0...argCount) {
            var val = pop();
            var id = Std.int(val);
            if (heap.exists(id)) args.push(heap.get(id));
            else args.push(val);
          }
          args.reverse();
          haxe.Log.trace(args.join(", "), { fileName: "testTwo.hx", lineNumber: lineNum, className: "Bytemod", methodName: "script" });

        case CALL_NATIVE:
          var path = symbols[read()];
          var argCount = read();

          if (nativeFunctions.exists(path)) {
            var func = nativeFunctions.get(path);
            push(func());
          }
          else {

            var parts = path.split(".");
            var methodName = parts.pop();
            var className = parts.join(".");

            var cls = Type.resolveClass(className);
            if (cls != null) {
              var result = Reflect.callMethod(cls, Reflect.field(cls, methodName), []);
              push(result);
            }
            else trace("Error: Could not resolve class " + className);
          }

        default: trace("Unknown OpCode: " + OpCode.toString(op));
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