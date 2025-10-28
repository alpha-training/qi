\l /home/pmorris/qi/qi.q
.qi.include`ta
\l /data/alf/polygon/hdb/us_stocks_sip
tt:select from bar1m where date=max date,sym=`A
tt2:select from bar1m where date=max date,sym=`AAPL
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
/ TK: Function for selecting universe from a range of data

orbUniv:{[x;tradeDate]
    / select from current date and past 14 days
    recent:select from x where date within (.Q.pv[(.Q.pv?tradeDate)-14];tradeDate);
    / calculate daily stats
    dailyStats:select
        dailyDolVol:sum volume*close,
        dailyTxns:sum transactions,
        barsActive:sum volume>0
        by date,sym from recent;
    / calculate liquidity
    liqStats:select
        addv:avg dailyDolVol,
        avgTxns:avg dailyTxns,
        tradeCont:avg barsActive%count distinct date 
        by sym from dailyStats;
    / select 1000 stocks with the highest liquidity
    liqUniv:select from liqStats where addv>5e6,avgTxns>100,tradeCont>0.8;
    liqUniv:-1000#(`addv xasc liqUniv);
    / select the universe of stocks that could be "in play"
    inPlayUniv:select from recent where sym in (key liqUniv)`sym;
    / quantify most "In Play" stocks with ratio: (Volume during OR of current day)/(Average volume during OR of past 14 days)
    inPlay:select avgVol:avg(10#volume) by date,sym from inPlayUniv;
    inPlay:select 
        currAV:avgVol where date=max date,
        histAV:avg(avgVol where date<>max date) 
        by sym from inPlay;
    inPlay:update ipRatio:currAV%histAV from inPlay;
    / select only the 40 most "in play" stocks - assume half will be bearish and will get filtered out
    inPlay:-40#(`ipRatio xasc inPlay);
    select from recent where date=tradeDate,sym in (key inPlay)`sym}

orb:{[x]
    enterLogic:{[x]
        openRange:(CFG`ORB.ORMINS)#x;
        orClose:last openRange`close;
        orOpen:first openRange`open;
        orHigh:max openRange`high;
        $[orClose>orOpen;orHigh<x`close;(count x)#0b]};
    exitLogic:{[x]
        entryPrice:(first select from x where prev enterLong)`open;
        x:.ta.ATR[x;CFG`ORB.ATR_PERIOD];
        x:update exitLong:(close<(entryPrice - atr*CFG`ORB.ATR_STOP))or time>CFG`EOD from x;
        x`exitLong};
    a:update enterLong:enterLogic[x] by sym from x;
    a:update exitLong:exitLogic[a] by sym from a
    }