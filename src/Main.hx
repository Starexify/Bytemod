import bytemod.Bytemod;
import bytemod.BytemodPrinter;

import Enemy;

class Main {
  static function main() {
    Bytemod.init();

//    var enemy:Enemy = new Enemy();
//    trace(enemy.takeDamage(10));
//
//    var scriptedEnemy:Enemy = Bytemod.createScriptedInstance("TestEntity", "testTwo.hx", new Enemy());
//    trace(scriptedEnemy.takeDamage(100));

//    trace(scriptedEnemy is IScriptable);
//    trace(enemy is IScriptable);

//    var bbEnemy:BabyEnemy = new BabyEnemy();
//    trace(bbEnemy.babySounds());
//
//    var scriptedbbEnemy:BabyEnemy = Bytemod.createScriptedInstance("TestBabyEntity", "testTwo.hx", new BabyEnemy());
//    trace(scriptedbbEnemy.babySounds());
//    trace(scriptedbbEnemy.takeDamage(10));

//    trace(scriptedbbEnemy is BabyEnemy);
//    trace(scriptedbbEnemy is Enemy);
//    trace(bbEnemy is BabyEnemy);
//    trace(bbEnemy is Enemy);

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