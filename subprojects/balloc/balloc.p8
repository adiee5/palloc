%import palloc
%import bnk_mgr
balloc{

    ubyte groupid=0
    ubyte firstbank
    &ubyte nextbank=$A000

    ; scope, that contains all errors returned by balloc
    sub err(){
        const ubyte NOMEM=$00 ; no more banks available
        const ubyte TOBIG=$FF ; provided size is too big
        const ubyte NOINI=$AA ; balloc was not initialised yet
        const ubyte INVIN=$18 ; User provided invalid input (for example requested an allocation with size of 0)
    }

    ; inits the balloc. this assumes, that `bnk_mgr.init()` was already called!!
    sub init()->bool{
        if groupid==0{
            groupid=bnk_mgr.get_groupid()
            if groupid==0{
                return false
            }
        }
        firstbank=bnk_mgr.get_bank(groupid)
        if firstbank==0{
            return false
        }
        cx16.rambank(firstbank)
        nextbank=0
        return palloc.init($A001, $BFFF)
    }

    ; allocates a specified amount of continuous memory on the heap and returns the pointer and a bank, where the memory is allocated.
    ; in case of failure, uword return is set to 0 and ubyte return is an error code. 
    inline asmsub alloc_m(uword size @AY)-> uword @AY, ubyte @X{
        %asm{{
            sta  p8b_balloc.p8s_alloc_p.p8v_size
            sty  p8b_balloc.p8s_alloc_p.p8v_size+1

            lda  #<cx16.r0
            ldy  #>cx16.r0
            sta  p8b_balloc.p8s_alloc_p.p8v_b_ptr
            sty  p8b_balloc.p8s_alloc_p.p8v_b_ptr+1

            lda  cx16.r0
            pha
            lda  cx16.r0+1
            pha
            lda  cx16.r0+2
            pha

            jsr  p8b_balloc.p8s_alloc_p

            ldx cx16.r0+2
            pla
            sta cx16.r0+2
            ldy cx16.r0+1
            pla
            sta cx16.r0+1
            lda cx16.r0
            sta P8ZP_SCRATCH_REG
            pla
            sta cx16.r0
            lda P8ZP_SCRATCH_REG
        }}
    }

    ; the same as alloc_m, but pointer and bank data are stored in a specified bptr variable (essentially a 3-byte buffer)
    sub alloc_p(uword size, uword b_ptr) -> bool{
        if not palloc.initialised{
            pokew(b_ptr,0)
            b_ptr[bptr.bank]=balloc.err.NOINI
            return false
        }
        if size>$C000-$A002-palloc.MINSIZE{
            pokew(b_ptr,0)
            b_ptr[bptr.bank]=balloc.err.TOBIG
            return false
        }
        if size==0{
            pokew(b_ptr,0)
            b_ptr[bptr.bank]=balloc.err.INVIN
            return false
        }
        cx16.rambank(firstbank)
        repeat{
            pokew(b_ptr,palloc.alloc(size))
            if b_ptr[1]!=0{
                b_ptr[bptr.bank]=cx16.getrambank()
                return true
            }
            if (nextbank==0) break
            cx16.rambank(nextbank)
        }
        nextbank=bnk_mgr.get_bank(groupid)
        if nextbank==0{
            pokew(b_ptr,0)
            b_ptr[bptr.bank]=balloc.err.NOMEM
            return false
        }
        cx16.rambank(nextbank)
        nextbank=0
        palloc.reinit()
        pokew(b_ptr,palloc.alloc(size))
        ; unless someone decided to use a different palloc implementation than reccomended, line above should always yield true,
        ; so there is no need to check that
        b_ptr[bptr.bank]=cx16.getrambank()
        return true
    }

    ; runs a constructor that's supposed to create an object with the help of palloc. see demo2.p8 for more info how to use this.
    ; result values are similar to balloc.alloc_m/p()
    inline asmsub try_construct_m(uword fn @AY)-> uword @AY, ubyte @X{
        %asm{{
            sta  p8b_balloc.p8s_try_construct_p.p8v_fn
            sty  p8b_balloc.p8s_try_construct_p.p8v_fn+1

            lda  #<cx16.r0
            ldy  #>cx16.r0
            sta  p8b_balloc.p8s_try_construct_p.p8v_b_ptr
            sty  p8b_balloc.p8s_try_construct_p.p8v_b_ptr+1

            lda  cx16.r0
            pha
            lda  cx16.r0+1
            pha
            lda  cx16.r0+2
            pha

            jsr  p8b_balloc.p8s_try_construct_p

            ldx cx16.r0+2
            pla
            sta cx16.r0+2
            ldy cx16.r0+1
            pla
            sta cx16.r0+1
            lda cx16.r0
            sta P8ZP_SCRATCH_REG
            pla
            sta cx16.r0
            lda P8ZP_SCRATCH_REG
        }}
    }

    sub try_construct_p(uword fn, uword b_ptr) -> bool{
        if not palloc.initialised{
            pokew(b_ptr,0)
            b_ptr[bptr.bank]=balloc.err.NOINI
            return false
        }
        cx16.rambank(firstbank)
        repeat{
            pokew(b_ptr,call(fn))
            if(peekw(b_ptr)>=$A002+palloc.MINSIZE) and (peekw(b_ptr)<$C000){
                b_ptr[bptr.bank]=cx16.getrambank()
                return true
            }
            else if peekw(b_ptr)==0{
                ;continue doing stuff
            }
            else{
                ; any pointer should fit within the boundaries of banked region. if it returns something else,
                ; this probably means that user provided an invalid constructor function, therefore this counts as invalid input
                pokew(b_ptr,0)
                b_ptr[bptr.bank]=balloc.err.INVIN
                return false
            }
            if (nextbank==0) break
            cx16.rambank(nextbank)
        }
        nextbank=bnk_mgr.get_bank(groupid)
        if nextbank==0{
            pokew(b_ptr,0)
            b_ptr[bptr.bank]=balloc.err.NOMEM
            return false
        }
        cx16.rambank(nextbank)
        nextbank=0
        palloc.reinit()
        pokew(b_ptr,call(fn))
        if peekw(b_ptr)==0{
            b_ptr[bptr.bank]=cx16.getrambank()
            cx16.rambank(firstbank)
            while nextbank!=b_ptr[bptr.bank]{
                cx16.rambank(nextbank)
            }
            nextbank=0
            void bnk_mgr.free_bank(groupid,b_ptr[bptr.bank])
            ; It could technically be INVIN (either in the arguments provided to an constructor or a bug in the constructor), but it's most likely TOBIG
            b_ptr[bptr.bank]=balloc.err.TOBIG
            return false
        }
        b_ptr[bptr.bank]=cx16.getrambank()
        return true
    }

    ; frees specified block, that was previosly allocated
    sub free_m(uword ptr, ubyte bank){
        if (not palloc.initialised) return
        if (bank == 0) return
        cx16.rambank(bank)
        palloc.free(ptr)
        if peekw($A001)==$C000{
            if firstbank==bank{
                if nextbank==0{
                    return ; we don't really want the situation, where no banks exist
                }
                firstbank=nextbank
            }
            else{
                ptr=nextbank
                cx16.rambank(firstbank)
                while nextbank!=bank{
                    if (nextbank==0) {
                        ; this is REALLY suspicious. sadly idk how to signal the user about that. this probably should not happen if user doesn't for example double free
                        ;%asm{{brk}} ; uncomment if you find this apropriate
                        return 
                    }
                    cx16.rambank(nextbank)
                }
                nextbank=ptr as ubyte
            }
            void bnk_mgr.free_bank(groupid,bank) ; it's unlikely, that this would yield false, if it would, that'd mean we clobbered data not bellonging to us
            ;if_z %asm{{brk}}
        }
    }

    ; the same as free_m(). it also empties the pointer variable, since we can do that
    inline asmsub free_p(uword b_ptr @AY) clobbers(A,X,Y){
        %asm{{
            sta  P8ZP_SCRATCH_W1
            sty  P8ZP_SCRATCH_W1+1
            lda  (P8ZP_SCRATCH_W1)
            sta  p8b_balloc.p8s_free_m.p8v_ptr
            lda  #0
            sta  (P8ZP_SCRATCH_W1)
            ldy  #1
            lda  (P8ZP_SCRATCH_W1),y
            sta  p8b_balloc.p8s_free_m.p8v_ptr+1
            lda  #0
            sta  (P8ZP_SCRATCH_W1),y
            iny
            lda  (P8ZP_SCRATCH_W1),y
            sta  p8b_balloc.p8s_free_m.p8v_bank
            lda  #0
            sta  (P8ZP_SCRATCH_W1),y
            jsr  p8b_balloc.p8s_free_m
        }}
    }

    ; disables balloc completely and frees all banks it has reserved. all pointers allocated up to this point are INVALID! 
    ; after running this, you can grab the value of balloc.groupid, reset the variable to 0 and reuse the value somewhere else
    ; or you can keep the variable intact, so when you initialise the balloc again, it will use the same groupid as before.
    sub shutdown(){
        if (not palloc.initialised) return
        void bnk_mgr.free_groupid(groupid) ; this only fails, when there are no banks of ours, we definitely have some.
        palloc.initialised=false
    }
}

; helper functions for banked pointer type.
bptr{
    const ubyte bank = 2

    ; sets the correct rambank, where the value is stored.
    ; doesn't need to be executed, when trying to use functions provided by balloc and bptr blocks
    sub setenv(uword self){
        cx16.rambank(self[bank])
    }

    ; sub get_ptr() ; use peekw(var)
    ; sub get_bank() ; use var[bptr.bank]

    ; small conversion subroutines. I don't think they're necessary, but whatever
    inline asmsub from_manual(uword ptr @AY, ubyte bank @X, uword target @R0) clobbers(A,X,Y) -> uword @R0{
        ;pokew(target, ptr)
        ;target[bptr.bank]=bank
        ;return target
        %asm{{
            sta (cx16.r0)
            tya
            ldy #1
            sta (cx16.r0),y
            iny
            txa
            sta (cx16.r0),y
        }}
    }
    inline asmsub to_manual(uword self @R0)->uword @AY, ubyte @X{
        %asm{{
            ldy #p8b_bptr.p8c_bank
            lda (cx16.r0),y
            tax
            dey
            lda (cx16.r0),y
            tay
            lda (cx16.r0)
        }}
    }

    ; subs, that treat the bptr as a pointer to an array. uwb stands for "uword byte aligned"
    sub get_ub(uword self, uword index)->ubyte{
        cx16.rambank(self[bank])
        return @(peekw(self)+index)
    }
    sub get_uw(uword self, uword index)->uword{
        return get_uwb(self, index*2)
    }
    sub get_uwb(uword self, uword index)->uword{
        cx16.rambank(self[bank])
        return peekw(peekw(self)+index)
    }

    sub set_ub(uword self, uword index, ubyte value){
        cx16.rambank(self[bank])
        if (index>(peekw(peekw(self)-6)-6))return ; since readme declares, that balloc will only word with original palloc, relying on internals is acceptable
        @(peekw(self)+index)=value
    }
    sub set_uw(uword self, uword index, uword value){
        set_uwb(self, index*2, value)
    }
    sub set_uwb(uword self, uword index, uword value){
        cx16.rambank(self[bank])
        if (index>(peekw(peekw(self)-6)-7))return
        pokew(peekw(self)+index,value)
    }
    
}