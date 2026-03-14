import bytemod.Bytemod;
import bytemod.BytemodPrinter;

class Main {
  static function main() {
    var _ = haxe.Timer;
    var _ = TestClass;
    Bytemod.init();
    //Bytemod.scriptCache.get("test.hx");
//    var startVM = Timer.stamp();
    Bytemod.scriptCache.get("testTwo.hx").callFunction("testFunc");
//    var endVM = Timer.stamp();
//    trace('Bytemod VM: ' + (endVM - startVM) + 's');

    BytemodPrinter.disassemble(Bytemod.scriptCache.get("testTwo.hx").functions.get("testFunc"));

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

}