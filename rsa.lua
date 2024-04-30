local rsa = {}

--[[
    returns gcd, bezout_x
]]
function rsa.gcd_ext(a, b)
    -- yeah don't ask me how this works i coped wikipedia's pseudocode
    assert(tonumber(a) and tonumber(b) and math.floor(a) == a and math.floor(b) == b and a > 0 and b > 0, "invalid gcd_ext args")

    local s, old_s = 0, 1
    local r, old_r = b, a
    while (r > 0) do
        local q = math.floor(old_r / r)

        old_r, r = r, old_r - (q * r)
        old_s, s = s, old_s - (q * s)
    end

    --[[local bezout_t = 0
    if (b > 0) then
        bezout_t = math.floor((old_r - (old_s * a)) / b)
    end
    ]]

    return old_r, old_s--, bezout_t
end

--[[
    returns (b^e) mod n
]]
function rsa.mod_exp(b, e, n)
    -- again im just yoinking wikipedia's pseudocode lol
    if (n == 1) then return 0 end

    local c = 1
    for i = 0, e-1 do
        c = (c * b) % n
    end

    return c
end

--[[
    lucas sequence V[e] (p, 1) mod n
    (used in checkPrime)
]]
local function lucas(e, p, n)
    -- adapted from weidai.com/lucas.html
    local i = math.floor(math.log(e, 2))

    if (i <= -1) then
        return 2
    end

    local v = p
    local v1 = ((p * p) - 2) % n

    local _e = e
    while (_e > 0) do
        if (e % 2 == 1) then
            v = ((v * v1) - p) % n
            v1 = ((v1 * v1) - 2) % n
        else
            v1 = ((v * v1) - p) % n
            v = ((v * v) - 2) % n
        end

        _e = math.floor(_e / 2)
    end

    return v
end

--[[
    (used in checkPrime)
]]
local function jacobi(n, k)
    -- yoinked from wikipedia implementation
    assert(k > 0 and k % 2 == 1, "invalid k for jacobi")

    n = n % k
    local t = 1
    while (n ~= 0) do
        while (n % 2 == 0) do
            n = n / 2
            local r = k % 8

            if (r == 3 or r == 5) then
                t = -t
            end
        end

        n, k = k, n
        if (n % 4 == 3 and k % 4 == 3) then
            t = -t
        end
        n = n % k
    end

    if (k == 1) then
        return t
    else
        return 0
    end
end

--[[
    lucas-lehmer-riesel,
    for N = (k * (2^n)) - 1,
    returns is_prime(N), N
    (given k is odd and < 2^n)
]]
function rsa.checkPrime(n, k)
    assert(k % 2 == 1 and k < 2^n, "invalid number form for checkPrime")
    

    -- N = actual number we're primality checking
    local N = (k * (2^n)) - 1


    ----- find u[0]
    local u

    -- finding p
    local p
    if (k % 3 == 0) then
        p = 4
    else
        -- idk wikipedia says these are good candidates but also that citation is needed
        local p_found = false
        local hardcoded_candidates = {5, 8, 9, 11}
        for _, _p in ipairs(hardcoded_candidates) do
            if (jacobi(_p - 2, N) == 1 and jacobi(_p + 2, N) == -1) then
                p = _p
                p_found = true
            end
        end

        if (not p_found) then
            local i = 12
            -- MATH (wikipedia tbh) SAYS THIS SHOULD BREAK EVENTUALLY SO IT BETTER
            while (true) do
                if (jacobi(i - 2, N) == 1 and jacobi(i + 2, N) == -1) then
                    p = i
                    break
                end
                os.sleep(0.05)
            end
        end
    end

    -- calculating u[0]
    u = lucas(k, p, N)

    
    ---- get u[n-2]
    for i = 1, n-2 do
        u = (u*u) - 2
    end

    -- N is prime if and only if it cleanly divides u[n-2]
    return (math.fmod(u, N) == 0), N
end

--[[
    magnitude = max power of 2 for 2^n component of p and q
    seed1, seed2 used for p and q generation
    returns n, e, d
    (n, e) = public key,
    d = private key
]]
function rsa.generate_keys(seed1, seed2, magnitude)
    if (not magnitude) then
        magnitude = 32
    end

    assert(magnitude >= 8, "magnitude must be higher for this e value")

    -- outputs
    local n, e, d


    ---- generate p and q, get totient
    math.randomseed(seed1, seed2)
    -- make sure totient(n) = lcm(p-1, q-1) is greater than 65537 so that e is valid
    local totient_thingy
    local p, q
    repeat
        -- generate p
        local is_prime = false
        local N
        repeat
            local _n = math.random(8, magnitude)
            local _k = math.random(2, (2^_n) - 2)
            if (_k % 2 == 0) then _k = _k + 1 end

            is_prime, N = rsa.checkPrime(_n, _k)
            os.sleep(0.05)
        until is_prime
        p = N

        -- generate q
        repeat
            local _n = math.random(8, magnitude)
            local _k = math.random(2, (2^_n) - 2)
            if (_k % 2 == 0) then _k = _k + 1 end

            is_prime, N = rsa.checkPrime(_n, _k)
            os.sleep(0.05)
        until is_prime
        q = N

        -- calculate lcm(p-1, q-1) = |(p-1)(q-1)| / gcd(p-1, q-1)
        local gcd, _ = rsa.gcd_ext(p-1, q-1)
        totient_thingy = math.abs((p-1) * (q-1)) / gcd

        os.sleep(0.05)
    until totient_thingy > 65537


    ---- get n
    n = p * q


    ---- get e
    e = 65537 -- yeag maybe its insecure but im just gonna go with 2^16+1 public key-


    ---- calculate d
    -- d = bezout_x from gcd(e, totient)
    _, d = rsa.gcd_ext(e, totient_thingy)


    -- return
    return n, e, d
end

--[[
    encrypts an INTEGER m given public keys e and n
]]
function rsa.encryptInt(m, e, n)
    return rsa.mod_exp(m, e, n)
end

--[[
    decrypts an encrypted INTEGER message ((m^e) mod n) given private key d and public key n
]]
function rsa.decryptInt(m, d, n)
    return rsa.mod_exp(m, d, n)
end



return rsa