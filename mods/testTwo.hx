function otherFunc() {
  var testClass = new Test.TestClass();
  trace(testClass);
  testClass.a = 2;
  trace(testClass.a);
  testClass.B = 2;
  trace(testClass.B);
  testClass.c = 2;
  trace(testClass.c);

  var text = "Text";
  trace(text);
  trace(tex);
}

function anotherFunc() {
  trace("Test");
}

function testTracing() {
  var start = haxe.Timer.stamp();
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  trace("Test");
  var end = haxe.Timer.stamp();
  trace(end - start);
}

function testSuite() {
  // --- STATIC TEST ---
//  static var i = 0;
//  trace(i);
//  i = i + 1;

  // --- FINALS TEST ---
//  final j = 1;
//  j = j + 1;
//  trace(j);
}