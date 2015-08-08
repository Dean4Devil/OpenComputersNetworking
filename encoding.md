# Arbitary type encoding

This encoding scheme allows for all Lua datatypes to be encoded in an relatively efficient binary encoding.
It uses a TLV-scheme for encoding.
Big Endianess is used to encode numerical values.

## Encoding Structure

The encoding of data consists of three components that appear in the following order:

Identifier octets | Lenght octets | Value octets
:----------------:|:-------------:|:-----------:
*Type*            | *Length*      | *Value*

### Identifier Octets

The identifier octets encode the type of the value.

Its bitstructure is as follows:

| 8 | 7 - 1 |
|---|-------|
|P/C| Type  |

The 8th bit defines if the value is primitive or constructed.
Currently constructed values are not implemented and this bit MUST be set to 0.

The type of the value is encoded with the other 7 bits according to this table:

|dec| binary   | Lua type         |
|:-:|:--------:|:-----------------|
| 0 | 00000000 | Nil              |
| 1 | 00000001 | Bool             |
| 2 | 00000010 | Unsigned Integer |
| 3 | 00000011 | String           |

### Length octets

The length octets give the length of the value (excluding the identifier and length octets).

There are two form how the length of a value can be encoded, a short form that can encode up to 127 bytes of lenght and a long form
that can encode up to 2^1016 bytes of length (Which is 7.022238x10^305 bytes which is slightly larger than the size of the Internet of around 5 Exabytes (5x10^18 bytes)).

The most significant bit in the length octets contains the scheme is used. If it is set to 0 the short form is used, if it is set to 1 the long form is used.

#### Short form:

The short form can encode lengths up to 127 bytes. It MUST be used if the payload is less than 128 bytes.

It uses one byte of length octets.

The most significant bit MUST be set to 0.
The seven others encode the length of the payload in bytes.

For example a string with the length of 35 would have the length byte set to `00100011`.

#### Long form:

In the long form the first byte of the length octets does not encode the length of the payload itself but the lenght of the following lenght octets in bytes.

A lenght of 64161 would be encoded as `10000010 11111010 10100001`.
