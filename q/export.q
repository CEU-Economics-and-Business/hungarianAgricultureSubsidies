\p 8850

system "l ../q/settlements.q";
system "l ../q/geocode.q";
system "l ../q/utils.q";
system "l ../q/elections.q";

.agrar.export.normalize:{[]
  .data.settlements: update settlement_id: i from delete zip_mod,settlement_mod from .data.settlements;

  normalized1: delete zip_mod,settlement_mod,ksh_id,zip,settlement from
    (update settlement: settlement_mod,zip:zip_mod from .data.full) lj
    `zip`settlement xkey select settlement_id,zip,settlement from .data.settlements;

  .data.winners: update winner_id: i from
    select distinct name,gender,address,formatted_address,is_firm,latitude,longitude,settlement_id from normalized1;
  normalized2: delete name_parts,addr_fixed,postcode,name,gender,address,formatted_address,is_firm,latitude,longitude,settlement_id from normalized1 lj
    `name`gender`address`formatted_address`is_firm`latitude`longitude`settlement_id xkey .data.winners;

  .data.funds: update fund_id: i from select distinct reason,program,source,land_based from normalized2;
  .data.wins: delete reason,program,source,land_based from normalized2 lj `reason`program`source`land_based xkey .data.funds;
  };

.agrar.export.save:{[]
  .agrar.save_csv["agrar_settlements"; .data.settlements];
  .agrar.save_csv["agrar_winners"; .data.winners];
  .agrar.save_csv["agrar_funds"; .data.funds];
  .agrar.save_csv["agrar_wins"; .data.wins];
  .agrar.save_csv["agrar_full"; .data.full];
  .agrar.save_csv["settlement_stats"; .data.settlement_stats];
  .agrar.save_csv["win_by_settlements"; .data.win_by_settlements];
  };

.agrar.export.init:{[]
  // load settlement data
  settlements: select settlement:helyseg, ksh_id:ksh_kod, settlement_type:tipus, county:megye, district:jaras_nev,
    district_code:jaras_kod, district_capital:jaras_szekhely, area:terulet, population:nepesseg, homes:lakasok,
    is_capital:{4}'[i] from .ksh.process_settlements_file[];
  county_capitals: `county xkey .ksh.county_capitals[];
  settlements: settlements lj county_capitals;

  settlements: update is_capital:{3}'[i] from settlements where settlement=district_capital;
  settlements: update is_capital:{2}'[i] from settlements where settlement=county_capital;
  settlements: update is_capital:{1}'[i] from settlements where settlement like "Budapest*";
  settlements: delete from settlements where settlement=`Budapest;

  // load agricultural subsidies
  raw_subsidies_0: .agrar.load_csvs[];

  // join geocoded addresses to subsidies
  processed_addresses: .geocode.process_files[];
  clean_addresses: `zip`settlement`address xkey select distinct zip,settlement,address,formatted_address,postcode,latitude,longitude
    from processed_addresses where status=`OK,number_of_results=1;
  raw_subsidies_1_with_clean_addresses: raw_subsidies_0 lj clean_addresses;

  // add zip codes to settlements
  budapest_zips: distinct select from raw_subsidies_1_with_clean_addresses where settlement like "*Budapest*";
  budapest_zips: .agrar.create_bp_zip_key[budapest_zips];
  bp_district_names: `zip_key xkey update zip_key:{"I"$"1",(ssr[;". ker.";""] ssr[;"Budapest ";""] string[x]),"0"}'[settlement] from select from settlements where settlement like "Budapest *";
  budapest_districts: delete zip_key from budapest_zips lj bp_district_names;
  bp_district_name_map: budapest_districts[`zip]!budapest_districts[`settlement];

  raw_subsidies_2_with_zip_mod: update zip_mod: zip ^ postcode from raw_subsidies_1_with_clean_addresses;
  raw_subsidies_3_with_bp_districts: update settlement_mod: settlement ^ bp_district_name_map[zip_mod] from raw_subsidies_2_with_zip_mod;

  zips_by_settlement: select distinct zip_mod by settlement_mod from raw_subsidies_3_with_bp_districts where zip_mod<>0N;

  // zip to ksh_id map
  zip_map: distinct (select zip,ksh_id,settlement from budapest_districts), 0!.ksh.ksh_id_zip_map[];
  .data.settlement_details: `ksh_id xkey distinct delete zip,zip_mod from update settlement:settlement_mod,zip:zip_mod from ungroup (update settlement_mod:settlement from settlements) lj zips_by_settlement;
  .data.settlements: zip_map lj .data.settlement_details;

  // add ksh_id to subsidies
  data_full: raw_subsidies_3_with_bp_districts lj `settlement_mod xkey select distinct ksh_id,settlement_mod from .data.settlements;
  .data.full: (select from data_full where ksh_id<>0N),(select from data_full where ksh_id=0N) lj `zip xkey zip_map;

  // assert: log if there are unmapped zip codes
  unmapped: `amount xdesc select sum amount by year,zip,settlement_mod from .data.full where ksh_id=0N;
  .agrar.assert[   {0<count x};   unmapped;   "Unmapped zip codes! Check where they belong and add them to manual_zip_map.csv";   "There are 0 unmapped zip codes!"];

  // settlement-level data for analysis
  .data.settlement_stats: select distinct from delete zip_mod,zip,settlement_id from .data.settlements;
  .data.win_by_settlements: 0! select sum amount by is_firm,land_based,year,ksh_id from .data.full;
  };

.agrar.save_name_mismatch:{[]
  agrar_zips: select distinct zip,settlement from .data.full;
  ksh: .ksh.process_settlements_parts_file[];
  ksh_zips: select distinct zip:iranyito_szam,settlement:helyseg from ksh;
  ksh_zip_list: exec distinct zip from ksh_zips;
  agrar_zip_list: exec distinct zip from agrar_zips;

  select from ksh_zips where zip in ksh_zip_list except agrar_zip_list;
  select from agrar_zips where zip in agrar_zip_list except ksh_zip_list;

  settlement_name_mismatch: (select zip, kdh_settlement:settlement from ksh_zips) ij (1! select zip,agrar_settlemnt:settlement from (agrar_zips except ksh_zips) where zip in ksh_zip_list);

  .agrar.save_csv["settlement_name_mismatch";settlement_name_mismatch];
  };

if[`EXPORT=`$.z.x[0];
  .agrar.export.init[];
  .agrar.export.normalize[];
  // .agrar.export.save[];
  ];

