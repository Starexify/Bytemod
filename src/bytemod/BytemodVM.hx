package bytemod;

import haxe.ds.Vector;

using StringTools;

class BytemodVM {
  // TODO: Add the ability to use native functions without ts
  public final nativeFunctions:Map<String, Dynamic> = ["haxe.Timer.stamp" => haxe.Timer.stamp];

  public var constants:Array<Dynamic> = [];
  public var symbols:Array<String> = [];
  public var varCounter:Int = 0;

  // Baked constants
  private var bakedConstants:Vector<Float>;

  public var memory:Vector<Float>;
  public var heap:Map<Int, Dynamic> = new Map();
  public var globalHeap:Map<Int, Dynamic> = new Map();
  private var stringPool:Map<String, Int> = new Map();
  private var heapCounter:Int = 0;

  public function new() {}

  public function storeInHeap(obj:Dynamic):Int {
    if (obj is String && stringPool.exists(obj)) return -(stringPool.get(obj) + 1);

    var id = heapCounter++;
    heap.set(id, obj);
    if (obj is String) stringPool.set(obj, id);

    return -(id + 1);
  }

  public function resolveObject(val:Float):Null<Dynamic> {
    if (val < 0) {
      var id = Std.int(-val) - 1;
      return heap.get(id);
    }
    return null;
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

    bakedConstants = new Vector<Float>(constants.length);
    for (i in 0...constants.length) {
      var c = constants[i];
      if (c is String) {
        bakedConstants[i] = storeInHeap(c);
      } else if (c is Float || c is Int) {
        bakedConstants[i] = cast c;
      } else {
        bakedConstants[i] = 0;
      }
    }

    var snapshotCounter = this.heapCounter;

    Sys.println('--- STARTING EXECUTION ---');
    try {
      while (pc < bytecode.length) {
        var op:OpCode = read();

        switch (op) {
          case PUSH_CONST | PUSH_STR: push(bakedConstants[read()]);
          case GET_VAR: push(memory[read()]);
          case SET_VAR: memory[read()] = pop();

          case GET_STATIC:
            var staticId = read();
            if (globalHeap.exists(staticId)) push(globalHeap.get(staticId));
            else push(0);

          case SET_STATIC: globalHeap.set(read(), pop());

          case GET_PROPERTY:
            var fieldId = bakedConstants[read()];
            var fieldName:String = (fieldId < 0) ? resolveObject(fieldId) : Std.string(fieldId);
            var val = pop();
            var instance = resolveObject(val);
            if (instance != null) {
              var val = Reflect.getProperty(instance, fieldName);
              push((val is Float || val is Int) ? val : storeInHeap(val));
            }
            else {
              BytemodErrorHandler.report(RuntimeError('Accessing "$fieldName" on null'), "testTwo.hx", -1);
              throw "BYTEMOD_RUNTIME_ERROR";
            }

          case SET_PROPERTY:
            var fieldId = bakedConstants[read()];
            var fieldName:String = (fieldId < 0) ? resolveObject(fieldId) : Std.string(fieldId);
            var val = pop();
            var instance = resolveObject(pop());
            if (instance != null) {
              var value:Dynamic = resolveObject(val);
              if (value == null) value = val;
              try {
                Reflect.setProperty(instance, fieldName, value);
              }
              catch (e:Dynamic) {
                BytemodErrorHandler.report(RuntimeError('Failed to set "$fieldName" on instance. Type mismatch?'), "testTwo.hx", -1);
                trace("Called push(0)");
              }
            }
            else {
              BytemodErrorHandler.report(RuntimeError('Cannot set property "$fieldName" on null'), "testTwo.hx", -1);
              throw "BYTEMOD_RUNTIME_ERROR";
            }

          case NEW:
            var classId = bakedConstants[read()];
            var className:String = (classId < 0) ? resolveObject(classId) : Std.string(classId);
            var cls = resolveClassSafe(className);

            // Set in heap
            if (cls != null) {
              push(storeInHeap(Type.createInstance(cls, [])));
            }
            else {
              BytemodErrorHandler.report(RuntimeError('Class not found: "$className"'), "testTwo.hx", -1);
              throw "BYTEMOD_RUNTIME_ERROR";
            }

          case LT:
            var b:Float = pop();
            var a:Float = pop();
            push((a < b) ? 1 : 0);

          case ADD:
            var b = pop();
            var a = pop();

            var valA = resolveObject(a);
            var valB = resolveObject(b);

            if (valA is String || valB is String) {
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

            var actualValue:Dynamic = resolveObject(valueId);
            if (actualValue == null) actualValue = valueId;
            var targetObj:Dynamic = resolveObject(targetId);
            if (targetObj == null) targetObj = targetId;

            var isMatch:Bool = false;

            if (targetObj is String) {
              var cls = resolveClassSafe(targetObj);
              if (cls != null) isMatch = Std.isOfType(actualValue, cls);
              else BytemodErrorHandler.report(RuntimeError('Type check failed - Class not found: "$targetObj"'), "testTwo.hx", -1);
            }
            else if (targetObj is Class) {
              isMatch = Std.isOfType(actualValue, targetObj);
            }
            else {
              isMatch = Std.isOfType(actualValue, targetObj);
            }
            push(isMatch ? 1 : 0);

          case JUMP: pc = read();

          case JUMP_IF_TRUE:
            var target = read();
            var cond:Dynamic = pop();
            if (cond != 0 && cond != null && cond != false) pc = target;

          case JUMP_IF_FALSE:
            var target = read();
            var cond:Dynamic = pop();
            if (cond == false || cond == 0 || cond == null) pc = target;

          case PRINT:
            var argCount = read();
            var line = read();

            var args = [];
            for (i in 0...argCount) {
              var val = pop();
              var obj = resolveObject(val);
              if (obj != null) args.push(obj);
              else args.push(val);
            }
            args.reverse();
            haxe.Log.trace(args.join(", "), { fileName: "testTwo.hx", lineNumber: line, className: "Bytemod", methodName: "script" });

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
              var method = Reflect.field(cls, methodName);
              if (method == null) {
                BytemodErrorHandler.report(RuntimeError('Method "$methodName" not found on class "$className"'), "testTwo.hx", -1);
                throw "BYTEMOD_RUNTIME_ERROR";
              }

              var result = Reflect.callMethod(cls, Reflect.field(cls, methodName), []);
              push(result);
            }

          default:
            BytemodErrorHandler.report(RuntimeError('Unknown OpCode: ${OpCode.toString(op)} at PC: ${pc - 1}'), "VM_INTERNAL", -1);
            throw "BYTEMOD_RUNTIME_ERROR";
        }
      }
    }
    catch (e:String) {
      if (e == "BYTEMOD_RUNTIME_ERROR") {
        Sys.println('Execution stopped due to runtime error.');
      } else throw e;
    }
    catch (e:Dynamic) {
      BytemodErrorHandler.report(RuntimeError('Fatal VM Crash: $e'), "VM", -1);
    }

//    Sys.println('--- BAKED CONSTANTS ---');
//    Sys.println(bakedConstants);
//    Sys.println('--- CONSTANTS ---');
//    Sys.println(constants);
//    Sys.println('--- SYMBOLS ---');
//    Sys.println(symbols);
//    Sys.println('--- STRING POOL ---');
//    Sys.println(stringPool.toString());
    Sys.println('--- HEAP BEFORE ---');
    Sys.println(heap.toString());

    // Cleaning the heap and pool
    var current = this.heapCounter;
    while (current > snapshotCounter) {
      current--;
      heap.remove(current);
      for (key in stringPool.keys()) {
        if (stringPool.get(key) == current) {
          stringPool.remove(key);
          break;
        }
      }
    }
    this.heapCounter = snapshotCounter;

    Sys.println('--- EXECUTION FINISHED ---');
//    Sys.println('--- STACK ---');
//    Sys.println(stack);
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

    // Check manually globals or smth later
    return null;
  }
}