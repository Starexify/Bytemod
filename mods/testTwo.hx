package test;

import haxe.Timer;

using StringTools;

class TestClass {
//  function testGetS() {
//    return TestClass.e;
//  }
//
//  static var e = 100;
//  function testGetSS() {
//    return e;
//  }
//
//  static function testFunc():Float {
//    return 10 - 100;
//  }
}

class TestEntity extends Enemy {
  override public function takeDamage(amount:Int):Int {
    return 10;
  }
}

class TestBabyEntity extends Enemy.BabyEnemy {
  override public function babySounds():String {
    //return super.babySounds();
    return 99;
  }
}

enum TestEnum {
}