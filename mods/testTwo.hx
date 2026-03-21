package test;

import haxe.Timer;
using StringTools;

@test()
class TestClass {
  @testvar()
  var test = 1;

  @testfinal()
  final TEST_FINAL = 100;

  function testOneLiner():Bool return true;

  static function testFunc():Bool {
    return false;
  }
}

enum TestEnum {

}