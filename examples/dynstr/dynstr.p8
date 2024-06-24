; A library, that implements dynamically sized strings. 

%import string
; remember to import palloc in the master program. This file itself doesn't import the palloc for the sake of flexibility

dynstr{
    const uword SIZE = 3
    const ubyte capacity = 2 ; the value of capacity corresponds to the results of string.length()

    ; dynstr variable creation functions:
    ;   dynstr.new() - creates an empty dynstr variable
    ;   dynstr.new.with_capacity(cap) - creates an empty dynstr variable with preallocated amount of space for the char buffer
    ;   dynstr.new.from(src) - creates a dynstr variable, that's prefilled with the provided string.
    ; All of them either return a pointer to a dynstr variable or return 0 in case of error
    sub new()->uword{
        return with_capacity(0)

        sub with_capacity(ubyte cap)->uword{
            reg1 = palloc.alloc(SIZE)
            if (reg1==0)return 0
            if not dynstr.deploy.with_capacity(reg1,cap){
                palloc.free(reg1)
                return 0
            }
            return reg1
        }

        sub from(str src)->uword{
            reg1=with_capacity(string.length(src))
            if reg1!=0{
                void string.copy(src, peekw(reg1))
                return reg1
            }
            return 0
        }
    }

    ; The same thing as new(), but instead of allocating the dynstr metadata on the heap, it requires user to provide an address to 3-byte buffer,
    ; where it's expected for the dynstr metadata to be stored. Note, that the string/text data itself is still going to be allocated on the heap.
    ; This method of creating dynstr variables may be useful when you want to have a dynstr as a part of a struct or generally as a space saving measure.
    ; All of them return true on success or false on failure.
    sub deploy(uword address)->bool{
        return with_capacity(address,0)

        sub with_capacity(uword address, ubyte cap)->bool{
            cx16.r0 =palloc.alloc(cap+1)
            if (cx16.r0==0)return false
            pokew(address,cx16.r0)
            address[capacity]=cap
            cx16.r0[0]=0
            cx16.r0[cap]=0
            return true
        }

        sub from(uword address, str src)->bool{
            if with_capacity(address, string.length(src)){
                void string.copy(src, peekw(address))
                return true
            }
            return false
        }
    }
    
    ; dealocates the provided dynstr and the string buffer it owned.
    ; WARNING: use only if the dynstr was created using dynstr.new() - using it on dynstr created 
    ;          with dynstr.deploy() may result in the corruption of the data, heap, program or the entire system!
    ;          for deployed dynstrs, manually deallocate the string buffer in a folowing way: `palloc.free(peekw(var_t_dynstr))`
    sub destroy(uword self){
        palloc.free(peekw(self))
        palloc.free(self)
    }

    ; Follows the same syntax as string.copy(), but the second argument has to be a dynstr (while the first one has to be a regular string!).
    ; In case of failure, the function returns false, the target dynstr will have capacity set to 0 and WILL NO LONGER HAVE ANY VALID STRING DATA!
    sub copy(str src, uword target)->bool{
        reg1=string.length(src)
        if reg1>target[capacity]{
            palloc.free(peekw(target))
            pokew(target,palloc.alloc(reg1+1))
            if peekw(target)==0{
                target[capacity]=0
                return false
            }
            target[capacity]=reg1 as ubyte
        }
        void string.copy(src, peekw(target))
        return true
    }

    ; the same syntax as string.append(), but the first argument has to be a dynstr (while the second one has to be a regular string!).
    ; Returns false in case of failure. In that case the dynstr variable remains untouched.
    sub append(uword self, str src)->bool{
        reg1 = string.length(peekw(self))+string.length(src)
        if (reg1>255)return false ; dynstrs can't hold buffers larger than 255 and you can't use that big of a string in prog8 reliably anyways.
        if reg1>self[capacity]{
            cx16.r1=palloc.alloc(reg1+1)
            if(cx16.r1==0)return false
            self[capacity]=reg1 as ubyte
            reg1 = string.copy(peekw(self),cx16.r1)
            void string.copy(src,cx16.r1+reg1)
            palloc.free(peekw(self))
            pokew(self,cx16.r1)
        }
        else void string.append(peekw(self),src)
        return true
    }

    ; moves the string data of the provided dynstr into a new, perfectly sized buffer.
    sub rebase(uword self){
        cx16.r0L=string.length(peekw(self))
        reg1 =palloc.alloc(cx16.r0L+1)
        if (reg1==0)return
        self[capacity]=cx16.r0L
        void string.copy(peekw(self),reg1)
        palloc.free(peekw(self))
        pokew(self,reg1)
    }

    ; Character manipulation methods. I think they're self-explanatory
    sub char_at(uword self, ubyte i)->ubyte{
        return @(peekw(self)+i)
    }
    sub setchar_at(uword self, ubyte i, ubyte char){
        if(i>=self[capacity])return
        @(peekw(self)+i)=char
    }

    ; Using the dynstr as stack of characters, because why not
    sub push_char(uword self, ubyte char)->bool{

        const ubyte SURPLUS = 7 ; when allocating new buffer, the new buffer will be larger than the previous one by this amount of bytes.
                                ; Allocating more data than necessarry is beneficial for the performance, especially when pushing multiple times.

        cx16.r1L=string.length(peekw(self))
        if (cx16.r1L>=255)return false
        if cx16.r1L>=self[capacity]{
            reg1=palloc.alloc(clamp((cx16.r1L as uword)+SURPLUS+1,1,256))
            if (reg1==0)return false
            void string.copy(peekw(self),reg1)
            palloc.free(peekw(self))
            self[capacity]=clamp((cx16.r1L as uword)+SURPLUS,0,255)as ubyte
            pokew(self,reg1)
        }
        @(peekw(self)+cx16.r1L)=char
        @(peekw(self)+cx16.r1L+1)=0
        return true
    }
    sub pop_char(uword self)->ubyte{
        if (@(peekw(self))==0)return 0
        reg1=string.length(peekw(self))
        cx16.r0L=@(peekw(self)+reg1-1)
        @(peekw(self)+reg1-1)=0
        return cx16.r0L
    }
    uword reg1 
}

