.agrar.remove_last_dot:{[addr]
  last_char: last addr;
  $["."=last_char;
  :-1 _ addr;
  :addr];
  };

.agrar.remove_spaces:{[str]
  ssr[;"  ";" "]/[str]
  };

.agrar.remove_street:{[addr]
  no_utca: ssr[addr;"[Uu]tca";""];
  no_ut: ssr[no_utca;"[Úú]t";""];
  no_ut
  };

.agrar.normalize_address:{[address]
  a: string address;
  a1: .agrar.remove_last_dot[a];
  a2: .agrar.remove_street[a1];
  a3: .agrar.remove_spaces[a2];
  `$ upper a3
  };

.agrar.save_csv:{[name;data]
  (hsym `$.agrar.output,name,".csv") 0: "," 0: data;
  };

.agrar.process_file:{[f]
  yr: `$ ssr[ssr[f;.agrar.input,"utf8_";""];".csv";""];
  show "  processing raw data for ", string yr;
  t: ("SISSSSSI";enlist";")0:`$f;
  t: `name`zip`city`address`reason`program`source`amount xcol t;
  t: update year: yr from t;
  t
  };
