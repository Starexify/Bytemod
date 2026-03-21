package bytemod;

class Constants {
  public static final COMMENT_REGEX:EReg = ~/"[^"]*"|(\/\/[^\n]*)|(\/\*[\s\S]*?\*\/)/g;
  public static final BYTEMOD_REGEX:EReg = ~/"[^"]*"|#[0-9]+|0x[0-9a-fA-F]+|[0-9.]+|[@a-zA-Z_]+|[\[\]\{\},:]/g;
  public static final HAXE_REGEX:EReg = ~/"([^"\\]|\\.)*"|'([^'\\]|\\.)*'|~\/[^\/\\]*(?:\\.[^\/\\]*)*\/[gimsu]*|\.\.\.|0x[0-9a-fA-F_]+|[0-9][0-9_]*(\.[0-9_]+)?([eE][+-]?[0-9_]+)?|->|>>=|<<=|\?\?=|>>>|>>|<<|\+\+|--|(?:\?\?)|&&|\|\||[\+\-\*\/%&|^<>!=]=?|@[a-zA-Z_:]+|[\$a-zA-Z_]+|[\[\]\{\}\|\^\/(),.;:?=]/g;
}