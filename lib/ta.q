/ Technical analysis helper library

.qi.includecfg"ta/settings.csv"

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
BBANDS:{BBANDSx[`high`low`close;CFG`BB.N;x]}

BBANDSx:{[pxCols;n;x]
  byc:u.bycols x;
  a:$[1=count pxCols;[c:pxCols 0;x];[c:`TP;![x;();byc;enlist[`TP]!enlist(avg;(enlist),pxCols)]]];
  a:![a;();byc;`sma`k_dev!((mavg;n;c);(*;CFG`BB.K;(mdev;n;c)))];
  update upperBB:sma+k_dev,lowerBB:sma-k_dev from a
 }
\
cfg.load`;

\d .

/

/ old definitions
BBANDS:{
  n:CFG`BB.N;
  a:update TP:avg(high;low;close)by sym from x;
  a:update sma:n mavg TP,k_dev:CFG[`BB.K]*n mdev TP by sym from a;
  update upperBB:sma+k_dev,lowerBB:sma-k_dev from a
  }

/ Stochastic Fast
STOCHF:{[table;tr;Tsym;n;m]
    a:select from table where date within tr,sym in Tsym;
    Hn:mmax[n]a`high;
    Ln:mmin[n]a`low;
    K:100*((a`close)-Ln)%(Hn-Ln);
    D:mavg[m;K];
    update Kfast:K,Dfast:D from a
  }

/Stochastic Slow
STOCH:{[table;tr;Tsym;n;m]
    a:select from table where date within tr,sym in Tsym;
    Hn:mmax[n] a`high;
    Ln:mmin[n] a`low;
    Kfast:100*((ta`close)-Ln)%(Hn-Ln);
    Kslow:mavg[m;Kfast];
    Dslow:mavg[m;Kslow];
    update Kslow:Kslow,Dslow:Dslow from a
  }

// Moving Average Convergence Divergence - MACD
MACD:{MACDx[`close;x;12;26;9]}

MACDx:{[pxCol;x;fast;slow;sigPeriod]
  a:x[pxCol];
    emaFast:ema[2%fast+1;a];emaSlow:ema[2%slow+1;a];
    macd:emaFast-emaSlow;
    macdSignal:ema[2%(sigPeriod+1);macd];
    macdHist:macd-macdSignal;
    update macd,macdSignal,macdHist from x
  }

// KAMA (Kaufman’s Adaptive Moving Average)
kama:{[T;tr;Tsym;n;fast;slow]
  a:select from T where date within tr, sym in Tsym;
  prices:a`close;
  fastSC:2%fast+1;
  slowSC:2%slow+1;

  er:{[n;x] 
    num:abs x-(prev/)[n;x];
    den:msum[n;abs deltas x];
    num%den
    }[n;prices];

  sc:((er*(fastSC-slowSC))+slowSC) xexp 2;
  sc:(n#0),(n)_sc;

  kama:{x+z*(y-x)}\[first prices;prices]sc;
  update KAMA:kama from a
  }

midpoint:{[tr;Tsym;n]
  a:select from T where date within tr,sym in Tsym;
  maxv:mmax[n] a`close;   / rolling highest high
  minv:mmin[n] a`close;   / rolling lowest low
  update midpoint:(maxv+minv)%2 from a
  }

midprice:{[tr;Tsym;n]
  a:select from T where date within tr,sym in Tsym;
  maxv:mmax[n] a`high;
  minv:mmin[n] a`low;
  update midprice:(maxv+minv)%2 from a

// MFI (Money Flow Index)
MFI:{[T;tr;Tsym;n]
  a:select from T where date within tr, sym in Tsym;
  tp:avg(a`high;a`low;a`close);
  rmf:tp*a`volume;
  posMF:rmf*tp>prev tp;negMF:rmf*tp<prev tp;
  rollsum:{sum x[z+til y]};
  sumPos:(n#0n),rollsum[posMF;n;] each 1+til count (n)_posMF;
  sumNeg:(n#0n),rollsum[negMF;n;] each 1+til count (n)_negMF;
  mfRatio:sumPos%sumNeg;s
  update mfi:100-(100%(1+mfRatio)) from a;
  }

cfg.load`;

\d .