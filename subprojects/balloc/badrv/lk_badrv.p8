; badrv for @tallLeRoy's bnk_mgr

%import bnk_mgr

lk_badrv{
        ubyte groupid=0
}

badrv{
    sub prepare()->bool{
        if lk_badrv.groupid==0{
            lk_badrv.groupid=bnk_mgr.get_groupid()
            if lk_badrv.groupid==0{
                return false
            }
        }
        return true
    }
    inline asmsub get_bank()->ubyte @A{
        %asm{{
            lda p8b_lk_badrv.p8v_groupid
            jsr p8b_bnk_mgr.p8s_get_bank
        }}
    }
    inline asmsub free_bank(ubyte bank @Y){
        %asm{{
            lda  p8b_lk_badrv.p8v_groupid
            jsr  p8b_bnk_mgr.p8s_free_bank
        }}
    }
    sub free_all(){
        void bnk_mgr.free_groupid(lk_badrv.groupid)
    }
}