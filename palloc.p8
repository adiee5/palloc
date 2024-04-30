palloc{
    uword @zp startaddr
    uword endaddr
    bool initialised=false
    const uword MINSIZE=7

    ;chunk structure:
    ; .byte size, size_msb, prevptr, prevptr_msb, nextptr, nextptr_msb, data, data, ....

    ; pointers returned to users point only to data
    ; size stores the size of the entire chunk, not just the data

    sub init(uword start, uword end) -> bool{
        if(initialised)return true
        if(not set_space(start, end))return false
        reinit()
        return true
    }

    inline asmsub init_golden(){
        %asm{{
        lda  #<$0400
        ldy  #>$0400
        sta  p8b_palloc.p8s_init.p8v_start
        sty  p8b_palloc.p8s_init.p8v_start+1

        lda  #<$07ff
        ldy  #>$07ff
        sta  p8b_palloc.p8s_init.p8v_end
        sty  p8b_palloc.p8s_init.p8v_end+1

        jsr  p8b_palloc.p8s_init
        }}
    }
    inline asmsub init_loram(){
        %asm{{
        lda  #<prog8_program_end
        ldy  #>prog8_program_end
        sta  p8b_palloc.p8s_init.p8v_start
        sty  p8b_palloc.p8s_init.p8v_start+1

        lda  #<$9eff
        ldy  #>$9eff
        sta  p8b_palloc.p8s_init.p8v_end
        sty  p8b_palloc.p8s_init.p8v_end+1

        jsr  p8b_palloc.p8s_init
        }}
    }
    inline asmsub init_hiram(){
        %asm{{
        lda  #<$a000
        ldy  #>$a000
        sta  p8b_palloc.p8s_init.p8v_start
        sty  p8b_palloc.p8s_init.p8v_start+1

        lda  #<$bfff
        ldy  #>$bfff
        sta  p8b_palloc.p8s_init.p8v_end
        sty  p8b_palloc.p8s_init.p8v_end+1

        jsr  p8b_palloc.p8s_init
        }}
    }

    sub reinit(){
        if(not initialised)return
        pokew(startaddr, endaddr)
    }

    sub set_space(uword start, uword end) -> bool{
        if initialised{
            return true
        }
        if start==end{
            return false
        }
        if end<start{
            reg_temp=end
            end=start
            start=reg_temp
        }
        if end-start<MINSIZE+2{
            return false
        }
        startaddr=start
        endaddr=end+1
        initialised=true
        return true
    }

    sub alloc(uword size)->uword{
        if(not initialised)return 0

        if peekw(startaddr)<startaddr+2{
            reinit()
        }

        size+=MINSIZE-1
        if (size<MINSIZE)return 0

        reg_curprev=peekw(startaddr)
        if ((reg_curprev-(startaddr+2))>=size){
            pokew(startaddr,startaddr+2)
            pokew(startaddr+2,size)
            pokew(startaddr+4,0)
            pokew(startaddr+6,reg_curprev)
            if(reg_curprev<endaddr)pokew(reg_curprev+2,startaddr+2)
            return startaddr+8
        }
        
        while reg_curprev<endaddr{
            reg_temp=peekw(reg_curprev)
            reg_next=peekw(reg_curprev+4)

            if ((reg_next-(reg_curprev+reg_temp))>=size){
                pokew(reg_curprev+reg_temp,size)
                pokew(reg_curprev+reg_temp+2,reg_curprev)
                pokew(reg_curprev+reg_temp+4,reg_next)
                pokew(reg_curprev+4,reg_curprev+reg_temp)
                if(reg_next<endaddr)pokew(reg_next+2, reg_curprev+reg_temp)
                return reg_curprev+reg_temp+6
            }
            reg_curprev=reg_next
        }
        return 0
    }
    sub free(uword ptr){
        if(not initialised) return
        if(ptr<(startaddr+2+MINSIZE-1) or ptr>=endaddr)return
        if(peekw(ptr-6)==0)return
        reg_curprev=peekw(ptr-4)
        reg_next=peekw(ptr-2)
        if reg_curprev==0{
            pokew(startaddr,reg_next)
        }
        else {
            pokew(reg_curprev+4,reg_next)
        }
        if reg_next<endaddr{
            pokew(reg_next+2,reg_curprev)
        }
        pokew(ptr-6,0)
    }

    ; temporary registers used for internal operations (cx16 registers used to be clobbered before)
    uword reg_temp
    uword @zp reg_curprev
    uword @zp reg_next
}