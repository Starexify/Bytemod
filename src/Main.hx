import bytemod.Bytemod;
import bytemod.BytemodPrinter;

class Main {
  static function main() {
    Bytemod.init();

    //while (true) {
//      BytemodPrinter.disassemble(Bytemod.scriptCache.get("testTwo.hx").functions.get("otherFunc"));
//      Bytemod.scriptCache.get("testTwo.hx").callFunction("otherFunc");

//      BytemodPrinter.disassemble(Bytemod.scriptCache.get("testTwo.hx").functions.get("anotherFunc"));
//      Bytemod.scriptCache.get("testTwo.hx").callFunction("anotherFunc");
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
  final B:Int = 20;
  public var c(never, null):Int;
  public var d(null, never):Int;
  static var e:Int = 10;

  public var score(default, set):Int;

  public function set_score(v) {
    this.score = v;
    return v;
  }

  public function toString() return "I am a TestClass instance!";

  public function new() {}
}