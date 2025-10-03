# qi

qi is a kdb+ helper library.

The file [qi.q](https://github.com/alpha-training/qi/blob/main/qi.q) is all that is needed:

    \l /path/to/qi.q      / load qi library
    
## Loading optional libraries
The function `.qi.include` can be used to load qi's [optional libraries](https://github.com/alpha-training/qi/tree/main/lib).

## promote.txt
Any functions listed in here will be promoted to the .q namespace. For example, if promote.txt contained:
	
	.qi.include

We can call `include` instead of `.qi.include`. **Note:** The `.qi.` prefix in promote.txt is superfluous - any functions listed without a namespace are assumed to be in .qi. 

## Creating custom libraries

You can also create a custom library:

    / common.q
    \l /path/to/qi.q    / load qi
    include`ipc     / inter-process communication library
    include"cron"   / timer library - include also takes a string
    
    // some custom code

And load it:

    \l /path/to/common.q    / load common instead of qi

## Environment variables

* `QILIB` specifies where the optional libraries are stored.  This defaults to `./lib` if not defined.
* `QICONFIG` specifies where `promote.txt` is located; if it exists. This defaults to `./config` if not defined.

## License

qi is licensed under the [MIT License](./docs/LICENSE.md).

## Don't be a stranger

We welcome feedback: [qi@alphakdb.com](mailto:qi@alphakdb.com)