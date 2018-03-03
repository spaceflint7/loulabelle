

local class = {}
local jspfx = package.JavaScript and "Loulabelle*" or ""
local StateStack = require(jspfx.."statestack")


function class.generate(tree)

    local self = {
        text={},
        sub_block_level=0,
        loop_level=0,
        jsdefs="",
        locals=StateStack.new(),
        error=nil,
        next_label=0 }

    for k,_ in pairs(class) do self[k] = class[k] end

    self.jsobject = tree.jsobject
    if not self.jsobject then
        if package.JavaScript then  -- compiled compiler
            local jsobj
            JavaScript("$1='$L'", jsobj)
            self.jsobject = jsobj
        else                        -- command line compiler
            self.jsobject = "$lua"
        end
    end

    self.debug = tree.debug
    self.JavaScript = tree.JavaScript
    self.globals = tree.globals

    self.jsyield     = "yield*" .. self.jsobject .. "."
    self.jsyieldget  = "(" .. self.jsyield .. "get("
    self.jsyieldcall = self.jsyield .. "call("
    self.strcoll     = self.jsobject .. ".strcoll("

    self.indent = tonumber(tree.indent)
    if self.indent then self.indent = string.rep(" ", self.indent)
    else self.indent = "\t" end

    self.chunk_name = self:escape_name(tree.chunk or "?")

    if tree.type == "chunk" then tree = tree.block end

    self.env_var_node = { type="var", var="_ENV" }

    self.locals:push()
    self.locals:set(self.env_var_node.var, "env")       -- variable _ENV
    self.locals:set("#", 1)                             -- first local is $1

    self:put(self.jsobject)
    self:put(".chunk(\n");
    self:func_head()
    self:putln()
    self:put("'use strict';func.args=Array.from(arguments);");
    self.locals:set("...", "func.args")

    self:func_body(tree, true, 1)
    if self.error then return nil, self.error end
    self:put(");")

    if self.jsdefs ~= "" then
        if self.debug then self.jsdefs = self.jsdefs .. "\n" end
        table.insert(self.text, 1, self.jsdefs)
    end
    return table.concat(self.text)

end


function class:func_head(args)

    self.locals:push()
    local var_base = self.locals:get("#")

    self:put(self.jsobject)
    self:put(".func(function*func")

    local arg = args
    args = {}

    while arg do
        if arg.type ~= "var" or (not arg.var) then break end
        if arg.var == "..." and arg.next then break end
        args[#args + 1] = arg.var
        arg = arg.next
    end
    if arg then self.error = "Internal error in function arguments" return end

    self.locals:set("...", nil)
    self:put("(")

    for i = 1, #args do

        local var_name = "a" .. tostring(i + var_base - 1)
        self.locals:set(args[i], var_name)

        if i > 1 then self:put(",") end
        if args[i] == "..." then self:put("...") end
        self:put(var_name)
    end

    self:put("){")

    self.locals:set("##", var_base) -- save old var_base to determine upvalues
    self.locals:set("#", var_base + #args)
    self.locals:set("%", 0) -- for_depth, keeps track of 'for' control variables

end


function class:func_body(stmt, is_main_chunk, func_line)

    --
    -- determine the number of locals in use by this function,
    -- then generate code for the function
    --

    local var_base = self.locals:get("#")
    local num_vars, for_depth = self:count_locals(stmt, 0, var_base)
    self.locals:set("#", var_base + num_vars)

    self.locals:set("#ti", 1)   -- next temp var to give out
    self.locals:set("#tj", 0)   -- highest temp var given out

    local var_pos1 = #self.text + 1
    self:putln()
    local var_pos2 = #self.text + 1
    self:put("var")

    local save_env_node_used = self.env_var_node.used
    self.env_var_node.used = is_main_chunk

    local save_upvalue_ref = self.upvalue_ref
    self.upvalue_ref = nil

    self:process_block(stmt, is_main_chunk, true)

    --
    -- insert variable declarations at the top of the function
    --

    local var_line, sep = "", " "

    if self.env_var_node.used then
        var_line = var_line .. " env=func.env"
        sep = ","
    end

    for i = 1, num_vars do
        var_line = var_line .. sep .. "v" .. tostring(i + var_base - 1)
        sep = ","
    end

    for i = 1, self.locals:get("#tj") do
        var_line = var_line .. sep .. "t" .. tostring(i)
        sep = ","
    end

    for i = 1, for_depth do
        local istr = tostring(i)
        var_line = var_line .. sep .. "x" .. istr .. ",y" .. istr .. ",z" .. istr
        sep = ","
    end

    if var_line == "" then
        for i = var_pos1, var_pos2 do
            table.remove(self.text, var_pos1)
        end
    else
        self.text[var_pos2] = self.text[var_pos2] .. var_line .. ";"
    end

    if self.debug and self.upvalue_ref then
        table.insert(self.text, var_pos1, "/*U*/")
    end

    --
    -- end the function and its local scope
    --

    self.upvalue_ref = save_upvalue_ref
    self.env_var_node.used = save_env_node_used

    self.locals:pop()
    self:putln()
    self:put("},")
    self:put(is_main_chunk and (self.jsobject .. ".env") or "func.env")

    if self.debug then
        self:put(",")
        if is_main_chunk then
            self:put("'")
            self:put(self.chunk_name)
            self:put("'")
        else
            self:put("func.file")
        end
        self:put(",")
        self:put(tostring(func_line or 0))
    end

    self:put(")")

end


function class:count_locals(stmt, num_vars, var_base)

    local for_depth = 0

    while stmt do

        if stmt.type == "for" or (stmt.type == "assign" and stmt["local"]) then
            stmt.var_num = var_base + num_vars
            num_vars = num_vars + stmt.vars.count
            if stmt.type == "for" and for_depth == 0 then for_depth = 1 end
        end

        for _,fld in pairs(self.sub_block_fields) do
            if stmt[fld] then
                local for_depth2
                num_vars, for_depth2 = self:count_locals(stmt[fld], num_vars, var_base)
                for_depth = for_depth + for_depth2
            end
        end

        stmt = stmt.next
    end

    return num_vars, for_depth

end

class.sub_block_fields = { "block", "then", "else", "elseif" }


function class:get_temp_var()

    local ti = self.locals:get("#ti")       -- next temp var to give out
    if ti > self.locals:get("#tj") then
        self.locals:set("#tj", ti)          -- highest temp var given out
    end
    self.locals:set("#ti", ti + 1)
    return "t" .. tostring(ti)

end


function class:get_set_temp_var(val)

    if val then self.locals:set("#ti", val)
    else return self.locals:get("#ti") end

end


function class:pop_locals_keep_temp()

    local tj = self.locals:get("#tj")
    self.locals:pop()
    self.locals:set("#tj", tj)

end


function class:process_block(stmt, is_main_chunk, is_function_start)

    local linenum_initialized = not is_function_start

    while stmt do

        self:putln()

        if self.JavaScript and stmt.type == "call"
            and stmt.func.type == "var"
            and stmt.func.var == "JavaScript" then

            --if self.JavaScript == false then
            --    self.error = "JavaScript statement not permitted"
            --else
                self:javascript_stmt(stmt.args)
            --end

        else

            if self.debug then

                if not linenum_initialized then
                    self:put("var $frame=")
                    self:put(self.jsobject)
                    self:put(".co.frame||[];")
                    self:putln()
                    if is_main_chunk then
                        self:put("$frame[1]='")
                        self:put(self.chunk_name)
                        self:put("';")
                        self:putln()
                        self:put("$frame[2]='main chunk';")
                        self:putln()
                    end
                    linenum_initialized = true
                    self.last_linenum_written = nil
                end

                local linenum_to_write = tostring(stmt.line or 0)
                if linenum_to_write ~= self.last_linenum_written then
                    self:put("$frame[0]=")
                    self:put(linenum_to_write)
                    self:put(";")
                    self:putln()
                    self.last_linenum_written = linenum_to_write
                end
            end

            if stmt.type == "assign" then
                self:assign_stmt(stmt)
            elseif stmt.type == "return" then
                self:return_stmt(stmt, is_function_start)
            elseif stmt.type == "call" or stmt.type == "method" then
                local s = self:expr(stmt)
                if s:sub(1,1) == "(" then s = s:sub(2,-2) end
                self:put(s)
                self:put(";")

            elseif stmt.type == "break" or stmt.type == "continue" then
                self:put(stmt.type)
                if stmt.target then
                    self:put(" ")
                    self:put(stmt.target.label)
                end
                self:put(";")
            elseif stmt.type == "goto" then
                self.error = "Unsupported goto"
            elseif stmt.type == "label" then
                ;

            elseif stmt.type == "do" then
                self:process_sub_block(stmt.block, 0, 0, true)
            elseif stmt.type == "if" then
                self:if_stmt(stmt)
            elseif stmt.type == "while" then
                self:while_stmt(stmt)
            elseif stmt.type == "repeat" then
                self:repeat_stmt(stmt)
            elseif stmt.type == "for" then
                self:for_stmt(stmt)

            else
                self.error = "Internal error in statement " .. (stmt.type or "?")
            end
        end

        if self.error then
            if not self.error_line then
                self.error = self.error .. " in line " .. tostring(stmt.line or 0)
                self.error_line = true
            end
            return
        end

        stmt = stmt.next
    end

end


function class:process_sub_block(stmt, sub_block_incr, loop_incr, push_pop_locals)

    self.sub_block_level = self.sub_block_level + sub_block_incr
    self.loop_level = self.loop_level + loop_incr
    if push_pop_locals then self.locals:push() end

    if loop_incr == 1 and stmt then self:process_goto(stmt, stmt.parent, false) end
    self:process_block(stmt)

    if push_pop_locals then
        local ti = self.locals:get("#ti")
        self:pop_locals_keep_temp()
        self.locals:set("#ti", ti)
    end
    self.sub_block_level = self.sub_block_level - sub_block_incr
    self.loop_level = self.loop_level - loop_incr

end


function class:process_goto(stmt, loop_stmt, inner_loop)

    while stmt do

        if stmt.child then

            local inner_loop_2 = inner_loop
            if stmt.type == "for" or stmt.type == "repeat" or stmt.type == "while" then
                inner_loop_2 = true
            end

            self:process_goto(stmt.child, loop_stmt, inner_loop_2)
            if stmt.child2 then self:process_goto(stmt.child2, loop_stmt, inner_loop_2) end

        elseif stmt.type == "goto" then

            local new_stmt_type

            local target = stmt.target
            if target and target.type == "label" then

                if target.parent == loop_stmt and not target.next then
                    new_stmt_type = "continue"
                elseif target.prev and target.prev == loop_stmt then
                    new_stmt_type = "break"
                end
            end

            if new_stmt_type then
                stmt.type = new_stmt_type
                if inner_loop then
                    if not loop_stmt.label then
                        self.next_label = self.next_label + 1
                        loop_stmt.label = "L" .. tostring(self.next_label)
                    end
                    stmt.target = loop_stmt
                else
                    stmt.target = nil
                end
            end
        end

        stmt = stmt.next
    end

end


function class:assign_stmt(stmt)

    -- evaluate all expressions on the right side of the assignment

    local vals = {}
    local multivals = {}
    local nvals = 0

    local val = stmt.vals
    while val do
        nvals = nvals + 1
        vals[nvals], multivals[nvals] = self:expr(val)
        val = val.next
        if self.error then return end
    end

    -- assign each right-side expression to each left-side variable

    local var_base = stmt.var_num
    local var_index = 0
    local tmp
    local save_tmp_var = self:get_set_temp_var()    -- save

    local var = stmt.vars
    while var do

        if var_base then
            self.locals:set(var.var, "v" .. tostring(var_base + var_index))
        end
        var_index = var_index + 1

        var.in_assign = true
        local var_name = self:expr(var)
        if not var_name then break end
        local var_value

        if var_index >= nvals then

            --
            -- handle the case where the last value is an explist/array:
            --
            -- a.  if there are multiple remaining variables, assign the
            -- array to a temporary variable, and each of the remaining
            -- variables gets array[i].
            --
            -- b.  if there is one remaining variable, it gets array[0].
            --
            -- c.  if the last value is not an explist, variables are
            -- set to undefined.  except if a statement outside a loop
            -- declares new variables, because those would be initialized
            -- to undefined anyway.
            --

            if var_index == nvals and var.next and multivals[nvals] then
                tmp = self:get_temp_var()
                self:put(tmp .. "=")
                self:put(vals[nvals])
                self:put(";")
                self:putln()
            end

            if tmp then
                var_value = tmp .. "[" .. tostring(var_index - 1) .. "]"

            elseif var_index > nvals then
                var_value = var_base and "" or "undefined"
            end

        end

        if not var_value then
            var_value = self:adjust_multival_expr(vals[var_index], multivals[var_index])
        end

        if var_value == "" and self.loop_level > 0 then var_value = "undefined" end

        if var_value ~= "" then

            if var_name:sub(1,#self.jsyieldget) == self.jsyieldget then

                self:put(self.jsyield)
                self:put("s")   -- 'set' instead of 'get'
                self:put(var_name:sub(#self.jsyieldget-2,-3))
                if not self.debug then self:put(",undefined") end
                self:put(",")
                self:put(var_value)
                self:put(");")

            else

                self:put(var_name)
                self:put("=")
                self:put(var_value)
                self:put(";")
            end

            if var.next then self:putln() end
        end

        var = var.next
        if self.error then return end

    end

    self:get_set_temp_var(save_tmp_var)             -- restore

end


function class:return_stmt(stmt, toplevel)

    -- evaluate all expressions to return

    local vals = {}
    local multivals = {}
    local nvals = 0

    local val = stmt.vals
    while val do
        nvals = nvals + 1
        vals[nvals], multivals[nvals] = self:expr(val)
        val = val.next
        if self.error then return end
    end

    -- construct return statement

    if nvals == 0 then

        if not toplevel then self:put("return;") end

    elseif multivals[nvals] then

        if nvals == 1 then

            -- returning a single expression of multiple values

            self:put("return ")
            self:put(vals[nvals])
            self:put(";")

        else

            -- if the last value is already an explist/array then we
            -- need to insert all preceding values at the start of that
            -- array and we are done

            local tmp = self:get_temp_var()

            self:put(tmp .. "=")
            self:put(vals[nvals])
            self:put(";")
            self:putln()
            self:put(tmp .. ".unshift(")
            for i = 1, nvals - 1 do
                local val = vals[i]
                if multivals[i] then val = "(" .. val .. ")[0]" end
                if i > 1 then self:put(",") end
                self:put(val)
            end
            self:put(");")
            self:putln()
            self:put("return " .. tmp .. ";")

        end

    else

        -- combine all return values into an array, except any
        -- trailing nil/undefined values that can be discarded

        local tmp
        if self.debug then
            tmp = self:get_temp_var()
            self:put(tmp .. "=[")
        else
            self:put("return[")
        end

        while nvals > 0 and (not multivals[nvals]) and vals[nvals] == "undefined" do
            nvals = nvals - 1
        end

        for i = 1, nvals do
            local val = vals[i]
            if multivals[i] then val = "(" .. val .. ")[0]" end
            if i > 1 then self:put(",") end
            self:put(val)
        end

        self:put("];")

        if self.debug then
            self:putln()
            self:put("return " .. tmp .. ";")
        end

    end

end


function class:javascript_stmt(args)

    if args.type == "str" and args.str then

        local string = self:escape_text("\t" .. args.str:sub(2,-2) .. "\t"):sub(2,-2)

        local arg = args.next
        while arg do
            args[#args+1] = arg
            arg = arg.next
        end

        local newstring = ""
        local i = 1
        local n = #string
        while i <= n do
            local c = string:sub(i,i)
            if c == "$" then
                i = i + 1
                c = string:sub(i,i)
                if c >= "0" and c <= "9" then
                    arg = args[c - "0"]
                    if arg then c = self:expr(arg)
                    else newstring = "" break end
                elseif c == "L" then c = self.jsobject
                elseif c ~= "$" then newstring = "" break end
            end
            newstring = newstring .. c
            i = i + 1
        end

        if #newstring > 0 then

            if newstring:sub(1,11) == "public var " then
                self.jsdefs = self.jsdefs .. newstring:sub(8) .. ";"
                -- if self.debug then table.remove(self.text, #self.text - 1) end -- undo last putln()
            --elseif newstring == "debug" then
            --    self.debug = (args and type(args[1]) == "table" and args[1].bool or false)
            else
                self:put(newstring)
                local c = string:sub(-1,-1)
                if c ~= "{" and c ~= "}" and c ~= ";" then self:put(";") end
            end

            return
        end
    end

    self.error = "Error in JavaScript statement"

end


function class:if_stmt(stmt, debug_line_number)

    self:put("if(")
    if debug_line_number then
        self:put("$frame[0]=")
        self:put(debug_line_number)
        self:put(",")
    end
    self:put(self:bool_expr(stmt["cond"]))
    self:put("){")

    self:process_sub_block(stmt["then"], 1, 0, true)

    self:putln()
    if stmt["else"] or stmt["elseif"] then
        self:put("}else ")
        if stmt["else"] then
            self:put("{")
            self:process_sub_block(stmt["else"], 1, 0, true)
            self:putln()
            self:put("}")
        else
            local line = self.debug and tostring(stmt["elseif"].line or 0)
            if line == self.last_linenum_written then line = nil end
            self:if_stmt(stmt["elseif"], line)
        end
    else
        self:put("}")
    end

end


function class:while_stmt(stmt)

    local label_pos = #self.text + 1
    self:put("while(")
    self:put(self:bool_expr(stmt["cond"]))
    self:put("){")
    self:process_sub_block(stmt["block"], 1, 1, true)
    self:pushlbl(label_pos, stmt.label)
    self:putln()
    self:put("}")

end


function class:repeat_stmt(stmt)

    local label_pos = #self.text + 1
    self.locals:push()
    self:put("do{")
    self:process_sub_block(stmt["block"], 1, 1, false)
    self:pushlbl(label_pos, stmt.label)
    self:putln()
    self:put("}while(!(")
    self:put(self:bool_expr(stmt["until"]))
    self:put("));")
    self:pop_locals_keep_temp()

end


function class:for_stmt(stmt)

    local for_depth = self.locals:get("%") + 1
    self.locals:set("%", for_depth)
    local xvar = "x" .. tostring(for_depth)
    local yvar = "y" .. tostring(for_depth)
    local zvar = "z" .. tostring(for_depth)

    if stmt.expr then
        self:for_generic(stmt, xvar, yvar, zvar)
    else
        self:for_numeric(stmt, xvar, yvar, zvar)
    end

    self.sub_block_level = self.sub_block_level - 1

    self:putln()
    self:put("}")

    self.locals:set("%", for_depth - 1)

end


function class:for_generic(stmt, xvar, yvar, zvar)

    -- we need to assign the explist in the generic for statement to the
    -- loop control variables x,y,z.  we want to reuse the logic from
    -- assign_stmt() so we need to adjust the stmt node a bit

    local stmt_vars = stmt.vars
    local stmt_var_num = stmt.var_num
    stmt.var_num = nil

    self.locals:push()
    self.sub_block_level = self.sub_block_level - 1 -- keep same indent

    self.locals:set("x", xvar)
    self.locals:set("y", yvar)
    self.locals:set("z", zvar)

    stmt.vars = { type="var", var="x", next={ type="var", var="y", next={ type="var", var="z" } } }
    stmt.vals = stmt.expr

    self:assign_stmt(stmt)
    self:putln()

    self.sub_block_level = self.sub_block_level + 1
    self:pop_locals_keep_temp()
    stmt.var_num = stmt_var_num
    stmt.vars = stmt_vars

    -- write the rest of the for loop

    local label_pos = #self.text + 1
    self:put("while(1){")

    self.sub_block_level = self.sub_block_level + 1
    self:putln()

    local tmp = self:get_temp_var()
    self:put(tmp .. "=(" .. self.jsyieldcall .. "'?'," .. xvar .. "," .. yvar .. "," .. zvar .. "));")
    self:putln()
    self:put(zvar .. "=" .. tmp .. "[0];")
    self:putln()
    self:put("if(" .. zvar .. "==undefined)break;")

    local var_base = stmt.var_num
    local var_index = 0

    local var = stmt.vars
    while var do

        if var_base then
            self.locals:set(var.var, "v" .. tostring(var_base + var_index))
        end

        self:putln()
        self:put(self:expr(var))
        if var_index == 0 then
            self:put("=" .. zvar .. ";")
        else
            self:put("=" .. tmp .. "[" .. tostring(var_index) .. "];")
        end

        var_index = var_index + 1
        var = var.next
        if self.error then return end
    end

    self:process_sub_block(stmt["block"], 0, 1, true)
    self:pushlbl(label_pos, stmt.label)

end


function class:for_numeric(stmt, xvar, yvar, zvar)

    --
    -- note in the segment below we call self:expr before checking
    -- the node type, this lets us take advantage of constant folding
    --

    local initial = self:expr(stmt.initial)
    self:put(xvar .. "=" .. initial .. ";")
    if stmt.initial.type ~= "num" then
        self:put("if(typeof " .. xvar .. "!=='number')")
        self:put(xvar .. "=" .. self.jsyield .. "tonumber(" .. xvar .. ");")
        self:putln()
        self:put("if(" .. xvar .. "===undefined)" .. self.jsyield .. "error_for1();")
        initial = nil
    end
    self:putln()

    local limit = self:expr(stmt.limit)
    if stmt.limit.type == "num" then
        yvar = tonumber(limit)
    else
        self:put(yvar .. "=" .. limit .. ";")
        self:put("if(typeof " .. yvar .. "!=='number')")
        self:put(yvar .. "=" .. self.jsyield .. "tonumber(" .. yvar .. ");")
        self:putln()
        self:put("if(" .. yvar .. "===undefined)" .. self.jsyield .. "error_for2();")
        self:putln()
    end

    local zvar_const = true
    if stmt.step then
        local step = self:expr(stmt.step)
        if stmt.step.type == "num" then
            zvar = tonumber(step)
        else
            self:put(zvar .. "=" .. step .. ";")
            self:put("if(typeof " .. zvar .. "!=='number')")
            self:put(zvar .. "=" .. self.jsyield .. "tonumber(" .. zvar .. ");")
            self:putln()
            self:put("if(" .. zvar .. "===undefined)" .. self.jsyield .. "error_for3();")
            self:putln()
            zvar_const = false
        end
    else zvar = 1 end

    local label_pos = #self.text + 1
    self:put("while(")
    if zvar_const then
        self:put(xvar)
        self:put((zvar > 0) and "<=" or ">=")
        self:put(yvar)
    else
        self:put("(" .. zvar .. ">0&&" .. xvar .. "<=" .. yvar .. ")")
        self:putln()
        self:put("||")
        self:put("(" .. zvar .. "<=0&&" .. xvar .. ">=" .. yvar .. ")")
    end
    self:put("){")

    self.sub_block_level = self.sub_block_level + 1
    self:putln()

    self.sub_block_level = self.sub_block_level - 1 -- keep same indent

    self.locals:set(stmt.vars.var, "v" .. tostring(stmt.var_num))
    self:put(self:expr(stmt.vars))
    self:put("=")
    self:put(xvar)
    self:put(";")

    local first_stmt_in_block = stmt["block"]
    local last_stmt_in_block = first_stmt_in_block
    if last_stmt_in_block then
        while last_stmt_in_block.next do
            last_stmt_in_block = last_stmt_in_block.next
        end
    end

    self:process_sub_block(first_stmt_in_block, 0, 1, true)
    self:pushlbl(label_pos, stmt.label)

    self.sub_block_level = self.sub_block_level + 1 -- restore indent

    if (not last_stmt_in_block) or last_stmt_in_block.type ~= "return" then

        self:putln()
        self:put(xvar)
        if zvar_const and zvar < 0 then
            self:put("-=")
            self:put(-zvar)
        else
            self:put("+=")
            self:put(zvar)
        end
        self:put(";")
    end

end


function class:expr(node)

    local save_tmp_var = self:get_set_temp_var()    -- save

    local expr_result, expr_multival = (function()

        local node_type = node.type

        if node_type == "method" and node.table and (node.field or node.index) then
            return self:expr_method(node)

        elseif node_type == "call" and node.func then
            return self:expr_call(node)

        elseif node_type == "member" and node.table and (node.field or node.index) then
            local field = node.field and ("'" .. node.field.var .. "'")
            return self:expr_get(node.table, field, node.index, node.in_assign)

        elseif node_type == "function" and not node.name then
            return self:expr_func(node)

        elseif node_type == "table" then
            return self:expr_table(node.block)

        elseif node_type == "var" and node.var then
            local var_name = self.locals:get(node.var)
            if var_name then
                if node.var == self.env_var_node.var then
                    self.env_var_node.used = true
                end
                local var_num = tonumber(var_name:sub(2))
                if var_num and var_num < self.locals:get("##") then
                    self.upvalue_ref = true
                end
                return var_name
            end
            local in_assign = node.in_assign
            if in_assign and not self.globals then
                self.error = "Assignment to global '" .. node.var .. "'"
                return nil
            end
            self.env_var_node.used = true
            return self:expr_get(self.env_var_node, "'" .. node.var .. "'", nil, in_assign)

        elseif node_type == "..." then
            local nm = self.locals:get(node_type)
            if nm then return nm, true end

        elseif node_type == "num" and node.num then
            return node.num

        elseif node_type == "str" and node.str then
            return self:escape_text(node.str)

        elseif node_type == "bool" then
            return node.bool and "true" or "false"

        elseif node_type == "nil" then
            return "undefined"

        elseif node.operand or (node.operand1 and node.operand2) then
            local ret = self:expr_op(node)
            return ret

        end

        self.error = "Internal error in expression " .. (node_type or "")
        return ""

    end)()

    self:get_set_temp_var(save_tmp_var)             -- restore

    return expr_result, expr_multival

end


function class:expr_method(node)

    local s = "("

    local node_type = node.type
    node.type = "member"

    local table
    if node.table.type == "var" then table = self.locals:get(node.table.var) end
    if not table then
        local node_table_expr = self:adjust_multival_expr(self:expr(node.table))
        local table_tmp = self:get_temp_var()
        s = s .. table_tmp .. "=" .. node_table_expr .. ","
        table = table_tmp
        if self.error then return "" end
    end

    local table_debug_name = self.debug and ("," .. self:debug_name(node.table)) or ""
    local field = node.field and ("'" .. node.field.var .. "'") or self:expr(node.index)
    local field_tmp = self:get_temp_var()
    s = s .. field_tmp .. "=" .. self.jsyieldget:sub(2) .. table .. "," .. field .. table_debug_name .. "),"
    if self.error then return "" end

    local args, multival = self:expr_call_args(node)
    if self.error then return "" end

    if self.debug or multival then
        local field_debug_name = self.debug and self:debug_name(node) or "undefined"
        s = s .. self.jsyieldcall .. field_debug_name .. "," .. field_tmp .. ","
    else
        s = s .. "(yield*(typeof " .. field_tmp .. "==='function'&&" .. field_tmp .. ".self||(" .. self.jsyield .. "resolve(" .. field_tmp .. ")))("
    end

    s = s .. table
    if args ~= "" then s = s .. "," .. args end
    s = s .. ")"
    if not (self.debug or multival) then s = s .. ")||[]" end
    s = s .. ")"

    node.type = node_type

    if node.parens then return s .. "[0]"
    else return s, true end

end


function class:expr_call(node)

    local s = "("

    local func = self:adjust_multival_expr(self:expr(node.func))
    if self.error then return "" end

    local args, multival = self:expr_call_args(node)
    if self.error then return "" end

    if self.debug or multival then

        local func_debug_name = self.debug and self:debug_name(node) or "undefined"
        s = s .. self.jsyieldcall .. func_debug_name .. "," .. func
        if args ~= "" then s = s .. "," end

    else

        local func_var = (node.func.type == "var") and self.locals:get(node.func.var)
        if func_var then
            func = func_var
        else
            local node_func_expr = self:adjust_multival_expr(self:expr(node.func))
            local func_tmp = self:get_temp_var()
            s = s .. func_tmp .. "=" .. node_func_expr .. ","
            func = func_tmp
            if self.error then return "" end
        end

        s = s .. "(yield*(typeof " .. func .. "==='function'&&" .. func .. ".self||(" .. self.jsyield .. "resolve(" .. func .. ")))("

    end

    s = s .. args .. ")"
    if not (self.debug or multival) then s = s .. ")||[]" end
    s = s .. ")"

    if node.parens then return s .. "[0]"
    else return s, true end

end


function class:expr_call_args(node)

    local result = ""
    local args = node.args
    local tmp, multival
    while args do
        tmp, multival = self:expr(args)
        if tmp == "" then break end
        if multival and args.next then tmp = "(" .. tmp .. ")[0]" end
        if result ~= "" then result = result .. "," end
        result = result .. tmp
        args = args.next
    end
    return result, multival

end


function class:expr_func(node)

    local s = ""
    local save_text = self.text
    self.text = {}
    self:func_head(node.args)
    if not self.error then
        self:func_body(node.block, false, node.line)
        if not self.error then
            s = table.concat(self.text)
        end
    end
    self.text = save_text
    return s

end


function class:expr_table(node0)

    local t1, n1 = {}, 0
    local t2, n2 = {}, 0
    local node = node0
    while node do
        if node.type ~= "field" then
            self.error = "Internal error in table constructor"
        elseif node.key then
            n1 = n1 + 1
            t1[n1] = { self:adjust_multival_expr(self:expr(node.key)), self:adjust_multival_expr(self:expr(node.val)) }
        else
            n2 = n2 + 1
            if node.next then
                t2[n2] = self:adjust_multival_expr(self:expr(node.val))
            else
                t2[n2] = self:expr(node.val)
            end
        end
        node = node.next
        if self.error then return "" end
    end

    local save_text = self.text
    self.text = {}

    self:put(self.jsyield)
    self:put("table(")
    if n1 > 0 or n2 > 0 then
        self:put("[")
        self:putln()
        for i = 1, n1 do
            self:put(t1[i][1])
            self:put(",")
            self:put(t1[i][2])
            if i ~= n1 then
                self:put(",")
                self:putln()
            end
        end
        if n2 > 0 then
            if n1 > 0 then
                self:put(",")
                self:putln()
            end
            for i = 1, n2 do
                self:put(t2[i])
                if i ~= n2 then
                    self:put(",")
                    self:putln()
                end
            end
        end
        self:putln()
        self:put("],")
        self:put(n1 * 2)
        self:put(",")
        self:put(n2)
    end
    self:put(")")

    local s = table.concat(self.text)
    self.text = save_text
    return s

end


function class:expr_op(node)

    if not node.simplified then
        self:expr_op_simplify(node)
        local have_operand =
            node.operand or (node.operand1 and node.operand2)
        if not have_operand then return self:expr(node) end
    end

    local s
    local suffix = (self.debug and ",true" or "") .. "))"

    local is_var = function(node) return node.var and self.locals:get(node.var) end

    local is_const = function(node)
        local node_type = node.type
        return node_type == "nil" or node_type == "bool"
            or node_type == "num" or node_type == "str"
    end

    local is_sub_expr = function(node)
        -- we want to avoid a costly call to the operator function (e.g. $L.add)
        -- where we can just do the operation inline (e.g., $1+$2).  and note also
        -- this requires checking the operand type at runtime.
        -- however, all of the above only makes sense for nodes that are variables
        -- or sub-expression.  for other nodes, we always call the operator function.
        local node_type = node.type
        return node_type == "call" or node_type == "method"
            or node_type == "member" or node_type == "var"
            or node.operand or node.operand1 or node.operand2
    end

    local temp_v_ = function(v,node_operand)
        if     node_operand.type == "nil"
            or node_operand.type == "bool"
            or node_operand.type == "num"
            or is_var(node_operand) then return v end
        local tmp = self:get_temp_var()
        s = s .. tmp .. "=" .. v .. ","
        return tmp
    end

    local node_type = node.type

    if node.operand then    -- unary

        local op = node.operand
        op.parens = true
        local v = self:expr(op)
        local function temp_v() v = temp_v_(v,op) end

        local unary_op = function(op_type, op_name, op_func)
            s = "("
            if is_sub_expr(op) then
                temp_v()
                s = s .. "typeof " .. v .. "==='" .. op_type .. "'" .. "?" .. op_func(v) .. ":"
            end
            return s .. self.jsyield .. op_name .. "(" .. v .. suffix
        end

        if node_type == "-" then
            return unary_op("number", "unm", function(v) return "-" .. v end)

        elseif node_type == "#" then
            return unary_op("string", "len", function(v) return v .. ".length" end)

        elseif node_type == "not" then
            if self:is_bool_node(op) then
                if op.type == "not" then
                    op.double_not = true
                    return self:expr(op)
                else
                    return "!(" .. v .. ")"
                end
            end
            s = "("
            temp_v()
            if node.double_not then
                s = s .. v .. "!==undefined&&" .. v .. "!==false?true:false)"
            else
                s = s .. v .. "===undefined||" .. v .. "===false?true:false)"
            end
            return s
        end

    else                    -- binary

        local op1 = node.operand1
        local op2 = node.operand2
        op1.parens = true
        op2.parens = true
        local v1 = self:expr(op1)
        local v2

        local function temp_v()
            v1 = temp_v_(v1,op1)
            v2 = self:expr(op2)
            v2 = temp_v_(v2,op2)
        end

        local binary_op = function(op_type, op_name, op_func)

            -- check that both operands are variable, sub-expression, number or string.
            -- if either operand fails the check, we go straight to the operator function.
            local const_type = op_type:sub(1, 3)    -- "str" or "num"
            local const1   = op1.type == const_type
            local const2   = op2.type == const_type
            local subexpr1 = is_sub_expr(op1)
            local subexpr2 = is_sub_expr(op2)
            if (not (const1 or subexpr1)) or (not (const2 or subexpr2)) then
                v2 = self:expr(op2)
                return "(" .. self.jsyield .. op_name .. "(" .. v1 .. "," .. v2 .. suffix
            end

            s = "("
            temp_v()
            local check1, check2 = true, true
            if const1 then check1 = false
            elseif const2 then check2 = false
            elseif op1.var and op1.var == op2.var then check2 = false end

            if check1 then s = s .. "typeof " .. v1 .. "==='" .. op_type .. "'" end
            if check1 and check2 then s = s .. "&&" end
            if check2 then s = s .. "typeof " .. v2 .. "==='" .. op_type .. "'" end
            s = s .. "?" .. op_func(v1, v2) .. ":" .. self.jsyield .. op_name .. "(" .. v1 .. "," .. v2 .. suffix
            return s
        end

        local compare_op = function(op_name, op_func, equality)

            local negate = op_name:sub(1,1)
            if negate == "!" then op_name = op_name:sub(2) else negate = "" end

            -- check that both operands are variable, sub-expression, number or string.
            -- if either operand fails the check, we go straight to the operator function.
            local const1   = is_const(op1)
            local const2   = is_const(op2)
            local subexpr1 = is_sub_expr(op1)
            local subexpr2 = is_sub_expr(op2)
            if (not (const1 or subexpr1)) or (not (const2 or subexpr2)) then
                v2 = self:expr(op2)
                return negate .. "(" .. self.jsyield .. op_name .. "(" .. v1 .. "," .. v2 .. suffix
            end

            s = "("

            if equality then

                if const1 or const2 then

                    v2 = self:expr(op2)
                    return op_func(v1, v2)

                else

                    temp_v()
                    s = s .. op_func(v1, v2) .. "||("
                            .. "typeof " .. v1 .. "==='object'&&"
                            .. "typeof " .. v2 .. "==='object'&&"
                    suffix = suffix .. ")"

                end

            else

                local num1, num2, str1, str2
                num1 = op1.type == "num" and tonumber(op1.num)
                num2 = op2.type == "num" and tonumber(op2.num)
                str1 = op1.type == "str" and op1.str
                str2 = op2.type == "str" and op2.str

                if str1 and str2 then

                    return op_func(str1, str2, true)

                elseif (str1 and subexpr2) or (subexpr1 and str2) then

                    temp_v()
                    s = s .. "typeof " .. (str1 and v2 or v1)
                          .. "==='string'"
                          .. "?" .. op_func(v1, v2, true) .. ":"

                elseif (num1 and subexpr2) or (subexpr1 and num2) then

                    temp_v()
                    s = s .. "typeof " .. (num1 and v2 or v1)
                          .. "==='number'"
                          .. "?" .. op_func(v1, v2) .. ":"

                elseif (subexpr1 and subexpr2) then

                    temp_v()
                    s = s .. "(typeof " .. v1 .. "==='number'&&"
                          .. "typeof " .. v2 .. "==='number')"
                          .. "?" .. op_func(v1, v2) .. ":"
                          .. "(typeof " .. v1 .. "==='string'&&"
                          .. "typeof " .. v2 .. "==='string')"
                          .. "?" .. op_func(v1, v2, true) .. ":"

                else v2 = self:expr(op2) end

            end

            if negate then s = s .. negate .. "(" end
            s = s .. self.jsyield .. op_name .. "(" .. v1 .. "," .. v2 .. suffix
            if negate then s = s .. ")" end

            return s
        end

        if node_type == "+" then
            return binary_op("number", "add", function(v1,v2) return v1 .. "+" .. v2 end)

        elseif node_type == "-" then
            return binary_op("number", "sub", function(v1,v2) return v1 .. "-" .. v2 end)

        elseif node_type == "*" then
            return binary_op("number", "mul", function(v1,v2) return v1 .. "*" .. v2 end)

        elseif node_type == "/" then
            return binary_op("number", "div", function(v1,v2) return v1 .. "/" .. v2 end)

        elseif node_type == "%" then
            return binary_op("number", "mul", function(v1,v2) return v1 .. "-Math.floor(" .. v1 .. "/" .. v2 .. ")*" .. v2 end)

        elseif node_type == "^" then
            return binary_op("number", "pow", function(v1,v2) return "Math.pow(" .. v1 .. "," .. v2 .. ")" end)

        elseif node_type == ".." then
            return binary_op("string", "concat", function(v1,v2) return v1 .. "+" .. v2 end)

        elseif node_type == "==" then
            return compare_op("cmpeq", function(v1, v2) return v1 .. "===" .. v2 end, true)

        elseif node_type == "~=" then
            return "!(" .. compare_op("cmpeq", function(v1, v2) return v1 .. "===" .. v2 end, true) .. ")"

        elseif node_type == "<" then
            return compare_op("cmplt", function(v1, v2, s)
                return s and (self.strcoll .. v1 .. "," .. v2 .. ")<0")
                          or (v1 .. "<" .. v2) end)

        elseif node_type == ">" then
            return compare_op("!cmple", function(v1, v2, s)
                return s and (self.strcoll .. v1 .. "," .. v2 .. ")>0")
                          or (v1 .. ">" .. v2) end)

        elseif node_type == "<=" then
            return compare_op("cmple", function(v1, v2, s)
                return s and (self.strcoll .. v1 .. "," .. v2 .. ")<=0")
                          or (v1 .. "<=" .. v2) end)

        elseif node_type == ">=" then
            return compare_op("!cmplt", function(v1, v2, s)
                return s and (self.strcoll .. v1 .. "," .. v2 .. ")>=0")
                          or (v1 .. ">=" .. v2) end)

        elseif node_type == "and" then
            if self:is_bool_node(op1) then
                v2 = self:expr(op2)
                return v1 .. "&&(" .. v2 .. ")"
            end
            s = "("
            v1 = temp_v_(v1,op1)
            v2 = self:expr(op2)
            s = s .. v1 .. "===undefined||" .. v1 .. "===false?" .. v1 .. ":(" .. v2 .. "))"
            return s

        elseif node_type == "or" then
            if self:is_bool_node(op1) then
                v2 = self:expr(op2)
                return v1 .. "||(" .. v2 .. ")"
            end
            s = "("
            v1 = temp_v_(v1,op1)
            v2 = self:expr(op2)
            s = s .. v1 .. "!==undefined&&" .. v1 .. "!==false?" .. v1 .. ":(" .. v2 .. "))"
            return s

        end

    end

    self.error = "Internal error in operator " .. (node.type or "")
    return ""

end


function class:expr_op_simplify(node)

    --
    -- check if the node describes an operator with constant
    -- operands which can be merged/simplified into a single
    -- result node during compile time
    --

    local node_type = node.type
    local op1 = node.operand or node.operand1
    local op2 = node.operand2
    local op1_type, op2_type
    local op1_const, op2_const
    local bool, num, str, copy

    if op2 then

        --
        -- binary operator simplify
        --

        self:expr_op_simplify(op1)
        self:expr_op_simplify(op2)
        op1_type = op1.type
        op2_type = op2.type

        local num1 = op1_type == "num" and tonumber(op1.num)
        local num2 = op2_type == "num" and tonumber(op2.num)
        local str1 = op1_type == "str" and op1.str
        local str2 = op2_type == "str" and op2.str

        --
        -- arithmetic and concatenation operators
        --

        if node_type == "+" then
            if num1 and num2 then num = num1 + num2 end

        elseif node_type == "-" then
            if num1 and num2 then num = num1 - num2 end

        elseif node_type == "*" then
            if num1 and num2 then num = num1 * num2 end

        elseif node_type == "/" then
            if num1 and num2 and num2 ~= 0 then num = num1 / num2 end

        elseif node_type == "%" then
            if num1 and num2 and num2 ~= 0 then num = num1 % num2 end

        elseif node_type == "^" then
            if num1 and num2 then num = num1 ^ num2 end

        elseif node_type == ".." then
            if (str1 or num1) and (str2 or num2) then
                if num1 then str1 = "'" .. tostring(num1) .. "'" end
                if num2 then str2 = "'" .. tostring(num2) .. "'" end
                str = "'" .. str1:sub(2,-2) .. str2:sub(2,-2) .. "'"
            end

        --
        -- relational operators
        --

        elseif node_type == "<" then
            if num1 and num2 then bool = (num1 < num2) end

        elseif node_type == ">" then
            if num1 and num2 then bool = (num1 > num2) end

        elseif node_type == "<=" then
            if num1 and num2 then bool = (num1 <= num2) end

        elseif node.type == ">=" then
            if num1 and num2 then bool = (num1 >= num2) end

        else

            local bool1, bool2
            if op1_type == "bool" then bool1 = op1.bool end
            if op2_type == "bool" then bool2 = op2.bool end
            local nil1 = op1_type == "nil"
            local nil2 = op2_type == "nil"

            local op1_const = nil1 or (bool1 ~= nil) or num1 or str1
            local op2_const = nil2 or (bool2 ~= nil) or num2 or str2

            if node_type == "==" or node_type == "~=" then

                if op1_const and op2_const then
                    bool = false
                    if op1_type == op2_type then
                        if nil1 then
                            bool = true
                        elseif bool1 ~= nil then
                            bool = (op1.bool == op2.bool)
                        elseif num1 then
                            bool = (num1 == num2)
                        elseif str1 then
                            bool = (str1 == str2)
                        end
                    end
                    if node_type == "~=" then bool = not bool end
                end

            --
            -- logical operators
            --

            elseif node_type == "and" then

                -- clone op1 if it is false/nil, otherwise
                -- clone op2 if op1 is a known (true) constant
                if nil1 or bool1 == false then copy = op1
                elseif op1_const then copy = op2 end

            elseif node_type == "or" then

                -- clone op2 if op1 is false/nil, otherwise
                -- clone op1 if it is a known (true) constant
                if nil1 or bool1 == false then copy = op2
                elseif op1_const then copy = op1 end

            end

        end

    elseif op1 then

        --
        -- unary operator simplify
        --

        self:expr_op_simplify(op1)
        op1_type = op1.type

        if node_type == "-" then
            if op1_type == "num" then
                num = -op1.num
            end

        elseif node_type == "#" then
            if op1_type == "str" then
                num = #op1.str - 2
            end

        elseif node_type == "not" then
            if op1_type == "bool" then bool = not op1.bool
            elseif op1_type == "nil" then bool = true
            elseif op1_type == "not" then
                -- three levels of NOTs, reduce to one level
                local sub_op = op1.operand
                if sub_op.type == "not" then
                    node.operand = sub_op.operand
                end
            end
        end

    end

    --
    -- replace node if applicable
    --

    if copy or str or num or (bool ~= nil) then

        node.operand = nil
        node.operand1 = nil
        node.operand2 = nil

        if copy then

            for k,v in pairs(copy) do node[k] = v end

        else

            if str then
                node.type = "str"
                node.str = str
            elseif num then
                node.type = "num"
                node.num = tostring(num) -- string.format("%.17g", num)
            elseif bool ~= nil then
                node.type = "bool"
                node.bool = bool
            end

        end
    end

    node.simplified = true

end


function class:expr_get(table_node, field_name, index_node, in_assign)

    table_node.parens = true

    local debug_name = self.debug and ("," .. self:debug_name(table_node)) or ""

    local table_name = self:expr(table_node)
    if not table_name then return nil end

    if not in_assign then

        local s = "("

        local table_var, table_var_tmp
        if table_node.var then table_var = self.locals:get(table_node.var) end
        if not table_var then
            local tmp = self:get_temp_var()
            s = s .. tmp .. "=" .. table_name .. ","
            table_var = tmp
        end

        local field_var, field_str, field_num
        if index_node then
            if index_node.var then field_var = self.locals:get(index_node.var) end
            if not field_var then
                if index_node.num then
                    field_var = index_node.num
                    field_num = true
                elseif index_node.str then
                    field_var = index_node.str
                    field_str = true
                else
                    local index_node_expr = self:expr(index_node)
                    local tmp = self:get_temp_var()
                    s = s .. tmp .. "=" .. index_node_expr .. ","
                    field_var = tmp
                end
            end
        else
            local tmp = self:get_temp_var()
            s = s .. tmp .. "=" .. field_name .. ","
            field_var = tmp
            field_str = true
        end

        s = s .."(typeof " .. table_var .. "==='object'&&" .. table_var .. ".luatable&&"
        if field_str then
            s = s .. table_var .. ".hash.get(" .. field_var .. ")"
        elseif field_num then
            s = s .. table_var .. ".array[" .. field_var .. "]"
        else
            s = s .. "(typeof " .. field_var .. "==='number'?" .. table_var .. ".array[" .. field_var .. "]:" .. table_var .. ".hash.get(" .. field_var .. "))"
        end

        return s .. ")||" .. self.jsyieldget .. table_var .. "," .. field_var .. debug_name .. ")))"

    else -- called from assign_stmt

        field_name = field_name or self:expr(index_node)
        return self.jsyieldget .. table_name .. "," .. field_name .. debug_name .. "))"

    end

end


function class:bool_expr(node)

    local s, multival = self:expr(node)
    if node.type == "num" or node.type == "str" or node.bool then return "true" end
    if node.type == "bool" or node.type == "nil" then return "false" end

    if node.type == "var" then return s .. "!==undefined&&" .. s .. "!==false" end
    if node.type == "not" and node.operand.type == "var" then
        s = self:expr(node.operand)
        return s .. "===undefined||" .. s .. "===false"
    end

    if self:is_bool_node(node) then return s end

    local tmp = self:get_temp_var()
    if multival then s = s .. "[0]" end
    return "(" .. tmp .. "=" .. s .. "," .. tmp .. "!==undefined&&" .. tmp .. "!==false)"

end


function class:is_bool_node(node)

    local type = node.type

    if type == "and" or type == "or" then
        return self:is_bool_node(node.operand1) and self:is_bool_node(node.operand2)
    end

    return type == "bool" or type == "not" or type == "==" or type == "~="
        or type == "<"    or type == ">"   or type == "<=" or type == ">="

end


function class:adjust_multival_expr(expr_str, multival)

    if multival then
        if expr_str:sub(1,1) ~= "(" then expr_str = "(" .. expr_str .. ")" end
        expr_str = expr_str .. "[0]"
    end
    return expr_str

end


function class:debug_name(node)

    local name

    if node.type == "call" then
        return self:debug_name(node.func)

    elseif node.type == "var" then
        if node == self.env_var_node then
            name = "U"
        else
            local var_name = self.locals:get(node.var)
            if var_name then
                local var_num = tonumber(var_name:sub(2))
                if var_num and var_num < self.locals:get("##") then
                    name = "U"
                    self.upvalue_ref = true
                else
                    name = "L"
                end
            else
                name = "G"
            end
        end
        name = name .. ":" .. self:escape_name(node.var)

    elseif node.type == "member" then
        if node.field then name = node.field.var
        elseif node.index and node.index.type == "str" then
            name = node.index.str:sub(2,-2)
        else name = "?" end
        name = "I:" .. self:escape_name(name)

    elseif node.type == "function" then
        name = "F:<" .. self.chunk_name .. ':' .. tostring(node.line or 0) .. ">"

    elseif node.type == "str" or node.type == "num" or node.type == "bool" or node.type == "nil" then
        name = "K:"

    else name = "?" end

    return "'" .. name .. "'"

end


function class:escape_name(s)

    local t = {}
    for i = 1, #s do
        local c = s:sub(i,i)
        if c == '"' then t[i] = '\\x22'
        elseif c == "'" then t[i] = '\\x27'
        elseif c == "\\" then t[i] = '\\x5C'
        elseif c:byte(1) < 32 then t[i] = '?'
        else t[i] = c end
    end
    return table.concat(t)

end


function class:escape_text(s)

    local quote_char = s:sub(1,1)
    local t, n = { quote_char }, 2

    local backslash_char = ''
    if quote_char == '"' or quote_char == "'" then
        backslash_char = '\\'
    end

    for i = 2, #s - 1 do
        local c, d = s:sub(i,i), s:byte(i,i)
        if d <= 31 or d >= 127 then
            t[n] = '\\'
            n = n + 1
            if c == '\t' then
                t[n] = 't'
            elseif c == '\r' then
                t[n] = 'r'
            elseif c == '\n' then
                t[n] = 'n'
            else
                local x1 = math.floor(d / 16)
                local x2 = math.floor(d % 16)
                t[n] = 'x'
                t[n + 1] = string.char((x1 > 9) and (x1 - 10 + 65) or (x1 + 48))
                t[n + 2] = string.char((x2 > 9) and (x2 - 10 + 65) or (x2 + 48))
                n = n + 2
            end
        else
            if c == quote_char or c == backslash_char then
                t[n] = '\\'
                n = n + 1
            end
            t[n] = c
        end
        n = n + 1
    end

    t[n] = quote_char
    return table.concat(t)
end


function class:put(s)

    self.text[#self.text+1] = s
    self.newline_written = false

end


function class:putln()

    if self.debug and (not self.newline_written) then
        self:put("\n")
        self:put(string.rep(self.indent, self.locals.n - 1 + self.sub_block_level))
        self.newline_written = true
    end

end


function class:pushlbl(pos, lbl)

    if lbl then
        table.insert(self.text, pos, ":")
        table.insert(self.text, pos, lbl)
    end

end


return class
