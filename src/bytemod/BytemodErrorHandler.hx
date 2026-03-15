package bytemod;

enum BytemodErrorType {
  CompileError(msg:String);
  RuntimeError(msg:String);
  Warning(msg:String);
}

class BytemodErrorHandler {
  public static var hasError:Bool = false;
  public static var errorCount:Int = 0;

  private static var log:Array<String> = [];

  public function new() {}

  public static function report(type:BytemodErrorType, file:String, line:Int) {
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

    if (isFatal) {
      hasError = true;
      errorCount++;
    }

    var formatted = '$file:$line: $prefix: $message';
    log.push(formatted);

    Sys.stderr().writeString(formatted + "\n");
  }

  public static function reset() {
    hasError = false;
    errorCount = 0;
    log = [];
  }
}
