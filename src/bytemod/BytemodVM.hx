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

  public function execute(code:Array<Int>) {
    this.bytecode = code;
    this.pc = 0;
    if (bytecode == null || bytecode.length == 0) return;

    while (pc < bytecode.length) {
      var op:OpCode = read();
      trace(OpCode.toString(op));
      switch (op) {

      }
    }
  }
}