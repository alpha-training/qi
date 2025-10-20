/ Technical analysis helper library

.qi.includecfg"ta/settings.csv"

\d .ta

cfg.add:{@[`.;`CFG;,;x]}
CFG:{`..CFG x}

u.SETTINGS:.qi.qiconfig`ta`settings.csv;
u.bycols:{a!a:`date`sym`tenor inter cols x}

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
  a:update upperBB:sma+k_dev,lowerBB:sma-k_dev from a;
  $[INTER;a;`sma`k_dev _a]
 }

/ old definition
BBANDSold:{
  n:CFG`BB.N;
  a:update TP:avg(high;low;close)by sym from x;
  a:update sma:n mavg TP,k_dev:CFG[`BB.K]*n mdev TP by sym from a;
  a:update upperBB:sma+k_dev,lowerBB:sma-k_dev from a;
  $[INTER;a;`sma`k_dev _a]
  }


/TA-LIb matching EMA
TAEMA:{[n;data]
  alpha:2.0%(n+1);
  {[alpha;x;y](alpha*y)+(1-alpha)*x}[alpha]\[first data;data]
  }


/ Stochastic Fast
STOCHF:{[x;n;m]
    a:update kfast:100*{(x-z)%y-z}[close;n mmax high;n mmin low]by sym from x;
    update dfast:m mavg kfast by sym from a
  }

/Stochastic Slow
STOCH:{[x;n;m]
    a:update kfast:100*{(x-z)%y-z}[close;n mmax high;n mmin low] by sym from x;
    a:update kslow:m mavg kfast by sym from a;
    update dslow:m mavg kslow by sym from a
    }

// Moving Average Convergence Divergence - MACD - Peter
MACD:{MACDx[`close;x;CFG`MACD.FAST;CFG`MACD.SLOW;CFG`MACD.PERIOD]}

MACDFIX:{MACDx[`close;x;12;26;CFG`MACD.PERIOD]}

MACDx:{[pxCol;x;fast;slow;sigPeriod]
  a:x[pxCol];
    emaFast:ema[2%fast+1;a];emaSlow:ema[2%slow+1;a];
    macd:emaFast-emaSlow;
    macdSignal:ema[2%(sigPeriod+1);macd];
    macdHist:macd-macdSignal;
    update macd,macdSignal,macdHist from x
  }

KAMA:{[x;n;fast;slow]
  prices: x`close;

  /Compute Efficiency Ratio (ER)
  er:{[n;x] 
    num:abs x-(prev/)[n;x];
    den:msum[n;abs deltas x];
    num%den
    }[n;prices];

  /Compute smoothing constant (SC)
  fastSC:2%fast+1;
  slowSC:2%slow+1;
  sc:((er*(fastSC-slowSC))+slowSC) xexp 2;

  / pad first n SCs with 0 to align
  sc:(n#0),(n)_sc;

  /Compute KAMA recursively
  kama:{x+z*(y-x)}\[first prices;prices]sc;
  /Add KAMA as a new column
  update KAMA:kama from x
  }

// MIDPOINT
midpoint:{[tr;Tsym;n]
  a:select from T where date within tr,sym in Tsym;
  maxv:mmax[n] a`close;   / rolling highest high
  minv:mmin[n] a`close;   / rolling lowest low
  update midpoint:(maxv+minv)%2 from a
  }

/ MIDPRICE
midprice:{[tr;Tsym;n]
  a:select from T where date within tr,sym in Tsym;
  maxv:mmax[n] a`high;
  minv:mmin[n] a`low;
  update midprice:(maxv+minv)%2 from a
  }

// MFI (Money Flow Index) - Peter
MFI:{[x;tr;s;n]
  a:select from x where date within tr, sym in s;
  tp:avg(a`high;a`low;a`close);
  rmf:tp*a`volume;
  posMF:rmf*tp>prev tp;negMF:rmf*tp<prev tp;
  rollsum:{sum x[z+til y]};
  sumPos:(n#0n),rollsum[posMF;n;] each 1+til count (n)_posMF;
  sumNeg:(n#0n),rollsum[negMF;n;] each 1+til count (n)_negMF;
  mfRatio:sumPos%sumNeg;
  update mfi:100-(100%(1+mfRatio)) from a;
  }

// AROON and AROONOSC (Aroon and Aroon Oscillator) - Peter
AROON:{[x;tr;s;n]
    a:select from x where date within tr, sym in s;
    update aroonUp:AROONx[a`high;n;max],aroonDn:AROONx[a`low;n;min] from a
    }

AROONOSC:{[x;tr;s;n]
    a:select from x where date within tr, sym in s;
    update aroonOsc:AROONx[a`high;n;max] - AROONx[a`low;n;min] from a
    }

AROONx:{[c;n;f] 
    m:reverse each a _'(n+1+a:til count[c]-n)#\:c;
    arFunc:#[n;0ni],{x? y x}'[m;f];
    100*reciprocal[n]*n-arFunc
    }

// Triangular Moving Average
TREMA:{[tr;Tsym;n]
  a:select from T where date within tr, sym in Tsym;
  ma1:mavg[ceiling n%2;a`close];
  ma2:mavg[ceiling n%2;ma1];
  update tma:ma2 from a
  }



// VOLATILITY INDICATORS - Peter

/ TRANGE (True Range)

TRANGE:{[high;low;close]
  max(high-low;abs high-prev close;abs low-prev close)}

/ ATR (Average True Range)
ATR:{[x;tr;s;n]
  a:select from x where date within tr by sym in s;
  tr:TRANGE[a`high;a`low;a`close];start:avg tr[1+til n];
  atr:(n#0n),start,{(y+x*(z-1))%z}\[start;(n+1)_tr;n];
  update atr:atr from a
  }

/ NATR (Normalized Average True Range)
NATR:{[x;tr;s;n]
  a:select from x where date within tr by sym in s;
  tr:TRANGE[a`high;a`low;a`close];start:avg tr[1+til n];
  atr:(n#0n),start,{(y+x*(z-1))%z}\[start;(n+1)_tr;n];
  natr:100*atr%a`close;
  update natr:natr from a
  }

// DEMA (Double Exponential Moving Average) - Peter

DEMA:{[px;n] (2*ema[2%n+1;px]) - ema[2%n+1;ema[2%n+1;px]]}

// ADX (Average Directional Index) and related Momentum Indicators - Peter
/ PLUS_DM, PLUS_DI, MINUS_DM, MINUS_DI, DX, ADX, ADXR

PLUS_DM:{[high;low;n]
  dH:high-prev high;dL:(prev low)-low;
  rawPlusDM:(dH>dL)&(dH>0)*dH;
  smoothedPlusDM:wilderSmooth[rawPlusDM;n]}

MINUS_DM:{[high;low;n]
  dH:high-prev high;dL:(prev low)-low;
  rawMinusDM:(dL>dH)&(dL>0)*dL;
  smoothedMinusDM:wilderSmooth[rawMinusDM;n]}

PLUS_DI:{[high;low;close;n]
  plusDM:PLUS_DM[high;low;n];
  tRange:.ta.TRANGE[high;low;close];
  smoothTR:wilderSmooth[tRange;n];
  smthPlusDM:100*plusDM%smoothTR;
  smthPlusDM[n-1]:0n;smthPlusDM}

MINUS_DI:{[high;low;close;n]
  plusDM:MINUS_DM[high;low;n];
  tRange:.ta.TRANGE[high;low;close];
  smoothTR:wilderSmooth[tRange;n];
  smthMinusDM:100*plusDM%smoothTR;
  smthMinusDM[n-1]:0n;smthMinusDM}

DX:{[high;low;close;n]
  plusDI:PLUS_DI[high;low;close;n];
  minusDI:MINUS_DI[high;low;close;n];
  dx:100*abs(plusDI-minusDI)%(plusDI+minusDI);
  dx[n-1]:0n;dx}

ADXx:{[high;low;close;n]
  dx:DX[high;low;close;n];
  adx:wilderAvgSmooth[(n)_dx;n];
  adx:(n#0n),adx}

ADXR:{[high;low;close;n]
  adx:ADX[high;low;close;n];
  shifted:(neg[n-1])_((n-1)#0n),adx;
  adxr:(shifted+adx)%2}

wilderSmooth:{[x;n]
  init:sum x[til n];
  smoothed:((n-1)#0n),init,{(x-(x%z))+y}\[init;(n)_x;n]}

wilderAvgSmooth:{[x;n]
  init:avg x[til n];
  smoothed:((n-1)#0n),init,{((x*(z-1))+y)%z}\[init;(n)_x;n]}

// MOM (Momentum) - Peter
MOM:{[px;n]
  mom:(n#0n),(neg n)_((n rotate px)-px)
  }

//ROC (Rate of Change) and related Momentum Indicators - Peter
/ ROC, ROCP, ROCR, ROCR100

ROC:{[px;n]
  roc:ROCP[px;n]*100
  }

ROCP:{[px;n]
  mom:.ta.MOM[px;n];
  rocp:(n#0n),((n)_mom%px)
  }

ROCR:{[px;n]
  mom:.ta.MOM[px;n];
  rocr:(n#0n),(((n)_mom%px)+1)
  }

ROCR100:{[px;n]
  rocr100:ROCR[px;n]*100
  }

/ VOLUME INDICATORS -Ian

/ AD 
AD:{[x]
  a:update mfm:((close - low)-(high - close))%high - low by sym from x;
  a:update mfv:mfm*volume by sym from a;
  update ad:sums mfv by sym from a
  }

/ AD-OSC 
ADOSC:{[x;fast;slow]
  a:AD x;
  update adosc:(taema[fast;a`ad] - taema[slow;a`ad]) by sym from a
  }

/ OBV 
OBV:{[x]
  a:update dir:signum deltas close by sym from x;
  a:update volAdj:dir*volume by sym from a;
  update obv:sums volAdj by sym from a
  }



cfg.load`;
INTER:CFG`SHOW_INTERMEDIARY

\d .