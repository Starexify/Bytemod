package bytemod;

import haxe.ds.Vector;

using StringTools;

class BytemodVM {
  public var scriptName = "";

  // TODO: Add the ability to use native functions without ts
  public final nativeFunctions:Map<String, Dynamic> = ["haxe.Timer.stamp" => haxe.Timer.stamp];

  public static var staticFields:Map<String, Map<String, Dynamic>> = new Map();

  public var constants:Array<Dynamic> = [];
  public var symbols:Array<String> = [];

  // Storage
  public var registers:Vector<Float> = new Vector<Float>(256);
  public var dynRegisters:Vector<Dynamic> = new Vector<Dynamic>(256);

  public function new() {}

  public function execute(code:Array<Int>, startAddress:Int = 0, funcName:String = 'unknown'):Null<Dynamic> {
    var regs = this.registers;
    var dRegs = this.dynRegisters;
    var b = code;
    var p = startAddress;
    #if debug trace(p, b); #end

    #if debug Sys.println('--- STARTING REGISTRY $funcName EXECUTION ---'); #end
    try {
      while (p < b.length) {
        var op:OpCode = b[p++];
        switch (op) {
          case ADD | SUB | MUL | DIV:
            final dest = b[p++];
            final left = b[p++];
            final right = b[p++];

            final valA = regs[left];
            final valB = regs[right];

            var res:Float = 0;
            switch(op) {
              case ADD: res = valA + valB;
                #if debug trace(OpCode.toString(op) + ' R$dest $valA + $valB = $res'); #end
              case SUB: res = valA - valB;
                #if debug trace(OpCode.toString(op) + ' R$dest $valA - $valB = $res'); #end
              case MUL: res = valA * valB;
                #if debug trace(OpCode.toString(op) + ' R$dest $valA * $valB = $res'); #end
              case DIV: res = valA / (valB == 0 ? 1 : valB);
                #if debug trace(OpCode.toString(op) + ' R$dest $valA / $valB = $res'); #end
              default:
            }
            regs[dest] = res;
            dRegs[dest] = res;

          case MOD:

          case AND:
          case OR:
          case XOR:
          case SHL:
          case SHR:
          case USHR:

          case NOT:
          case BNOT:
          case NEG:

          case LDC:
            final r1 = b[p++];
            final constIdx = b[p++];
            final val:Dynamic = this.constants[constIdx];
            dRegs[r1] = val;
            if (val is Float || val is Int) {
              regs[r1] = cast val;
            }
            #if debug trace(OpCode.toString(op) + ' R$r1 c[$val]'); #end

          case LDI:
            final r1 = b[p++];
            final i_val = b[p++];
            regs[r1] = i_val;
            dRegs[r1] = i_val;
            #if debug trace(OpCode.toString(op) + ' R$r1 $i_val'); #end

          case MOV:
            final dest = b[p++];
            final src = b[p++];
            regs[dest] = regs[src];
            dRegs[dest] = dRegs[src];
            #if debug trace(OpCode.toString(op) + ' R$src -> R$dest'); #end

          case GETS:
            final dest = b[p++];
            final classID = b[p++];
            final fieldID = b[p++];

            final className = this.constants[classID];
            final fieldName = this.constants[fieldID];

            var val:Dynamic = BytemodVM.staticFields.get(className)?.get(fieldName);
            if (val == null) {
              var nativeClass:Class<Dynamic> = Type.resolveClass(className);
              if (nativeClass != null) val = Reflect.getProperty(nativeClass, fieldName);
            }

            if (val == null) {
              BytemodErrorHandler.report(RuntimeError('Could not resolve $className.$fieldName'), this.scriptName, -1);
              return null;
            }

            dRegs[dest] = val;
            if (val is Float || val is Int) regs[dest] = cast val;
            #if debug trace(OpCode.toString(op) + ' $className.$fieldName -> R$dest ($val)'); #end

          case SETS:

          case EQ:
          case NEQ:
          case LT:
          case GT:
          case LTE:
          case GTE:
          case IS:

          case NEW:
          case NNEW:
          case CALL:
          case NCALL:
          case GETP:
          case SETP:

          case JMP:
          case JZ:
          case JNZ:
          case JLT:
          case JGT:
          case JEQ:
          case RET:
            final regIdx = b[p++];
            final r1 = dRegs[regIdx];
            #if debug trace(OpCode.toString(op), r1); #end
            return r1;

          case INC:
          case DEC:

          default:
            #if debug trace('Unknown OpCode: ${OpCode.toString(op)} at PC: $p'); #end
            break;
        }
      }
    }
    catch (e:Dynamic) {
      BytemodErrorHandler.report(RuntimeError('VM Execution Error in $funcName: $e'), this.scriptName ?? "unknown");
    }

    #if debug Sys.println('--- FINISHED REGISTRY EXECUTION ---');
    Sys.println('--- CONSTANTS ---');
    trace(constants);
    Sys.println('--- SYMBOLS ---');
    trace(symbols);
    Sys.println('--- REGISTERS ---');
    trace(registers);
    #end
    return null;
  }
}