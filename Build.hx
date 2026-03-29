import sys.FileSystem;
class Build {
  public static var VERBOSE:Bool = false;

  static function main() {
    var args = Sys.args();

    // haxe --run Build --verbose
    if (args.contains("--verbose")) VERBOSE = true;

    // haxe --run Build clean
    if (args.contains("clean")) {
      cleanFolders();
      if (args.length == 1) return;
    }

    // haxe --run Build build
    if (args.contains("build")) {
      //trace("Compiling C files...");
      //Sys.command("gcc", ["-shared", "-fPIC", "test.c", "-lhl", "-lSDL3", "-o", "test.hdll"]);

      log("Compiling Haxe to HL...");
      Sys.command("haxe", [
        "-cp", "src",
        "-main", "Main",
        "-hl", "bin/hl/out.hl"
      ]);

      log("Running...");
      Sys.command("hl", ["bin/hl/out.hl"]);
    }

    // haxe --run Build compile
    if (args.contains("compile")) {
      if (!FileSystem.exists("bin/hlc")) FileSystem.createDirectory("bin/hlc");
      //trace("Compiling C files...");
      //Sys.command("gcc", ["-shared", "-fPIC", "test.c", "-lhl", "-lSDL3", "-o", "bin/test.hdll"]);

      log("Compiling HashLink...");
      var haxeArgs = [
        "-cp", "src",
        "-main", "Main",
        "-hl", "build/hlc/main.c"
      ];

      if (args.contains("debug")) {
        haxeArgs.push("-D");
        haxeArgs.push("debug");
      }

      Sys.command("haxe", haxeArgs);

      log("Compiling Native...");
      // -O3: Optimize
      // -Isrc: So it finds hlc.h and hl.h
      Sys.command("gcc", [
        //"-O3",
        "build/hlc/main.c",
        "-Ibuild/hlc",
        "-lhl", "-lm",
        "-o", "bin/hlc/out"
      ]);

      log("Running...");
      Sys.command("bin/hlc/out", []);
    }

    // haxe --run Build hxcpp
    if (args.contains("hxcpp")) {
      log("Compiling HXCPP...");
      var exitCode = Sys.command("haxe", [
        "-cp", "src",
        "-lib", "hxcpp",
        "-main", "Main",
        "-cpp", "build/cpp",
        "-D", "analyzer-optimize",
      ]);

      // Move the executable in bin
      if (exitCode != 0) return;

      var exeName = "Main";
      if (!FileSystem.exists("bin/hxcpp")) FileSystem.createDirectory("bin/hxcpp");
      FileSystem.rename("build/cpp/" + exeName, "bin/hxcpp/" + exeName);

      log("Running...");
      Sys.command("bin/hxcpp/" + exeName, []);
    }
  }

  static function cleanFolders() {
    log("Cleaning build folders...");
    Sys.command("rm", ["-rf", "bin", "out"]);
  }

  static function log(msg:String) {
    if (VERBOSE) Sys.println(msg);
  }
}