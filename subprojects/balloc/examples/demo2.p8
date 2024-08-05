%import balloc
%import dynstr
%import textio
%zeropage basicsafe
%option no_sysinit

; this example shows how we can use libraries made for palloc in a balloc ecosystem

main{
    sub start(){
        ; generally speaking, it could be a good idea to make a library bank-aware and make it for balloc, however, not always this can be done.

        bnk_mgr.init()
        if not balloc.init(){ ; in case of success, the currently set bank is always set to the one owned by balloc
            txt.print("we couldn't init the balloc")
            sys.exit(0)
        }

        ; first and fore most, since balloc is built on top of palloc, all of the palloc api is still available. you just need to make sure,
        ; that you perform actions on banks that belong to balloc. 
        ; neat thing about palloc.alloc() is that it ensures, that every allocation is on the same bank, which is exactly what we need for the compatibility!
        uword temp=palloc.alloc(5)
        palloc.free(temp)

        ; if your library provides a deploy function (one, that generates the base struct in a specified location instead of allocating it on a heap),
        ; it might be a good idea to use it instead of a function, that allocates the base struct for us.
        ubyte[3] done
        if not balloc.alloc_p(dynstr.SIZE,done){
            txt.print("something wrong happened")
            sys.exit(0)
        }

        bptr.setenv(done)
        dynstr.deploy.from(peekw(done), "test")

        ; in case there is only a function, that allocates the base struct on the heap, you can use a `try_construct` function.
        ubyte[3] yat
        cx16.r2="there"
        if not balloc.try_construct_p(lambda_1,yat){
            txt.print("something wrong happened")
            sys.exit(0)
        }
        ; this function as the first argument takes a constructor function. there are several criteria that the constructor has to meet:
        ; - must return a LSB of uword in @A and MSB in @Y (all functions written entirely in prog8 do that)
        ; - must return a pointer recieved from palloc in case of success or 0 in case of failure
        ; - must not leave garbage behind in case of failure
        ; - be able to be executed multiple times without any additional setup
        ; - must not expect any arguments. if the constructor delivered by the library does expect arguments,
        ;     you need to create a kind of wrapper that either provides static arguments or provides arguments with external variables 
        ;     that aren't modified by `balloc.try_construct()` nor the constructor itself (don't use cx16.r0 or cx16.r1 for that)
        ; - must not change banks when running
        sub lambda_1()->uword{
            return dynstr.new.from(cx16.r2)
        }

        ; whenever you want to use those objects and the API, don't forget to set the apropriate banks:
        bptr.setenv(done)
        dynstr.push_char(peekw(done),'1')
        dynstr.push_char(peekw(done),'2')
        dynstr.push_char(peekw(done),'3')
        dynstr.push_char(peekw(done),' ')

        ; remember, that some stuff may be more complicated due to banking
        if done[bptr.bank]==yat[bptr.bank]{
            bptr.setenv(done)
            dynstr.append(peekw(done),peekw(peekw(yat)))
        }
        else{
            ; idk, handle this somehow
        }

        bptr.setenv(done)
        txt.print(peekw(peekw(done)))

        ; destructors can be ran normally, as long as you make sure the correct bank is set (as usual)
        bptr.setenv(yat)
        dynstr.destroy(peekw(yat))
        bptr.setenv(done)
        dynstr.destroy(peekw(done))
    }
}