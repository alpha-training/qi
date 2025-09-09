\d .qi

tostr:{$[0=t:type x;.z.s each x;10=abs t;x;string x]}
tosym:{$[0=t:type x;.z.s each x;11=abs t;x;`$tostr x]}
path:{$[0>type x;hsym tosym x;` sv @[raze tosym x;0;hsym]]}
spath:1_string path@
envpath:{[env;default;x]path($[count a:getenv env;a;default];$[any x~/:(::;`);();x])}
home:envpath[`QIHOME;`qi]
config:envpath[`QICONFIG;home`config]
exists:not()~key@
INCLUDED:0#`
fetch:{[p;f] -1"fetching ",tostr f;p 0:enlist"A:100"}
include:{if[not x in INCLUDED;if[not exists p:path home`lib,` sv x,`q;fetch[p;x]];system"l ",spath p;INCLUDED,:x]}
now:{.z.p};today:{.z.d}
guess:{$[(t:type x)in 0 98 99h;.z.s each x;10<>abs t;x;-10=t;$["*J"x in .Q.n]x;","in x;.z.s each","vs x;x~x inter .Q.n,".";$["JF""."in x]x;"S"$x]}
opts:guess first each .Q.opt .z.x
try:{[func;args;catch] $[`QI_ERR~first r:.[func;args;{(`QI_ERR;x)}];(0b;catch;r 1);(1b;r;"")]}
try1:{try[x;enlist y;z]}
promote:{@[`.;x;:;$["."=first tostr x;x;.qi x]];}
promote each{$[exists x;`$read0 x;()]}config`promote.txt;

\d .