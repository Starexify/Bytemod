import bytemod.Bytemod;
import bytemod.BytemodPrinter;

class Main {
  static function main() {
    Bytemod.init();
    //Bytemod.scriptCache.get("test.hx");
    BytemodPrinter.disassemble(Bytemod.scriptCache.get("testTwo.hx").functions.get("testFunc"));
//    var startVM = Timer.stamp();
    Bytemod.scriptCache.get("testTwo.hx").callFunction("testFunc");
//    var endVM = Timer.stamp();
//    trace('Bytemod VM: ' + (endVM - startVM) + 's');


    // VM
/*    var startVM = Timer.stamp();
    Bytemod.scriptCache.get("testTwo.hx").callFunction("testFunc");
    var endVM = Timer.stamp();

    // NATIVE HAXE
    var startNative = Timer.stamp();
    testFunc();
    var endNative = Timer.stamp();

    trace('--- PERFORMANCE TEST --');
    trace('Bytemod VM: ' + (endVM - startVM) + 's');
    trace('Native Haxe: ' + (endNative - startNative) + 's');*/
  }
}

class TestClass {
  public function toString() return "I am a TestClass instance!";
}