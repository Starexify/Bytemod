package bytemod;

class Constants {
  public static final COMMENT_REGEX:EReg = ~/"[^"]*"|(\/\/[^\n]*)|(\/\*[\s\S]*?\*\/)/g;
  public static final BYTEMOD_REGEX:EReg = ~/"[^"]*"|#[0-9]+|0x[0-9a-fA-F]+|[0-9.]+|[@a-zA-Z_]+|[\[\]\{\},:]/g;
}