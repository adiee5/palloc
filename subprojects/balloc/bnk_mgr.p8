; bnk_mgr.p8 - a bank manager created by @tallLeRoy


; this RAM bank manager will arrange banks into groupids. the number of banks in a groupid can grow
; with each call to get_bank() the bank returned may not be contiguous, and may be higher or lower
; than other banks with the same groupid. 
;
bnk_mgr {
    const ubyte BM_BANK_RESERVED = 0
    const ubyte BM_BANK_AVAILABLE = 1
    const ubyte BM_INVALID_GROUPID = 0
    const ubyte BM_FIRST_GROUPID = BM_BANK_AVAILABLE + 1
    ubyte[256] bnk_tbl
    ubyte next_groupid, i, t

    ; init() should be called before any other subroutine in this block. 
    ; it marks each bank in the system as reserved or available
    ; unpopulated banks are marked reserved
    sub init() {
        next_groupid = BM_FIRST_GROUPID
        t = lsb(cx16.numbanks() - 1)    ; t contains the last physical RAM bank
        bnk_tbl[0] = BM_BANK_RESERVED
        for i in 1 to 255 {
            bnk_tbl[i] = BM_BANK_AVAILABLE
            if i > t {
                bnk_tbl[i] = BM_BANK_RESERVED
            }
        }
    }

    ; reserve any bank that is used in your program but not allocated by the bank manager
    ; RAM bank 0 was reserved by init()
    sub reserve_bank(ubyte bank) -> bool {
        if bnk_tbl[bank] != BM_BANK_AVAILABLE {
            ; already has a groupid or is reserved
            return false
        }
        bnk_tbl[bank] = BM_BANK_RESERVED
        return true
    }

    ; group ids go from 2 through 255, they can be reused after free by the same program routine.
    ; if this call returns BM_ (0) , you are out to groupids, it will not reset
    ; you may reuse a groupid once given even after freeing all banks with free_groupid()
    sub get_groupid() -> ubyte {
        t = next_groupid            ; t is the return value, the existing next_groupid
        if next_groupid != BM_INVALID_GROUPID {    ; stick with BM_INVALID_GROUPID once attained
            next_groupid += 1       ; increment next_groupid for next time
        }
        return t
    }

    ; get_bank() will return a number between 1 and 255 if a free bank is available. 
    ; if this call returns BM_BANK_RESERVED (0) , no bank is available for your program.
    sub get_bank(ubyte groupid) -> ubyte {
        t = BM_BANK_RESERVED    ; t is the return value, preset to failure
        if groupid >= BM_FIRST_GROUPID {
            for i in 0 to 255 {
                if bnk_tbl[i] == BM_BANK_AVAILABLE {
                    bnk_tbl[i] = groupid    
                    t = i       ; reset return value to the available bank
                    break
                }
            }
        }
        return t
    }

    ; get_consecutive_banks will add given count banks to the given groupid. 
    ; if the call fails, BM_BANK_RESERVED (0) is returned else 
    ; the number of the first bank is returned. count banks will be consecutive.
    sub get_consecutive_banks(ubyte groupid, ubyte count) -> ubyte {
        ubyte j
        t = BM_BANK_RESERVED    ; t is the return value, preset to failure
        for i in 1 to 255 {
            j = 0
            repeat count {
                if bnk_tbl[i+j] != BM_BANK_AVAILABLE {
                    break       ; the repeat count loop
                }
                j++
            }
            if j == count {     ; we found the sequence
                t = i           ; reset the return value to the first bank in sequence
                repeat count {
                    bnk_tbl[i] = groupid
                    i++
                }
                break           ; the for i in 1 to 255 loop
            }
        }
        return t
    }

    ; free_groupid() marks all banks with the given groupid as availabe
    ; the groupid may be later reused by the program
    sub free_groupid(ubyte groupid) -> bool {
        t = 0
        for i in 0 to 255 {
            if bnk_tbl[i] == groupid {
                bnk_tbl[i] = BM_BANK_AVAILABLE
                t = 1
            }
        }
        return t == 1
    }

    ; free_bank() will mark a single bank as available if the bank belongs
    ; to the groupid give. If not, it does nothing and returns false
    sub free_bank(ubyte groupid, ubyte bank) -> bool {
        if bnk_tbl[bank] == groupid {
            bnk_tbl[bank] = BM_BANK_AVAILABLE
            return true
        }
        return false
    }
}