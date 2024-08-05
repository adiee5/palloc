%import palloc
%import dynstr
%import textio
%option no_sysinit
%zeropage basicsafe

main{
    sub start(){
        palloc.init_golden()

        ; creating a dynstr using new()
        uword j=dynstr.new.from("i like")

        txt.print(peekw(j))
        txt.print(peekw(dynstr.new()))

        void dynstr.copy(" commander",j)
        void dynstr.append(j," x16")
        txt.print(peekw(j))

        txt.nl()

        txt.chrout(dynstr.char_at(j,4))
        dynstr.setchar_at(j,1,'k')
        txt.print(peekw(j))

        ; creating a dynstr using deploy()
        ubyte[3] pj
        void dynstr.deploy.from(pj,peekw(j))

        dynstr.destroy(j)
        txt.nl()

        txt.chrout(dynstr.pop_char(pj))
        void dynstr.push_char(pj,'9')
        txt.nl()
        txt.print(peekw(pj))
    }
}