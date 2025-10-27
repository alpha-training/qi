\l /home/iwickham/qi/qi.q
.qi.include`ta
/.ta.cfg.loadJSON`test.json
.qi.includecfg"ta/settings.csv"

\l /data/alf/polygon/hdb/us_stocks_sip

tt:select from bar1m where date within (2022.03.02 2022.03.10),sym in `TSLA`AAPL


/ buy the dip
simplestrat_buydip:{[x]
    a:update rsi:.ta.RSI[x`close;CFG`RSI.N] by sym from x;
    a:.ta.BBANDS a;
    a:update enter_long:((close<lowerBB)&(rsi<CFG`RSI.ENTRY_MAX)&(volume>1.5*mavg[20;volume])) by sym from a;
    a:update exit_long:((close>upperBB)|(rsi>CFG`RSI.EXIT_MAX)) by sym from a;
    update exit_long:1b by sym from a where time in (value select max time by date from a)`time
    }



simplestrat_volumeSpike:{[x]
    / Step 1: compute RSI per symbol
    a:update rsi:.ta.RSI[x`close;CFG`RSI.N]by sym from x;
    / Step 2: compute Bollinger Bands
    a:.ta.BBANDS a;
    / Step 3: rolling average volume (20 bars intra
    a:update volma:20 mavg volume by sym from a;
    / Step 4: price breakout signal (20-bar high)
    a:update swing_high:20 mmax close by sym from a;
    / step
    a:update vwap:close wavg volume by sym from a;
    / Step 5: final entry condition
    a:update enter_long:(volume>2f*volma)&(close>swing_high)&(close>vwap)by sym from a;
    / Step 6: exit conditions (momentum decay)
    a:update exit_long:((close<ema[5;close])|(rsi>CFG`RSI.EXIT_MAX))by sym from a;
    / Step 7: force exit at end of each session
    update exit_long:1b by sym from a where time in (value select max time by date from a)`time;
    $[.ta.INTER;a;`rsi`upperBB`lowerBB`volma`swing_high`vwap`TP _a]
    }


RSITrendReversion:{[x]
    / Step 1: compute short & long RSI
    a:update rsi5:.ta.RSI[x`close;CFG`RSI.LONG_SHORT],
    rsi14:.ta.RSI[x`close;CFG`RSI.LONG_BASE] by sym from x;

    / Step 2: compute trend filter
    a:update sma50:50 mavg close by sym from a;
    / Step 3: entry condition
    / short-term RSI weaker than long-term, in uptrend
    a:update enter_long:(rsi5<rsi14)&(close>sma50) by sym from a;
    / Step 4: exit condition
    / momentum reversal OR trend break
    a:update exit_long:(rsi5>CFG`RSI.EXIT_MAX)|(close<sma50) by sym from a;
    / Step 5: force exit at end of session
    a:update exit_long:1b by sym from a where time in (value select max time by date from a)`time;
    / Step 6: output shape same as your other strats
    $[.ta.INTER;a;`rsi5`rsi14`sma50 _a]
  }
