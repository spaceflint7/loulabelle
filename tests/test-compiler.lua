
--local source_text = "print (1,2,3,'Hello World\n')"
local source_text = "local a='Hello\\nWorld'"

local Compiler = require "Loulabelle"
local js, err = Compiler("name", source_text, {})
print (js,err)
