
JavaScript("public var $L={\z
            unique:0x10000001,env:{},\z
            strcoll:new Intl.Collator().compare,\z
            co:{stack:[]},\z
            chunk:function(f){f().next()},\z
            func:function(f,e,fl,ln){[f.self,f.env,f.file,f.line]=[f,e,fl,ln];return f}\z
            }")

--
-- call(name,func,args...)
--

JavaScript("$L.call=$1", function(name, func, ...)
    -- if last element of args is an array, merge it into the end of the args array.
    -- and if it is an empty array, then just discard the last element of args.
    JavaScript("var n=$1.length-1,r=$1[n]", ...)
    JavaScript("if(typeof r==='object'){")
    JavaScript("var j=r.length")
    JavaScript("if(j>0){for(var i=0;i<j;i++)$1[n+i]=r[i]}", ...)
    JavaScript("else if(j===0)$1.pop()}", ...)
    -- determine the target function
    JavaScript("if(!$1||!$1.self)$1=yield*$L.resolve($1,$2)", func, name)
    -- invoke the function.  note that using f.apply(undefined,a) is faster than f(...a)
    JavaScript("if(!$3)return(yield*$1.apply(undefined,$2))||[]", func, ..., name)
    -- if debug mode, create a stack frame then invoke the function
    JavaScript("$L.co.stack.push($L.co.frame=[$1.line,$1.file,$2,$1])", func, name)
    JavaScript("r=yield*$1.apply(undefined,$2)", func, ...)
    JavaScript("$L.co.stack.pop()")
    JavaScript("$L.co.frame=undefined")
    JavaScript("return r||[]")
end)

--
-- resolve(func,name)
--

JavaScript("$L.resolve=$1", function(func, name)
    JavaScript("if(typeof $1!=='function'){", func)
                -- check metatable if $L.call was invoked for a non-function.
    JavaScript(     "var f0=$1", func)
    JavaScript(     "$1=yield*$L.gmt($1,undefined,'resolve')", func)
    JavaScript(     "$1=$1&&$1.hash.get('__call')", func)
    JavaScript(     "if(typeof $1!=='function'){", func)
    JavaScript(         "if(typeof $1==='string'&&$1.charAt(0)!=='?')yield*$L.error('attempt to call '+(yield*$L.demangle($1))+' (a '+(yield*$L.type(f0))+' value)',0)", name)
    JavaScript(         "else yield*$L.error('attempt to call a '+(yield*$L.type(f0))+' value',0)}")
                -- if there was a __call metamethod, we need to bind a new function
                -- that pushes the object itself as the first parameter
    JavaScript(     "if($1!==f0.call1){f0.call1=$1;f0.call2=$1.bind(undefined,f0)}", func)
    JavaScript(     "$1=f0.call2", func)
    -- the following is only for completeness sake, because a function declaration
    -- in $L.func already sets the self field to itself
    JavaScript("}else $1.self=$1", func)
    JavaScript("return $1", func)
end)

--
-- error(message)
--

JavaScript("$L.error=$1", function(msg, lvl)
    JavaScript("var msg,lvl=($1===undefined?1:$1)", lvl)
    JavaScript("var stklen=$L.co.stack.length")
    JavaScript("if((typeof $1==='string'||typeof $1==='number')&&lvl>=0&&lvl<stklen){", msg)
    JavaScript(     "msg=$L.co.stack[stklen-lvl-1]")
    JavaScript(     "msg=msg[1]+':'+msg[0]+': '+$1}", msg)
    JavaScript("else msg=$1", msg)
    JavaScript("throw msg")
end)

--
-- traceback
--

JavaScript("$L.traceback=$1", function(msg, lvl)
    JavaScript("var msg,lvl=($1===undefined?1:$1)", lvl)
    JavaScript("if($1===undefined)msg=''", msg)
    JavaScript("else if(typeof $1!=='string')return $1", msg)
    JavaScript("else msg=$1+'\n'", msg)
    JavaScript("msg+='stack traceback:'")
    JavaScript("var stkidx=$L.co.stack.length-lvl")
    JavaScript("while(stkidx-->0){")
    JavaScript("var f=$L.co.stack[stkidx]")
    JavaScript("var w=f[2]")
    JavaScript("if(w==='?'&&typeof f[3]==='function')w='F:<'+f[3].file+':'+f[3].line+'>'")
    JavaScript("if(w.charAt(1)===':'){")                                    -- if decorated name,
    JavaScript("if(w.charAt(2)==='<')w='function '+w.substr(2)")            --   anonymous function
    JavaScript("else w=\"function '\"+w.substr(2)+\"'\"}")                  --   or normal function
    JavaScript("else if(w.substr(0,2)==='__')w=\"function '\"+w+\"'\"")     -- otherwise, metamethod
    JavaScript("msg+='\n\t'+f[1]+':'+f[0]+': in '+w}")
    JavaScript("return msg")
end)

--
-- type
--

JavaScript("$L.type=$1", function(x)
    JavaScript("if($1===undefined)return'nil'", x)
    JavaScript("var t=typeof $1", x)
    JavaScript("if(t==='object'&&$1.luatable)return'table'", x)
    JavaScript("if(t==='object'&&$1.luacoroutine)return'thread'", x)
    JavaScript("if(t==='boolean'||t==='number'||t==='string'||t==='function')return t")
    JavaScript("yield*$L.error('unexpected type: '+t,0)")
end)

JavaScript("$L.error_for1=function*(){yield*$L.error(\"'for' initial value must be a number\",0)};")
JavaScript("$L.error_for2=function*(){yield*$L.error(\"'for' limit must be a number\",0)};")
JavaScript("$L.error_for3=function*(){yield*$L.error(\"'for' step must be a number\",0)};")

JavaScript("$L.error_nil=function*(lvl){yield*$L.error('table index is nil',lvl||0)};")
JavaScript("$L.error_nan=function*(lvl){yield*$L.error('table index is NaN',lvl||0)};")

JavaScript("$L.error_regex=function*(){yield*$L.error('regex not known')};")

JavaScript("$L.error_sort=function*(){yield*$L.error('invalid order function for sorting')};")

JavaScript("$L.error_arg=$1", function(num,msg)
    JavaScript("var w=$L.co.frame&&$L.co.frame[2].substr(2)")
    JavaScript("yield*$L.error('bad argument #'+$1+\" to '\"+w+\"' (\"+$2+')',1)", num, msg)
end)

JavaScript("$L.error_argtype=$1", function(got,num,exp)
    JavaScript("yield*$L.error_arg($2,$3+' expected, got '+(yield*$L.type($1)))", got, num, exp)
end)

JavaScript("$L.error_argexp=$1", function(num, argslen)
    JavaScript("if($2<$1)yield*$L.error_arg($1,'value expected')", num, argslen)
end)

JavaScript("$L.checkstring=$1", function(arg,num)
    -- luaL_checklstring (which uses lua_tolstring) does not use tostring or metatable; see section 5.1
    JavaScript("var ty=typeof $1", arg)
    JavaScript("if(ty==='string')return $1", arg)
    JavaScript("if(ty==='number')return $1.toString()", arg)
    JavaScript("yield*$L.error_argtype($1,$2,'string')", arg, num)
end)

JavaScript("$L.checknumber=$1", function(arg,num)
    -- luaL_checknumber (which uses lua_tointegerx) does not use tostring or metatable; see section 5.1
    JavaScript("var ty=typeof $1", arg)
    JavaScript("if(ty==='number')return $1", arg)
    JavaScript("if(ty==='string'){")
    JavaScript("var n=yield*$L.tonumber($1)", arg)
    JavaScript("if(n!==undefined)return n}")
    JavaScript("if($2!==undefined)yield*$L.error_argtype($1,$2,'number')", arg, num)
end)

JavaScript("$L.checktable=$1", function(arg,num)
    JavaScript("if(typeof $1!=='object'||!$1.luatable)yield*$L.error_argtype($1,$2,'table')", arg, num)
end)

JavaScript("$L.checkfunction=$1", function(arg,num)
    JavaScript("if(typeof $1!=='function'||\z
                   $1.prototype.toString()!=='[object Generator]')\z
                        yield*$L.error_argtype($1,$2,'function')", arg, num)
end)

JavaScript("$L.checkcoroutine=$1", function(arg,num)
    JavaScript("if(typeof $1!=='object'||!$1.luacoroutine)yield*$L.error_argtype($1,$2,'coroutine')", arg, num)
end)

JavaScript("$L.demangle=$1", function(name)
    JavaScript("if($1.charAt(1)!==':')return $1", name)
    JavaScript("var c=$1.charAt(0).toUpperCase()", name)
    JavaScript(     "if(c==='G')c='global'")
    JavaScript("else if(c==='L')c='local'")
    JavaScript("else if(c==='M')c='method'")
    JavaScript("else if(c==='I')c='field'")
    JavaScript("else if(c==='U')c='upvalue'")
    JavaScript("else if(c==='F')c='function'")
    JavaScript("else if(c==='K')c='a constant'")
    JavaScript("else return $1", name)
    JavaScript("if($1.length===2)return c", name)
    JavaScript("return c+\" '\"+$1.substr(2)+\"'\"", name)
end)

--
-- comparison
--

JavaScript("$L.error_cmp=$1", function(o1, o2)
    JavaScript("yield*$L.error('attempt to compare '+(yield*$L.type($1))+' with '+(yield*$L.type($2)),0)", o1, o2)
end)

JavaScript("$L.cmpeq=$1", function(o1, o2, dbg)
    JavaScript("if($1===$2)return true", o1, o2)
    JavaScript("if(typeof $1==='object'&&$1.luatable&&\z
                   typeof $2==='object'&&$2.luatable){", o1, o2)
    JavaScript(     "var m1=$1.metatable,m2=$2.metatable", o1, o2)
    JavaScript(     "if(m1&&m2){")
    JavaScript(         "var eq='__eq'")
    JavaScript(         "var f=m1.hash.get(eq)")
    JavaScript(         "if(f!==undefined&&(m2===m1||m2.hash.get(eq)===f)){")
    JavaScript(             "var r=(yield*$L.call($3&&('F:'+eq),f,$1,$2))[0]", o1, o2, dbg)
    JavaScript(             "if(r!==undefined&&r!==false)return true}}}", o1, o2)
    JavaScript("return false")
end)

JavaScript("$L.callcmpop=$1", function(o1, o2, t1, t2, nm, dbg)
    JavaScript("var f=yield*$L.gmt($1,$2,$3)", o1, t1, nm)
    JavaScript("f=f&&f.hash.get($1)", nm)
    JavaScript("if(f===undefined){")
    JavaScript("f=yield*$L.gmt($1,$2,$3)", o2, t2, nm)
    JavaScript("f=f&&f.hash.get($1)", nm)
    JavaScript("if(f===undefined)return}")
    JavaScript("var r=lua.call($4&&$3,f,$1,$2)[0]", o1, o2, nm, dbg)
    JavaScript("return(r!==undefined&&r!==false)?true:false")
end)

JavaScript("$L.cmplt=$1", function(o1, o2, dbg)
    JavaScript("var t1=typeof $1,t2=typeof $2", o1, o2)
    JavaScript("if(t1==='number'&&t2===t1)return $1<$2", o1, o2)
    JavaScript("if(t1==='string'&&t2===t1)return $L.strcoll($1,$2)<0", o1, o2)
    JavaScript("var r=yield*$L.callcmpop($1,$2,t1,t2,'__lt',$3)", o1, o2, dbg)
    JavaScript("if(r!==undefined)return r")
    JavaScript("yield*$L.error_cmp($1,$2)", o1, o2)
end)

JavaScript("$L.cmple=$1", function(o1, o2, dbg)
    JavaScript("var t1=typeof $1,t2=typeof $2", o1, o2)
    JavaScript("if(t1==='number'&&t2===t1)return $1<=$2", o1, o2)
    JavaScript("if(t1==='string'&&t2===t1)return $L.strcoll($1,$2)<=0", o1, o2)
    JavaScript("var r=yield*$L.callcmpop($1,$2,t1,t2,'__le',$3)", o1, o2, dbg)
    JavaScript("if(r!==undefined)return r")
    -- try to use __le when __lt is missing, per section 2.4
    JavaScript("var r=yield*$L.callcmpop($2,$1,t1,t2,'__lt',$3)", o1, o2, dbg)
    JavaScript("if(r!==undefined)return !r")
    JavaScript("yield*$L.error_cmp($1,$2)", o1, o2)
end)

--
-- arithmetic
--

JavaScript("$L.error_arith=$1", function(o)
    JavaScript("yield*$L.error('attempt to perform arithmetic on a '+(yield*$L.type($1))+' value',0)", o)
end)

JavaScript("$L.unm=$1", function(o, dbg)
    JavaScript("var t=typeof $1", o)
    JavaScript("var n=t==='number'?$1:(yield*$L.tonumber($1))", o)
    JavaScript("if(n!==undefined)return -n")
    JavaScript("var unm='__unm'")
    JavaScript("var f=yield*$L.gmt($1,t,unm)", o)
    JavaScript("f=f&&f.hash.get(unm)")
    JavaScript("if(f===undefined)yield*$L.error_arith($1)", o)
    JavaScript("return yield*$L.call($2&&('F:'+unm),f,$1)[0]", o, dbg)
end)

JavaScript("$L.arith=$1", function(o1, o2, t1, t2, n1, nm, dbg)
    JavaScript("var f=yield*$L.gmt($1,$2,$3)", o1, t1, nm)
    JavaScript("f=f&&f.hash.get($1)", nm)
    JavaScript("if(f===undefined){")
    JavaScript(     "f=yield*$L.gmt($1,$2,$3)", o2, t2, nm)
    JavaScript(     "f=f&&f.hash.get($1)", nm)
    JavaScript(     "if(f===undefined){")
    JavaScript(         "var o=$3===undefined?$1:$2", o1, o2, n1)
    JavaScript(         "yield*$L.error_arith(o)}}")
    JavaScript("return (yield*$L.call($4&&('F:'+$3),f,$1,$2))[0]", o1, o2, nm, dbg)
end)

JavaScript("$L.add=$1", function(o1, o2, dbg)
    JavaScript("var t1=typeof $1,t2=typeof $2", o1, o2)
    JavaScript("var n1=t1==='number'?$1:(yield*$L.tonumber($1))", o1)
    JavaScript("var n2=t2==='number'?$1:(yield*$L.tonumber($1))", o2)
    JavaScript("if(n1!==undefined&&n2!==undefined)return n1+n2")
    JavaScript("return yield*$L.arith($1,$2,t1,t2,n1,'__add',$3)", o1, o2, dbg)
end)

JavaScript("$L.sub=$1", function(o1, o2, dbg)
    JavaScript("var t1=typeof $1,t2=typeof $2", o1, o2)
    JavaScript("var n1=t1==='number'?$1:(yield*$L.tonumber($1))", o1)
    JavaScript("var n2=t2==='number'?$1:(yield*$L.tonumber($1))", o2)
    JavaScript("if(n1!==undefined&&n2!==undefined)return n1-n2")
    JavaScript("return yield*$L.arith($1,$2,t1,t2,n1,'__sub',$3)", o1, o2, dbg)
end)

JavaScript("$L.mul=$1", function(o1, o2, dbg)
    JavaScript("var t1=typeof $1,t2=typeof $2", o1, o2)
    JavaScript("var n1=t1==='number'?$1:(yield*$L.tonumber($1))", o1)
    JavaScript("var n2=t2==='number'?$1:(yield*$L.tonumber($1))", o2)
    JavaScript("if(n1!==undefined&&n2!==undefined)return n1*n2")
    JavaScript("return yield*$L.arith($1,$2,t1,t2,n1,'__mul',$3)", o1, o2, dbg)
end)

JavaScript("$L.div=$1", function(o1, o2, dbg)
    JavaScript("var t1=typeof $1,t2=typeof $2", o1, o2)
    JavaScript("var n1=t1==='number'?$1:(yield*$L.tonumber($1))", o1)
    JavaScript("var n2=t2==='number'?$1:(yield*$L.tonumber($1))", o2)
    JavaScript("if(n1!==undefined&&n2!==undefined)return n1/n2")
    JavaScript("return yield*$L.arith($1,$2,t1,t2,n1,'__div',$3)", o1, o2, dbg)
end)

JavaScript("$L.mod=$1", function(o1, o2, dbg)
    JavaScript("var t1=typeof $1,t2=typeof $2", o1, o2)
    JavaScript("var n1=t1==='number'?$1:(yield*$L.tonumber($1))", o1)
    JavaScript("var n2=t2==='number'?$1:(yield*$L.tonumber($1))", o2)
    JavaScript("if(n1!==undefined&&n2!==undefined)return n1-Math.floor(n1/n2)*n2")
    JavaScript("return yield*$L.arith($1,$2,t1,t2,n1,'__mod',$3)", o1, o2, dbg)
end)

JavaScript("$L.pow=$1", function(o1, o2, dbg)
    JavaScript("var t1=typeof $1,t2=typeof $2", o1, o2)
    JavaScript("var n1=t1==='number'?$1:(yield*$L.tonumber($1))", o1)
    JavaScript("var n2=t2==='number'?$1:(yield*$L.tonumber($1))", o2)
    JavaScript("if(n1!==undefined&&n2!==undefined)return Math.pow(n1,n2)")
    JavaScript("return yield*$L.arith($1,$2,t1,t2,n1,'__pow',$3)", o1, o2, dbg)
end)

--
-- concatenation
--

JavaScript("$L.concat=$1", function(o1, o2, dbg)
    JavaScript("var t1=typeof $1,t2=typeof $2", o1, o2)
    JavaScript("if((t1==='number'||t1==='string')&&(t2==='number'||t2==='string'))return $1+''+$2", o1, o2)
    JavaScript("var concat='__concat'")
    JavaScript("var f=yield*$L.gmt($1,t1,concat)", o1)
    JavaScript("f=f&&f.hash.get(concat)", nm)
    JavaScript("if(f===undefined){")
    JavaScript(     "f=yield*$L.gmt($1,t2,concat)", o2)
    JavaScript(     "f=f&&f.hash.get(concat)", nm)
    JavaScript(     "if(f===undefined){")
    JavaScript(         "var o=t1==='number'||t1==='string'?$2:$1", o1, o2)
    JavaScript(         "yield*$L.error('attempt to concatenate a '+(yield*$L.type(o))+' value',0)}}")
    JavaScript("return(yield*$L.call($3&&('F:'+concat),f,$1,$2))[0]", o1, o2, dbg)
end)

--
-- length
--

JavaScript("$L.len=$1", function(o, dbg)
    JavaScript("var t=typeof $1", o)
    JavaScript("if(t==='string')return $1.length", o)
    JavaScript("var len='__len'")
    JavaScript("var f=yield*$L.gmt($1,t,len)", o)
    JavaScript("f=f&&f.hash.get(len)")
    JavaScript("if(f===undefined){")
    JavaScript("if(t!=='object'||!$1.luatable)yield*$L.error('attempt to get length of a '+(yield*$L.type($1))+' value',0)", o)
    JavaScript("var a=$1.array", o)
    JavaScript("var n=a.length")
    JavaScript("while(0<--n){if(a[n]!==undefined)return n}")
    JavaScript("return 0}")
    JavaScript("return (yield*$L.call($2&&('F:'+len),f,$1))[0]", o, dbg)
end)

--
-- table
--

JavaScript("$L.table=$1", function(a,n1,n2)
    -- named elements are intentionally initialized first,
    -- this matches the behavior of the official implementation
    JavaScript("var i,k,v")
    JavaScript("var t={luatable:true,array:[],hash:new Map()};")
    JavaScript("if($1){\z
                    for(i=0;i<$2;){\z
                        k=$1[i++];\z
                        v=$1[i++];\z
                        if(typeof k==='number'){\z
                            if(k!==k)yield*$L.error_nan();\z
                            t.array[k]=v\z
                        }else{\z
                            if(k===undefined)yield*$L.error_nil();\z
                            t.hash.set(k,v)\z
                        }\z
                    }\z
                    for(k=0;k<$3;){t.array[++k]=$1[i++]}\z
                    if(typeof (v=t.array[k])==='object'){\z
                        if(($3=v.length)>0){for(i=0;i<$3;i++)t.array[k+i]=v[i]}\z
                        else if($3===0)t.array.pop()}\z
                }", a, n1, n2)
    JavaScript("return t")
end)

--
-- table get/set
--

JavaScript("$L.error_index=$1", function(o, n)
    JavaScript("if($2)yield*$L.error('attempt to index '+(yield*$L.demangle($2))+' (a '+(yield*$L.type($1))+' value)',0)", o, n)
    JavaScript( "else yield*$L.error('attempt to index a '+(yield*$L.type($1))+' value',0)", o)
end)

JavaScript("$L.get=$1", function(t, k, n)
    JavaScript("var v,t=typeof $1,index='__index'", t)
    JavaScript("if(t==='object'&&$1.luatable){", t)
    JavaScript(     "v=typeof $2==='number'?$1.array[$2]:$1.hash.get($2)", t, k)
    JavaScript(     "if(v!==undefined)return v")
    JavaScript(     "v=$1.metatable&&$1.metatable.hash.get(index)", t)
    JavaScript(     "if(v===undefined)return v}")
    JavaScript("else{")
    JavaScript(     "v=yield*$L.gmt($1,t,'get')", t)
    JavaScript(     "v=v&&v.hash.get(index)")
    JavaScript(     "if(v===undefined)yield*$L.error_index($1,$2)}", t, n)
    JavaScript("if(typeof v!=='function')return yield*$L.get(v,$1,$2)", k, n)
    JavaScript("return(yield*$L.call($3&&('F:'+index),v,$1,$2))[0]", t, k, n)
end)

JavaScript("$L.set=$1", function(t, k, n, v)
    JavaScript("var v,t=typeof $1,newindex='__newindex'", t)
    JavaScript("if(t==='object'&&$1.luatable){", t)
    JavaScript(     "if(typeof $1==='number'){", k)
    JavaScript(         "if($1.array[$2]!==undefined){$1.array[$2]=$3;return}", t, k, v)
    JavaScript(         "v=$1.metatable&&$1.metatable.hash.get(newindex)", t)
    JavaScript(         "if(v===undefined){")
    JavaScript(             "if($1!==$1)yield*$L.error_nan()", k)
    JavaScript(             "$1.array[$2]=$3", t, k, v)
    JavaScript(             "return}}")
    JavaScript(     "else{")
    JavaScript(         "if($1.hash.get($2)!==undefined){$1.hash.set($2,$3);return}", t, k, v)
    JavaScript(         "v=$1.metatable&&$1.metatable.hash.get(newindex)", t)
    JavaScript(         "if(v===undefined){")
    JavaScript(             "if($1===undefined)yield*$L.error_nil()", k)
    JavaScript(             "$1.hash.set($2,$3)", t, k, v)
    JavaScript(             "return}}}")
    JavaScript("else{")
    JavaScript(     "v=yield*$L.gmt($1,t,'set')", t)
    JavaScript(     "v=v&&v.hash.get(newindex)")
    JavaScript(     "if(v===undefined)yield*$L.error_index($1,$2)}", t, n)
    JavaScript("if(typeof v!=='function')yield*$L.set(v,$1,$2,$3)", k, n, v)
    JavaScript("else yield*$L.call($3&&('F:'+newindex),v,$1,$2,$4)", t, k, n, v)
end)

--
-- global environment
--
-- note that a property 'env' was already defined at the top of this module
-- as an empty object, and references to it were copied into all functions
-- in this module by the $L.func() mechanism.
--

JavaScript("Object.assign($L.env,yield*$L.table())")
JavaScript("$L.env.hash.set('_VERSION','Lua 5.2')")
_G=_ENV

--
-- metatable
--

JavaScript("$L.vmt=[]") -- metatables for value types: nil, boolean, number, string, function, thread

JavaScript("$L.gmt=$1", function(val, typ, who)
    JavaScript("var i=0")
    JavaScript("if($1!==undefined){", val)
    JavaScript(     "var t=$2||typeof $1", val, typ)
    JavaScript(     "if(t==='object'&&$1.luatable)return $1.metatable", val)
    JavaScript(     "if(t==='object'&&$1.luacoroutine)i=5", val)
    JavaScript(     "else if(t==='function')i=4")
    JavaScript(     "else if(t==='string')i=3")
    JavaScript(     "else if(t==='number')i=2")
    JavaScript(     "else if(t==='boolean')i=1")
    JavaScript(     "else yield*$L.error('unexpected type in getmetatable-'+$1,0)", who)
    JavaScript("}")
    JavaScript("return $L.vmt[i]")
end)

JavaScript("$L.smt=$1", function(val, mt)
    JavaScript("var i=0")
    JavaScript("if($1!==undefined){", val)
    JavaScript(     "var t=typeof $1", val)
    JavaScript(     "if(t==='object'&&$1.luatable){$1.metatable=$2;return}", val, mt)
    JavaScript(     "if(t==='object'&&$1.luacoroutine)i=5", val)
    JavaScript(     "else if(t==='function')i=4")
    JavaScript(     "else if(t==='string')i=3")
    JavaScript(     "else if(t==='number')i=2")
    JavaScript(     "else if(t==='boolean')i=1")
    JavaScript(     "else yield*$L.error('unexpected type in setmetatable',0)")
    JavaScript("}")
    JavaScript("$L.vmt[i]=$1", mt)
end)

getmetatable = function(...)    -- function(t)
    local t = ...
    local mt
    JavaScript("yield*$L.error_argexp(1,$1.length)", ...)
    JavaScript("$2=yield*$L.gmt($1,undefined,'normal')", t, mt)
    JavaScript("if($1){", mt)
    JavaScript("var x=$1.hash.get('__metatable')", mt)
    JavaScript("if(x)$1=x", mt)
    JavaScript("}")
    return mt
end

setmetatable = function(...)    -- function(t,mt)
    local t, mt = ...
    JavaScript("yield*$L.checktable($1,1)", t)
    JavaScript("if($2.length<2||($1!==undefined&&(typeof $1!=='object'||!$1.luatable)))yield*$L.error_arg(2,'nil or table expected')", mt, ...)
    JavaScript("if($1.metatable&&$1.metatable.hash.get('__metatable'))yield*$L.error('cannot change a protected metatable')", t)
    JavaScript("$1.metatable=$2", t, mt)
    return t
end

--
-- tonumber
--

JavaScript("$L.tonumber_re10=new RegExp('^\\s*([+-]?[0-9]*[.]?[0-9]*[eE]?[+-]?[0-9]+)\\s*$$')")
JavaScript("$L.tonumber_re16=new RegExp('^\\s*([+-]?)0x([0-9a-fA-F]*)[.]?([0-9a-fA-F]*)([pP]([+-]?[0-9]+))?\\s*$$')")
JavaScript("$L.tonumber_reint=new RegExp('^\\s*([+-]?)([0-9a-zA-Z]+)\\s*$$')")

JavaScript("$L.tonumber=$1", function(str)
    JavaScript("var r=$L.tonumber_re10.exec($1)", str)
    JavaScript("if(r){r=parseFloat(r[1]);return r===r?r:undefined}")
    JavaScript("r=$L.tonumber_re16.exec($1)", str)
    JavaScript("if(!r)return undefined")
    JavaScript("if(!r[3])r[3]=''")
    JavaScript("var m=parseInt(r[1]+r[2]+r[3],16)")
    JavaScript("if(m!==m)return undefined")
    JavaScript("var e=(r[5]|0)-4*r[3].length")
    JavaScript("return m*Math.pow(2,e)")
end)

tonumber = function(s,b)
    if not b then
        JavaScript("if(typeof $1!=='number')$1=yield*$L.tonumber($1)", s)
        return s
    end
    JavaScript("$1=yield*$L.checkstring($1,1)", s)
    JavaScript("$1=(yield*$L.checknumber($1,2))|0", b)
    JavaScript("if($1<2||$1>36)yield*$L.error_arg(2,'base out of range')", b)
    JavaScript("var r=$L.tonumber_reint.exec($1)", s)
    -- we don't use parseInt here because it is not useful,
    -- for example it accepts prefix 0x even with explicit radix 16
    JavaScript("if(!r)return undefined")
    local num=0
    JavaScript("var s=r[2],n=r[2].length")
    JavaScript("for(var i=0;i<n;i++){")
    JavaScript("var c=s.charCodeAt(i)")
    JavaScript("if(c>=97)c=c-97+10")            -- lowercase
    JavaScript("else if(c>=65)c=c-65+10")       -- uppercase
    JavaScript("else if(c>=48)c=c-48")          -- digits
    JavaScript("else return undefined")         -- invalid, but should not happen
    JavaScript("if(c>=$1)return undefined", b)  -- digit not valid for base
    JavaScript("$2=$2*$1+c}", b, num)
    JavaScript("if(r[1]=='-')$1=-$1", num)
    return num

end

--
-- tostring
--

JavaScript("$L.tostring=$1", function(o, dbg)
    JavaScript("var t=typeof $1,tostring='__tostring'", o)
    JavaScript("var f=yield*$L.gmt($1,t,tostring)", o)
    JavaScript("f=f&&f.hash.get(tostring)")
    JavaScript("if(f!==undefined){")
    JavaScript("$1=(yield*$L.call($2&&('F:'+tostring),f,$1))[0]", o, dbg)
    JavaScript("return typeof $1==='number'?$1+'':$1}", o)
    JavaScript("if($1===undefined)return'nil'", o)
    JavaScript("if(t==='boolean'||t==='number')return $1+''", o)
    JavaScript("if(t==='string')return $1", o)
    JavaScript("if(t==='object'&&$1.luatable)t='table'", o)
    JavaScript("if(t==='object'&&$1.luacoroutine)t='thread'", o)
    JavaScript("if(t==='function'||t==='table'||t==='thread'){")
    JavaScript("if(!$1.id)$1.id=($L.unique++).toString(16)", o)
    JavaScript("return t+': '+$1.id}", o)
    JavaScript("yield*$L.error('unexpected type: '+t)")
end)

tostring = function(...)    -- function(v)
    local v = ...
    JavaScript("yield*$L.error_argexp(1,$1.length)", ...)
    JavaScript("return[yield*$L.tostring($1,typeof $$frame==='object')]", v)
end

--
-- raw access functions
--

rawget = function(...)      -- function(t, k)
    local t, k = ...
    JavaScript("yield*$L.checktable($1,1)", t)
    JavaScript("yield*$L.error_argexp(2,$1.length)", ...)
    JavaScript("return[typeof $2==='number'?$1.array[$2]:$1.hash.get($2)]", t, k)
end

rawset = function(...)      -- function(t, k, v)
    local t, k, v = ...
    JavaScript("yield*$L.checktable($1,1)", t)
    JavaScript("yield*$L.error_argexp(2,$1.length)", ...)
    JavaScript("yield*$L.error_argexp(3,$1.length)", ...)
    JavaScript("if(typeof $1==='number'){", k)
    JavaScript(     "if($1!==$1)yield*$L.error_nan(1)", k)
    JavaScript(     "$1.array[$2]=$3}", t, k, v)
    JavaScript("else{")
    JavaScript(     "if($1===undefined)yield*$L.error_nil(1)", k)
    JavaScript(     "$1.hash.set($2,$3)}", t, k, v)
    JavaScript("return[$1]", t)
end

rawequal = function(...)        -- function(a, b)
    local a, b = ...
    JavaScript("yield*$L.error_argexp(1,$1.length)", ...)
    JavaScript("yield*$L.error_argexp(2,$1.length)", ...)
    JavaScript("return[$1===$2]", a, b)
end

rawlen = function(o)
    ::update_stack_frame::
    JavaScript("var t=typeof $1", o)
    JavaScript("if(t==='string')return $1.length", o)
    JavaScript("if(t!=='object'||!$1.luatable)yield*$L.error_arg(1,'table or string expected')", o)
    JavaScript("var a=$1.array", o)
    JavaScript("var n=a.length")
    JavaScript("while(0<--n){if(a[n]!==undefined)return n}")
    JavaScript("return 0")
end

--
-- error
--

error = function(msg, lvl)
    ::update_stack_frame::
    JavaScript("if($1!==undefined)$1=(yield*$L.checknumber($1,2))|0", lvl)
    JavaScript("if($1===0)$1=-1", lvl)
    JavaScript("yield*$L.error($1,$2)", msg, lvl)
end

--
-- assert
--

assert = function(...)
    local v, msg = ...
    if not v then JavaScript("yield*$L.error($1,1)", msg or 'assertion failed!') end
    return ...
end

--
-- type
--

type = function(...)        -- function(v)
    local v = ...
    JavaScript("yield*$L.error_argexp(1,$1.length)", ...)
    JavaScript("return[yield*$L.type($1)]", v)
end

--
-- print
-- note: print uses tostring() from _G, while string.format should call $L.tostring
--

print = function(...)
    local tos = tostring
    local str = ""
    JavaScript("for(var i=0;i<$1.length;i++){", ...)
    JavaScript(     "var s=yield*$L.call('G:tostring',$1,$2[i])", tos, ...)
    JavaScript(     "if(typeof s!=='object')yield*$L.error(\"'tostring' must return a string to 'print'\")")
    JavaScript(     "else $1+=(i>0?'\t':'')+s[0]}", str)
    local printwriter = printwriter
    JavaScript("if(typeof $2==='function')yield*($2)($1)", str, printwriter)
    JavaScript("else console.log($1)", str)
end

--
-- next
--

JavaScript("$L.next=$1", function(t, k)
    JavaScript("var it,nx")

    -- case #1, if k is nil, restart iterating from the top of the array part
    JavaScript("if($1===undefined){", k)
    JavaScript(     "it=$1.array.entries()", t)
    JavaScript(     "$1.iter=[it,true]}", t)    -- [iterator,is_array_part,curr_key]

    -- case #2, k equals the curr_key, so we have nothing further to do
    JavaScript("else if($1.iter&&$2===$1.iter[2])it=$1.iter[0]", t, k)

    -- case #3, if k is not nil, but not same as current iterator (or no iterator),
    -- then create a new iterator to search for k, and if we find k, use the rest of
    -- that iterator as if we created it in case #1
    JavaScript("else{")
    JavaScript(     "if(typeof $1==='number'){", k)
    JavaScript(         "it=$1.array.entries()", t)
    JavaScript(         "$1.iter=[it,true]}", t)
    JavaScript(     "else{")
    JavaScript(         "it=$1.hash.entries()", t)
    JavaScript(         "$1.iter=[it,false]}", t)
    JavaScript(     "do{")
    JavaScript(         "nx=it.next()")
    JavaScript(         "if(nx.done){")
    JavaScript(             "$1.iter=undefined", t)
    JavaScript(             "yield*$L.error(\"invalid key to 'next'\")}")
    JavaScript(     "}while($1!==nx.value[0])}", k)

    -- all cases reach here, with the purpose of advancing to the next key.
    -- if the array part is finished, switch to the hash part.
    -- if the next key or value is nil, do another iteration of the main loop.
    JavaScript("while(1){")
    JavaScript(     "nx=it.next()")
    JavaScript(     "if(nx.done){")
    JavaScript(         "if($1.iter[1]){", t)
    JavaScript(             "it=$1.hash.entries()", t)
    JavaScript(             "$1.iter=[it,false]", t)
    JavaScript(             "nx=it.next()}")
    JavaScript(         "if(nx.done){")
    JavaScript(             "$1.iter=undefined", t)
    JavaScript(             "return[]}}")
    JavaScript(     "nx=nx.value")
    JavaScript(     "if(nx[0]!==undefined&&nx[1]!==undefined){")
    JavaScript(         "$1.iter[2]=nx[0]", t)
    JavaScript(         "return nx}}")
end)

next = function(t, k)
    ::update_stack_frame::
    JavaScript("yield*$L.checktable($1,1)", t)
    JavaScript("return yield*$L.next($1,$2)", t, k)
end

--
-- pairs
--

JavaScript("$L.xpairs=$1", function(t, i)
    JavaScript("var p=$1+'pairs'", i)
    JavaScript("var f=yield*$L.gmt($1,undefined,p)", t)
    JavaScript("f=f&&f.hash.get('__'+p)")
    JavaScript("if(f!==undefined)return yield*$L.call('?'+p,f,$1)", t)
    JavaScript("yield*$L.checktable($1,1)", t)
end)

pairs = function(t)
    ::update_stack_frame::
    JavaScript("var r=yield*$L.xpairs($1,'')", t)
    -- to prevent multiple concurrent loops from competing for the same iterator
    -- (see $L.next and case #3), we create a temporary table object, which
    -- shares the array and hash with the original table, but has its own iterator.
    JavaScript("if(r===undefined)r=[$L.next,{luatable:true,array:$1.array,hash:$1.hash}]", t)
    JavaScript("return r")
end

--
-- ipairs
--

JavaScript("$L.inext=$1", function(t, k)
    JavaScript("var k=$1+1", k)
    JavaScript("var v=$1.array[k]", t)
    JavaScript("return(v===undefined?[]:[k,v])")
end)

ipairs = function(t)
    ::update_stack_frame::
    JavaScript("var r=yield*$L.xpairs($1,'i')", t)
    JavaScript("if(r===undefined)r=[$L.inext,$1,0]", t)
    JavaScript("return r")
end

--
-- select
--

select = function(idx, ...)
    ::update_stack_frame::
    JavaScript("var n=$1.length", ...)
    JavaScript("if($1==='#')return[n]", idx)
    JavaScript("var i=yield*$L.checknumber($1,1)", idx)
    JavaScript("if(i<0){i+=n+1;if(i<0)yield*$L.error_arg(1,'index out of range')}")
    JavaScript("if(i<=n)return $1.slice(i-1)", ...)
end

--
-- pcall(func,args)
-- xpcall(func,msgh,args)
--

JavaScript("$L.xpcall=$1", function(msgh, func, args)
    JavaScript("$L.co.protected=($L.co.protected||0)+1")
    JavaScript("var r")
    JavaScript("var stklen=$L.co.stack.length")
    JavaScript("try{")
    JavaScript(     "r=yield*$L.call('?xpcall',$1,$2)", func, args)
    JavaScript(     "r.unshift(true)}")
    JavaScript("catch(x){")
    JavaScript(     "if(typeof x==='object'&&typeof x.stack==='string'&&typeof x.message==='string'){console.error(x);x='JS '+x.message}")
    JavaScript(     "r='error in error handling'")
    JavaScript(     "if(typeof $1==='function'&&$L.co.protected<200){", msgh)
    JavaScript(         "var t=yield*$L.xpcall($1,$1,x)", msgh)
    JavaScript(         "if(t[0])r=t[1]}")
    JavaScript(     "r=[false,r]")
    JavaScript(     "while($L.co.stack.length>stklen)$L.co.stack.pop()}")
    JavaScript("$L.protected--")
    JavaScript("return r")
end)

JavaScript("$L.dflt_msgh=function*(x){return[x]};")

pcall = function(func, ...)
    ::update_stack_frame::
    JavaScript("return yield*$L.xpcall($L.dflt_msgh,$1,$2)", func, ...)
end

xpcall = function(func, msgh, ...)
    ::update_stack_frame::
    JavaScript("return yield*$L.xpcall($1,$2,$3)", msgh, func, ...)
end

--
-- load
--

load = function(func, source, mode, env)
    ::update_stack_frame::
    JavaScript("yield*$L.checkfunction($1,1)", func)
    JavaScript("yield*$L.checktable($1,4)", env)
    JavaScript("var src=$1.toString()", func)
    JavaScript("var idx=src.indexOf('(')")
    JavaScript("src=\"'use strict';return function*func\"+src.substring(idx)")
    JavaScript("var f=Function(src)()")
    JavaScript("[f.self,f.env,f.file,f.line]=[f,$2,$1.file,$1.line]", func, env)
    JavaScript("return[f]")
end

--
-- debug library
--

debug = {

    getmetatable = function(...)    -- function(t)
        local t = ...
        local mt
        JavaScript("yield*$L.error_argexp(1,$1.length)", ...)
        JavaScript("$2=yield*$L.gmt($1,undefined,'debug')", t, mt)
        return mt
    end,

    setmetatable = function(...)    -- function(t, mt)
        local t, mt = ...
        JavaScript("if($2.length<2||($1!==undefined&&(typeof $1!=='object'||!$1.luatable)))yield*$L.error_arg(2,'nil or table expected')", mt, ...)
        JavaScript("yield*$L.smt($1,$2)", t, mt)
        return t
    end,

    traceback = function(msg, lvl)
        ::update_stack_frame::
        JavaScript("if($1!==undefined)$1=yield*$L.checknumber($1,2)", lvl)
        JavaScript("return[yield*$L.traceback($1,$2)]", msg, lvl)
    end,

}

--
-- math library
--

JavaScript("$L.rngseed=1")
JavaScript("$L.pi180=Math.PI/180")

math = {

    abs = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.abs(yield*$L.checknumber($1,1))]", x)
    end,

    ceil = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.ceil(yield*$L.checknumber($1,1))]", x)
    end,

    floor = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.floor(yield*$L.checknumber($1,1))]", x)
    end,

    fmod = function(x, y)
        ::update_stack_frame::
        JavaScript("$1=yield*$L.checknumber($1,1)", x)
        JavaScript("$1=yield*$L.checknumber($1,2)", y)
        JavaScript("if(!isFinite($1)||isNaN($2)||$2===0)return[NaN]", x, y)
        JavaScript("if($1===0||!isFinite($2))return[$1]", x, y)
        JavaScript("var r=Math.abs($1)%Math.abs($2)", x, y)
        JavaScript("if(Math.sign($1)<0)r=-r", x)
        JavaScript("return[r]")
    end,

    modf = function(x)
        ::update_stack_frame::
        JavaScript("var i=Math.trunc(yield*$L.checknumber($1,1))", x)
        JavaScript("return[i,$1-i]", x)
    end,

    pow = function(b, e)
        ::update_stack_frame::
        JavaScript("return[Math.pow(yield*$L.checknumber($1,1),yield*$L.checknumber($2,2))]", b, e)
    end,

    sqrt = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.sqrt(yield*$L.checknumber($1,1))]", x)
    end,

    log = function(x, b)
        ::update_stack_frame::
        JavaScript("$1=yield*$L.checknumber($1,1)", x)
        JavaScript("if($2===undefined)return[Math.log($1)]", x, b)
        JavaScript("$1=yield*$L.checknumber($1,2)", b)
        JavaScript("if($2===10)return[Math.log10($1)]", x, b)
        JavaScript("if($2===2)return[Math.log2($1)]", x, b)
        JavaScript("return[Math.log($1)/Math.log($2)]", x, b)
    end,

    log10 = function(x) return log(x, 10) end,

    exp = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.exp(yield*$L.checknumber($1,1))]", x)
    end,

    frexp = function(x)
        -- http://yourjs.com/snippets/92
        ::update_stack_frame::
        JavaScript("var s,x=yield*$L.checknumber($1,1)", x)
        JavaScript("if(!isFinite(x)||x===0)return[x,0]")
        JavaScript("var s=x<0?-1:1")
        JavaScript("var e=Math.floor(1+Math.log(x*s)/Math.LN2)")
        JavaScript("var m=s*x/Math.pow(2,e)")
        JavaScript("return[m,e]")
    end,

    ldexp = function(m, e)
        ::update_stack_frame::
        JavaScript("$1=yield*$L.checknumber($1,1)", m)
        JavaScript("$1=(yield*$L.checknumber($1,2))|0", e)
        JavaScript("return[$1*Math.pow(2,$2)]", m, e)
    end,

    deg = function(x)
        ::update_stack_frame::
        JavaScript("return[yield*$L.checknumber($1,1)/$L.pi180]", x)
    end,

    rad = function(x)
        ::update_stack_frame::
        JavaScript("return[yield*$L.checknumber($1,1)*$L.pi180]", x)
    end,

    min = function(...)
        ::update_stack_frame::
        JavaScript("var a=[],n=$1.length,i", ...)
        JavaScript("for(i=0;i<n;++i)a[i]=yield*$L.checknumber($1[i])", ...)
        JavaScript("return[Math.min.apply(null, a)]")
    end,

    max = function(...)
        ::update_stack_frame::
        JavaScript("var a=[],n=$1.length,i", ...)
        JavaScript("for(i=0;i<n;++i)a[i]=yield*$L.checknumber($1[i])", ...)
        JavaScript("return[Math.max.apply(null, a)]")
    end,

    acos = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.acos(yield*$L.checknumber($1,1))]", x)
    end,

    acosh = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.acosh(yield*$L.checknumber($1,1))]", x)
    end,

    asin = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.asin(yield*$L.checknumber($1,1))]", x)
    end,

    asinh = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.asinh(yield*$L.checknumber($1,1))]", x)
    end,

    atan = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.atan(yield*$L.checknumber($1,1))]", x)
    end,

    atan2 = function(y, x)
        ::update_stack_frame::
        JavaScript("return[Math.atan2(yield*$L.checknumber($1,1),yield*$L.checknumber($2,2))]", y, x)
    end,

    atanh = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.atanh(yield*$L.checknumber($1,1))]", x)
    end,

    cos = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.cos(yield*$L.checknumber($1,1))]", x)
    end,

    cosh = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.cosh(yield*$L.checknumber($1,1))]", x)
    end,

    sin = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.sin(yield*$L.checknumber($1,1))]", x)
    end,

    sinh = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.sinh(yield*$L.checknumber($1,1))]", x)
    end,

    sqrt = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.sqrt(yield*$L.checknumber($1,1))]", x)
    end,

    tan = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.tan(yield*$L.checknumber($1,1))]", x)
    end,

    tanh = function(x)
        ::update_stack_frame::
        JavaScript("return[Math.tanh(yield*$L.checknumber($1,1))]", x)
    end,

    random = function(...)
        ::update_stack_frame::
        JavaScript("var n=$1.length,r=Math.sin($L.rngseed++)*10000", ...)
        JavaScript("r=r-Math.floor(r)")
        JavaScript("if(n==0)return[r]")
        JavaScript("if(n>2)yield*$L.error('wrong number of arguments')")
        JavaScript("var a=yield*$L.checknumber($1[0],1)", a)
        JavaScript("if(n==1){")
        JavaScript("if(a<1)yield*$L.error_arg(1,'interval is empty')")
        JavaScript("return[Math.floor(r*a)+1]}")
        JavaScript("var b=yield*$L.checknumber($1[1],2)", b)
        JavaScript("if(a>b)yield*$L.error_arg(2,'interval is empty')")
        JavaScript("return[Math.floor(r*(b-a+1))+a]")
    end,

    randomseed = function(seed)
        ::update_stack_frame::
        JavaScript("$L.rngseed=yield*$L.checknumber($1,1)>>>0", seed)
    end,
}

JavaScript("$1.hash.set('pi',Math.PI)", math)
JavaScript("$1.hash.set('huge',Number.POSITIVE_INFINITY)", math)

--
-- string library
--

string = {

    dump = function(f)
        ::update_stack_frame::
        JavaScript("yield*$L.checkfunction($1,1)", f)
        return f
    end,

    len = function(s)
        ::update_stack_frame::
        JavaScript("return[(yield*$L.checkstring($1,1)).length]", s)
    end,

    lower = function(s)
        ::update_stack_frame::
        JavaScript("return[(yield*$L.checkstring($1,1)).toLocaleLowerCase()]", s)
    end,

    upper = function(s)
        ::update_stack_frame::
        JavaScript("return[(yield*$L.checkstring($1,1)).toLocaleUpperCase()]", s)
    end,

    rep = function(str, num, sep)
        ::update_stack_frame::
        JavaScript("var s=yield*$L.checkstring($1,1)", str)
        JavaScript("var n=(yield*$L.checknumber($1,2))|0", num)
        JavaScript("if(n<=0)return['']")
        JavaScript("if($1===undefined)return[s.repeat(n)]", sep)
        JavaScript("var t=yield*$L.checkstring($1,3)", sep)
        JavaScript("return[(s+t).repeat(n-1)+s]")
    end,

    reverse = function(s)
        ::update_stack_frame::
        JavaScript("return[(yield*$L.checkstring($1,1)).split('').reverse().join('')]", s)
    end,

    sub = function(s, i, j)
        ::update_stack_frame::
        JavaScript("var s=yield*$L.checkstring($1,1)", s)
        JavaScript("var i=(yield*$L.checknumber($1,2))|0", i)
        JavaScript("var n=s.length")
        JavaScript("if(i<0)i+=n+1")
        JavaScript("if($1===undefined)return[s.substring(i-1)]", j)
        JavaScript("var j=(yield*$L.checknumber($1,3))|0", j)
        JavaScript("if(j<0)j+=n+1")
        JavaScript("return[i<=j?s.substring(i-1,j):'']")
    end,

    char = function(...)
        ::update_stack_frame::
        JavaScript("var n=$1.length", ...)
        JavaScript("for(var i=0;i<n;i++)$1[i]=(yield*$L.checknumber($1[i],i+1))|0", ...)
        JavaScript("return String.fromCharCode.apply(undefined,$1)", ...)
    end,

    byte = function(s, i, j)
        ::update_stack_frame::
        JavaScript("var s=yield*$L.checkstring($1,1)", s)
        JavaScript("if($1===undefined)return[s.charCodeAt(0)]", i)
        JavaScript("var i=(yield*$L.checknumber($1,2))|0", i)
        JavaScript("var n=s.length")
        JavaScript("if(i<0)i+=n+1")
        JavaScript("if($1===undefined)return[s.charCodeAt(i-1)]", j)
        JavaScript("var j=(yield*$L.checknumber($1,3))|0", j)
        JavaScript("if(j<0)j+=n+1")
        JavaScript("var a=[]")
        JavaScript("for(;i<=j;i++)a.push(s.charCodeAt(i-1))")
        JavaScript("return a")
    end,

    regex = function(s)
        ::update_stack_frame::
        JavaScript("if(!$L.regex_known.has(yield*$L.checkstring($1,1))){", s)
        JavaScript("var r=new RegExp($1,'g')", s)
        JavaScript("$L.regex_known.set(yield*$L.checkstring($1,1),r)}", s)
        return s
    end,

    find = function(haystack, needle, init, plain)
        ::update_stack_frame::
        JavaScript("var plain=$1!==undefined&&$1!==false?true:false", plain)
        JavaScript("var r=yield*$L.find_match($1,$2,$3,plain)", haystack, needle, init)
        JavaScript("if(plain)return r")
        -- convert return value from regexp.exec
        JavaScript("if(r===null)return[undefined]")
        JavaScript("var n=r.length,a=[r.index+1,r.index+r[0].length]")
        JavaScript("for(var i=1;i<r.length;i++)a[i+1]=r[i]")
        JavaScript("return a")
    end,

    match = function(haystack, needle, init)
        ::update_stack_frame::
        JavaScript("var r=yield*$L.find_match($1,$2,$3,false)", haystack, needle, init)
        -- convert return value from regexp.exec
        JavaScript("if(r===null)return[undefined]")
        JavaScript("var n=r.length,a=[]")
        JavaScript("if(n>1)for(var i=1;i<r.length;i++)a[i-1]=r[i]") -- with captures
        JavaScript("else a[0]=r[0]") -- without captures
        JavaScript("return a")
    end,

    gmatch = function(string, pattern)
        ::update_stack_frame::
        JavaScript("var s=yield*$L.checkstring($1,1)", string)
        JavaScript("var p=$L.regex_known.get($1)", pattern)
        JavaScript("if(p===undefined)yield*$L.error_regex()")
        JavaScript("var x=0")
        return function()
            JavaScript("p.lastIndex=x")
            JavaScript("var r=p.exec(s)")
            -- convert return value from regexp.exec
            JavaScript("if(r===null)return[undefined]")
            JavaScript("var n=r.length,a=[]")
            JavaScript("if(n>1)for(var i=1;i<r.length;i++)a[i-1]=r[i]") -- with captures
            JavaScript("else a[0]=r[0]") -- without captures
            JavaScript("x+=r[0].length")
            JavaScript("return a")
        end
    end,

    gsub = function(string, pattern, replace, count)
        ::update_stack_frame::
        JavaScript("var str=yield*$L.checkstring($1,1)", string)
        JavaScript("var rgx=$L.regex_known.get($1)", pattern)
        JavaScript("if(rgx===undefined)yield*$L.error_regex()")
        JavaScript("var num=0,max=$1===undefined?str.length+1:(yield*$L.checknumber($1,4))|0", count)
        JavaScript("var rep=$1,typ=typeof rep", replace)
        JavaScript("if(typ==='number'){typ='string';rep=rep.toString()}")
        JavaScript("else if(!(typ==='string'||typ==='function'||(typ==='object'&&rep.luatable)))yield*$L.error_arg(3,'string/function/table expected')")
        -- main loop
        JavaScript("rgx.lastIndex=0")
        JavaScript("var idx=0")
        JavaScript("var buf=''")
        JavaScript("while(num<max){")
        JavaScript(     "var r=rgx.exec(str)")
        JavaScript(     "if(r===null)break")
        JavaScript(     "buf+=str.substring(idx,r.index)")
        JavaScript(     "idx=r.index+r[0].length")
        JavaScript(     "if(r.length===1)r[1]=r[0]")    -- when no captures
        JavaScript(     "if(typ==='string')buf+=yield*$L.gsub_string(rep,r)")
        JavaScript(     "else{")
        JavaScript(         "var x")
        JavaScript(         "if(typ==='function'){")
        JavaScript(             "x=[]")
        JavaScript(             "for(var y=1;y<r.length;y++)x[y-1]=r[y]")
        JavaScript(             "x=(yield*$L.call(typeof $$frame==='object'?'F:gsub':undefined,rep,x))[0]")
        JavaScript(         "}else x=yield*$L.get(rep,r[1],'?')") -- table
        JavaScript(         "if(x!==undefined&&x!==false)buf+=x")
        JavaScript(         "else buf+=r[0]}")
        JavaScript(     "num++}")
        JavaScript("buf+=str.substring(idx)")
        JavaScript("return[buf,num]")
    end,

    format = function(fmt, ...)
        ::update_stack_frame::
        JavaScript("var fmt=yield*$L.checkstring($1,1)", fmt)
        JavaScript("var i=0,k=0,str=''")
        JavaScript("while(1){")
        JavaScript("var j=fmt.indexOf('%',i)")
        JavaScript("if(j==-1)return[str+fmt.substr(i)]")
        JavaScript("if(j!==i)str+=fmt.substring(i,j)")
        JavaScript("var c=fmt.charAt(++j)")
        JavaScript("if(c==='%'){str+='%';i=j+1;continue}")
        JavaScript("if(k>=$1.length)yield*$L.error_arg(k+2,'no value')", ...)
        JavaScript("var fmt1=yield*$L.format_scan(fmt,j,c)")
        JavaScript("str+=yield*$L.format_print(fmt1,$1[k],k+2)", ...)
        JavaScript("k++")
        JavaScript("i=j+fmt1.len}")
    end,

    index = function(haystack, needle, init)
        ::update_stack_frame::
        JavaScript("return yield*$L.indexof($1,$2,$3,String.prototype.indexOf)", haystack, needle, init)
    end,

    rindex = function(haystack, needle, init)
        ::update_stack_frame::
        JavaScript("return yield*$L.indexof($1,$2,$3,String.prototype.lastIndexOf)", haystack, needle, init)
    end,

    startswith = function(str, pfx, idx)
        ::update_stack_frame::
        JavaScript("var str=yield*$L.checkstring($1,1)", str)
        JavaScript("var pfx=yield*$L.checkstring($1,2)", pfx)
        JavaScript("var idx=$1===undefined?0:(yield*$L.checknumber($1,3))", idx)
        JavaScript("return[str.startsWith(pfx,idx)]")
    end,

    endswith = function(str, sfx, len)
        ::update_stack_frame::
        JavaScript("var str=yield*$L.checkstring($1,1)", str)
        JavaScript("var pfx=yield*$L.checkstring($1,2)", pfx)
        JavaScript("if($1===undefined)return[str.endsWith(sfx)]", len)
        JavaScript("var len=(yield*$L.checknumber($1,3))", len)
        JavaScript("return[str.endsWith(sfx,len)]")
    end,

    trim = function(str)
        ::update_stack_frame::
        JavaScript("var str=yield*$L.checkstring($1,1)", str)
        JavaScript("return[str.trim()]")
    end,

    ltrim = function(str)
        ::update_stack_frame::
        JavaScript("var str=yield*$L.checkstring($1,1)", str)
        JavaScript("return[str.trimLeft()]")
    end,

    rtrim = function(str)
        ::update_stack_frame::
        JavaScript("var str=yield*$L.checkstring($1,1)", str)
        JavaScript("return[str.trimRight()]")
    end,

}

--
-- string patterns
--

-- JavaScript("$L.pattern_specials=new RegExp('[' + '\\' + '^' + '$$' + '*' + '+' + '?' + '.' + '(' + '[' + '%' + '\\' + '-' + ']')")
JavaScript("$L.regex_known=new Map()")

--
-- string.find and string.match helper
--

JavaScript("$L.find_match=$1", function(haystack, needle, init, plain)
    JavaScript("$1=yield*$L.checkstring($1,1)", haystack)
    JavaScript("$1=yield*$L.checkstring($1,2)", needle)
    JavaScript("var idx,len=$1.length", haystack)
    JavaScript("if($1===undefined)idx=1", init)
    JavaScript("else{")
    JavaScript(     "idx=yield*$L.checknumber($1,3)", init)
    JavaScript(     "if(idx===0||idx<=-len)idx=1")
    JavaScript(     "else if(idx<0)idx+=len+1}")
    JavaScript("if(idx>len)return[undefined]")      -- past end of string
    JavaScript("if($1){", plain)
    JavaScript(     "idx=$1.indexOf($2,idx-1)", haystack, needle)
    JavaScript(     "if(++idx===0)return[undefined]")
    JavaScript(     "return[idx,idx+$1.length-1]}", needle)
    -- execute regular expression search
    JavaScript("var r=$L.regex_known.get($1)", needle)
    JavaScript("if(r===undefined)yield*$L.error_regex()")
    JavaScript("r.lastIndex=idx-1")
    JavaScript("return r.exec($1)", haystack)
end)

--
-- string.index and string.rindex helper
--

JavaScript("$L.indexof=$1", function(haystack, needle, init, func)
    JavaScript("$1=yield*$L.checkstring($1,1)", haystack)
    JavaScript("$1=yield*$L.checkstring($1,2)", needle)
    JavaScript("var idx=$4.apply($1,$3===undefined?[$2]:[$2,(yield*$L.checknumber($1,3))-1])", haystack, needle, init, func)
    JavaScript("return[idx===-1?undefined:idx+1]")
end)

--
-- string.gsub helper: gsub_string
--

JavaScript("$L.gsub_string=$1", function(rep,res)
    JavaScript("var i=0,s=''")
    JavaScript("while(1){")
    JavaScript(     "var j=$1.indexOf('%',i)", rep)
    JavaScript(     "if(j===-1)break")
    JavaScript(     "s+=$1.substring(i,j)", rep)
    JavaScript(     "var c=$1.charAt(j+1)", rep)
    JavaScript(     "if(c==='%')s+=c")
    JavaScript(     "else if(c>='0'&&c<='9'){")
    JavaScript(         "var q=$1[c-'0']", res)
    JavaScript(         "if(q===undefined)yield*$L.error('invalid capture index')")
    JavaScript(         "s+=q}")
    JavaScript(     "else yield*$L.error('invalid use of % in replacement string')")
    JavaScript(     "i=j+2}")
    JavaScript("return s+$1.substring(i)", rep)
end)

--
-- string.format helper: format_scan
--

JavaScript("$L.format_scan=$1", function(str,idx,chr)
    JavaScript("var str=$1,idx=$2,chr=$3", str, idx, chr)
    JavaScript("var fmt={},idx0=idx")
    -- collect prefix flags
    JavaScript("while(1){")
    JavaScript("if(chr=='-')fmt.minus=true")
    JavaScript("else if(chr=='+')fmt.plus=true")
    JavaScript("else if(chr==' ')fmt.space=true")
    JavaScript("else if(chr=='#')fmt.alt=true")
    JavaScript("else if(chr=='0')fmt.zero=true")
    JavaScript("else break")
    -- skip two digits of width and two digits of precision
    JavaScript("chr=str.charAt(++idx)}")
    JavaScript("if(chr>='0'&&chr<='9'){")
    JavaScript(     "fmt.width=chr-'0'")
    JavaScript(     "chr=str.charAt(++idx)")
    JavaScript(     "if(chr>='0'&&chr<='9'){")
    JavaScript(         "fmt.width=fmt.width*10+(chr-'0')")
    JavaScript(         "chr=str.charAt(++idx)}}")
    JavaScript("else fmt.width=0")
    JavaScript("if(chr=='.'){")
    JavaScript(     "chr=str.charAt(++idx)")
    JavaScript(     "if(chr>='0'&&chr<='9'){")
    JavaScript(         "fmt.prec=chr-'0'")
    JavaScript(         "chr=str.charAt(++idx)")
    JavaScript(         "if(chr>='0'&&chr<='9'){")
    JavaScript(             "fmt.prec=fmt.prec*10+(chr-'0')")
    JavaScript(             "chr=str.charAt(++idx)}}")
    JavaScript(     "else fmt.prec=0}")
    JavaScript("if(chr>='0'&&chr<='9')yield*$L.error('invalid format (width or precision too long)')")
    -- collect format type, and return the format
    JavaScript("fmt.letter=chr")
    JavaScript("fmt.len=idx+1-idx0")
    JavaScript("return fmt")
end)

--
-- string.format helper: format_print
--

JavaScript("$L.format_print=$1", function(fmt, val, pos)
    JavaScript("var len,str=''")
    JavaScript("switch($1.letter){", fmt)
    JavaScript("case'd':case'i':case'o':case'u':case'x':case'X':\z
                        str=yield*$L.format_integer($3,yield*$L.checknumber($1,$2),$2);break", val, pos, fmt)
    JavaScript("case'e':case'E':case'f':case'F':case'g':case'G':case'a':case'A':\z
                        str=yield*$L.format_number($3,yield*$L.checknumber($1,$2),$2);break", val, pos, fmt)
    JavaScript("case'c':str=String.fromCharCode(yield*$L.checknumber($1,$2));break", val, pos)
    JavaScript("case's':str=yield*$L.tostring($2).substr(0,$1.prec);break", fmt, val)
    -- option q does not respect any printf flags
    JavaScript("case'q':return yield*$L.format_quote(yield*$L.checkstring($1,$2))", val, pos)
    JavaScript("default:yield*$L.error(\"invalid option '%\"+$1.letter+\"' to 'format'\")", fmt)
    JavaScript("}")
    -- apply the width modifier the same way to all format types
    JavaScript("len=$1.width-str.length", fmt)
    JavaScript("if(len>0){", fmt)
    JavaScript(     "if($1.minus)str+=' '.repeat(len)", fmt)
    JavaScript(     "else str=($1.zero?'0':' ').repeat(len)+str}", fmt)
    JavaScript("return str")
end)

--
-- string.format helper: format_quote
--

JavaScript("$L.format_quote=$1", function(a)
    JavaScript("var a=$1,b='\"',n=a.length,j=0,c,c2", a)
    JavaScript("while(j<n){")
    JavaScript(     "c=a.charAt(j++)")
    JavaScript(     "if(c<32||c==127){")
    JavaScript(         "b+='\\\\'")
    JavaScript(         "c2=a.charAt(j)")
    -- if not followed by a digit, or if it is a three-digit char code, write as is
    JavaScript(         "if(c2<'0'||c2>'9'||(c|0)>99)b+=(c|0)")
    -- otherwise, it is followed by a digit, so must make it a three-digit char code
    JavaScript(         "else if(c|0>9)b+='0'+(c|0)")
    JavaScript(         "else b+='00'+(c|0)}")
    JavaScript(     "else{")
    JavaScript(         "if(c=='\"'||c==\"'\"||c=='\n')b+='\\\\'")
    JavaScript(         "b+=c}}")
    JavaScript("return b+'\"'")
end)

--
-- string.format helper: format_number
--

JavaScript("$L.format_number=$1", function(fmt, num, pos)
    -- check special cases
    JavaScript("var n=$1,s", num)
    JavaScript("if(isNaN(n))return $1.letter>='a'?'nan':'NAN'", fmt)
    JavaScript("if(!isFinite(n)){")
    JavaScript(     "s=(n<0||(n===0&&1/n===-Infinity))?'-':($1.plus?'+':($1.space?' ':''))", fmt)
    JavaScript(     "return s+($1.letter>='a'?'inf':'INF')}", fmt)
    -- prepare to format number as requested
    JavaScript("var w=$1.letter", fmt)
    JavaScript("if(w==='a'||w==='A')return yield*$L.format_number_hex($1,$2)", fmt, num)
    JavaScript("var z=false,x=false,p=$1.prec===undefined?6:$1.prec", fmt)
    JavaScript("if(p>20)yield*$L.error_arg($1,'max precision is 20')", pos)
    -- type g:  precision specifies number of significant digits, with a minimum of 1.
    -- use either toExponential() or toPrecision(), based on exponent.
    JavaScript("if(w==='g'||w==='G'){")
    JavaScript(     "w=w=='G'?'E':'e'")
    JavaScript(     "z=!$1.alt", fmt)   -- remove trailing zeroes (unless # modifier)
    JavaScript(     "var e=n===0?0:Math.log10(Math.abs(n))")
    JavaScript(     "if(p===0)p=1")
    JavaScript(     "if(e<-4||e>=p){")
    JavaScript(         "x=true")       -- allow e in result
    JavaScript(         "s=n.toExponential(p)")
    JavaScript(         "if(e<-4){")
    JavaScript(             "var i=s.search(/[123456789]/)")
    JavaScript(             "if(i>0){")
    JavaScript(                 "p+=i")
    JavaScript(                 "if(p>20)p=20")
    JavaScript(                 "n.toExponential(p)}}}")
    JavaScript(     "else{")
    JavaScript(         "s=n.toPrecision(p)}}")
    -- type f:  precision specifies number of digits after decimal point for toFixed()
    JavaScript("else if(w==='f'||w==='F'){")
    JavaScript(     "w=w=='F'?'E':'e'")
    JavaScript(     "s=n.toFixed(p)}")
    -- type e:  precision specifies number of digits after decimal point for toExponential()
    JavaScript("else if(w==='e'||w==='E'){", fmt)
    JavaScript(     "x=true")           -- allow e in result
    JavaScript(     "s=n.toExponential(p)}")
    -- the number was formatted as a string but may require additional processing
    JavaScript("s=s.split('e',2)")
    JavaScript("var s1=s[0],s2=''")
    JavaScript("if(z)s1=s1.replace(/[.]?0*$$/,'')") -- remove trailing zeros for g
    JavaScript("if($1.alt&&s1.indexOf('.')===-1)s1+='.'", fmt)
    JavaScript("if(s1.charAt(0)!=='-'){")
    JavaScript(     "if($1.plus)s1='+'+s1", fmt)
    JavaScript(     "else if($1.space)s1=' '+s1}", fmt)
    JavaScript("if(s[1]){")
    JavaScript(     "if(x){")
                        -- result should include e, make sure it has two digits
    JavaScript(         "s2=s[1]")
    JavaScript(         "if(s2.length<3)s2=w+s2.charAt(0)+'0'+s2.charAt(1)")
    JavaScript(         "else s2=w+s2.substr(1)}")
    JavaScript(     "else{")
                        -- result should not include e, pad with extra zeroes
    JavaScript(         "e=s[1]|0")
    JavaScript(         "s1=s1.charAt(0)+s1.substr(2)+'0'.repeat(e-s1.length+2)")
    JavaScript(         "if(p)s1+='.'+'0'.repeat(p)")
    JavaScript(         "}}")
    JavaScript("return s1+s2")
end)

--
-- string.format helper: format_number_hex
--

JavaScript("$L.format_hex_lower='0123456789abcdefpx'")
JavaScript("$L.format_hex_upper='0123456789ABCDEFPX'")

JavaScript("$L.format_number_hex_f64=new Float64Array(1)")
JavaScript("$L.format_number_hex_u8=new Uint8Array($L.format_number_hex_f64.buffer)")

JavaScript("$L.format_number_hex=$1", function(fmt, num)
    JavaScript("$L.format_number_hex_f64[0]=$1", num)
    JavaScript("var m=$L.format_number_hex_u8")
    JavaScript("var p=$1.prec", fmt)
    -- extract sign, exponent and mantissa
    JavaScript("var str=(m[7]&0x80?'-':($1.plus?'+':($1.space?' ':'')))", fmt)
    JavaScript("var exp=(((m[7]&0x7F)<<4|m[6]>>4)-1023)")
    JavaScript("var mnt=[1,m[6]&0x0F,\z
                        (m[5]&0xF0)>>4,m[5]&0x0F,\z
                        (m[4]&0xF0)>>4,m[4]&0x0F,\z
                        (m[3]&0xF0)>>4,m[3]&0x0F,\z
                        (m[2]&0xF0)>>4,m[2]&0x0F,\z
                        (m[1]&0xF0)>>4,m[1]&0x0F,\z
                        (m[0]&0xF0)>>4,m[0]&0x0F]")
    -- round to specified number of digits, or expand with trailing zeroes.
    -- if precision is not specified, discard trailing zeroes.
    JavaScript("var i=mnt.length,j")
    JavaScript("if(p!==undefined){")
    JavaScript(     "p=p+1")
    JavaScript(     "while(p<i){")
    JavaScript(         "if(mnt[--i]>=8){")
    JavaScript(             "j=i")
    JavaScript(             "while(1){")
    JavaScript(                 "j--")
    JavaScript(                 "if(mnt[j]==15)mnt[j]=0")
    JavaScript(                 "else{mnt[j]=mnt[j]+1;break}}}")
    JavaScript(         "mnt[i]=0")
    JavaScript(         "}")
    JavaScript(     "while(p>i)mnt[i++]=0}")
    JavaScript("else while(mnt[i-1]==0)i--")    -- precision not specified
    -- combine array into result string
    JavaScript("p=$1.letter=='A'?$L.format_hex_upper:$L.format_hex_lower", fmt)
    JavaScript("str+='0'+p[17]+p[mnt[0]]")
    JavaScript("if(i>1||$1.alt)str+='.'", fmt)
    JavaScript("for(j=1;j<i;++j)str+=p[mnt[j]]")
    JavaScript("if(exp>=0)exp='+'+exp")
    JavaScript("return str+p[16]+exp")
end)

--
-- string.format helper: format_integer
--

JavaScript("$L.format_integer=$1", function(fmt, num, pos)
    JavaScript("var w=$1.letter,p=$1.prec,n=$2,ni,diff", fmt, num)
    JavaScript("if(w==='d'||w==='i'){")
    JavaScript(     "ni=n|0")
    JavaScript(     "diff=n-ni")
    JavaScript(     "if(diff<-1||diff>1)yield*$L.error_arg($1,'not a number in proper range')", pos)
    JavaScript(     "n=ni.toString()")
    JavaScript(     "if(n.charAt(0)!=='-'){")
    JavaScript(         "if($1.plus)n='+'+n", fmt)
    JavaScript(         "else if($1.space)n=' '+n}}", fmt)
    JavaScript("else{")
    JavaScript(     "ni=n>>>0")
    JavaScript(     "diff=n-ni")
    JavaScript(     "if(diff<-1||diff>1)yield*$L.error_arg($1,'not a non-negative number in proper range')", pos)
    JavaScript(     "if(w==='u')n=ni.toString()")
    JavaScript(     "else if(w==='o')n=ni.toString(8)")
    JavaScript(     "else if(w==='x')n=ni.toString(16)")
    JavaScript(     "else if(w==='X')n=ni.toString(16).toUpperCase()}")
    JavaScript("if(p!==undefined){")
    JavaScript(     "p-=n.length")
    JavaScript(     "if(p>0)n='0'.repeat(p)+n}")
    JavaScript("if($1.alt){", fmt)
    JavaScript(     "if(w==='o'&&n.charAt(0)!=='0')n='0'+n", fmt)
    JavaScript(     "else if(w==='x')n='0'+$L.format_hex_lower[17]+n")
    JavaScript(     "else if(w==='X')n='0'+$L.format_hex_upper[17]+n}")
    JavaScript("return n")
end)

--
-- set string table as the metatable for strings
--

JavaScript("yield*$L.smt('',$1)", { __index = string })

--
-- table library
--

table = {

    concat = function(tbl, sep, first, last)
        ::update_stack_frame::
        JavaScript("var sep=$1===undefined?'':yield*$L.checkstring($1,2)", sep)
        JavaScript("yield*$L.checktable($1,1)", tbl)
        JavaScript("var i=$1===undefined?1:(yield*$L.checknumber($1,3))|0", first)
        JavaScript("var j=$1===undefined?$2.array.length-1:(yield*$L.checknumber($1,4))|0", last, tbl)
        JavaScript("var s=''")
        JavaScript("for(;i<j;i++){")
        JavaScript("var x=$1.array[i]", tbl)
        JavaScript("if(typeof x==='number')x=x.toString()")
        JavaScript("else if(typeof x!=='string')yield*$L.error(\"invalid value (\"+(yield*$L.type(x))+\") at index \"+i+\" in table for 'concat'\", 2)")
        JavaScript("s+=x+sep}")
        JavaScript("if(i===j)s+=$1.array[i]", tbl)
        JavaScript("return[s]")
    end,

    insert = function(tbl, ...)
        ::update_stack_frame::
        JavaScript("yield*$L.checktable($1,1)", tbl)
        JavaScript("var a=$1.array", tbl)
        JavaScript("var n=a.length")
        JavaScript("if(n>0){while(0<--n){if(a[n]!==undefined)break}}")
        JavaScript("n++")
        JavaScript("if($1.length===2){", ...)
        JavaScript(     "var m=(yield*$L.checknumber($1.shift(),2))|0", ...)
        JavaScript(     "if(m<1||m>n)yield*$L.error_arg(2,'position out of bounds')")
        JavaScript(     "for(var i=n;i>m;i--)a[i]=a[i-1]")
        JavaScript(     "n=m}")
        JavaScript("else if($1.length!==1)yield*$L.error(\"wrong number of arguments to 'insert'\", 2)", ...)
        JavaScript("a[n]=$1[0]", ...)
    end,

    remove = function(tbl, idx)
        ::update_stack_frame::
        JavaScript("yield*$L.checktable($1,1)", tbl)
        JavaScript("var a=$1.array", tbl)
        JavaScript("var n=a.length")
        JavaScript("while(0<--n){if(a[n]!==undefined)break}")
        JavaScript("var m=n")
        JavaScript("if($1!==undefined){", idx)
        JavaScript("m=(yield*$L.checknumber($1,2))|0", idx)
        JavaScript("if(m<1||m>n+1)yield*$L.error_arg(2,'position out of bounds')}")
        JavaScript("var v=a[m]")
        JavaScript("while(m<n)a[m]=a[++m]")
        JavaScript("a[m]=undefined")
        JavaScript("return[v]")
    end,

    pack = function(...)
        ::update_stack_frame::
        JavaScript("var n=$1.length", ...)
        JavaScript("var t={luatable:true,array:[],hash:new Map()};")
        JavaScript("t.hash.set('n',n)")
        JavaScript("for(var i=0;i<n;){var x=$1[i];t.array[++i]=x};", ...)
        JavaScript("return[t]")
    end,

    unpack = function(tbl, first, last)
        ::update_stack_frame::
        JavaScript("yield*$L.checktable($1,1)", tbl)
        JavaScript("var i=$1===undefined?1:(yield*$L.checknumber($1,2))|0", first)
        JavaScript("var j=$1===undefined?$2.array.length:(yield*$L.checknumber($1,3))|0", last, tbl)
        JavaScript("var r=[]")
        JavaScript("while(i<j)r.push($1.array[i++])", tbl)
        JavaScript("return r")
    end,

    sort = function(tbl, cmp)
        ::update_stack_frame::
        JavaScript("yield*$L.checktable($1,1)", tbl)
        JavaScript("var cmp=$1", cmp)
        JavaScript("if(cmp===undefined)cmp=$L.cmplt")
        JavaScript("else yield*$L.checkfunction(cmp,2)")
        JavaScript("var a=$1.array", tbl)
        JavaScript("yield*$L.qsort_array(a,1,a.length-1,cmp)")
        -- cannot use javascript array.sort because it breaks chain of generators
        -- JavaScript("$1.array.sort(function(a,b){", tbl)
        -- JavaScript(     "var x=(yield*$L.call('?',cmp,a,b))[0]")
        -- JavaScript(     "if(x!==undefined&&x!==false)return -1")    -- a comes before b
        -- JavaScript(     "x=(yield*$L.call('?',cmp,b,a))[0]")
        -- JavaScript(     "if(x!==undefined&&x!==false)return 1")     -- b comes before a
        -- JavaScript(     "return 0})")                               -- a and b are equal
    end,

}

--
-- table.sort helper: qsort_array,
-- ported from ltablib.c in the official implementation
--

JavaScript("$L.qsort_array=$1", function(a,l,u,cmp)
    JavaScript("var i,j,r,p,a=$1,l=$2,u=$3,cmp=$4",a,l,u,cmp)
    JavaScript("while(l<u){")
    JavaScript("r=(yield*$L.call('?',cmp,a[u],a[l]))[0]")
    JavaScript("if(r!==undefined&&r!==false)[a[l],a[u]]=[a[u],a[l]]")       -- a[u] < a[l]? swap
    JavaScript("if(u-l===1)break")                                          -- only 2 elements
    JavaScript("i=((l+u)/2)|0")
    JavaScript("r=(yield*$L.call('?',cmp,a[i],a[l]))[0]")
    JavaScript("if(r!==undefined&&r!==false)[a[i],a[l]]=[a[l],a[i]]")       -- a[i] < a[l]? swap
    JavaScript("else{")
    JavaScript(     "r=(yield*$L.call('?',cmp,a[u],a[i]))[0]")
    JavaScript(     "if(r!==undefined&&r!==false)[a[u],a[i]]=[a[i],a[u]]}") -- a[u] < a[i]? swap
    JavaScript("if(u-l===2)break")                                          -- only 3 elements
    -- pivot P is value at a[i]
    JavaScript("p=a[i]")
    -- swap a[i] and a[u-1], while keeping original value in P
    JavaScript("j=u-1")
    JavaScript("[a[i],a[j]]=[a[j],p]")                                      -- swap a[i] and a[u-1]
    -- a[l] <= P == a[u-1] <= a[u], only need to sort from l+1 to u-2
    JavaScript("i=l")
    -- invariant: a[l..i] <= P <= a[j..u]
    JavaScript("while(1){")                                                 -- a[l..i] <= P <= a[j..u]
    -- repeat ++i until a[i] >= P
    JavaScript(     "while(1){")
    JavaScript(         "r=(yield*$L.call('?',cmp,a[++i],p))[0]")
    JavaScript(         "if(r===undefined||r===false)break")
    JavaScript(         "if(i>=u)yield*$L.error_sort()}")
    -- repeat --j until a[j] <= P
    JavaScript(     "while(1){")
    JavaScript(         "r=(yield*$L.call('?',cmp,p,a[--j]))[0]")
    JavaScript(         "if(r===undefined||r===false)break")
    JavaScript(         "if(j<=l)yield*$L.error_sort()}")
    -- swap a[i] and a[j], unless j<i
    JavaScript(     "if(j<i)break")
    JavaScript(     "[a[i],a[j]]=[a[j],a[i]]}")
    -- swap pivot (a[u-1]) with a[i]
    JavaScript("[a[u-1],a[i]]=[a[i],a[u-1]]")
    -- a[l..i-1] <= a[i] == P <= a[i+1..u]
    -- adjust so that shorter sequence is in [j..i] and larger one in [l..u]
    JavaScript("if(i-l<u-i)[j,i,l]=[l,i-1,i+1]")
    JavaScript("else[j,i,u]=[i+1,u,i-1]")
    -- call recursively on the shorter sequence, repeat loop on larger sequence
    JavaScript("if(j<i)yield*$L.qsort_array(a,j,i,cmp)}")
end)

--
-- bit32 library
--

bit32 = {

    band = function(...)
        ::update_stack_frame::
        JavaScript("var n=$1.length,r=0xFFFFFFFF>>>0", ...)
        JavaScript("for(var i=0;i<n;i++)r&=(yield*$L.checknumber($1[i],i+1))>>>0", ...)
        JavaScript("return[r]")
    end,

    btest = function(...)
        ::update_stack_frame::
        JavaScript("var n=$1.length,r=0xFFFFFFFF>>>0", ...)
        JavaScript("for(var i=0;i<n;i++)r&=(yield*$L.checknumber($1[i],i+1))>>>0", ...)
        JavaScript("return[r!==0]")
    end,

    bor = function(...)
        ::update_stack_frame::
        JavaScript("var n=$1.length,r=0>>>0", ...)
        JavaScript("for(var i=0;i<n;i++)r|=(yield*$L.checknumber($1[i],i+1))>>>0", ...)
        JavaScript("return[r]")
    end,

    bxor = function(...)
        ::update_stack_frame::
        JavaScript("var n=$1.length,r=0>>>0", ...)
        JavaScript("for(var i=0;i<n;i++)r^=(yield*$L.checknumber($1[i],i+1))>>>0", ...)
        JavaScript("return[r]")
    end,

    bnot = function(x)
        ::update_stack_frame::
        JavaScript("return[~(yield*$L.checknumber($1,1))>>>0]", x)
    end,

    lshift = function(x, disp)
        ::update_stack_frame::
        JavaScript("var r=(yield*$L.checknumber($1,1))>>>0", x)
        JavaScript("var i=(yield*$L.checknumber($1,2))|0", disp)
        JavaScript("if(i<0){i=-i;if(i>=32)r=0;else r>>>=i}")    -- shift right
        JavaScript("else{if(i>=32)r=0;else r<<=i}")        -- else shift left
        JavaScript("return[r>>>0]")
    end,

    rshift = function(x, disp)
        ::update_stack_frame::
        JavaScript("var r=(yield*$L.checknumber($1,1))>>>0", x)
        JavaScript("var i=(-(yield*$L.checknumber($1,2)))|0", disp)
        JavaScript("if(i<0){i=-i;if(i>=32)r=0;else r>>>=i}")    -- shift right
        JavaScript("else{if(i>=32)r=0;else r<<=i}")        -- else shift left
        JavaScript("return[r>>>0]")
    end,

    arshift = function(x, disp)
        ::update_stack_frame::
        JavaScript("var r=(yield*$L.checknumber($1,1))>>>0", x)
        JavaScript("var i=(-(yield*$L.checknumber($1,2)))|0", disp)
        JavaScript("if(i<0){i=-i;if(i>=32)r=-1|0;else r>>=i}")  -- signed shift right
        JavaScript("else{if(i>=32)r=-1|0;else r<<=i}")            -- else shift left
        JavaScript("return[r>>>0]")
    end,

    lrotate = function(x, disp)
        ::update_stack_frame::
        JavaScript("var r=(yield*$L.checknumber($1,1))>>>0", x)
        JavaScript("var i=((yield*$L.checknumber($1,2))|0)&31", disp)
        JavaScript("if(i!==0)r=(r<<i)|(r>>>(32-i))")
        JavaScript("return[r>>>0]")
    end,

    rrotate = function(x, disp)
        ::update_stack_frame::
        JavaScript("var r=(yield*$L.checknumber($1,1))>>>0", x)
        JavaScript("var i=((-(yield*$L.checknumber($1,2)))|0)&31", disp)
        JavaScript("if(i!==0)r=(r<<i)|(r>>>(32-i))")
        JavaScript("return[r>>>0]")
    end,

    extract = function(n, field, width)
        ::update_stack_frame::
        JavaScript("var f,w")
        JavaScript("var r=(yield*$L.checknumber($1,1))>>>0", n)
        JavaScript("[f,w]=yield*$L.bit_field_args(2,$1,$2)", field, width)
        JavaScript("return[((r>>f)&w)>>>0]")
    end,

    replace = function(n, v, field, width)
        ::update_stack_frame::
        JavaScript("var f,w")
        JavaScript("var r=(yield*$L.checknumber($1,1))>>>0", n)
        JavaScript("var v=(yield*$L.checknumber($1,2))>>>0", v)
        JavaScript("[f,w]=yield*$L.bit_field_args(3,$1,$2)", field, width)
        JavaScript("return[((r&~(w<<f))|((v&w)<<f))>>>0]")
    end,

}

--
-- helper function for bit32.extract and bit32.replace
--

JavaScript("$L.bit_field_args=$1", function(argnum, field, width)
    JavaScript("var f=(yield*$L.checknumber($1,$2))|0", field, argnum)
    JavaScript("var w=$1===undefined?1:(yield*$L.checknumber($1,$2+1))|0", width, argnum)
    JavaScript("if(f<0)yield*$L.error_arg($1,'field cannot be negative')", argnum)
    JavaScript("if(w<=0)yield*$L.error_arg($1+1,'width must be positive')", argnum)
    JavaScript("if(f+w>32)yield*$L.error('trying to access non-existent bits')")
    JavaScript("w=~(((-1|0)<<1)<<(w-1))") -- build a number with 'w' ones
    JavaScript("return[f,w]")
end)

--
-- os library
--

os = {

    date = function(fmt, tm)
        ::update_stack_frame::
        JavaScript("var dt,utc,idx")
        JavaScript("var fmt=$1===undefined?'':(yield*$L.checkstring($1,1))", fmt)
        JavaScript("if($1===undefined)dt=new Date()", tm)
        JavaScript("else dt=new Date((yield*$L.checknumber($1,2))*1000)", tm)
        JavaScript("if(utc=(fmt.charAt(0)==='!'))fmt=fmt.substr(1)")
        JavaScript("if(fmt==='*t'){") do
            local year, month, day, hour, min, sec, wday, yday
            JavaScript("$1=utc?dt.getUTCFullYear():dt.getFullYear()", year)
            JavaScript("$1=1+(utc?dt.getUTCMonth():dt.getUTCMonth())", month)
            JavaScript("$1=utc?dt.getUTCDate():dt.getDate()", day)
            JavaScript("$1=utc?dt.getUTCHours():dt.getHours()", hour)
            JavaScript("$1=utc?dt.getUTCMinutes():dt.getMinutes()", min)
            JavaScript("$1=utc?dt.getUTCSeconds():dt.getSeconds()", sec)
            JavaScript("$1=1+(utc?dt.getUTCDay():dt.getDay())", wday)
            -- calculate yday, based on https://stackoverflow.com/a/27790471
            JavaScript("$1=function(y,m,d){return --m>=0&&m<12&&d>0&&d<29+(4*(y=y&3||!(y%25)&&y&15?0:1)+15662003>>m*2&3)&&m*31-(m>1?(1054267675>>m*3-6&7)-y:0)+d}($2,$3,$4)", yday, year, month, day)
            return { year = year, month = month, day = day,
                     hour = hour, min = min, sec = sec,
                     wday = wday, yday = yday, isdst = false }
        end
        JavaScript("}else if(fmt===''||fmt==='%c'){")
        JavaScript(     "var options=utc?{timeZone:'UTC'}:undefined")
        JavaScript(     "return[dt.toLocaleString(undefined,options)]}")
        error("unsupported date format '" .. fmt .. "'", 2)
    end,

    time = function(tbl)
        ::update_stack_frame::
        JavaScript("var dt,tz=0")
        JavaScript("if($1===undefined)dt=Date.now()", tbl)
        JavaScript("else{")
        JavaScript(     "yield*$L.checktable($1,1)", tbl)
        JavaScript(     "function*chk(k,d){")
        JavaScript(         "var v=yield*$L.checknumber(yield*$L.get($1,k))", tbl)
        JavaScript(         "if(v===undefined){v=d")
        JavaScript(         "if(v===undefined)yield*$L.error('field \\''+k+'\\' missing in date table')}")
        JavaScript(         "return v|0}")
        JavaScript(     "var sc=yield*chk('sec',0)")
        JavaScript(     "var mi=yield*chk('min',0)")
        JavaScript(     "var hr=yield*chk('hour',12)")
        JavaScript(     "var dy=yield*chk('day')")
        JavaScript(     "var mo=(yield*chk('month'))-1")
        JavaScript(     "var yr=(yield*chk('year'))")
        JavaScript(     "if(yr<100)yr+=1900")
        JavaScript(     "dt=new Date(yr,mo,dy,hr,mi,sc)")
        JavaScript(     "var dst=yield*$L.get($1,'isdst')", tbl)
        JavaScript(     "if(dst!==undefined&&dst!==false)tz=dt.getTimezoneOffset()*60000")
        JavaScript(     "dt=dt.getTime()}")
        JavaScript("return[Math.floor((dt+tz)/1000)]")
    end,

    --[[difftime = function(t2,t1)
        ::update_stack_frame::
        JavaScript("var t2=yield*$L.checknumber($1,1))", t2)
        JavaScript("var t1=$1===undefined?0:(yield*$L.checknumber($1,2)))", t1)
        JavaScript("return[t2-t1]")
    end,]]

    setlocale = function(locale, category)
        ::update_stack_frame::
        JavaScript("if($1!==undefined)$1=yield*$L.checkstring($1,1)", locale)
        JavaScript("$1=$1===undefined?'':(yield*$L.checkstring($1,2))", category)
        if category ~= "" and category ~= "all" and category ~= "collate" then
            error("unsupported category '" .. category .. "'", 2)
        end
        JavaScript("if($1==='')$1=undefined", locale)
        JavaScript("try{")
        JavaScript(     "var coll=new Intl.Collator($1)", locale)
        JavaScript(     "$L.strcoll=coll.compare")
        JavaScript(     "if($1===undefined)$1=''", locale)
        JavaScript("}catch(e){$1=undefined}", locale)
        return locale
    end,
}

--
-- coroutine library
--

coroutine = {

    create = function(func)
        ::update_stack_frame::
        JavaScript("yield*$L.checkfunction($1,1)", func)

        JavaScript("var co={\z
            id:($L.unique++).toString(16),\z
            luacoroutine:true,\z
            generator:$1,\z
            status:'suspended',\z
            stack:[],\z
            protected:0};", func)

        JavaScript("co.resume=function(argarr){\z
            $L.co=co;\z
            if(co.status==='dead')\z
                $L.error('cannot resume dead coroutine').next();\z
            if(co.status==='running')\z
                $L.error('cannot resume non-suspended coroutine').next();\z
            if(co.timeoutid){clearTimeout(co.timeoutid);co.timeoutid=undefined}\z
            var old_status=co.status;\z
            co.status='running';\z
            if(co.generator){\z
                co.stack.push(co.frame=[co.generator.line,co.generator.file,'coroutine',co.generator]);\z
                co.luacoroutine=co.generator.apply(undefined,argarr);\z
                co.generator=argarr=undefined};\z
            var res;\z
            co.protected++;\z
            try{\z
                res=co.luacoroutine.next(argarr);\z
                if(res.done){\z
                    res=res.value||[undefined];\z
                    if(co.resume_result===true)co.resume_result=res;\z
                    res.unshift(true)}\z
                else res=undefined}\z
            catch(x){\z
                if(typeof x==='object'&&typeof x.stack==='string'&&typeof x.message==='string'){\z
                    console.error(x);\z
                    x='JS '+x.message};\z
                if(!co.protected)\z
                    console.log($L.traceback('lua: '+x,0).next().value);\z
                res=[false,x]};\z
            co.protected--;\z
            $L.co=undefined;\z
            if(res){\z
                co.status='dead';\z
                if(co.caller)setTimeout(co.caller.resume,0,res);\z
                res=undefined};\z
            if(old_status=='asyncwait')co.caller=co.old_callers.pop();\z
            return res};")

        -- note that co.resume modifies $L.co, so should generally
        -- NOT be invoked directly, but always through setTimeout().

        JavaScript("return[co]")
    end,

    resume = function(co, ...)
        ::update_stack_frame::
        JavaScript("yield*$L.checkcoroutine($1,1)", co)

        JavaScript("var co=$1", co)
        JavaScript("if(co.status==='dead')return[false,'cannot resume dead coroutine']")
        JavaScript("if(co.caller||(co.status!=='asyncwait'&&co.status!=='suspended'))return[false,'cannot resume non-suspended coroutine']")

        JavaScript("if(co.status==='asyncwait'){setTimeout(co.resume,0,$1);return}", ...)

        JavaScript("co.caller=$L.co")
        JavaScript("$L.co.status='normal'")
        JavaScript("setTimeout(co.resume,0,$1)", ...)
        JavaScript("return(yield)")
    end,

    yield = function(...)
        ::update_stack_frame::
        JavaScript("var co=$L.co")
        JavaScript("if(!co||!co.caller)$L.error('attempt to yield from outside a coroutine')")
        JavaScript("$L.co=undefined")
        JavaScript("var caller=co.caller")
        JavaScript("co.caller=undefined")
        JavaScript("co.status='suspended'")
        JavaScript("$1.unshift(true)", ...)
        JavaScript("setTimeout(caller.resume,0,$1)", ...)
        JavaScript("return(yield)")
    end,

    suspend = function()
        ::update_stack_frame::

        JavaScript("var co=$L.co")
        JavaScript("if(!co)$L.error('attempt to suspend from outside a coroutine')")
        JavaScript("$L.co=undefined")
        JavaScript("if(!co.old_callers)co.old_callers=[]")
        JavaScript("co.old_callers.push(co.caller)")
        JavaScript("co.caller=undefined")
        JavaScript("co.status='asyncwait'")
        JavaScript("return(yield)")
    end,

    wrap = function(func)
        ::update_stack_frame::
        JavaScript("yield*$L.checkfunction($1,1)", func)
        JavaScript("var co=(yield*$L.cocreate($1))[0]", func)
        JavaScript("return[$1,co]", function(...)
            JavaScript("var r")
            JavaScript("if(co.status==='dead')r=[false,'cannot resume dead coroutine']")
            JavaScript("else if(co.caller||co.status!=='suspended')r=[false,'cannot resume non-suspended coroutine']")
            JavaScript("else{")
            JavaScript(     "co.caller=$L.co")
            JavaScript(     "if(co.caller)co.caller.status='normal'")
            JavaScript(     "setTimeout(co.resume,0,$1)", ...)
            JavaScript(     "r=yield}")
            JavaScript("var x=r.shift()")
            JavaScript("if(!x)yield*$L.error(r[0])")
            JavaScript("return r")
        end)
    end,

    running = function()
        ::update_stack_frame::
        JavaScript("if(!$L.co)return[undefined,false]")
        JavaScript("return[$L.co,!!$L.co.main]")
    end,

    status = function(co)
        ::update_stack_frame::
        JavaScript("yield*$L.checkcoroutine($1,1)", co, 1)
        JavaScript("return[$1.status]", co)
    end,

    sleep = function(timeout)
        ::update_stack_frame::
        JavaScript("yield*$L.checknumber($1,1)", timeout)
        JavaScript("var co=$L.co")
        JavaScript("co.timeoutid=setTimeout(co.resume,$1|0)", timeout)
        JavaScript("yield*$L.cosuspend()")
    end,

    spawn = function(func, ...)
        ::update_stack_frame::
        JavaScript("yield*$L.checkfunction($1,1)", func)
        JavaScript("var fn,co")
        JavaScript("[fn,co]=yield*$L.cowrap($1)", func)
        JavaScript("co.protected=-1")
        JavaScript("setTimeout(function(){$L.co=undefined;fn.apply(undefined,$1).next()})", ...)
        JavaScript("return[co]")
    end,

    jscallback = function(func, ...)
        ::update_stack_frame::
        JavaScript("yield*$L.checkfunction($1,1)", func)
        JavaScript("var stack=[],func=$1,arg1=$2", func, ...)
        JavaScript("for(var i=0;i<$L.co.stack.length;i++)\z
                stack[i]=$L.co.stack[i].slice()")
        JavaScript("return[function(...arg2){\z
            var co0=$L.co;\z
            $L.co={};\z
            var co=$L.cocreate(func).next().value[0];\z
            co.protected=-1;\z
            co.resume_result=true;\z
            for(var i=0;i<stack.length;i++)\z
                co.stack[i]=stack[i].slice();\z
            co.resume(arg1.concat(arg2));\z
            var r=co.resume_result;\z
            $L.co=co0;\z
            if(typeof r==='object'&&r[0]===true)return r[1]}]")
    end,

    jsconvert = function(jsobj, luatab)
        local helper
        if jsobj ~= nil then
            JavaScript("if(typeof $1!=='object'||$1===null)yield*$L.error_arg(1,'javascript object expected')", jsobj)
            if luatab then
                JavaScript("yield*$L.checktable($1,1)", luatab)
            else luatab = {} end
            helper = function(luatable, jsobject)
                local k, v
                JavaScript("for(var k in $1){", jsobject)
                JavaScript(     "if(k===null||k===undefined)continue")
                JavaScript(     "var v=$1[k]", jsobject)
                JavaScript(     "if(v===null)v=undefined")
                JavaScript(     "[$1,$2]=[k,v]", k, v)
                JavaScript(     "if(typeof v==='object'){")
                                    v = helper({}, v)
                JavaScript(     "}")
                                luatable[k] = v
                JavaScript("}")
                return luatable
            end
            return helper(luatab, jsobj)
        else
            helper = function(luatable)
                JavaScript("var jsobject={};")
                for k, v in pairs(luatable) do
                    if v ~= nil then
                        JavaScript("var t=typeof $1", k)
                        JavaScript("if(t==='string'||t==='number'){")
                        JavaScript(     "t=typeof $1", v)
                        JavaScript(     "if(t==='boolean'||t==='number'||t==='string')jsobject[$1]=$2", k, v)
                        JavaScript(     "else if(t==='object'&&$1.luatable){", v)
                        JavaScript(         "jsobject[$1]=$2}}", k, helper(v))
                    end
                end
                JavaScript("return jsobject")
            end
            JavaScript("$1=$2", jsobj, helper(luatab))
            return jsobj
        end
    end,

    fastcall = function(func, ...)
        ::update_stack_frame::
        JavaScript("var co=$L.co.luacoroutine")
        JavaScript("$L.co.luacoroutine=undefined")
        JavaScript("try{")
        JavaScript(     "($L.call.fast||$L.fastcall($L.call))('?',$1,$2)}", func, ...)
        JavaScript("catch(x){")
        JavaScript(     "$L.co.luacoroutine=co")
        JavaScript(     "if(typeof x==='object'&&typeof x.stack==='string'&&typeof x.message==='string'){console.error(x);x='JS '+x.message+\" in a function processed by 'fastcall'\"}")
        JavaScript(     "yield*$L.error(x)}")
        JavaScript("$L.co.luacoroutine=co")
    end,

    mutex_metatable = { __index = {

        trylock = function (self)
            assert(getmetatable(self) == coroutine.mutex_metatable)
            local success
            if self.locked then
                success = false
            else
                success = true
                self.locked = true
            end
            return success
        end,

        lock = function (self)
            assert(getmetatable(self) == coroutine.mutex_metatable)
            if self.locked then
                local co = coroutine.running()
                local waiters = self.waiters
                repeat
                    local n = #waiters
                    local dup = false
                    for i = 1, n do
                        if waiters[n] == co then
                            dup = true
                            break
                        end
                    end
                    if not dup then
                        waiters[n + 1] = co
                    end
                    coroutine.suspend()
                until not self.locked
            end
            self.locked = true
            return true
        end,

        unlock = function (self)
            assert(getmetatable(self) == coroutine.mutex_metatable)
            assert(self.locked)
            self.locked = false
            local waiters = self.waiters
            if #waiters > 0 then
                local co = waiters[1]
                table.remove(waiters, 1)
                coroutine.resume(co)
            end
        end
    }},

    mutex = function()
        return setmetatable({ locked=false, waiters={} }, coroutine.mutex_metatable)
    end,

}

JavaScript("[$L.cocreate,$L.coresume,$L.cosuspend,$L.cowrap]=[$1,$2,$3,$4]",
    coroutine.create, coroutine.resume, coroutine.suspend, coroutine.wrap)

--
-- require() and package table
--

package = { loaded = {}, JavaScript = true, Loulabelle = 5201 }

require = function(module)
    ::update_stack_frame::
    JavaScript("$1=yield*$L.checkstring($1,1)", module)
    local result = package.loaded[module]
    if not result then
        JavaScript("$2=(yield*$L.require_lua($1+'.js'))[0]", module, result)
        JavaScript("if(typeof $2!=='function')$L.error(\"module '\"+$1+\"' not found\",2).next()", module, result)
        result = result(module)
        if result == nil then
            result = package.loaded[module]
            if result == nil then result = true end
        end
        package.loaded[module] = result
    end
    return result
end

--
-- load lua chunk
--

JavaScript("$L.require_lua=$1", function(url)
    ::update_stack_frame::
    JavaScript("var chunk=[false]")
    -- check execution environment to determine how we load the chunk
    JavaScript("if(!!(typeof window!=='undefined'&&typeof navigator!=='undefined'&&window.document)){")
    -- in the browser we only have an async load, so create a new <script> element.
    -- by the time the onload event is fired, the script has already registered itself
    -- via use of $L.chunk and $L.require_chunk (defined below)
    JavaScript(     "var elem=document.createElement('script')")
    JavaScript(     "elem.require_chunk=chunk")
    JavaScript(     "elem.type='text/javascript'")
    JavaScript(     "(document.head||document.getElementsByTagName('head')[0]).appendChild(elem)")
    JavaScript(     "elem.onerror=elem.onload=$L.co.resume")
    JavaScript(     "elem.src=$1", url)
    JavaScript(     "yield*$L.cosuspend()")
    JavaScript(     "elem.require_chunk=undefined")
    JavaScript("}else{")
    -- otherwise we are in a web worker or running undernode.js,
    -- which load the script synchronously
    JavaScript(     "if($L.require_chunk!==undefined)yield*$L.error('attempting to load more than one chunk at once')")
    JavaScript(     "$L.require_chunk=chunk")
    JavaScript(     "try{")
    JavaScript(         "if(typeof importScripts!=='undefined'){")
                            -- web worker
    JavaScript(             "importScripts($1)}", url)
    JavaScript(         "else{")
                            -- node.js
    JavaScript(             "require($1)}", url)
    JavaScript(     "}catch(x){}")
    JavaScript(     "$L.require_chunk=undefined}")
    JavaScript("return chunk")
end)

JavaScript("$L.require_chunk=function(f){\z
    if(typeof document==='object'&&typeof document.currentScript==='object'&&typeof document.currentScript.require_chunk==='object')\z
        document.currentScript.require_chunk[0]=f;\z
    else if(typeof $L.require_chunk==='object')\z
        $L.require_chunk[0]=f;\z
    else{console.error('attempting to load more than one main chunk');console.trace()}};")

JavaScript("$L.preload_chunk=function(n,f){\z
    var r=f(n).next();\z
    if(r.done){\z
        if(typeof r.value==='object'&&r.value[0]!==undefined)r=r.value[0];\z
        else{\z
            r=$L.env.hash.get('package').hash.get('loaded').hash.get(n);\z
            if(r===undefined)r=true};\z
        $L.env.hash.get('package').hash.get('loaded').hash.set(n,r)}\z
    else{console.error('preloaded chunk \\''+n+'\\' yielded during initialization');console.trace()}};")

--
-- load javascript
--

JavaScript("$L.require_js=$1", function(url)
    ::update_stack_frame::
    -- see 'require' for browser/worker/node.js checks
    JavaScript("if(!!(typeof window!=='undefined'&&typeof navigator!=='undefined'&&window.document)){")
    JavaScript(     "var elem=document.createElement('script')")
    JavaScript(     "elem.type='text/javascript'")
    JavaScript(     "(document.head||document.getElementsByTagName('head')[0]).appendChild(elem)")
    JavaScript(     "elem.onerror=elem.onload=$L.co.resume")
    JavaScript(     "elem.src=$1", url)
    JavaScript(     "yield*$L.cosuspend()")
    JavaScript("}else{")
    JavaScript(     "try{")
    JavaScript(         "if(typeof importScripts!=='undefined'){")
    JavaScript(             "importScripts($1)}", url)
    JavaScript(         "else{require($1)}", url)
    JavaScript(     "}catch(x){}}")
end)

--
-- load css
--

JavaScript("$L.require_css=$1", function(url, media)
    ::update_stack_frame::
    -- see 'require' for browser/worker/node.js checks
    JavaScript("if(!!(typeof window!=='undefined'&&typeof navigator!=='undefined'&&window.document)){")
    JavaScript(     "var elem=document.createElement('link')")
    JavaScript(     "elem.rel='stylesheet'")
    JavaScript(     "elem.type='text/css'")
    JavaScript(     "elem.media=$1", media or 'screen')
    JavaScript(     "(document.head||document.getElementsByTagName('head')[0]).appendChild(elem)")
    JavaScript(     "elem.onerror=elem.onload=$L.co.resume")
    JavaScript(     "elem.href=$1", url)
    JavaScript(     "yield*$L.cosuspend()}")
end)

--
-- fastcall
--
-- recompile (on the fly) an input generator function as a normal function,
-- replacing yield*(expr(args)) with (t0=expr,t0.fast||$L.fastcall(t0))(args).
-- store the new function as the property 'fast' on the old function.
--

JavaScript("$L.fastcall=function(func){\z
    if(func.prototype.toString()!=='[object Generator]'){return func.fast=func};\z
    var src=$L.fastcall_convert(func.toString());\z
    var idx1=src.indexOf('*');\z
    var idx2=src.indexOf('{');\z
    if(src.substr(idx2+1,5)==='/*U*/')$L.fastcall_error('upvalue reference');\z
    if(idx1>7&&idx1<idx2)src=src.substring(0,idx1)+' '+src.substring(idx1+1);\z
    src=\"'use strict';return \"+src.substring(0,idx2+1)+'var t0;'+src.substring(idx2+1);\z
    var fast=Function(src)();\z
    [func.fast,fast.self,fast.env,fast.file,fast.line]=[fast,fast,func.env,func.file,func.line];\z
    return fast};")

JavaScript("$L.fastcall_regex1=new RegExp('\\'|\\\"|yield\\*|[$$]frame[[]0]=[0-9]+;','g')")
JavaScript("$L.fastcall_regex2=new RegExp('[a-zA-Z0-9$$_.]')")

JavaScript("$L.fastcall_error=function(e){$L.error(e+\" in a function processed by 'fastcall'\").next()};")

JavaScript("$L.fastcall_convert=function(src){\z
    var txt='',idx=0,len;\z
    while(1){\z
        $L.fastcall_regex1.lastIndex=idx;\z
        var r=$L.fastcall_regex1.exec(src);\z
        if(r===null){return txt+src.substr(idx)}\z
        txt+=src.substring(idx,r.index);\z
        idx=r.index;\z
        if(r[0]===\"'\"||r[0]=='\"'){\z
            len=$L.fastcall_quote(src,idx,r[0]);\z
            txt+=src.substr(idx,len);\z
            idx+=len;\z
        }else if(r[0].charAt(0)==='$$'){\z
            idx+=r[0].length;\z
        }else{\z
            idx+=6;\z
            if(src.charAt(idx)==='(')\z
                len=$L.fastcall_parens(src,idx);\z
            else \z
                len=$L.fastcall_ident(src,idx);\z
            var callee=src.substr(idx,len).trim(),suffix=callee.substr(-6);\z
            if(suffix==='.apply')callee=callee.substring(0,callee.length-6);else suffix='';\z
            if(callee==='')$L.fastcall_error('cannot determine yield* callee');\z
            txt+='(t0='+$L.fastcall_convert(callee)+',t0.fast||$L.fastcall(t0))'+suffix;\z
            idx+=len;\z
        }}};")

JavaScript("$L.fastcall_quote=function(src,idx,quote){\z
    var len=1;\z
    while(1){\z
        var ch=src.charAt(idx+(len++));\z
        if(ch==='')$L.fastcall_error('mismatched quotes');\z
        if(ch===quote)return len;\z
        if(ch==='\\\\')len++;\z
    }};")

JavaScript("$L.fastcall_ident=function(src,idx){\z
    var len=0;\z
    while(1){\z
        var ch=src.charAt(idx+(len++));\z
        if(!$L.fastcall_regex2.test(ch))return len-1;\z
    }};")

JavaScript("$L.fastcall_parens=function(src,idx){\z
    if(src.charAt(idx)!=='(')return 0;\z
    var len=1,num=1;\z
    while(1){\z
        var ch=src.charAt(idx+(len++));\z
        if(ch==='')$L.fastcall_error('mismatched parentheses');\z
        if(ch===\"'\"||ch=='\"')len+=$L.fastcall_quote(src,idx+len-1,ch)-1;\z
        else if(ch==='(')num++;\z
        else if(ch===')'){num--;if(num===0)return len}\z
    }};")

--
-- prepare a stack frame for the main chunk
--

JavaScript("$L.co.stack.push($L.co.frame=[0,'',''])")

-- make $L global in node.js
JavaScript("if(typeof global==='object')global.$L=$L")

--
-- wrapper function for lua chunks.  (1) note that the first
-- definition for $L.chunk is in the definition of $L at the
-- very top this file.  that definition is used to process
-- this file.  (2) the execution of the core module replaces
-- $L.chunk with the function below, which will be used to
-- run the first lua module as the main coroutine.  (3) the
-- function below again replaces $L.chunk to its third form,
-- which is initially defined as $L.require_chunk, and is a
-- helper function for $L.require_lua.

JavaScript("$L.chunk=function(f){\z
    [$L.chunk,$L.require_chunk]=[$L.require_chunk,undefined];\z
    f.env=$L.env;\z
    var args=(typeof process==='object'&&typeof process.argv==='object')?process.argv.slice(2):[];\z
    var co=$L.cocreate(f).next().value[0];\z
    co.main=true;\z
    co.protected=-1;\z
    co.resume(args)}")

--
-- note that the dummy label ::update_stack_frame:: is only used to
-- force the generation of stack frame information, in functions that
-- start with JavaScript statements.  any label name would work.
--
