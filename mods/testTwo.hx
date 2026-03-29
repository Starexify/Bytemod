package test;

import haxe.Timer;

using StringTools;

class TestClass {
  function testGetS() {
    return TestClass.e;
  }

  static var e = 100;
  function testGetSS() {
    return e;
  }

  static function testFunc():Float {
    return 10;
  }
}

enum TestEnum {
}