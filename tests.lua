-- Tests borrowed from LibSerialize and modified for LibCBOR
if loadfile then
  loadfile("LibCBOR.lua")()
else
  LibCBOR = LibStub and LibStub:GetLibrary("LibCBOR-1.0")
end

function LibCBOR:RunTests()
    do
        local serialized = LibCBOR:Serialize({ a = 1})
        local tab = LibCBOR:Deserialize(serialized)
        assert(tab.a == 1)
        assert(tab.b == nil)
    end

    --[[do
        local t = { a = 1 }
        t.t = t
        t[t] = "test"
        local serialized = LibCBOR:Serialize(t)
        local success, tab = LibCBOR:Deserialize(serialized)
        assert(success)
        assert(tab.t.t.t.t.t.t.a == 1)
        assert(tab[tab.t] == "test")
    end]]

    do
        local t = { a = 1, c = 3 }
        local nested = { a = 1, c = 3 }
        t.nested = nested
        local serialized = LibCBOR:Serialize(t)
        local tab = LibCBOR:Deserialize(serialized)
        assert(tab.a == 1)
        assert(tab.b == nil)
        assert(tab.c == 3)
        assert(tab.nested.a == 1)
        assert(tab.nested.b == nil)
        assert(tab.nested.c == 3)
    end


    --[[---------------------------------------------------------------------------
        Utilities
    --]]---------------------------------------------------------------------------

    local function isnan(value)
        return (value < 0) == (value >= 0)
    end

    local function tCompare(lhsTable, rhsTable, depth)
        depth = depth or 1
        for key, value in pairs(lhsTable) do
            if type(value) == "table" then
                local rhsValue = rhsTable[key]
                if type(rhsValue) ~= "table" then
                    return false
                end
                if depth > 1 then
                    if not tCompare(value, rhsValue, depth - 1) then
                        return false
                    end
                end
            elseif value ~= rhsTable[key] then
                print("mismatched value: " .. key .. ": " .. tostring(value) .. ", " .. tostring(rhsTable[key]))
                return false
            end
        end
        -- Check for any keys that are in rhsTable and not lhsTable.
        for key, value in pairs(rhsTable) do
            if lhsTable[key] == nil then
                print("mismatched key: " .. key)
                return false
            end
        end
        return true
    end


    --[[---------------------------------------------------------------------------
        Test cases for serialization
    --]]---------------------------------------------------------------------------

    local function fail(index, fromVer, toVer, value, desc)
        assert(false, ("Test #%d failed (serialization ver: %s, deserialization ver: %s) (%s): %s"):format(index, fromVer, toVer, tostring(value), desc))
    end

    local function testfilter(t, k, v)
        return k ~= "banned" and v ~= "banned"
    end

    local function check(index, fromVer, from, toVer, to, value, bytelen, cmp)
        local serialized = from:Serialize(value)

        local deserialized = to:Deserialize(serialized)

        -- Tests involving NaNs will be compared in string form.
        if type(value) == "number" and isnan(value) then
            value = tostring(value)
            deserialized = tostring(deserialized)
        end

        local typ = type(value)
        if typ == "table" and not tCompare(cmp or value, deserialized) then
            fail(index, fromVer, toVer, value, "Non-matching deserialization result")
        elseif typ ~= "table" and value ~= deserialized then
            fail(index, fromVer, toVer, value, ("Non-matching deserialization result: %s"):format(tostring(deserialized)))
        end
    end

    local function checkLatest(index, value)
        check(index, "latest", LibCBOR, "latest", LibCBOR, value)
    end

    -- Format: each test case is { value, bytelen, cmp, earliest }. The value will be serialized
    -- and then deserialized, checking for success and equality, and the length of
    -- the serialized string will be compared against bytelen. If `cmp` is provided,
    -- it will be used for comparison against the deserialized result instead of `value`.
    -- Note that the length always contains one extra byte for the version number.
    -- `earliest` is an index into the `versions` table below, indicating the earliest
    -- version that supports the test case.
    local print = nil
    local testCases = {
        { nil, 2 },
        { true, 2 },
        { false, 2 },
        { 0, 2 },
        { 1, 2 },
        { 127, 2 },
        { 128, 3 },
        { 4095, 3 },
        { 4096, 4 },
        { 65535, 4 },
        { 65536, 5 },
        { 16777215, 5 },
        { 16777216, 6 },
        { 4294967295, 6 },
        { 4294967296, 9 },
        { 9007199254740992, 9 },
        { 1.5, 6 },
        { 27.32, 8 },
        { 123.45678901235, 10 },
        { 148921291233.23, 10 },
        { -0, 2 },
        { -1, 3 },
        { -4095, 3 },
        { -4096, 4 },
        { -65535, 4 },
        { -65536, 5 },
        { -16777215, 5 },
        { -16777216, 6 },
        { -4294967295, 6 },
        { -4294967296, 9 },
        { -9007199254740992, 9 },
        { -1.5, 6 },
        { -123.45678901235, 10 },
        { -148921291233.23, 10 },
        { 0/0, 10 },  -- -1.#IND or -nan(ind)
        { 1/0, 10, nil, 3 },  -- 1.#INF or inf
        { -1/0, 10, nil, 3 }, -- -1.#INF or -inf
        { "", 2 },
        { "a", 3 },
        { "abcdefghijklmno", 17 },
        { "abcdefghijklmnop", 19 },
        { ("1234567890"):rep(30), 304 },
        { {}, 2 },
        { { 1 }, 3 },
        { { 1, 2, 3, 4, 5 }, 7 },
        { { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }, 17 },
        { { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 }, 19 },
        { { 1, 2, 3, 4, a = 1, b = 2, [true] = 3, d = 4 }, 17 },
        { { 1, 2, 3, 4, 5, a = 1, b = 2, c = true, d = 4 }, 21 },
        { { 1, 2, 3, 4, 5, a = 1, b = 2, c = 3, d = 4, e = false }, 24 },
        { { a = 1, b = 2, c = 3 }, 11 },
        { { "aa", "bb", "aa", "bb" }, 14 },
        { { "aa1", "bb2", "aa3", "bb4" }, 18 },
        { { "aa1", "bb2", "aa1", "bb2" }, 14 },
        { { "aa1", "bb2", "bb2", "aa1" }, 14 },
        { { "abcdefghijklmno", "abcdefghijklmno", "abcdefghijklmno", "abcdefghijklmno" }, 24 },
        { { "abcdefghijklmno", "abcdefghijklmno", "abcdefghijklmno", "abcdefghijklmnop" }, 40 },
        { { 1, 2, 3, print, print, 6 }, 7, { 1, 2, 3, nil, nil, 6 } },
        { { 1, 2, 3, print, 5, 6 }, 8, { 1, 2, 3, nil, 5, 6 } },
        { { a = print, b = 1, c = print }, 5, { b = 1 } },
        { { "banned", 1, 2, 3, banned = 4, test = "banned", a = 1 }, 9, { nil, 1, 2, 3, a = 1 } },
        { { 1, 2, [math.huge] = "f", [3] = 3 }, 16, nil, 3 },
        { { 1, 2, [-math.huge] = "f", [3] = 3 }, 16, nil, 3 },
    }

    do
        local t = { a = 1, b = 2 }
        table.insert(testCases, { { t, t, t }, 13 })
        table.insert(testCases, { { { a = 1, b = 2 }, { a = 1, b = 2 }, { a = 1, b = 2 } }, 23 })
    end

    for i, testCase in ipairs(testCases) do
        checkLatest(i, unpack(testCase))
    end

    print = _G.print
    -- Since all the above tests assume serialization success, try some failures now.
    local failCases = {
        { print },
        { [print] = true },
        { [true] = print },
        print,
    }

    for _, testCase in ipairs(failCases) do
        local success = pcall(LibCBOR.Serialize, LibCBOR, testCase)
        assert(success == false)
    end

    print("All tests passed!")
end

-- Run tests immediately when executed from a non-WoW environment.
if require then
    LibCBOR:RunTests()
end
