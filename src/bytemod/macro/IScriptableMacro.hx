package bytemod.macro;

import haxe.macro.Expr.Field;
import haxe.macro.Context;

class IScriptableMacro {
  public static function build():Array<Field> {
    var fields = Context.getBuildFields();

    var localClassRef = Context.getLocalClass();
    if (localClassRef == null) return fields;

    var localClass = localClassRef.get();
    var className = localClass.name;

    #if debug Sys.println('\n--- Macro Scriptable for $className ---'); #end

    var inheritsScriptField = false;
    var currentSuper = localClass.superClass;
    while (currentSuper != null) {
      final superCls = currentSuper.t.get();
      for (f in superCls.fields.get()) {
        if (f.name == "_script") {
          inheritsScriptField = true;
          break;
        }
      }
      if (inheritsScriptField) break;
      currentSuper = superCls.superClass;
    }

    var hasLocalScriptField = false;
    for (f in fields) {
      if (f.name == "_script") {
        hasLocalScriptField = true;
        break;
      }
    }

    if (!inheritsScriptField && !hasLocalScriptField) {
      Sys.println(' Injecting `_script` and `_callScriptFunc` into base class: $className');

      var injectedFields = (macro class {
        public var _script:bytemod.BytemodScript.Scriptable = null;

        public function _callScriptFunc(name:String, ?args:Array<Dynamic>):Null<Dynamic> {
          if (_script != null && _script.script != null) {
            return _script.script.callInstance(name, this, args ?? []);
          }
          return null;
        }
      }).fields;

      fields = fields.concat(injectedFields);
    } else
      #if debug Sys.println(' Skipping injection: $className inherits script properties from parent class.'); #end

    for (f in fields) {
      switch (f.kind) {
        case FFun(func):
          if (f.name == "new" || f.name == "_callScriptFunc") continue;

          var hookName = f.name;
          var origBody = func.expr;
          var argExpressions = [for (arg in func.args) macro $i{arg.name}];

          #if debug Sys.println(' Wrapping Method $className.$hookName()'); #end

          func.expr = macro {
            if (this._script != null && !this._script.bypassScript && this._script.script.hasFunction(this._script.className, $v{hookName})) {
              return this._callScriptFunc($v{hookName}, $a{argExpressions});
            }
            return $origBody;
          };
        default:
      }
    }

    return fields;
  }
}