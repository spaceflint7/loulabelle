

local class = {}


function class.new(text)

    local self = {

        text = text,
        text_pos = 0,
        text_len = #text,

        line = 1,
        column = 1,
        token_line = nil,
        token_column = nil,
    }

    for k,_ in pairs(class) do self[k] = class[k] end

    return self

end


local function isalpha_(c) return c and (c == '_' or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z')) end
local function isspace(c) return c and (c == ' ' or c == '\t' or c == '\n' or c == '\r') end
local function isdigit(c) return c and (c >= '0' and c <= '9') end
local function isxdigit(c) return c and ((c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F')) end


function class:next_token()

    while true do

        local c
        while true do
            c = self:get_char()
            if not isspace(c) then
                if c then break
                else -- end of file
                    self.token_line, self.token_column = self.line, self.column
                    return c
                end
            end
        end

        self.token_line, self.token_column = self.line, self.column

        if c == '-' and self:peek_chars(1) == '-' then

            self:get_char()
            c = self:get_char()
            local lvl = (c == '[') and self:check_long_bracket()
            if lvl then
                local _, err = self:next_long_string(lvl, 'comment')
                if err then return nil, err end
            else
                while c and c ~= '\n' do c = self:get_char() end
            end

        elseif not isalpha_(c) then

            if isdigit(c) then return self:next_number(c) end
            if c == '\'' or c == '\"' then return self:next_short_string(c) end
            if c == '[' then
                local lvl = self:check_long_bracket()
                if lvl then return self:next_long_string(lvl, 'string') end
            end

            return self:next_symbol(c)

        else

            local s = ''
            while true do
                s = s .. c
                c = self:get_char()
                if not (isalpha_(c) or isdigit(c)) then
                    if c and not isspace(c) then
                        self.text_pos = self.text_pos - 1
                        self.column = self.column - 1
                    end
                    break
                end
            end

            return s
        end

    end

end


local lower_a_byte = ('a'):byte()
local upper_A_byte = ('A'):byte()

function class:next_short_string(quote_char)

    local t, n = { quote_char }, 2

    local skip_ws = false
    while true do
        local c = self:get_char()
        while skip_ws do
            if isspace(c) then c = self:get_char() else skip_ws = false end
        end
        if c == quote_char then break end
        if c == '\n' or c == '\r' or (not c) then
            return nil, 'unfinished string'
        end
        if c == '\\' then
            c = self:get_char()
            -- backslash followed by newline: always generates "\n"
            if c == '\r' or c == '\n' then
                self:skip_newline()
                c = '\n'
            -- backslash followed by 'z': skip to next non-whitespace character
            elseif c == 'z' then
                c = ''
                skip_ws = true
            -- backslash followed by a C escape character
            elseif c == 'a' then c = '\x07'
            elseif c == 'b' then c = '\x08'
            elseif c == 't' then c = '\x09'
            elseif c == 'n' then c = '\x0A'
            elseif c == 'v' then c = '\x0B'
            elseif c == 'f' then c = '\x0C'
            elseif c == 'r' then c = '\x0D'
            elseif c == '"' or c == "'" or c == '\\' then ;
            -- character code in hex
            elseif c == 'x' then
                local x1 = self:get_char()
                local x2 = self:get_char()
                if not isxdigit(x1) or not isxdigit(x2) then
                    return nil, 'hexadecimal digit expected in string escape sequence'
                end
                    if x1 >= 'a' then x1 = 10 + x1:byte() - lower_a_byte
                elseif x1 >= 'A' then x1 = 10 + x1:byte() - upper_A_byte end
                    if x2 >= 'a' then x2 = 10 + x2:byte() - lower_a_byte
                elseif x2 >= 'A' then x2 = 10 + x2:byte() - upper_A_byte end
                c = string.char(x1 * 16 + x2)
            -- character code in decimal
            elseif isdigit(c) then
                local d1, d2, d3 = 0, 0, c
                if isdigit(self:peek_chars(1)) then
                    d2 = d3
                    d3 = self:get_char()
                    if isdigit(self:peek_chars(1)) then
                        d1 = d2
                        d2 = d3
                        d3 = self:get_char()
                    end
                end
                c = string.char(d1 * 100 + d2 * 10 + d3)
            else
                return nil, 'invalid escape sequence'
            end
        end
        t[n] = c
        n = n + 1
    end

    t[n] = quote_char
    return table.concat(t)
end


function class:next_long_string(lvl, string_or_comment)

    local t, n = { "'" }, 2

    local chk = string.rep('=', lvl) .. ']'
    local c = self:peek_chars(1)
    if c == '\r' or c == '\n' then
        self:get_char()
        self:skip_newline() -- skip initial newline
    end
    while true do
        c = self:get_char()
        if c == '\r' or c == '\n' then
            self:skip_newline()
            c = '\n'
        else
            if c == ']' and self:peek_chars(lvl + 1) == chk then
                for i = 0, lvl do self:get_char() end
                break
            elseif (not c) then
                return nil, 'unfinished long ' .. string_or_comment
            end
        end
        t[n] = c
        n = n + 1
    end

    t[n] = "'"
    return table.concat(t)
end


function class:check_long_bracket()

    local c = self:peek_chars(1)
    if c == '[' then
        self:get_char()
        return 0
    end
    if c == '=' then
        local lvl = 1
        local chk = '='
        while true do
            local s = self:peek_chars(lvl + 1)
            if s == chk .. '[' then
                --print ('Compared', s, 'with', chk..'[', 'and selecting level', lvl)
                for i = 0, lvl do self:get_char() end
                return lvl
            elseif s == chk .. '=' then
                lvl = lvl + 1
                chk = chk .. '='
                --print ('Compared', s, 'with', chk, 'and advancing level')
            else
                break
            end
        end
    end
    return nil
end


function class:next_number(c)

    local initial_pos = self.text_pos

    local x, exp1, exp2 = self:peek_chars(1), 'e', 'E'
    x = (c == '0' and (x == 'x' or x == 'X'))
    if x then
        self:get_char()
        c = self:peek_chars(1)
        if isxdigit(c) then exp1, exp2 = 'p', 'P'
        else exp1 = nil end
    end

    if exp1 then
        while true do
            c = self:peek_chars(1)
            if c == exp1 or c == exp2 then
                exp1, exp2 = nil, nil
                self:get_char()
                c = self:get_char()
                if not (c == '-' or c == '+' or isdigit(c)) then break end
            elseif isdigit(c) or isalpha_(c) or c == '.' then self:get_char()
            else break end
        end
    end

    local num = tonumber(self.text:sub(initial_pos, self.text_pos))
    if num then return string.format("%.17g", num) else return nil, "invalid number" end

end


function class:next_symbol(c)

    -- we can convert a minus token followed by digits (i.e. a number token)
    -- into a negative) number token, but only if the minus token is separated
    -- from the previous token by a space character.
    if c == '-' then
        if (not isdigit(self:peek_chars(1)))
        or (self.text_pos > 0 and
                (not isspace(self.text:sub(self.text_pos - 1, self.text_pos - 1))))
            then return c
        else
            local num, err = self:next_number(self:get_char())
            --if type(num) == "number" then num = -num end
            if num then num = "-" .. num end
            return num, err
        end
    end

    if c == '+' or c == '*' or c == '/' or c == '%' or c == '^' or c == '#'
    or c == '(' or c == ')' or c == '{' or c == '}' or c == '[' or c == ']'
    or c == ';' or c == ',' then return c end

    if c == '.' then
        local c2 = self:peek_chars(1)
        if isdigit(c2) then return self:next_number(c)
        elseif c2 ~= '.' then return '.' end
        self:get_char(1)
        if self:peek_chars(1) ~= '.' then return '..' end
        self:get_char(1)
        return '...'
    end

    if c == ':' or c == '=' then
        if self:peek_chars(1) ~= c then return c end
        self:get_char()
        return c .. c
    end

    if c == '<' or c == '>' then
        if self:peek_chars(1) ~= '=' then return c end
        self:get_char()
        return c .. '='
    end

    if c == '~' and self:peek_chars(1) == '=' then
        self:get_char()
        return c .. '='
    end

    return nil, 'unrecognized symbol ' .. c

end


function class:get_char()

    local c
    if (self.text_pos < self.text_len) then
        self.text_pos = self.text_pos + 1
        c = self.text:sub(self.text_pos, self.text_pos)
        if c == '\n' then
            self.line = self.line + 1
            self.column = 1
        else
            self.column = self.column + 1
        end
    end
    return c

end


function class:peek_chars(n)

    local s
    if (self.text_pos + n <= self.text_len) then
        s = self.text:sub(self.text_pos + 1, self.text_pos + n)
    end
    return s

end


function class:skip_newline()

    local n = self.text_pos
    local c1 = self.text:sub(n, n)
    if c1 == '\r' or c1 == '\n' then
        local c2 = self.text:sub(n + 1, n + 1)
        if (c2 == '\r' or c2 == '\n') and (c2 ~= c1) then
            self:get_char()
        end
    end

end


return class
