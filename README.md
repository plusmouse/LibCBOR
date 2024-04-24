LibCBOR
========

LibCBOR is a pure Lua implementation of the [CBOR](http://cbor.io/), a compact
data serialization format, defined in [RFC
7049](http://tools.ietf.org/html/rfc7049) for World of Warcraft

API
---

```lua
local cbor = LibStub("LibCBOR-1.0")
```

### `cbor:Serialize(object)`

Encodes `object` into its CBOR representation and returns that as a string.

### `cbor:Deserialize(string)`

Decodes CBOR encoded data from `string` and returns a Lua value.

Using external input
--------------------

When injecting external CBOR data into a lua file for WoW replace the following
codes with the literal characters shown to prevent the lua interpreter glitching:
* Null (0) is to be replaced with `\000`
* alert (7) to literally `\a`
* newline (10) to `\n`
* carriage return (13) to `\r`
* `\` (92) to `\\`
* `"` (147) to `\"`
