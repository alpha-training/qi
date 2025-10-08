/ Q Sharpe - Helper library for technical analysis

includecfg"qs/settings.csv"

\d .qs

SETTINGS_FILE:.qi.qiconfig`qs`settings.csv;

/ global settings: .qs.CFG
loadSettings:{
  a:("SC*";enlist",")0:SETTINGS_FILE;
  CFG,:(1#.q),exec name!upper[typ]$default from a;
  CFG_TYPES,:exec name!upper typ from a;
 }

/ Override .qs.CFG with specific settings
loadCustomSettings:{[p]
  a:.j.k trim raze read0 .qi.path p;
  if[count new:key[a]except key CFG;'"unrecognized: ",sv[",";string new]," must be present in ",.qi.spath SETTINGS_FILE];
  typ:@[key[a]#CFG_TYPES;where 10<>abs type each a;lower];
  CFG,:typ$a;
 }

/// Indicator Code ///

/ Relative strength index - RSI - ranges from 0-100
relativeStrength:{[n;px]
  start:avg(n+1)#px;
  (n#0n),start,{(y+x*(z-1))%z}\[start;(n+1)_px;n]}

rsiMain:{[n;px]
  diff:px-prev px;
  rs:relativeStrength[n;diff*diff>0]%relativeStrength[n;abs diff*diff<0];
  100*rs%1+rs
  }

/ Bollinger Bands
bollBands:{
  n:CFG`BB.N;
  k:CFG`BB.K;
  a:update TP:avg(high;low;close)by sym from x;
  a:update sma:n mavg TP,k_dev:k*n mdev TP by sym from a;
  update upperBB:sma+k_dev,lowerBB:sma-k_dev from a
  }

loadSettings`;

\d .