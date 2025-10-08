\d .qi

REPO:"https://raw.githubusercontent.com/alpha-training/qi/main/"
REPO_LIBS:`cron`event`ipc`qs
tostr:{$[0=t:type x;.z.s each x;10=abs t;x;string x]}
tosym:{$[0=t:type x;.z.s each x;11=abs t;x;`$tostr x]}
path:{$[0>type x;hsym tosym x;` sv @[raze tosym x;0;hsym]]}
spath:1_string path@
envpath:{[env;default;x]path($[count a:getenv env;a;default];$[any x~/:(::;`);();x])}
qilib:{envpath[`QILIB;`:lib;dotq x]}
qiconfig:envpath[`QICONFIG;`:config]
exists:not()~key@
INCLUDED:0#`
dotq:{$[x like"*.q";x;-11=type x;` sv x,`q;x,".q"]}
fetch:{[dir;p;x] system"mkdir -p ",spath first ` vs p;system"wget -O ",spath[p]," ",REPO,dir,"/",tostr $[dir~"lib";dotq x;x]}
fetchcfg:fetch"config"
fetchlib:fetch"lib"
include:{a:first` vs x;if[not a in REPO_LIBS;'"unrecognized library"];if[not a in INCLUDED;if[not exists p:qilib a;fetchlib[p;a]];system"l ",spath p;INCLUDED,:a]}
includecfg:{if[not exists p:qiconfig x;fetchcfg[p;x]]}
now:{.z.p};today:{.z.d}
guess:{$[(t:type x)in 0 98 99h;.z.s each x;10<>abs t;x;-10=t;$["*J"x in .Q.n]x;","in x;.z.s each","vs x;x~x inter .Q.n,".";$["JF""."in x]x;"S"$x]}
opts:guess first each .Q.opt .z.x
try:{[func;args;catch] $[`ERR~first r:.[func;args;{(`ERR;x)}];(0b;catch;r 1);(1b;r;"")]}
try1:{try[x;enlist y;z]}

\d .q
{{$[b;last` vs x;x]set get$[b:"."=first s:.qi.tostr x;x;` sv`.qi,x]}each $[.qi.exists x;`$read0 x;()]}.qi.qiconfig`promote.txt;
\d .