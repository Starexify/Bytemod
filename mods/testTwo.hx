function testFunc() {
  var i = 1;
  trace(i);
//  trace("Link: //not-a-comment");
//  var testClass = new Test.TestClass();
//  trace(testClass);
//  trace(testClass is Test.TestClass);
//  trace(testClass is String);
}

function otherFunc() {
//  var i:Int = 9;
//  trace(i);
  var testClass:Test.TestClass = new Test.TestClass();
  trace(testClass);
  trace(testClass.a);
//  testClass.a = 20;
//  trace(testClass.a);
//  trace(testClass.score);
//  testClass.score = 20;
//  trace(testClass.score);

  var start = haxe.Timer.stamp();
  var end = haxe.Timer.stamp();

  trace(end);
  trace(start);
  trace(end - start);
}