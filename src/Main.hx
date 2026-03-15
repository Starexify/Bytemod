import bytemod.Bytemod;
import bytemod.BytemodPrinter;

class Main {
  static function main() {
    Bytemod.init();

    //while (true) {
      BytemodPrinter.disassemble(Bytemod.scriptCache.get("testTwo.hx").functions.get("otherFunc"));
      Bytemod.scriptCache.get("testTwo.hx").callFunction("otherFunc");
      Bytemod.scriptCache.get("testTwo.hx").callFunction("otherFunc");
    //}
    // NATIVE HAXE
    //otherFunc();
  }

  static function otherFunc() {
    var testClass:TestClass = new TestClass();
    trace(testClass);
    @:privateAccess trace(testClass.a);

    // Testing while loop
    var start = haxe.Timer.stamp();
    var i = 0;
    while (i < 10000) {
      i = i + 1;
    }
    var end = haxe.Timer.stamp();
    trace(end - start);
  }
}

class TestClass {
  var a:Int = 10;

  public var score(default, set):Int;
  public function set_score(v) {
    this.score = v;
    return v;
  }

  public function toString() return "I am a TestClass instance!";

  public function new() {}
}