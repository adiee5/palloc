# dynstr - Dynamic strings in Prog8

This folder contains [`dynstr` library](./dynstr.p8) as well as an [example program](./demo.p8) showcasing its capabilities.

## Usage
Import [`dynstr`](./dynstr.p8) to your project. Make sure an imlementation of `palloc` is also imported. 

Let's say, that our dynstr variable is called `az`. Now, if we want to pass the variable to a function, that expects a `dynstr` var, we pass the name of the variable, so for example `my_func(az)`. If we want to get access to the string data of our dynstr, we use `peekw(az)`, for example we can write `txt.print(peekw(az))` – `txt.print(az)` will not work correctly! Storing the value of `peekw(az)` in an uword variable as a "convenience" is usually a bad idea, because the actual address of the string buffer may change at any moment. Capacity attribute can be viewed by using `az[dynstr.capacity]`.

For the usage of the functions provided by the dynstr library, please head to [the source code of the library](./dynstr.p8) or view [an example program](./demo.p8).