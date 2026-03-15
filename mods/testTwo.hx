function otherFunc() {
  var testClass:Test.TestClass = new Test.TestClass();
  trace(testClass);
  trace(testClass.a);

  var start = haxe.Timer.stamp();
  var i = 0;
  while (i < 10000) {
    i = i + 1;
  }
  trace(i);
  var end = haxe.Timer.stamp();

  trace(end);
  trace(start);
  trace(end - start);
}