# palloc
This is a library made in prog8, that provides a dynamic memory allocation. It was primarily made with Commander X16 in mind, but it should actually work on every platform supporded by prog8.

## Usage 
Add [`palloc.p8`](/palloc.p8) file to your project and import it. Call `palloc.init(start_address, end_address)` function in order to initialize the library. There are also other, parameter-less variants of that function, that initialize the heap in the commonly used locations: `init_golden()`, `init_loram()` and `init_hiram()`. After that you can call `palloc.alloc(size)` to allocate a chunk, that can hold a provided amount of data bytes. Note, that the `alloc()` function *doesn't actually clear the data buffer*, so it contains garbage data and it's your responsibility to clean it. The address of the buffer is returned directly by the function. This address can be later used in `palloc.free(ptr)` function, in order to free this previously allocated chunk. 

Outside of the most commonly used functions mentioned above, there are also additional functions, for example `palloc.reinit()`, which clears all allocations and resets the heap to usable state. It's generally recommended to normaly free the data one at the time, but there may be situations, where `reinit()` might be usefull. There's also `palloc.set_space(start_address, end_address)` which works similarly to `init()`, but doesn't actually reset the heap, therefore it can be usefull in environments, where it is expected for multiple programs running at the same time to utilize the same heap. 

Have a look at the [examples](/examples/)!

The library and all of the examples are licensed under MIT, feel free to use them in any kind of project.