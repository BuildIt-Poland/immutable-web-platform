{lib}:
  arr: 
    builtins.unsafeDiscardStringContext (
      lib.concatStrings (
        lib.intersperse "/" (
          builtins.filter (x: !(builtins.isNull x)) arr)))
