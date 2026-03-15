function otherFunc() {
  static var i = 0;
  var text = "Text";
  trace(text);

  final j = 1;
  j = j + 1;
  trace(j);

  i = i + 1;
  trace(i);
  i = i + 1;
  i = i + 1;
  i = i + 1;
}
