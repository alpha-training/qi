.qi.include`event

\d .ipc

TIMEOUT:1000

conns:1!flip`name`proc`port`handle`pid`lastHearbeat`error!"ssiiip*"$\:()
conn:{[name] if[null(e:conns name)`handle;conns[name]:e,:`handle`error!tryConnect e`port];e`handle}
tryConnect:{[port] 1_.qi.try1[hopen;("::",.qi.tostr port;TIMEOUT);0Ni]}
disconnect:{update handle:0Ni,pid:0Ni,lastHearbeat:0Np from`.ipc.conns where handle=x}

\d .

.event.addHandler[`.z.pc;`.ipc.disconnect]