function testFunc() {
//  var i = 10;
//  var j = 1 + 1;
//  trace(i, j);
//  var start = haxe.Timer.stamp();
//
//  var check = 0;
//  while (check < 10000000) {
//    check = check + 1;
//  }
//  var end = haxe.Timer.stamp();
//  trace(end - start);
//
//  trace(123456789012);
//  var v = 12345678901200000;
//  trace(v);
  // This is a comment!
  var i = 10; /* This is also
                   a comment! */
  trace("Link: //not-a-comment"); // This will print correctly
  var timer = new haxe.Timer();

  trace(timer);
}