package bytemod;

import sys.FileSystem;
import haxe.io.Path;
import sys.io.File;

using StringTools;

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
      else {
        var fileType:String = '';

        if (item.endsWith(".bm"))
          fileType = 'Bytemod';
        else if (item.endsWith(".hx"))
          fileType = 'Haxe';

        if (fileType == '') continue;

        var script:BytemodScript = new BytemodScript(item, File.getContent(path), fileType);
        if (script == null) continue;

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