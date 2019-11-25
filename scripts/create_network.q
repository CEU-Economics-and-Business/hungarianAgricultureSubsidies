\c 25 180
\p 8848

.agrar.process_file:{[f]
  yr: `$ ssr[ssr[f;.agrar.input,"utf8_";""];".csv";""];
  show "  processing raw data for ", string yr;
  t: ("SISSSSSI";enlist";")0:`$f;
  t: `name`zip`city`address`reason`program`source`amount xcol t;
  t: update year: yr from t;
  t
  };

.agrar.load_csvs:{[]
  show "loading raw CSVs";
  .agrar.root: raze system "pwd";
  .agrar.input: .agrar.root,"/../input/csv/";
  .agrar.output: .agrar.root,"/../outout/";

  files: system "ls ",.agrar.input, "utf8_*csv";
  raw_data: raze .agrar.process_file each files;
  show "raw files processed";

  data: update name_parts:{count " " vs string x}'[name] from raw_data;
  data: delete reason, program from delete from data where name_parts>5;
  data: delete from data where name=`;
  delete_list: upper ("*BT*";"*KFT*";"*Alapítvány*";"*Egyesület*";"*ZRT*";"*VÁLLALAT*";"*Önkormányzat*";"*Község*";"*Társulat*";"*Szövetkezet*";"*Asztaltársaság*";"*Vadásztársaság*";"*Intézmény*";"*Társulás*";"*Közösség*";"*Központ*";"*Társaság*";"*szolgálat*";"*Plébánia*";"*Szervezet*";"*Szövetség*";"*Sportklub*";"*Igazgatóság*";"*Intézet*";"*Klub*";"*Baráti köre*");
  data1: delete from data where amount < 1000000;
  data1: delete from data1 where any upper[name] like/: delete_list;
  show "firms and small amounts removed";

  .agrar.raw: update address: .agrar.normalize_address'[address] from data1;
  show ".agrar.raw variable crated - ", string count .agrar.raw;
  };

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

.agrar.init:{[]
  .agrar.load_csvs[];
  };

if[`CREATE_NETWORK=`$.z.x[0];
  .agrar.init[];
  // exit 0;
  ];