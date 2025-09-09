# qi

qi is a kdb+ helper library.

The file [qi.q](https://alphakdb.com/qi/repo/qi.q) is all that is needed:

    \l /path/to/qi.q      / load qi library
    
## Loading optional libraries
The function `.qi.include` can be used to load qi's optional libraries, which are listed [here]().

## Creating custom libraries

You can also create a custom library:

    // common.q
    \l /path/to/qi.q    / load qi
    .qi.include`ipc     / inter-process communication library
    .qi.include"cron"   / timer library - include also takes a string
    
    // some custom code

And load it:

    \l /path/to/common.q    / load common instead of qi

## More information

A tutorial on how to get a kdb+ stack up and running may be found [here](https://alphakdb.com/qi/videos/getting-started-1).

## License

qi is licensed under the [MIT License](./docs/LICENSE.md).

## Don't be a stranger

We welcome feedback: [qi@alphakdb.com](mailto:qi@alphakdb.com)