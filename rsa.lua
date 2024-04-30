--[[
    returns gcd, bezout_x
]]
function gcd_ext(a, b)
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
function mod_exp(b, e, n)
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
    t = 1
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
    gets is_prime((k * (2^n)) - 1)
    (given k is odd and < 2^n)
]]
function checkPrime(n, k)
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
        for _p in hardcoded_candidates do
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
    return (math.fmod(u, N) == 0)
end

--[[
    returns n, e, d
]]
function generate_keys(seed1, seed2)
    math.randomseed(seed1, seed2)

end