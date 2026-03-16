package bytemod;

import bytemod.compiler.BytemodHaxeCompiler;

class BytemodScript {
  public var scriptName:String;
  public var fileName:String;
  public var vm:BytemodVM;

  public var functions:Map<String, Array<Int>> = new Map();

  public function new(name:String, code:String) {
    this.fileName = name;
    this.vm = new BytemodVM();

    final compiler = new BytemodHaxeCompiler();
    final result:CompileResult = compiler.compile(BytemodHaxeCompiler.tokenize(code));

    this.functions = result.functions;

    vm.symbols = compiler.nativeSymbols;
    vm.varCounter = compiler.varCounter;
    vm.constants = compiler.constants;
  }

  public function callFunction(funcName:String):Void {
    if (functions.exists(funcName)) vm.execute(functions.get(funcName));
    else trace('Function with name $funcName() doesn\'t exist !');
  }
}
