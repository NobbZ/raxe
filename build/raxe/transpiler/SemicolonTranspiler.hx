package raxe.transpiler;using Lambda;using StringTools;// vim: set ft=rb:

import raxe.tools.StringHandle;

class SemicolonTranspiler implements Transpiler{

public var counter : Array<Int>

public function new(){
  counter = Array<Int>new ();
};

dynamic public function tokens() : Array<String>{
  return [
    ")", "}", ";",
    "#", "\"",
    "@", "//", "/**", "**/",
    "=", "+", "-", "*", ".", "/", "," , "|", "&", "{", "(", "[", "^", "%", "<", ">", "~",
    "if", "for", "while", "else", "try", "catch",
  ];
};

dynamic public function transpile(handle : StringHandle){
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

dynamic public function skipLines(handle : StringHandle){
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
    }else if(handle.is("<")){
      var count = 1;
      var position = handle.position;
      handle.increment();

      while(safeNextToken(handle)){
        if(handle.is(">")){
          count = count - 1;
          handle.increment();
        }else if(handle.is("<")){
          count = count + 1;
          handle.increment();
        }else if(handle.is(",")){
          handle.increment();
        }else{
          if (count == 1){
            handle.position = position;
          }
          break;
        }
      };

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
    }else{
      break;
    }
  };

  handle.nextTokenLine();
};

dynamic public function onlyWhitespace(content : String, from : Int, to : Int){
  var sub = content.substr(from, to - from);
  var regex =new  EReg("^\\s*$", "");
  return regex.match(sub);
};

private dynamic function safeNextToken(handle : StringHandle) : Bool{
  handle.nextToken();

  if (safeCheck(handle, "if") && safeCheck(handle, "for") && safeCheck(handle, "while") &&
      safeCheck(handle, "else")  && safeCheck(handle, "try") && safeCheck(handle, "catch")){
    return true;
  }else{
    handle.increment();
    return safeNextToken(handle);
  }
};

private dynamic function safeCheck(handle : StringHandle, content : String) : Bool{
  if(handle.is(content)){
    return handle.safeis(content);
  }

  return true;
};

}