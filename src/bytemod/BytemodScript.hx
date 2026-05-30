package bytemod;

import bytemod.BytemodErrorHandler;
import bytemod.compiler.BytemodCompiler;
import bytemod.compiler.BytemodHaxeCompiler;
import bytemod.compiler.IBytemodCompiler;
import bytemod.compiler.Modifier;
import haxe.Timer;

class BytemodScript {
  public var fileName:String;
  public var fileType:String;
  public var data:CompileResult;
  public var functionMap:Map<String, Int> = new Map();

  public var vm:BytemodVM;

  public function new(name:String, code:String, fileType:String) {
    this.fileName = name;
    this.fileType = fileType;
    this.vm = new BytemodVM();
    vm.scriptName = fileName;

    final compiler:IBytemodCompiler = switch (fileType) {
      case "Bytemod": new BytemodCompiler();
      case "Haxe": new BytemodHaxeCompiler(fileName);
      default: throw "Unsupported script file type: " + fileType;
    }
    compiler.tokenize(code);
    this.data = compiler.compile();

    if (data.bytecode.length < 1) return;
    vm.constants = data.constants;

    for (cls in data.classes) {
      var className = data.constants[cls.nameID];
      var fullyQualifiedClass = className;

      for (field in cls.fields) {
        var fieldName = data.constants[field.nameID];
        // Populate the static fields map
        if (field.flags.has(Modifier.Static)) {
          // Create a new Map for the class inside the VM's staticFields Map
          if (!BytemodVM.staticFields.exists(className)) BytemodVM.staticFields.set(className, new Map());

          BytemodVM.staticFields.get(className).set(fieldName, 100);
          #if debug trace('Initialized Static: $className.$fieldName (Flags: ${field.flags})'); #end
        }
      }

      for (f in cls.functions) {
        var funcName = data.constants[f.nameID];
        var globalKey = fullyQualifiedClass + "." + funcName;
        functionMap.set(globalKey, f.startAddress);
        #if debug trace('Registered Bytecode Path: $globalKey -> Addr: ${f.startAddress}'); #end
      }
    }

    #if debug
    for (func in functionMap.keys()) {
      var start = Timer.stamp();
      var result = call(func);
      var end = Timer.stamp();
      trace("Function call took: " + (end - start));
      trace(result);
    }
    #end
  }

  /**
   * Calls a function stored in the script.
   */
  public function call(name:String, ?args:Array<Dynamic>):Null<Dynamic> {
    if (!functionMap.exists(name)) {
      BytemodErrorHandler.report(BytemodErrorType.RuntimeError('Function "$name" not found in ${fileName}'), fileName);
      return null;
    }
    return vm.execute(data.bytecode, functionMap.get(name), name);
  }

  /**
   * Calls a function from a script's native parent.
   */
  public function callInstance(name:String, nativeInstance:Dynamic, args:Array<Dynamic>):Null<Dynamic> {
    var state:Scriptable = Reflect.field(nativeInstance, "_script");
    if (state == null) return null;

    var globalKey = state.className + "." + name;
    if (!functionMap.exists(globalKey)) {
      BytemodErrorHandler.report(BytemodErrorType.RuntimeError('Function "$name" not found in ${fileName}'), fileName);
      return null;
    }

    vm.registers[0] = Reflect.field(nativeInstance, "_script");

    return vm.execute(data.bytecode, functionMap.get(globalKey), name);
  }

  /**
   * Checks if a function from a scripted class exists.
   */
  public function hasFunction(fullyQualifiedClass:String, functionName:String):Bool {
    return functionMap.exists(fullyQualifiedClass + "." + functionName);
  }
}

class Scriptable {
  public var className:String;
  public var script:BytemodScript;
  public var fields:Map<String, Dynamic> = new Map();
  public var nativeObject:Dynamic;

  public function new(className:String, script:BytemodScript, nativeObject:Dynamic) {
    this.className = className;
    this.script = script;
    this.nativeObject = nativeObject;
  }
}


@:autoBuild(bytemod.macro.IScriptableMacro.build())
interface IScriptable {
//  public var _script:Scriptable;

//  public function _callScriptFunc(name:String, ?args:Array<Dynamic>):Null<Dynamic>;
}