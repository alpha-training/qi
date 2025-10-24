\l /home/iwickham/qi/qi.q
.qi.include`ta
/.ta.cfg.loadJSON`test.json
.qi.includecfg"ta/settings.csv"

\l /data/alf/polygon/hdb/us_stocks_sip

getBB:{[dt;s] .ta.BBANDS select from bar1m where date=dt,sym in s}

tt:select from bar1m where date within (2022.03.02 2022.03.02),sym in `TSLA`AAPL
/-15#tt 
/[bar1m;2025.09.19 2025.09.20;`A;INSERT_VARIABLE_HERE]

r:getBB[max date;`AAPL`MSFT]

STOCH2:{[x;n;m]
    a:update kfast:100*{(x-z)%y-z}[close;n mmax high;n mmin low] by sym from x;
    a:update kslow:m mavg kfast by sym from a;
    a:update dslow:m mavg kslow by sym from a;
    a
    }

simplestrat_buydip:{[x]
    a:update rsi:.ta.RSI[x`close;CFG`RSI.N] by sym from x;
    a:.ta.BBANDS a;
    a:update enter_long:((close<lowerBB)&(rsi<CFG`RSI.ENTRY)&(volume>1.5*mavg[20;volume])) by sym from a;
    a:update exit_long:((close>upperBB)|(rsi>CFG`RSI.EXIT)) by sym from a;
    update exit_long:1b by sym from a where time in (value select max time by date from a)`time
    }



simplestrat_volumeSpike:{[x]
    / Step 1: compute RSI per symbol
    a:update rsi:.ta.RSI[x`close;CFG`RSI.N]by sym from x;
    / Step 2: compute Bollinger Bands
    a:.ta.BBANDS a;
    / Step 3: rolling average volume (20 bars intraday)
    a:update volma:20 mavg volume by sym from a;
    / Step 4: price breakout signal (20-bar high)
    a:update swing_high:20 mmax close by sym from a;
    / step
    a:update vwap:close wavg volume by sym from a;
    / Step 5: final entry condition
    a:update enter_long:(volume>2f*volma)&(close>swing_high)&(close>vwap)by sym from a;
    / Step 6: exit conditions (momentum decay)
    a:update exit_long:((close<ema[5;close])|(rsi>CFG`RSI.EXIT))by sym from a;
    / Step 7: force exit at end of each session
    update exit_long:1b by sym from a where time in (value select max time by date from a)`time
    }

a:update exit_long:((close<ema[5;close])|(rsi>CFG`RSI.EXIT)) by sym from a;