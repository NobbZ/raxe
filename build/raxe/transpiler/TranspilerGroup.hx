package raxe.transpiler;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.tools.StringHandle;

class TranspilerGroup{

public var transpilers : Array<Transpiler>

public function new(){
  transpilers = Array<Transpiler>new ();
};

dynamic public function push(transpiler : Transpiler) : TranspilerGroup{
  transpilers.push(transpiler);
  return this;
};

}