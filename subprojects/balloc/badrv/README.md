# badrv (bank allocation driver)

`badrv` is an interface used by balloc to reserve banks. The goal of this common API is to be able to integrate balloc into any desired bank reservation system.

## Implementations.
Right now, this folder only containts [`lk_badrv`](./lk_badrv.p8), which is a badrv for @tallLeRoy's [`bnk_mgr`](../bnk_mgr.p8). Feel free to suggest any badrv implementations you'd like to see. 

## API

### `badrv.prepare() -> bool`
A routine that prepares stuff before balloc can request its first bank. It **shoudn't** initialise/reset the entire alocator though, it's just for necessary steps that a client of the reservation system has to take (such as registering in a bank ownership system). In case no steps except initalisation of the system need to be taken, just define the function as an empty subroutine that returns `true`

Has to return *`true`* in case of success or *`false`* in case of failure

---

### `badrv.get_bank() -> ubyte`
Has to return a ***number of bank***, that bank reserver lets us use, or `0` in case of failure.

---

### `badrv.free_bank(ubyte bank)`
Unreserve specified bank.

---

### `badrv.free_all()`
Unreserve all banks that belong to balloc. In case your bank reservation system does not keep track of the ownership itself, feel free to rely on balloc's internals (`balloc.firstbank` and `balloc.nextbank` variables), as this API is intended to be used *only* by balloc anyway.