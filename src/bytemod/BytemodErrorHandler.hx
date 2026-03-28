package bytemod;

enum BytemodErrorType {
  CompileError(msg:String);
  RuntimeError(msg:String);
  Warning(msg:String);
}

class BytemodErrorHandler {
  public static function report(type:BytemodErrorType, file:String, line:Int = -1) {
    var isFatal = true;
    var prefix = "";
    var message = "";

    switch (type) {
      case CompileError(msg):
        prefix = "Compile Error";
        message = msg;
      case RuntimeError(msg):
        prefix = "Runtime Error";
        message = msg;
      case Warning(msg):
        prefix = "Warning";
        message = msg;
        isFatal = false;
    }

    var formatted = '$file:$line: $prefix: $message';

    Sys.stderr().writeString(formatted + "\n");
  }
}
