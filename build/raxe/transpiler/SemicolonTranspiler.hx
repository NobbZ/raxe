package raxe.transpiler;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.tools.StringHandle;

class SemicolonTranspiler implements Transpiler{

public var counter : Array<Int>;

public function new(){
  counter =new  Array<Int>();
};

public function tokens() : Array<String> return{
  return [
    ")", "}", ";",
    "(:", ":)", "#", "\"",
    "@", "//", "/**", "**/",
    "=", "+", "-", "*", ".", "/", "," , "|", "&", "{", "(", "[", "^", "%", "<", ">", "~",
    "if", "for", "while", "else", "try", "catch",
  ];
};

public function transpile(handle : StringHandle) return{
  while(handle.nextTokenLine()){
    skipLines(handle);

    if(handle.is("\n") || handle.is("//")){
      var position = handle.position;
      var isComment = handle.is("//");

      handle.nextToken();
      handle.position = position;

      if(!handle.isOne([")", "]"])){
        handle.insert(";");
        handle.increment();
      }

      if(isComment){
        handle.next("\n");
      }

      handle.increment("\n");
    }else{
      handle.increment();
    }
  }

  return handle.content;
};

public function skipLines(handle : StringHandle) return{
  while(handle.nextTokenLine()){
    if(handle.is("\n") || handle.is("//")){
      var isComment = handle.is("//");
      var position = handle.position;
      handle.prevTokenLine();

      if(handle.isOne(["=", ";", "+", "-", "*", ".", "/", "," , "|", "&", "{", "(", "[", "^", "%", "<", ">", "~", "\n", ]) &&
          onlyWhitespace(handle.content, handle.position + 1, position)){
        handle.position = position;

        if(isComment){
          handle.next("\n");
          handle.increment();
        }else{
          handle.increment("\n");
        }
      }else{
        handle.position = position;

        if(!isComment){
          position = handle.position;
          handle.increment("\n");
          handle.nextToken();

          if(handle.isOne(["=", "+", "-", "*", ".", "/", "," , "|", "&", ")", "]", "^", "%", "<", ">", "~"]) &&
              onlyWhitespace(handle.content, position + 1, handle.position - 1)){
            break;
          }else{
            handle.position = position;
            break;
          }
        }else{
          break;
        }
      }
    }else if(handle.is("\"")){
      handle.increment();

      while(handle.nextToken()){
        if(handle.is("\"") && (handle.content.charAt(handle.position -1) != "\\" ||
            (handle.content.charAt(handle.position -1) == "\\" && handle.content.charAt(handle.position -2) == "\\"))){
          break;
        }

        handle.increment();
      }

      handle.increment();
    }else if(handle.is("#")){
      handle.next("\n");
      handle.increment();
    }else if(handle.is("/**")){
      handle.next("**/");
      handle.increment();
    }else if(handle.is("@")){
      handle.next("\n");
      handle.increment();
    }else if(handle.safeis("if") || handle.safeis("while") || handle.safeis("for") || handle.safeis("else") || handle.safeis("try")|| handle.safeis("catch")){
      if(handle.safeis("else")){
        var position = handle.position;
        handle.nextToken();

        if(!handle.safeis("if")){
          handle.position = position;
        }
      }

      counter.push(0);
      handle.increment();
    }else if(handle.is("{")){
      if(counter.length > 0){
        counter[counter.length - 1] = counter[counter.length - 1] + 1;
      }

      handle.increment();
    }else if(handle.is("}")){
      var position = handle.position;
      handle.prevTokenLine();
      handle.position = position;

      if(!handle.is("\n")){
        handle.insert(";");
        handle.increment();
      }

      handle.nextTokenLine();

      if(counter.length > 0){
        counter[counter.length - 1] = counter[counter.length - 1] - 1;

        if(counter[counter.length - 1] == 0){
          counter.pop();
          handle.increment();
          handle.nextTokenLine();
        }
      }

      if(!handle.safeis("else") && !handle.safeis("catch")){
        handle.increment();
      }
    }else if(handle.is("(:")){
      handle.remove();
      handle.insert("<");
      handle.next(":)");
      handle.remove();
      handle.insert(">");
      handle.increment();
      break;
    }else{
      break;
    }
  };

  handle.nextTokenLine();
};

public function onlyWhitespace(content : String, from : Int, to : Int) return{
  var sub = content.substr(from, to - from);
  var regex =new  EReg("^\\s*$", "");
  return regex.match(sub);
};

}