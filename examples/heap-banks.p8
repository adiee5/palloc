%import palloc
%import textio
%import string
%zeropage basicsafe
%option no_sysinit
%encoding iso

; i really had no idea for this one, however, it's supposed to show, 
; that it's possible to have separate heaps per bank

main{
    sub start(){
        cx16.rambank(1)
        palloc.init_hiram()
        uword i1=palloc.alloc(1)

        ;init other banks as well and allocate empty values
        cx16.rambank(2)
        palloc.reinit()
        uword i2=palloc.alloc(2)
        cx16.rambank(3)
        palloc.reinit()
        uword i3=palloc.alloc(3)
        cx16.rambank(4)
        palloc.reinit()
        uword i4=palloc.alloc(4)

        uword[4] @split ps

        cx16.rambank(1)
        ps[0]=palloc.alloc(40)
        string.copy("SELECT CONCAT",ps[0])
        cx16.rambank(2)
        ps[1]=palloc.alloc(40)
        string.copy("NJman",ps[1])
        cx16.rambank(3)
        ps[2]=palloc.alloc(40)
        string.copy("Adiee5",ps[2])
        cx16.rambank(4)
        ps[3]=palloc.alloc(40)
        string.copy("kopiujprawo",ps[3])

        ubyte i
        for i in 0 to 3{
            cx16.rambank(i+1)
            txt.print_ub(i+1)
            txt.chrout(':')
            txt.spc()
            txt.print(ps[i])
            txt.nl()
        }

        txt.print_uwhex(i1,true)
        cx16.rambank(1)
        palloc.free(i1)
        i1=palloc.alloc(1)
        txt.print("->")
        txt.print_uwhex(i1,true)
        txt.nl()
        txt.print_uwhex(i2,true)
        cx16.rambank(2)
        palloc.free(i2)
        i2=palloc.alloc(1)
        txt.print("->")
        txt.print_uwhex(i2,true)
        txt.nl()
        txt.print_uwhex(i3,true)
        cx16.rambank(3)
        palloc.free(i3)
        i3=palloc.alloc(1)
        txt.print("->")
        txt.print_uwhex(i3,true)
        txt.nl()
        txt.print_uwhex(i4,true)
        cx16.rambank(4)
        palloc.free(i4)
        i4=palloc.alloc(1)
        txt.print("->")
        txt.print_uwhex(i4,true)


    }
}