\l /home/pmorris/qi/qi.q
.qi.include`ta
\l /data/alf/polygon/hdb/us_stocks_sip
tt:select from bar1m where date=max date,sym=`A
.ta.INTER:0

// RAC (RSI/ADX COMBO)
/ Enter oversold conditions when market is trending 

rac:{[x;n] 
    a:update rsi:.ta.RSI[close;n] by sym from x;
    a:.ta.ADX[a;n];
    a:update enterLong:(rsi<CFG`RAC.RSI_ENT)&(adx>CFG`RAC.ADX_ENT) by sym from a;
    a:update exitLong:(rsi>CFG`RAC.RSI_EX) by sym from a;
    delete rsi,adx from a}

// (demac) DOUBLE EXPONENTIAL MOVING AVERAGE CROSSOVER
/ Enter when fast EMA > slow EMA (i.e. APO is +ve) AND greater than 0.1% of price volatility (ATR) AND favourable trend (ADX>20)
/ Exit when fast EMA <= slow EMA (i.e. APO is 0 or -ve)

demac:{[x]
    fast:CFG`DEMAC.FAST;slow:CFG`DEMAC.SLOW;
    a:.ta.APO[x;fast;slow];
    a:.ta.ADX[a;fast];a:.ta.ATR[a;fast];
    a:update enterLong:((atr*(CFG`DEMAC.ATR_PERCENT)%100)<apo)&(adx>CFG`DEMAC.ADX_MIN) from a;
    a:update exitLong:(apo<=0) from a;
    $[.ta.INTER;a;`apo`adx`atr _a]}

// (dDemac) DOUBLE DOUBLE EXPONENTIAL MOVING AVERAGE CROSSOVER
/ Same as demac, but using DEMA instead of EMA for faster signals

dDemac:{[x]
    fast:CFG`DDEMAC.FAST;slow:CFG`DDEMAC.SLOW;
    a:update demaFast:.ta.DEMA[x`close;fast] by sym from x;
    a:update demaSlow:.ta.DEMA[a`close;slow] by sym from a;
    a:update apo:((fast#0n),fast _(demaFast-demaSlow)) by sym from a;
    a:.ta.ADX[a;fast];a:.ta.ATR[a;fast];
    a:update enterLong:((atr*(CFG`DDEMAC.ATR_PERCENT)%100)<apo)&(adx>CFG`DDEMAC.ADX_MIN) from a;
    a:update exitLong:(apo<=0) from a;
    $[.ta.INTER;a;`demaFast`demaSlow`apo`adx`atr _a]}

// wirMer (Williams %R Mean Reversion)

wirMer:{[x]
    a:.ta.WILLR[x;CFG`WILLR];
    a:.ta.MACD[a];
    a:update macdMavg:mavg[CFG`WIRMER.MAVG;macd] by sym from a;
    a:update macdMdev:mdev[CFG`WIRMER.MDEV;macd] by sym from a;
    a:update macdOB:macd>(macdMavg+macdMdev*CFG`WIRMER.DEVMULT) by sym from a;
    a:update macdOS:macd<(macdMavg-macdMdev*CFG`WIRMER.DEVMULT) by sym from a;
    a:update enterLong:(willR<CFG`WIRMER.OVERSOLD_THRESH)&macdOS&(macd>macdSignal) by sym from a;
    a:update exitLong:(willR>CFG`WIRMER.OVERBOUGHT_THRESH)&macdOB&(macd<macdSignal) by sym from a;
    $[.ta.INTER;a;`willR`macd`macdSignal`macdHist`macdMavg`macdMdev`macdOB`macdOS _a]}

// ORB (Opening Range Breakout)
/ Based on https://www.quantconnect.com/research/18444/opening-range-breakout-for-stocks-in-play/p1

orb:{[x]
    orbLogic:{[x]
        openRange:CFG`ORB.ORMINS#x;
        orClose:last openRange`close;
        orOpen:first openRange`open;
        orHigh:max openRange`high;
        $[orClose>orOpen;a:update enterLong:close>orHigh from x;:x];
        entryPrice:(first select from a where prev enterLong)`open;
        a:.ta.ATR[a;CFG`ORB.ATR_PERIOD];
        a:update exitLong:(close<(entryPrice - CFG`ORB.ATR_STOP*atr))or time>CFG`EOD from a};
    orbLogic[x] by sym from x
    }