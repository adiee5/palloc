%import palloc
%import textio
%zeropage basicsafe
%option no_sysinit

main{
    sub start(){
        palloc.init($400,$4ff)
        uword i=palloc.alloc(8)
        txt.print_uwhex(i,true)
        uword j=palloc.alloc(2+8)
        txt.print_uwhex(j,true)
        txt.print_uwhex(palloc.alloc(1),true)
        ;pokew($400,j-6)
        ;pokew(j-4,0)
        palloc.free(i)
        ;%breakpoint
        txt.print_uwhex(palloc.alloc(1),true)
        txt.print_uwhex(palloc.alloc(0),true)
        txt.print_uwhex(palloc.alloc(1),true)
        ;%breakpoint
    }
}