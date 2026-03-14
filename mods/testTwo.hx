function testFunc() {
  var i = 10;
  var j = 1;
  trace(i, j);
  var start = haxe.Timer.stamp();

  var check = 0;
  while (check < 10000000) {
    check = check + 1;
  }
  var end = haxe.Timer.stamp();
  trace(end - start);

  trace(123456789012);
}