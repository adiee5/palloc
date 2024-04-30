%import textio
%import string
%import palloc
%zeropage basicsafe
%option no_sysinit

; a small rewrite of my older obj.p8, that takes advantage of the dynamic heap allocation
; og can be found here: https://gist.github.com/adiee5/b87e0a3303b577d0122e12cb032101f1


main{
    sub start(){
        ;sys.exit(0)
        void palloc.init_golden()
        uword andrzej=human.new("andrzej","marecki")
        uword poet=human.new("czes£aw","mi£osz")
        uword girl=human.new("taylor","swift")

        txt.print(human.get_name(andrzej))
        txt.chrout('\r')
        txt.print(human.get_name(poet))
        txt.chrout('\r')
        txt.print(human.get_name(girl))
        human.choose_job(girl,"singer",true)
        human.choose_job(poet,"poet",true)
        txt.chrout('\r')
        human.marry(andrzej,girl)
        human.marry(poet,human.new("carol","thigpen-mi£osz"))
        human.set_statflag(poet,human.flags.dead)
        andrzej[human.age]=20
        girl[human.age]=30
        poet[human.age]=80
        @(human.get_partner(poet)+human.age)=60
        human.print(andrzej)
        human.print(poet)
        human.print(girl)
        human.print(human.get_partner(poet))
        human.disintegrate(human.get_partner(poet))
        uword guy=human.new("david","murray")
        guy[human.age]=40
        human.choose_job(guy,"8-bit guy",true)
        human.print(guy)
    }
}
human{
    const ubyte SIZE=(2+1)+1+1+2+(2+1)+(2+1)

    const ubyte name =0; &str + len()
    const ubyte age=3; ubyte
    const ubyte status=4; 8 bits
    const ubyte partner=5; &obj
    const ubyte last_name=7; &str + len()
    const ubyte job=10; &str + len()

    sub flags(){ ; IT'S NOT A FUNCTION!!!!!!, it's just a scope for constant bolean values of status atribute
        const ubyte dead=$80
        const ubyte married=$40
        const ubyte employed=$20
        ;$10
        ;8
        ;4
        ;2
        ;1
    }

    
    ;allocates memory for new object and names. returns the pointer to new object 
    sub new(str new_name, str new_last_name)->uword{
        void new_empty()

        tempuword=palloc.alloc(string.length(new_name)+1)
        if tempuword==0{
            txt.color(10)
            txt.print("there's no space left for the new 'human' object, the program's going to quit")
            txt.color(1)
            sys.exit(0)
        }
        string.copy(new_name, tempuword)
        tempresult[name]=lsb(tempuword)
        tempresult[name+1]=msb(tempuword)
        tempresult[name+2]=string.length(tempuword)

        tempuword=palloc.alloc(string.length(new_last_name)+1)
        if tempuword==0{
            txt.color(10)
            txt.print("there's no space left for the new 'human' object, the program's going to quit")
            txt.color(1)
            sys.exit(0)
        }
        string.copy(new_last_name, tempuword)
        tempresult[last_name]=lsb(tempuword)
        tempresult[last_name+1]=msb(tempuword)
        tempresult[last_name+2]=string.length(tempuword)

        return tempresult
    }

    ; similar to human.new(), but only allocates the object itself and you'll need to set name and last_name afterwards
    sub new_empty()->uword{
        tempresult=palloc.alloc(SIZE)
        if tempresult==0{
            txt.color(10)
            txt.print("there's no space left for the new 'human' object, the program's going to quit")
            txt.color(1)
            sys.exit(0)
        }
        ubyte i
        for i in 0 to SIZE-1{
            tempresult[i]=0
        }
        return tempresult
    }

    ; the human object and related allocations aget freed
    sub disintegrate(uword obj){
        divorce(obj)
        palloc.free(get_job_name(obj))
        palloc.free(get_name(obj))
        palloc.free(get_last_name(obj))
        palloc.free(obj)
    }

    sub get_name(uword self )->uword{
        return mkword (self[name+1], self[name])
    }
    ; get_age == obj[age]
    ; get_status == obj[status] ;there are however helper functions
    sub get_partner(uword self)->uword{
        return mkword(self[partner+1],self[partner])
    }
    sub get_last_name(uword self )->uword{
        return mkword (self[last_name+1], self[last_name])
    }
    sub get_job_name(uword self)->uword{ ;returns 0 of there's no buffer
        return mkword (self[job+1], self[job])
    }

    ; returns true if they get married, false if marriage was unsuccesful.
    ; you can see marriage error message in `human.tempstr` variable
    sub marry(uword az, uword buky)->bool{ 
        if az[status]&human.flags.married!=0{
            tempstr[0]='"'
            tempstr[1]=0
            void string.append(tempstr,human.get_name(az))
            void string.append(tempstr,"\"is already married, please call 'human.divorce()' first.")
            return false
        }
        if buky[status]&human.flags.married!=0{
            tempstr[0]='"'
            tempstr[1]=0
            void string.append(tempstr,human.get_name(buky))
            void string.append(tempstr,"\"is already married, please call 'human.divorce()' first.") ;" ;vscode syntax coloring is broken 3-(
            return false
        }
        @(az+status)|=human.flags.married
        @(buky+status)|=human.flags.married
        az[partner]=lsb(buky)
        az[partner+1]=msb(buky)
        buky[partner]=lsb(az)
        buky[partner+1]=msb(az)
        return true
    }

    ; divorces a human.
    sub divorce(uword self){
        if self[status]&human.flags.married==0{
            return
        }
        uword temppartner=get_partner(self);human.divorce() is often used internally, so it has it's own temp var...
        @(self+status)&=~human.flags.married
        @(temppartner+status)&=~human.flags.married
        self[partner]=0
        self[partner+1]=0
        temppartner[partner]=0
        temppartner[partner+1]=0
    }

    ;changes the contents of name buffer. if new name is longer than the current buffer,
    ;it will either crop the name to fit (if not new_buf) or will create a new, bigger buffer (if new_buf) and old buffer will be discarded (which doesn't waste memory anymore!)
    sub change_name(uword self, str new_name, bool new_buf){
        if string.length(new_name)>self[name+2]{
            if new_buf{
                tempresult=palloc.alloc(string.length(new_name)+1)
                if tempresult!=0{
                    string.copy(new_name, tempresult)
                    palloc.free(get_name(self))
                    self[name]=lsb(tempresult)
                    self[name+1]=msb(tempresult)
                    self[name+2]=string.length(new_name)
                }else if get_name(self)!=0{
                    void string.copy(new_name,tempstr)
                    tempstr[self[name+2]]=0
                    tempstr[self[name+2]-1]='_'
                    void string.copy(tempstr,get_name(self))
                }
            }else if get_name(self)!=0{
                void string.copy(new_name,tempstr)
                tempstr[self[name+2]]=0
                tempstr[self[name+2]-1]='_'
                void string.copy(tempstr,get_name(self))
            }
        }
        else{
            void string.copy(new_name, get_name(self))
        }
    }

    ; sets the name atribute to the address of a buffer, that user provides in the function. 
    ; you also have to provide the length of the buffer (it's reccomended to place `len(buffer)` into that field if possible)
    ; it's not recommended to be used with string literals or temporary buffers, that are often used by your program.
    ; In most cases, it's more reccomended to use human.change_name() instead
    sub assign_name(uword self, uword nameptr, ubyte namelen){
        self[name]=lsb(nameptr)
        self[name+1]=msb(nameptr)
        self[name+2]=namelen
    }

    ;similar to human.change_name()
    sub change_last_name(uword self, str new_last_name, bool new_buf){
        if string.length(new_last_name)>self[last_name+2]{
            if new_buf{
                tempresult=palloc.alloc(string.length(new_last_name)+1)
                if tempresult!=0{
                    string.copy(new_last_name, tempresult)
                    palloc.free(get_last_name(self))
                    self[last_name]=lsb(tempresult)
                    self[last_name+1]=msb(tempresult)
                    self[last_name+2]=string.length(new_last_name)
                }else if get_last_name(self)!=0{
                    void string.copy(new_last_name,tempstr)
                    tempstr[self[last_name+2]]=0
                    tempstr[self[last_name+2]-1]='_'
                    void string.copy(tempstr,get_last_name(self))
                }

            }else if get_last_name(self)!=0{
                void string.copy(new_last_name,tempstr)
                tempstr[self[last_name+2]]=0
                tempstr[self[last_name+2]-1]='_'
                void string.copy(tempstr,get_last_name(self))
            }
        }
        else{
            void string.copy(new_last_name, get_last_name(self))
        }
    }

    ; similar to human.assign_name()
    ; In most cases, it's more reccomended to use human.change_last_name() instead
    sub assign_last_name(uword self, uword last_nameptr, ubyte last_namelen){
        self[last_name]=lsb(last_nameptr)
        self[last_name+1]=msb(last_nameptr)
        self[last_name+2]=last_namelen
    }

    ;similar to human.change_name()
    sub choose_job(uword self, str new_job, bool new_buf){
        @(self+status)|=human.flags.employed
        if string.length(new_job)>self[job+2]{
            if new_buf{
                tempresult=palloc.alloc(string.length(new_job)+1)
                if tempresult!=0{
                    string.copy(new_job, tempresult)
                    palloc.free(get_job_name(self))
                    self[job]=lsb(tempresult)
                    self[job+1]=msb(tempresult)
                    self[job+2]=string.length(new_job)
                }else if get_job_name(self)!=0{
                    void string.copy(new_job,tempstr)
                    tempstr[self[job+2]]=0
                    tempstr[self[job+2]-1]='_'
                    void string.copy(tempstr,get_job_name(self))
                }

            }else if get_job_name(self)!=0{
                void string.copy(new_job,tempstr)
                tempstr[self[job+2]]=0
                tempstr[self[job+2]-1]='_'
                void string.copy(tempstr,get_job_name(self))
            }
        }
        else{
            void string.copy(new_job, get_job_name(self))
        }
    }

    ; similar to human.assign_name()
    ; In most cases, it's more reccomended to use human.choose_job() instead
    sub assign_job(uword self, uword jobptr, ubyte joblen){
        @(self+status)|=human.flags.employed
        self[job]=lsb(jobptr)
        self[job+1]=msb(jobptr)
        self[job+2]=joblen
    }
    sub lose_job(uword self, bool keepname){
        @(self+status)&=~human.flags.employed
        if not keepname{
            palloc.free(get_job_name(self))
            @(get_job_name(self))=0
        }
    }

    ;subroutines below are simple utility routines for managing human.status atribute, so that user doesn't need to use those inconvienient bitwise operators
    
    ;checks fo specific flag's value
    sub is(uword self, ubyte flag)->bool{
        return self[status]&flag!=0
    }

    ;sets chosen flag(s) to true
    sub set_statflag(uword self, ubyte flag){
        flag&=~human.flags.married
        @(self+status)|=flag
    }

    ;sets chosen flag(s) to false
    sub clear_statflag(uword self, ubyte flag){
        flag&=~human.flags.married
        @(self+status)&=~flag
    }
    ;get_gender() ; decided to ditch the concept of gender, because it's kind of a controversial topic (on both sides of the political specrtum) in the 21st century...

    sub print(uword self){
        txt.print("\rname: ")
        txt.print(get_name(self))
        txt.print("\rlast name: ")
        txt.print(get_last_name(self))
        txt.print("\rage: ")
        txt.print_ub(self[age])
        txt.print("\rmarried: ")
        if is(self, human.flags.married){
            txt.print("yes")
            txt.print("\rpartner's name: ")
            txt.print(get_name(get_partner(self)))
        }else{
            txt.print("no")
        }
        txt.print("\remployed: ")
        if is(self, human.flags.employed){
            txt.print("yes")
            txt.print("\rjob: ")
            txt.print(get_job_name(self))
        }else{
            txt.print("no")
        }
        txt.print("\rdead: ")
        if is(self, human.flags.dead){
            txt.print("yes")
        }
        else{
            txt.print("no")
        }
        txt.chrout('\r')
    }

    ubyte[96] tempstr
    uword tempuword
    uword tempresult
}