/ Technical analysis helper library

includecfg"ta/settings.csv"

\d .ta

cfg.add:{@[`.;`CFG;,;x]}
CFG:{`..CFG x}

u.SETTINGS:.qi.qiconfig`ta`settings.csv;

/ global settings
cfg.load:{
  a:("SC*";enlist",")0:u.SETTINGS;
  cfg.add(1#.q),exec name!upper[typ]$default from a;
  @[`.;`CFG_TYPES;:;exec name!upper typ from a];
 }

/ Override .qs.CFG with specific settings
cfg.loadJSON:{[p]
  a:.j.k trim raze read0 .qi.path p;
  if[count new:key[a]except key`. `CFG;'"unrecognized: ",sv[",";string new]," must be present in ",.qi.spath u.SETTINGS];
  typ:@[key[a]#`. `CFG_TYPES;where 10<>abs type each a;lower];
  cfg.add typ$a;
 }

/// Indicator Code ///

/ Relative strength index - RSI - ranges from 0-100
u.relativeStrength:{[px;n]
  start:avg(n+1)#px;
  (n#0n),start,{(y+x*(z-1))%z}\[start;(n+1)_px;n]}

RSI:{[px;n]
  diff:px-prev px;
  rs:u.relativeStrength[diff*diff>0;n]%u.relativeStrength[abs diff*diff<0;n];
  100*rs%1+rs
  }

/ Bollinger Bands
BBANDS:{
  n:CFG`BB.N;
  a:update TP:avg(high;low;close)by sym from x;
  a:update sma:n mavg TP,k_dev:CFG[`BB.K]*n mdev TP by sym from a;
  update upperBB:sma+k_dev,lowerBB:sma-k_dev from a
  }

cfg.load`;

\d .