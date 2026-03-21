package bytemod;

import bytemod.compiler.BytemodCompiler;
import bytemod.compiler.BytemodHaxeCompiler;
import bytemod.compiler.IBytemodCompiler;

class BytemodScript {
  public var fileName:String;
  public var fileType:String;
  public var data:CompileResult;

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
    trace(data);
    //trace(data?.importMap.toString());
  }
}
