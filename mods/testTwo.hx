function testFunc() {
  var i = 10;
  trace("Link: //not-a-comment");
  var testClass = new Test.TestClass();
  trace(testClass);
  trace(testClass is Test.TestClass);
  trace(testClass is String);
}