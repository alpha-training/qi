#qi

qi is a kdb+ helper library.

The file [qi.q](https://alphakdb.com/qi/repo/qi.q) is all that is needed:

    \l /path/to/qi.q      / load qi library

You can also create custom libraries:

    my_common.q
    -----------
    \l /path/to/qi.q    / load qi
    .qi.include`ipc     / load optional inter-process communication library
    .qi.include"cron"   / load cron (timer) library (include also takes a string)
    ...

    some-file.q
    -----------
    \l /path/to/my_common.q    / load my-common instead of qi
    ...
   
.qi.include first tries to load locally. If a library of that name is not found, it will be downloaded from the repository [alphakdb.com/qi/repo](https://alphakdb.com/qi/repo).

qi will use as its working directory:

1. `QIHOME`if that environment variable is defined. If not,
2. it will write to a qi folder in the current working directory

## More information

A glossary of qi's libraries and functions may be found [here](https://alphakdb.com/qi/docs).

A tutorial on how to get a kdb+ stack up and running may be found [here](https://alphakdb.com/qi/videos/getting-started-1).

## License

qi is licensed under the [MIT License](./docs/LICENSE.md).

## Don't be a stranger

We welcome feedback: [qi@alphakdb.com](mailto:qi@alphakdb.com)