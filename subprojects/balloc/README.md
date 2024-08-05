# balloc - banked allocator

This is an extension of palloc that allocates data across multiple banks keeps track of them. This library is intended to be used only on Commander X16 and requires the [original implementation of palloc](/palloc.p8) to work due to balloc closely relying on og palloc's internal behaviour (not that there is any choice at the time of writing this).

Many functions from `balloc` block have two variants: `_m` and `_p`. `_m` variants take/return a pointer and bank separately, while `_p` variants work with `bptr`s - special banked pointer type variables, that are essentially a 3-byte buffers, that hold pointer and bank data.

See [`balloc.p8`](./balloc.p8) and [examples](./examples/)

This folder also contains [bnk_mgr](./bnk_mgr.p8) library, which is a bank reservation system written by @tallLeRoy. It's included it this repo, because it's an essential dependency of balloc, the author himself doesn't want to host repo for that and he gave me consent to do so.