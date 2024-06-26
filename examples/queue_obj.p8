; a way to have multiple queues allocated on the heap.
; you'll need a queue.p8 library, which you can get here: https://gist.github.com/adiee5/22bbc588cf5c5329ef57d6dd48a5fae8

%import queue
%import palloc
%import textio
%option no_sysinit
%zeropage basicsafe

main{
    sub start(){
        txt.print_ub(queue_obj.SIZE)
        palloc.init_golden()
        uword j=queue_obj.new(500)
        queue_obj.select(j)
        txt.print("\rj=")
        queue.input()
        queue_obj.select(queue_obj.new(200))
        txt.print("\rtmp=")
        queue.input()
        txt.print("\rtmp=")
        queue.print()
        queue_obj.destroy()
        txt.print("\rj=")
        queue_obj.select(j)
        queue.print()
        queue_obj.destroy()
    }
}

queue_obj{
    const ubyte SIZE=2*3+1

    const ubyte endaddr=0
    const ubyte fi=2
    const ubyte fo=4
    const ubyte state=6

    ; creates a new queue object
    sub new(uword size)->uword{
        if(size==0)return 0
        cx16.r0=palloc.alloc(SIZE+size)
        if (cx16.r0==0)return 0
        pokew(cx16.r0+endaddr,cx16.r0+SIZE+size-1)
        pokew(cx16.r0+fi,cx16.r0+SIZE)
        pokew(cx16.r0+fo,cx16.r0+SIZE)
        cx16.r0[state]=queue.initialised
        return cx16.r0
    }

    ; select which queue we want to work on
    sub select(uword q){
        if (queue_cfg.startaddr!=0)save()
        queue_cfg.startaddr=q+SIZE
        queue_cfg.endaddr=peekw(q+endaddr)
        queue.fi=peekw(q+fi)
        queue.fo=peekw(q+fo)
        queue.state=q[state]
    }

    ; save the metadata of the currently selected queue
    sub save(){
        cx16.r0=queue_cfg.startaddr-SIZE
        pokew(cx16.r0+endaddr,queue_cfg.endaddr)
        pokew(cx16.r0+fi,queue.fi)
        pokew(cx16.r0+fo,queue.fo)
        cx16.r0[state]=queue.state
    }

    ; deallocates the currently selected queue. For unselected queues, one can just use palloc.free(), no need to select a queue just for that
    sub destroy(){
        if (queue_cfg.startaddr==0)return
        palloc.free(queue_cfg.startaddr-SIZE)
        queue_cfg.startaddr=0
        queue.state=0
    }
}

queue_cfg{
    ; they have to be variables - they have to be editable!
    uword startaddr=0
    uword endaddr

    sub on_runtimeerr(){
        txt.color(10)
        txt.print("SEGFAULT!!")
        sys.exit(0)
    }
}