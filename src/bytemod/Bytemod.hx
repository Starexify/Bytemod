package bytemod;

import sys.FileSystem;
import haxe.io.Path;
import sys.io.File;

class Bytemod {
  public static var scriptCache:Map<String, BytemodScript> = new Map();

  public static function init() {
    final folder = getModsFolder();

    if (!FileSystem.exists(folder)) {
      FileSystem.createDirectory(folder);
      return;
    }

    scanMods();
  }

  public static function scanMods(?targetFolder:String) {
    final folder = targetFolder == null ? getModsFolder() : targetFolder;

    if (!FileSystem.exists(folder)) return;

    for (item in FileSystem.readDirectory(folder)) {
      var path = Path.join([folder, item]);

      if (FileSystem.isDirectory(path)) scanMods(path);
      else if (StringTools.endsWith(item, ".bm")) {
        var content = File.getContent(path);
        var script = new BytemodScript(item, content, "Bytemod");
        scriptCache.set(item, script);
        trace('Loaded script file: $item');
      }
    }
  }

  public static function getModsFolder():String {
    // TODO: REMOVE TO TEST INDIVIDUALLY IN APPLICATION SOURCE INSTEAD OF PROJECT ROOT DIR
    return "mods/";
/*    var exePath = Sys.programPath();
    var exeDir = Path.directory(exePath);
    return Path.join([exeDir, "mods/"]);*/
  }
}