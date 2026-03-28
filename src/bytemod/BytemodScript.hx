package bytemod;

import bytemod.compiler.BytemodCompiler;
import bytemod.compiler.BytemodHaxeCompiler;
import bytemod.compiler.IBytemodCompiler;
import bytemod.BytemodErrorHandler;
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
      for (f in cls.functions) {
        var name = data.constants[f.nameID];
        functionMap.set(name, f.startAddress);
      }
    }
    //var start = Timer.stamp();
    for (func in functionMap.keys()) {
      var result = call(func);
      trace(result);
    }
    //trace(Timer.stamp() - start);
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
}
