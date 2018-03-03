

local class = {}
local jspfx = package.JavaScript and "Loulabelle*" or ""
local Lexer = require(jspfx.."lexer")


function class.parse(text,name)

    local self = {

        lexer = Lexer.new(text),

        token = nil,
        token_line = nil,
        token_column = nil,
        token_stack = nil,
        last_token = "",

        vararg_func = true,
        inside_loop = false,
        --label_index = 0,
    }

    for k,_ in pairs(class) do self[k] = class[k] end

    self:next_token()
    local node = self:statlist()
    if self.token and not self.error then
        self.error = "expected end of file after '" .. self.last_token .. "'"
    end
    if not self.error then
        if node == "" then
            node = nil
        else
            self:connect_parent_node(node)
            self:validate_gotos(node)
        end
    end
    if self.error then
        self.error = self.error .. " in line " .. tostring(self.token_line)
        node = nil
    else
        node = { type="chunk", chunk=name, block=node }
    end
    return node, self.error

end


function class:next_token()

    if not self.error then
        if self.token_stack then
            local stk = self.token_stack[1]
            table.remove(self.token_stack, 1)
            if #self.token_stack == 0 then self.token_stack = nil end
            self.token, self.token_line, self.token_column = stk[1], stk[2], stk[3]
        else
            self.token, self.error = self.lexer:next_token()
            self.token_line, self.token_column = self.lexer.token_line, self.lexer.token_column
            if self.error then self.token = nil end
        end
    end
    if self.token then self.last_token = self.token end
    return self.token

end


--[[function class:node_tostring(node)

    if not node then return "null node" end
    local rest = ""
    if node.type=="var" then rest="var=" .. node.var end
    if node.type=="str" then rest="str=" .. node.str end
    if node.type=="num" then rest="num=" .. tostring(node.num) end
    if node.type=="member" then rest="member=" .. self:node_tostring(node.table) .. "." .. self:node_tostring(node.field) end
    if node.type=="method" then rest="method=" .. self:node_tostring(node.table) .. "." .. self:node_tostring(node.field) end
    if node.type=="call" then rest="func=" .. self:node_tostring(node.func) end
    if node.type=="do" or node.type=="while" or node.type=="repeat" then
        rest="block with " .. (node.block and tostring(node.block.count) or "zero") .. " statements"
    end
    if node.type=="assign" then rest="scope=" .. (node["local"] and "local" or "global") end
    if node.operand then rest="unary operator" end
    if node.operand2 then rest="binary operator" end
    return "[node type=" .. (node.type or "?") .. " " .. rest .. "]"

end


function class:print_node(who, node)

    print (who .. " got " .. self:node_tostring(node))

end


function class:print_tree(who, node)

    local count = 1
    while node do
        self:print_node(who .. "." .. tostring(count), node)
        local children = node.cond
        if children then
            self:print_tree("  C-" .. who .. "." .. tostring(count), children)
        end
        children = node.block or node.vars or node.operand or node.operand1 or node.key or node.args or node["then"]
        if children then
            self:print_tree("  L-" .. who .. "." .. tostring(count), children)
        end
        children = node.operand2 or node.val or node.vals or node["else"] or node["elseif"]
        if children then
            self:print_tree("  R-" .. who .. "." .. tostring(count), children)
        end
        node = node.next
        count = count + 1
    end

end]]


--
-- lua port of lparser.c from the official lua implementation
--


class.reserved_words = {
    ["and"]=true,["break"]=true,["continue"]=true,["do"]=true,
    ["else"]=true,["elseif"]=true,["end"]=true,["false"]=true,
    ["for"]=true,["function"]=true,["goto"]=true,["if"]=true,
    ["in"]=true,["local"]=true,["nil"]=true,["not"]=true,
    ["or"]=true,["repeat"]=true,["return"]=true,["then"]=true,
    ["true"]=true,["until"]=true,["while"]=true,
}


function class:is_quoted()

    if type(self.token) == "string" then
        local q = self.token:sub(1,1)
        if q == '\'' or q == '\"' then return true end
    end
    return false

end


function class:is_identifier()

    if type(self.token) == "string" then
        local x = self.token:sub(1,1)
        if x == '_' or (x >= 'a' and x <= 'z') or (x >= 'A' and x <= 'Z') then return true end
    end
    return false

end


function class:check(expect, advance)

    if self.token ~= expect then
        self.error = "'" .. expect .. "' expected"
        --error(self.error)
        return false
    else
        if advance then self:next_token() end
        return true
    end

end


function class:check_match(what, who, where)

    local success = self:check(what, true)
    if not success then
        if where ~= self.token_line then
            self.error = self.error .. " (to close '" .. who .. "' at line " .. tostring(where) .. ")"
        end
    end
    return success

end


function class:check_var(after)

    local node
    if self:is_identifier() then
        if not self.reserved_words[self.token] then
            node = { type="var", var=self.token }
            self:next_token()
        else
            self.error = "unexpected keyword '" .. self.token .. "' " .. after
        end
    elseif self.token then
        self.error = "unexpected symbol '" .. self.token .. "' " .. after
    elseif not self.error then
        self.error = "unexpected end of file " .. after
    end
    return node

end


function class:check_label(node)

    local prev = node.prev
    while prev do
        if prev.type == "label" and prev.label == node.label then
            self.error = "label '" .. node.label .. "' already defined on line " .. tostring(prev.line)
            self.token_line, self.token_column = node.line, node.column
            return false
        end
        prev = prev.prev
    end
    return true

end


function class:append_node(node, first, prev)

    if not first then
        first = node
        first.count = 1
    else
        prev.next = node
        node.prev = prev
        first.count = first.count + 1
    end
    prev = node
    return first, prev

end


function class:connect_parent_node(node, parent)

    while node do
        node.parent = parent
        if node.type=="do" or node.type=="for" or node.type=="while" or node.type=="repeat" then
            node.child = node.block
            self:connect_parent_node(node.block, node)
        elseif node.type=="if" then
            node.child = node["then"]
            node.child2 = node["else"] or node["elseif"]
            self:connect_parent_node(node.child, node)
            if node.child2 then self:connect_parent_node(node.child2, node) end
        end
        node = node.next
    end

end


function class:statlist(inside_loop)

    local save_inside_loop = self.inside_loop
    if inside_loop then self.inside_loop = inside_loop end

    local first_node, prev_node
    while true do
        while self.token == ";" do self:next_token() end
        local line = self.token_line
        local column = self.token_column
        if self.token == "end" or self.token == "until"
            or self.token == "else" or self.token == "elseif"
            or (not self.token) then break end
        local is_return = (self.token == "return")
        local node = self:statement()
        if not node then return nil end
        node.line = line
        node.column = column
        first_node, prev_node = self:append_node(node, first_node, prev_node)
        if node.type == "label" and not self:check_label(node) then return nil end
        if is_return then break end
    end

    self.inside_loop = save_inside_loop

    if not first_node then first_node = "" end
    return first_node

end


function class:body(line,method)

    if not self:check("(", true) then return nil end

    local first_node, prev_node
    local vararg = false
    if method then
        local self_arg = { type="var", var="self" }
        first_node, prev_node = self:append_node(self_arg, first_node, prev_node)
    end
    while true do
        if self.token == ")" then break
        elseif self.token == "..." then
            local dots_arg = { type="var", var="..." }
            first_node, prev_node = self:append_node(dots_arg, first_node, prev_node)
            self:next_token()
            vararg = true
            break
        else
            local next_arg = self:check_var("in function arguments")
            if not next_arg then return nil end
            first_node, prev_node = self:append_node(next_arg, first_node, prev_node)
            if self.token ~= "," then break end
            self:next_token()
        end
    end
    if not self:check(")", true) then return nil end

    local save_vararg_func = self.vararg_func
    self.vararg_func = vararg
    local stmts = self:statlist()
    self.vararg_func = save_vararg_func

    if not (stmts and self:check_match("end", "function", line)) then return nil end
    local node = { type="function", args=first_node, line=line, vararg=vararg }
    if stmts ~= "" then
        self:connect_parent_node(stmts)
        self:validate_gotos(stmts)
        node["block"] = stmts
        if self.error then node = nil end
    end

    return node

end


function class:explist()

    local first_node, prev_node
    while true do
        local node = self:expr()
        if not node then return nil end
        first_node, prev_node = self:append_node(node, first_node, prev_node)
        if self.token ~= "," then break end
        self:next_token()
    end
    return first_node

end


function class:constructor()

    local line = self.token_line

    local first_node, prev_node
    while true do
        self:next_token()
        if self.token == "}" then break end

        local key_expr
        if self.token == "[" then
            local line2 = self.token_line
            self:next_token()
            key_expr = self:expr()
            if (not key_expr)
                or (not self:check_match("]", "[", line2))
                    or (not self:check("=", true))
                        then return nil end

        elseif self:is_identifier() and not self.reserved_words[self.token] then
            -- here we employ the token stack mechanism from next_token(),
            -- because the current token may either be a varname, or the first
            -- token in an expr() expression.  and we only know for sure after
            -- we look at the next token, to check if it is '=' or not.
            local save_token, save_token_line, save_token_column =
                        self.token, self.token_line, self.token_column
            self:next_token()
            if self.token == "=" then
                key_expr = { type="str", str='"' .. save_token .. '"' }
                self:next_token()           -- move past '='
            else
                self.token_stack = { { self.token, self.token_line, self.token_column } }
                self.token, self.token_line, self.token_column =
                        save_token, save_token_line, save_token_column
            end
        end

        local node = self:expr()
        if not node then return nil end
        node = { type="field", val=node }
        if key_expr then node.key = key_expr end
        first_node, prev_node = self:append_node(node, first_node, prev_node)

        if self.token ~= "," and self.token ~= ";" then break end
    end

    if not self:check_match("}", "{", line) then first_node = nil
    else first_node = { type="table", block=first_node } end
    return first_node

end


function class:funcargs(line)

    local node

    if self.token == "(" then
        local line = self.token_line
        self:next_token()
        if self.token == ")" then
            self:next_token()
            node = ""
        else
            node = self:explist()
            if node and not self:check_match(')', '(', line) then node = nil end
        end

    elseif self.token == "{" then
        node = self:constructor()

    elseif self:is_quoted() then
        node = { type='str', str=self.token }
        self:next_token()

    else
        self.error = "function arguments expected"
    end

    return node

end


function class:suffixedexp()

    local node
    if self.token == "(" then
        local line = self.token_line
        self:next_token()
        node = self:expr()
        if node then
            node["parens"] = true
            if not self:check_match(")", "(", line) then node = nil end
        end
    else
        node = self:check_var("in expression")
    end

    while node do

        if self.token == "." then
            self:next_token()
            local subnode = self:check_var("after '.'")
            if subnode then node = { type="member", table=node, field=subnode }
            else node = nil end

        elseif self.token == "[" then
            local line = self.token_line
            self:next_token()
            local subnode = self:expr()
            if subnode and not self:check_match(']', '[', line) then subnode = nil end
            if subnode then node = { type="member", table=node, index=subnode }
            else node = nil end

        elseif self.token == ":" then
            self:next_token()
            local subnode1, subnode2 = self:check_var("after ':'")
            if subnode1 then subnode2 = self:funcargs() end
            if subnode1 and subnode2 then
                node = { type="method", table=node, field=subnode1 }
                if subnode2 ~= "" then node["args"]=subnode2 end
            else node = nil end

        elseif self.token == "(" or self.token == "{" or self:is_quoted() then
            local subnode = self:funcargs()
            if subnode then
                node = { type="call", func=node }
                if subnode ~= "" then node["args"]=subnode end
            else node = nil end

        else break end
    end

    return node

end


function class:simpleexp()

    local node
    --if type(self.token)=="number" then node = { type="num", num=self.token }
    if tonumber(self.token) then node = { type="num", num=self.token }
    elseif self:is_quoted() then node = { type="str", str=self.token }
    elseif self.token=="nil" or (self.token=="..." and self.vararg_func) then node = { type=self.token }
    elseif self.token=="..." then self.error = "cannot use '...' outside a vararg function" return nil
    elseif self.token=="true" then node = { type="bool", bool=true }
    elseif self.token=="false" then node = { type="bool", bool=false }
    elseif self.token=="{" then return self:constructor()
    elseif self.token=="function" then self:next_token() return self:body(self.token_line)
    else return self:suffixedexp() end
    self:next_token()
    return node

end


class.operator_priority = {
    -- priority for all unary operators
    ["/unary"]=8,   -- the key must be something that can never match any single token
    -- left and right priorities for each binary operator
    ["+"]={6,6},    ["-"]={6,6},    ["*"]={7,7},    ["/"]={7,7},    ["%"]={7,7},
    ["^"]={10,9},   [".."]={5,4},
    ["=="]={3,3},   ["<"]={3,3},    ["<="]={3,3},   ["~="]={3,3},   [">"]={3,3},    [">="]={3,3},
    ["and"]={2,2},  ["or"]={1,1}
}


function class:subexpr(limit)

    local node, node2
    if self.token == "not" or self.token == "-" or self.token == "#" then
        local node_type = self.token
        self:next_token()
        node2 = self:subexpr(self.operator_priority["/unary"])
        if not node2 then return nil end
        node = { type=node_type, operand=node2 }
    else node = self:simpleexp() end

    local pri = self.operator_priority[self.token]
    while pri and pri[1] > limit do         -- pri[1] is left priority
        local node_type = self.token
        self:next_token()
        node2, pri = self:subexpr(pri[2])   -- pri[2] is right priority
        if not node2 then return nil end
        node = { type=node_type, operand1=node, operand2=node2 }
    end
    return node, pri

end


function class:expr()

    local node = self:subexpr(0)
    --if node then node = { type="expr", expr=node } end
    return node

end


function class:assignment(node,is_local)

    local first_node, prev_node
    if not node then
        node = self:suffixedexp()
        if not node then return end
    end
    while true do
        if node.type ~= "var" and node.type ~= "member" then
            self.error = "syntax error"
            return nil
        end
        first_node, prev_node = self:append_node(node, first_node, prev_node)
        if self.token == "=" then break
        elseif self.token ~= "," then
            if is_local then
                if first_node then break end
                self.error = "expected local variable name"
            else
                self.error = "expected '=' or ',' in assignment"
            end
            return nil
        end
        self:next_token()
        node = self:suffixedexp()
    end

    local node = { type="assign", vars=first_node }
    if is_local then node["local"]=true end
    if self.token == "=" then
        self:next_token()
        local expr_list = self:explist()
        if expr_list then node["vals"]=expr_list else node = nil end
    end
    return node

end


function class:assignfunc(is_local)

    local line = self.token_line
    local is_method = false
    local node, parent
    while true do
        node = self:check_var("where function name was expected")
        if not node then return nil end
        if is_local then break end
        if parent then node = { type="member", table=parent, field=node } end
        if is_method then break end
        if self.token == "." or self.token == ":" then
            is_method = (self.token == ":")
            self:next_token()
            parent = node
        else break end
    end
    local stmts = self:body(self.token_line, is_method)
    if stmts then
        node.count = 1
        node = { type="assign", vars=node, vals=stmts }
        if is_local then node["local"]=true end
    else node = nil end
    return node

end


function class:ifstat()

    local line = self.token_line
    local ifword = self.token
    self:next_token()
    local node
    local cond = self:expr()
    if cond and self:check("then", true) then
        local stmts = self:statlist()
        if stmts then
            node = { type=ifword, cond=cond }
            if stmts ~= "" then node["then"]=stmts end
            if self.token == "elseif" then
                local line2 = self.token_line
                local subnode = self:ifstat()
                if subnode then
                    subnode.line = line2
                    node["elseif"] = subnode
                else node = nil end
            else
                if self.token == "else" then
                    self:next_token()
                    stmts = self:statlist()
                    if not stmts then node = nil
                    elseif stmts ~= "" then node["else"] = stmts end
                end
                if node and not self:check_match("end", ifword, line) then node = nil end
            end
        end
    end
    return node
end


function class:dostat(inside_loop)

    local line = self.token_line
    self:next_token()
    local stmts = self:statlist(inside_loop)
    if stmts and self:check_match("end", "do", line) then
        local node = { type="do" }
        if stmts ~= "" then node["block"]=stmts end
        return node
    else return nil end

end


function class:whilestat()

    local node
    self:next_token()
    local cond = self:expr()
    if cond and self:check("do", false) then
        node = self:dostat("while")
        if node then
            node["type"]="while"
            node["cond"]=cond
        end
    end
    return node

end


function class:repeatstat()

    local line = self.token_line
    self:next_token()
    local node = self:statlist("repeat")
    if node and not self:check_match("until", "repeat", line) then node = nil end
    if node then
        local cond = self:expr()
        if cond then
            local stmts = node
            node = { type="repeat", ["until"]=cond }
            if stmts ~= "" then node["block"]=stmts end
        else node = nil end
    end
    return node

end


function class:forstat()

    local line = self.token_line
    self:next_token()

    local first_node, prev_node, node
    while true do
        node = self:check_var("in 'for'")
        if not node then return nil end
        first_node, prev_node = self:append_node(node, first_node, prev_node)
        if self.token == "=" or self.token ~= "," then break end
        self:next_token()
    end
    node = { type="for", vars=first_node }

    if self.token == "=" then       -- numeric 'for'
        if first_node.count ~= 1 then
            self.error = "syntax error in numeric 'for'"
            return nil
        end
        self:next_token()
        local expr = self:expr()
        if not expr or not self:check(",", true) then return nil end
        node["initial"] = expr
        expr = self:expr()
        if not expr then return nil end
        node["limit"] = expr
        if self.token == "," then
            self:next_token()
            expr = self:expr()
            if not expr then return nil end
            node["step"] = expr
        end

    elseif self.token == "in" then -- generic 'for'
        self:next_token()
        local expr = self:explist()
        if not expr then return nil end
        node["expr"] = expr

    else
        self.error = "expected 'in' or '=' in 'for'"
        return nil
    end

    local subnode
    if self:check("do", false) then subnode = self:dostat("for") end
    if not subnode then return nil end
    node["block"] = subnode["block"]
    return node

end


function class:exprstat()

    local node = self:suffixedexp()
    if self.token == "=" or self.token == "," then
        node = self:assignment(node)
    elseif node and node.type ~= 'call' and node.type ~= 'method' then
        if self.token then self.error = "syntax error"
        elseif not self.error then self.error = "unexpected end of file" end
        node = nil
    end
    return node

end


function class:statement()

    local node
    while self.token == ";" do self:next_token() end

    if self.token == "if" then
        node = self:ifstat()
    elseif self.token == "do" then
        node = self:dostat()
    elseif self.token == "while" then
        node = self:whilestat()
    elseif self.token == "repeat" then
        node = self:repeatstat()
    elseif self.token == "for" then
        node = self:forstat()

    elseif self.token == "function" or self.token == "local" then
        local is_local = false
        if self.token == "local" then
            is_local = true
            self:next_token()
        end
        if self.token == "function" then
            self:next_token()
            node = self:assignfunc(is_local)
        else
            node = self:assignment(nil,is_local)
        end

    elseif self.token == "return" then
        self:next_token()
        node = { type="return" }
        if self.token ~= nil and self.token ~= "end" and self.token ~= ";" then
            local vals = self:explist()
            if vals then node["vals"] = vals else node = nil end
        end
        if node and self.token == ";" then self:next_token() end

    elseif self.token == "::" then
        self:next_token()
        node = self:check_var("in label")
        if node then
            if not self:check("::", true) then node = nil
            else
                -- self.label_index = self.label_index + 1
                node = { type="label", label=node.var } --, index=self.label_index }
            end
        end

    elseif self.token == "goto" then
        self:next_token()
        node = self:check_var("in goto")
        if node then node = { type="goto", label=node.var } end

    elseif self.token == "break" or self.token == "continue" then
        if self.inside_loop then
            if self.token == "continue" and self.inside_loop ~= "while" then
                self.error = self.token .. " not inside while loop"
            else
                node = { type=self.token }
                self:next_token()
            end
        else
            self.error = self.token .. " not inside loop"
        end

    else node = self:exprstat() end

    return node

end


function class:validate_gotos(node)

    local first_node = node
    while node do
        if node.child then
            self:validate_gotos(node.child)
            if node.child2 then self:validate_gotos(node.child2) end
        elseif node.type == "goto" then
            node.target = self:validate_one_goto(node, first_node)
            if not node.target then
                self.token_line, self.token_column = node.line, node.column
                return
            end
        end
        node = node.next
    end

end


function class:validate_one_goto(goto_node, first_node)

    local label_name, label_node = goto_node.label
    while true do

        local node = first_node
        while node do
            if node.type == "label" and node.label == label_name then
                label_node = node
                break
            end
            node = node.next
        end

        if label_node then

            if not label_node.next then return node end     -- label is last in block, don't check scope

            node = first_node
            while node do
                if node == label_node then return node
                elseif node == goto_node then break end
                node = node.next
            end

            while node do
                if node == label_node then return node
                elseif node.type == "assign" and node["local"] then
                    self.error = "'goto " .. label_name .. "' jumps into the scope of local '" .. node.vars.var .. "'"
                    return
                end
                node = node.next
            end

            return {}   -- should never reach here

        else

            goto_node = goto_node.parent
            if not goto_node or goto_node.type == "function" or goto_node.type == "chunk" then
                self.error = "no visible label '" .. label_name .. "' for goto"
                return
            end

            first_node = goto_node
            while first_node.prev do first_node = first_node.prev end

        end
    end
end


return class
