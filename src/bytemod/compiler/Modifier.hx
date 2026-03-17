package bytemod.compiler;

enum abstract Modifier(Int) from Int to Int {
  var None      = 0x00;
  var Public    = 0x01;
  var Private   = 0x02;
  var Static    = 0x04;
  var Final     = 0x08;
  var Inline    = 0x10;
  var Dynamic   = 0x20;

  public inline function has(flag:Modifier):Bool {
    return (this & flag) != 0;
  }

  public inline function set(flag:Modifier):Modifier {
    return this | flag;
  }
}