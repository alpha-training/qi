/ qi - q/kdb+ helper functions

\d .qi

DEFAULT_OWNER:"alpha-training"
RAW:"https://raw.githubusercontent.com/"
API:"https://api.github.com/repos/"
getAPI:{[isTag;repo;ref] API,repo,"/git/refs/",$[isTag;"tags";"heads"],"/",ref}

tostr:{$[0=count x;"";0=t:type x;.z.s each x;t in -10 10h;x;string x]}
tosym:{$[0=count x;`$();0=t:type x;.z.s each x;t in -11 11h;x;`$tostr x]}
path:{$[0>type x;hsym tosym x;` sv @[raze tosym x;0;hsym]]}     /  returns `:path/to/file
spath:1_string path@    / returns "path/to/file"
exists:not()~key@
env:{[v;default;f] sv[`;`.env,v]set $[count r:getenv v;f r;default];}
dotq:{$[x like"*.*";x;type[x]in -11 11h;` sv x,`q;x,".q"]}
.log.info:{[x] $[type x;-1;-1" "sv]x}
.qi.system:{.log.info"system ",x;system x}
curl:system"curl -fsSL ",
jcurl:.j.k raze curl@
fetch:{[url;p] .log.info"fetch ",url;path[p]0:curl url}
readj:{.j.k raze read0 x}
loadf:{[p] system"l ",spath p;}
loadcfg:{[module;dir]
  f:$[(def:`default.csv)in f:key p:` sv dir,`config;distinct def,f;f];
  if[not count f@:where f like"*csv";:()];
  get".",tostr[module],".cfg,:1#.q";  / TODO - could this be nicer?
  {[ns;p;f]
    r:exec name!upper[typ]$default from("SC*";enlist",")0:` sv p,f;
    @[ns;`cfg;,;r]}[` sv `,module;p]each f;
  if[exists pp:` sv p,`pp.q;loadf pp];  / if post-process file (pp.q) exists, load it
 }

env[`QI_INDEX_URL;RAW,DEFAULT_OWNER,"/qi/main/index.json";::]
env[`QI_HOME;hsym`$getenv[`HOME],"/.qi";path]
env[`QI_VENDOR;`:vendor/qi;path]
env[`QI_LOCK;`:qi.lock;path]
env[`QI_CONFIG;`:qi.json;path]
env[`QI_OFFLINE;0b;"1"=first@]

envpath:{path @[x;0;.env]}

include:use:{[x]
  module:first` vs sx:tosym x;
  f:dotq sx;
  if[exists pv:envpath(`QI_VENDOR;f);
    :loadf pv];
  if[exists pl:.env.QI_LOCK;
    dbg2];
  if[exists pc:.env.QI_CONFIG;
    dbg3];
  if[not exists pi:path(.env.QI_HOME;`cache;`index.json);
    fetch[.env.QI_INDEX_URL;pi]];
  m:readj[pi][`modules]module;
  repo:$["/"in m`repo;m`repo;DEFAULT_OWNER,"/",m`repo];

  isTag:m[`ref]like"v[0-9]*";
  sha:jcurl[getAPI[isTag;repo;m`ref]][`object]`sha;


    dbg;
  if[not isTag;
    sha:jcurl[getAPI[isTag;repo;m`ref]][`object]`sha;
    dir:envpath(`QI_HOME;`pkgs;module;`refs;m`ref);
    current:0b;mp:path(dir;`store;sha;f);
    if[exists cf:path dir,`current;
      if[current:sha~raze read0 cf]];
    if[not current;
      tree_sha:jcurl[API,repo,"/git/commits/",sha][`tree]`sha;
      treeInfo:`typ xcol`type`path#/:jcurl[API,repo,"/git/trees/",tree_sha,"?recursive=1"]`tree;
      {[api;dir;sha;fp]
        url:api,"/",sha,"/",fp;
        fetch[url;(dir;`store;sha;fp)]}[RAW,repo;dir;sha]each exec path from treeInfo where typ like"blob";
      path[dir,`lastFetch]0:enlist string .z.p;
      cf 0:enlist sha]];
  loadcfg[module;first` vs mp];
  loadf mp;
  }

use`ta

\

/p.home:{envpath[`QI_HOME;getenv`HOME;dotq x]}
/p.index:{envpath[`QI_INDEX;x;y]}[;`index.json]

INDEX:
/ envpath:{[env;default;x]path($[count a:getenv env;a;default];$[any x~/:(::;`);();x])}
\

INCLUDED:0#`

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