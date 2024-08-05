%import balloc
%import textio
%zeropage basicsafe
%option no_sysinit

main{
    sub start(){
        bnk_mgr.init()
        if not balloc.init(){
            txt.print("we couldn't init the balloc")
            sys.exit(0)
        }
        ubyte[3] zat
        if not balloc.alloc_p(3,zat){
            txt.print("allocation failed")
            sys.exit(0)
        }
        txt.print_ubhex(zat[bptr.bank],true)
        txt.print_uwhex(peekw(zat),false)
        uword zato
        ubyte zati
        zato, zati = bptr.to_manual(zat)
        txt.print_ubhex(zati,true)
        txt.print_uwhex(zato,false)
        balloc.free_m(zato, zati)
        %breakpoint
        cx16.r0=6502
        txt.nl()
        txt.print_uw(cx16.r0)
        zato, zati = balloc.alloc_m(3)
        txt.nl()
        txt.print_ubhex(zati,true)
        txt.print_uwhex(zato,false)
        txt.nl()
        txt.print_uw(cx16.r0)
    }
}