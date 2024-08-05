; a demo program for the bnk_mgr made by @tallLeRoy.

%import bnk_mgr
%import textio

main {

    sub start() {
        bnk_mgr.init()
        void bnk_mgr.reserve_bank(16)
        ubyte groupid1, groupid2, groupid3

        groupid1 = bnk_mgr.get_groupid()
        if_z { ; failed to get a groupid
            txt.print("bnk_mgr.get_groupid() groupid1 failed\n")
        } else {
            txt.print("bnk_mgr.get_groupid() groupid1 = ")
            txt.print_ub(groupid1)
            txt.nl()
        }

        groupid2 = bnk_mgr.get_groupid()
        if_z { ; failed to get a groupid
            txt.print("bnk_mgr.get_groupid() groupid2 failed\n")
        } else {
            txt.print("bnk_mgr.get_groupid() groupid2 = ")
            txt.print_ub(groupid2)
            txt.nl()
        }

        ubyte bnk1, bnk2, bnk3, bnk4, bnk5, bnk6
        bnk1 = bnk_mgr.get_bank(groupid1)
        if_z {
            txt.print("bnk_mgr.get_bank(groupid1) bnk1 failed\n")
        } else {
            txt.print("bnk_mgr.get_bank(groupid1) bnk1 = ")
            txt.print_ub(bnk1)
            txt.nl()
        }

        bnk2 = bnk_mgr.get_bank(groupid2)
        if_z {
            txt.print("bnk_mgr.get_bank(groupid2) bnk2 failed\n")
        } else {
            txt.print("bnk_mgr.get_bank(groupid2) bnk2 = ")
            txt.print_ub(bnk2)
            txt.nl()
        }

        bnk3 = bnk_mgr.get_bank(groupid1)
        if_z {
            txt.print("bnk_mgr.get_bank(groupid1) bnk3 failed\n")
        } else {
            txt.print("bnk_mgr.get_bank(groupid1) bnk3 = ")
            txt.print_ub(bnk3)
            txt.nl()
        }
 
        if bnk_mgr.free_groupid(groupid2) {
            txt.print("bnk_mgr.free_groupid(groupid2) ok\n")
        } else {
            txt.print("bnk_mgr.free_groupid(groupid2) failed\n")
        }

        bnk4 = bnk_mgr.get_bank(groupid1)
        if_z {
            txt.print("bnk_mgr.get_bank(groupid1) bnk4 failed\n")
        } else {
            txt.print("bnk_mgr.get_bank(groupid1) bnk4 = ")
            txt.print_ub(bnk4)
            txt.nl()
        }

        if bnk_mgr.free_bank(groupid1,bnk1) {
            txt.print("bnk_mgr.free_bank(groupid1,bnk1) ok\n")
        } else {
            txt.print("bnk_mgr.free_bank(groupid1,bnk1) failed\n")
        }

        groupid3 = bnk_mgr.BM_INVALID_GROUPID
        bnk5 = bnk_mgr.get_bank(groupid3)
        if_z {
            txt.print("bnk_mgr.get_bank(groupid3) bnk5 failed\n")
        } else {
            txt.print("bnk_mgr.get_bank(groupid3) bnk5 = ")
            txt.print_ub(bnk5)
            txt.nl()
        }

        bnk6 = bnk_mgr.get_consecutive_banks(groupid2, 7)
        if_z {
            txt.print("bnk_mgr.get_consecutive_banks(groupid2, 7) failed\n")
        } else {
            txt.print("bnk_mgr.get_consecutive_banks(groupid2, 7) bnk6 = ")
            txt.print_ub(bnk6)
            txt.nl()
        }

        void txt.waitkey()
    }
}
