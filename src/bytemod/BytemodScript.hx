package bytemod;

import bytemod.compiler.BytemodCompiler;
import bytemod.compiler.IBytemodCompiler;

class BytemodScript {
  public var scriptName:String;
  public var fileName:String;
  public var vm:BytemodVM;

  public var functions:Map<String, Array<Int>> = new Map();

  public function new(name:String, code:String, fileType:String) {
    this.fileName = name;
    this.vm = new BytemodVM();

    final compiler:BytemodCompiler = switch (fileType) {
      case "Bytemod": new BytemodCompiler();
      default: throw "Unsupported script file type: " + fileType;
    }

    compiler.tokenize(code);
    final result:CompileResult = compiler.compile();
  }
}
