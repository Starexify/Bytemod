package bytemod;

import bytemod.BytemodCompiler;

class BytemodScript {
  public var scriptName:String;
  public var fileName:String;
  public var vm:BytemodVM;

  public var functions:Map<String, Array<Int>> = new Map();

  public function new(name:String, code:String) {
    this.fileName = name;
    this.vm = new BytemodVM();

    final compiler = new BytemodCompiler();
    final result:CompileResult = compiler.compile(BytemodCompiler.tokenize(code));

    vm.symbols = result.nativeSymbols;
    this.functions = result.functions;
    this.vm.varCounter = compiler.varCounter;
    this.vm.constants = compiler.constants;
  }

  public function callFunction(funcName:String):Void {
    Sys.println(' Calling function $funcName from script $fileName');
    if (functions.exists(funcName)) vm.execute(functions.get(funcName));
    else trace('Function with name $funcName() doesn\'t exist !');
  }
}
