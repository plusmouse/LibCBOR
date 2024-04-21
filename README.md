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
