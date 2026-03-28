package bytemod;

import haxe.ds.Vector;

using StringTools;

class BytemodVM {
  // TODO: Add the ability to use native functions without ts
  public final nativeFunctions:Map<String, Dynamic> = ["haxe.Timer.stamp" => haxe.Timer.stamp];

  public var constants:Array<Dynamic> = [];
  public var symbols:Array<String> = [];

  // Storage
  public var registers:Vector<Float> = new Vector<Float>(256);
  public var dynRegisters:Vector<Dynamic> = new Vector<Dynamic>(256);
  public var globals:Map<Int, Dynamic> = new Map();

  public function new() {}

  public function execute(code:Array<Int>, startAddress:Int = 0, funcName:String = 'unknown'):Null<Dynamic> {
    var regs = this.registers;
    var dRegs = this.dynRegisters;
    var b = code;
    var p = startAddress;
    trace(p, b);

    inline function read():Int return b[p++];
    inline function readReg():Float return regs[read()];
    inline function readDyn():Dynamic return dRegs[read()];

    Sys.println('--- STARTING REGISTRY $funcName EXECUTION ---');
    try {
      while (p < b.length) {
        var op:OpCode = read();
        switch (op) {
          case ADD:
          case SUB:
          case MUL:
          case DIV:
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
          case LDI:
            final r1 = read();
            final i_val = read();
            regs[r1] = i_val;
            trace(OpCode.toString(op), r1, i_val);
          case MOV:

          case GETG:
          case SETG:
          case GETS:
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
            final r1 = readReg();
            trace(OpCode.toString(op), r1);
            return r1;

          case INC:
          case DEC:

          default:
            trace('Unknown OpCode: ${OpCode.toString(op)} at PC: $p');
            break;
        }
      }
    }
    catch (e:Dynamic) {
      trace("VM Error: " + e);
    }

    Sys.println('--- FINISHED REGISTRY EXECUTION ---');
//    Sys.println('--- CONSTANTS ---');
//    trace(constants);
//    Sys.println('--- SYMBOLS ---');
//    trace(symbols);
//    Sys.println('--- REGISTERS ---');
//    trace(registers);
//    Sys.println('--- OBJ REGISTER ---');
//    trace(objRegs);
//    Sys.println('--- GLOBALS ---');
//    trace(globals);
    return null;
  }
}