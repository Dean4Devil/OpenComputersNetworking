local encoding = {}

-- Encode an UNSIGNED integer
-- INPUT: unsigned interger
-- OUTPUT: array of bytes
local function encode_unsigned_integer(uint)
	-- Check how many bytes we need to encode this integer
	local bytecount = math.ceil(select(2, math.frexp(uint))/8)

	-- TODO: Implement long length encoding
	if bytecount > 127 then
		print("Long encoding form is not yet implemented")
		return
	end

	local result = {}
	for i = 1, bytecount do
		-- Traverse from the highest byte (2^(8*bytecount)) to the lowest one (2^(8*0))
		local mod = bytecount - i
		local mul = 2^(8*mod)

		-- Divide the int by mul so we get to the byte we want.
		result[i] = math.floor(uint/mul)

		-- Remove the byte we just encoded
		uint = uint - result[i]*mul
	end
	table.insert(result, 1, tonumber("00000010",2))
	table.insert(result, 2, bytecount)

	return result
end

-- Decodes a bytearray to an integer
local function decode_unsigned_integer(bytearray)
	local len = #bytearray

	local number = 0
	for i = 1, len do
		number = number + bytearray[i] * 2^(8*(len-i))
	end

	return number
end

-- Encodes a string
local function encode_string(str)
	if str:len() > 127 then
		print("Long lenth form not implemented!")
		return
	end
	local bytes = {str:byte(1,-1)}
	table.insert(bytes, 1, tonumber("00000011",2))
	table.insert(bytes, 2, str:len())
	return bytes
end

-- Decodes a string
local function decode_string(bytearray)
	return string.char(table.unpack(bytearray))
end

-- Outputs the encoded data into file
-- Returns a string if file is nil
function encoding.encode(data, file)
	local tagdata = {}
	if type(data) == "table" then
		for _,val in pairs(data) do
			if type(val) == "nil" then
				table.insert(tagdata,tonumber("00000000",2))
				table.insert(tagdata,tonumber("00000000",2))
			elseif tonumber(val) ~= nil then
				local encoded = encode_unsigned_integer(tonumber(val))
				for i=1,#encoded do
					table.insert(tagdata,encoded[i])
				end
			elseif type(val) == "string" then
				local encoded = encode_string(val)
				for i=1,#encoded do
					table.insert(tagdata, encoded[i])
				end
			end
		end
	else
		if type(data) == "nil" then
			tagdata = {tonumber("00000000",2), tonumber("00000000",2)}
		elseif tonumber(data) ~= nil then
			tagdata = encode_unsigned_integer(tonumber(data))
		elseif type(data) == "string" then
			tagdata = encode_string(data)
		end
	end

	tag = string.char(table.unpack(tagdata))
	if file == nil then
		return tag
	else
		file:write(tag)
		return
	end
end

-- data can be either a string directly or a file handle
function encoding.decode(data)
	local bytearray = {}
	if type(data) == "table" then -- File Handle
	elseif type(data) == "string" then
		bytearray = {data:byte(1, -1)}
	end

	local array_len = #bytearray
	local tag_len = bytearray[2] + 2
	local start = 1
	local result = {}
	while true do
		local value = {}
		for i=start,tag_len do
			table.insert(value, bytearray[i])
		end
		if value[1] == 0 then -- Nil value
			table.insert(result, nil)
		elseif value[1] == 2 then -- Unsigned Integer
			table.remove(value, 1)
			table.remove(value, 1)
			table.insert(result,decode_unsigned_integer(value))
		elseif value[1] == 3 then -- String
			table.remove(value, 1)
			table.remove(value, 1)
			table.insert(result,decode_string(value))
		end

		if tag_len >= array_len then break end
		start = tag_len + 1
		-- Access the next lenght tag and set accordingly
		tag_len = tag_len + bytearray[tag_len+2] + 2
	end

	return result
end

--ser = require("serialization")

----input_data = {16, 256, 655432, 9872345892345, "This is a String", "T!\"ß#+asdf"}
--input_data = 987345097234057234908752390847523098475238904752398475230984752934752983475239084752349850239475

--result = encoding.encode(input_data)
--print("Binary encoding scheme:", result:len())
--print("Serialize encoding:", ser.serialize(input_data):len())
