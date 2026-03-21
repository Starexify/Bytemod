package bytemod;

import haxe.ds.Vector;

using StringTools;

class BytemodVM {
  // TODO: Add the ability to use native functions without ts
  public final nativeFunctions:Map<String, Dynamic> = ["haxe.Timer.stamp" => haxe.Timer.stamp];

  public var constants:Array<Dynamic> = [];
  public var symbols:Array<String> = [];

  // Storage
  public var registers:Vector<Dynamic> = new Vector<Dynamic>(256);
  public var globals:Map<Int, Dynamic> = new Map();

  // Execution
  private var bytecode:Array<Int> = [];
  private var pc:Int = 0;

  public function new() {}

  inline function read():Int return bytecode[pc++];

  public function execute(code:Array<Int>, startAddress:Int = 0):Null<Dynamic> {
    this.bytecode = code;
    this.pc = startAddress;
    if (bytecode == null || startAddress < 0 || startAddress >= bytecode.length) return null;

    while (pc < bytecode.length) {
      var op:OpCode = read();
      switch (op) {
        case LDI:
          var regIdx = read();
          var value = read();
          registers[regIdx] = value;

        case RET:
          var regIdx = read();
          return registers[regIdx];

        default:
          trace('Unknown OpCode: ${OpCode.toString(op)} at PC: $pc');
          break;
      }
    }

    return null;
  }
}