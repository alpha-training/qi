.qi.include`event

\d .cron

jobs:1!flip`func`start`period`lastRun`nextRun`error!"spnpp*"$\:()
add:{[func;start;period] `.cron.jobs upsert(func;start;p;0Np;start+p:"n"$period;"");}
run1:{[job;now] r:.qi.try1[get job;now;::];jobs[job]:e,`lastRun`nextRun`error!(now;$[(p:(e:jobs job)`period)in 0N 0Wn;0Wp;now+p];r 2)}
run:{run1[;x]each exec func from jobs where nextRun<x;}

\d .

.event.addHandler[`.z.ts;`.cron.run]
