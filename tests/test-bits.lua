
local function printBits(x) print(string.format("%X", x)) end

printBits (bit32.bnot(0))
printBits (bit32.bnot(bit32.bnot(0)))

print (bit32.btest())
print (bit32.btest(0x10,0x20))

printBits (bit32.band())
printBits (bit32.band(0x11, 0x12, 0x13, 0x14))

printBits (bit32.bor())
printBits (bit32.bor(0x101, 0x202, 0x303, 0x404))

printBits (bit32.bxor())
printBits (bit32.bxor(0x101, 0x202, 0x303, 0x404))

print "\tLSHIFT"

printBits (bit32.lshift(0x111, 4))
printBits (bit32.lshift(0x111, -4))
printBits (bit32.lshift(-0x111, 4))
printBits (bit32.lshift(-0x111, -4))

print "\tRSHIFT"

printBits (bit32.rshift(0x111, 4))
printBits (bit32.rshift(0x111, -4))
printBits (bit32.rshift(-0x111, 4))
printBits (bit32.rshift(-0x111, -4))

print "\tARSHIFT"

printBits (bit32.arshift(0x12345678, 4))
printBits (bit32.arshift(-0x12345678, 4))
printBits (bit32.arshift(0x12345678, -4))
printBits (bit32.arshift(-0x12345678, -4))

print "\tLROTATE"

printBits (bit32.lrotate(0x12345678, 4))
printBits (bit32.lrotate(-0x12345678, 4))
printBits (bit32.lrotate(0x12345678, -4))
printBits (bit32.lrotate(-0x12345678, -4))

print "\tRROTATE"

printBits (bit32.rrotate(0x12345678, 4))
printBits (bit32.rrotate(-0x12345678, 4))
printBits (bit32.rrotate(0x12345678, -4))
printBits (bit32.rrotate(-0x12345678, -4))

print "\tEXTRACT"

printBits (bit32.extract(0x12345678, 0, 32))
printBits (bit32.extract(0x12345678, 8, 16))


print "\tREPLACE"

printBits (bit32.replace(0x12345678, 0x90ABCDEF, 0, 32))
printBits (bit32.replace(0x12345678, 0xABCD, 8, 16))
