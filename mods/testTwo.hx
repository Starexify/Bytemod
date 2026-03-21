package test;

import haxe.Timer;
using StringTools;

class Test {
  var test = 1;

  function func():Void {
    trace(test);
    test++;
  }
}