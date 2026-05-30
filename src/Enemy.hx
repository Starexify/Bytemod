import bytemod.BytemodScript;
import Enemy;

class Enemy implements IScriptable {
  public var health:Int = 100;

  public function new() {
  }

  public function takeDamage(amount:Int):Int {
    this.health -= amount;
    return this.health;
  }
}

class BabyEnemy extends Enemy {
  public function new() {
    super();
  }

  public function babySounds() {
    return "SomeSounds";
  }
}