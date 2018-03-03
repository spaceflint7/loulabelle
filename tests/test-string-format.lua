
if string.format("%.0e", 0.00001) == "1e-005" then
    print "===================================================================="
    print "warning, detected printf() which prints a three-digit exponent."
    print "see https://msdn.microsoft.com/en-us/library/0fatw238(v=vs.110).aspx"
    print "to fix, recompile lua with _set_output_format(_TWO_DIGIT_EXPONENT)"
    print "===================================================================="
end

--
-- in addition to above, note also that Windows printf rounds
-- differently than other implementations, including Node.js,
-- which means this test might fail when it runs on Windows,
-- unless we carefully pick fractions that round the same on
-- all implementations, for example .125.
--

print "123456789012345678901234567890123456789012345678901234567890"

print (string.format("%#.12X", 1e6))

print (string.format("%f", 3433543453))
print (string.format("%f", 3453534335434534550930986598459684956849568364564563))

print (string.format("%.10f", 123456789.125))
print (string.format("%.16f", .34335434534550930986598459684956849568364564563))
print (string.format("%.20f", 1e-20))

print (string.format("%.0f", 0.34335434534550930986598459684956849568e22))
print (string.format("%g", 44))

print (string.format("%.0g", 0.1))
print (string.format("%.0g", 0.01))
print (string.format("%.0g", 0.001))
print (string.format("%.0g", 0.0001))
print (string.format("%.0g", 0.00001))

print (string.format("%.20e", 1.4140625))
print (string.format("%.20g", 1.4140625))
print (string.format("%.20f", 1.4140625))

print (string.format("%.20e", 1234.4853515625))
print (string.format("%.20g", 1234.4853515625))
print (string.format("%.20f", 1234.4853515625))

print (string.format("%#.10e", 1234.4853515625))
print (string.format("%#.10g", 1234.4853515625))
print (string.format("%#.10f", 1234.4853515625))

print (string.format("%#.10e", 1.4140625))
print (string.format("%#.10g", 1.4140625))
print (string.format("%#.10f", 1.4140625))
