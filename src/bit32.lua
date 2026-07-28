--- [ bit32 Lib ] --------------------------------------------------------------
return bit32 or {
    bor = load("return function(a, b) return a | b end")(),
    band = load("return function(a, b) return a & b end")(),
    bxor = load("return function(a, b) return a ~ b end")(),
    bnot = load("return function(a) return ~a end")(),
    lshift = load("return function(a, b) return a << b end")(),
    rshift = load("return function(a, b) return a >> b end")(),
    lrotate = load([[return function(a, b)
                                b = b % 32
                                return ((a << b) | (a >> (32 - b))) & 0xFFFFFFFF
                            end]])()
}