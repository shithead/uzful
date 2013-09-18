--------------------------------------------------------------------------------
-- @author john
-- @author pt
-- @copyright 2011 https://github.com/tuxcodejohn
-- @release v3.4-503-g4972a28
--------------------------------------------------------------------------------

local io = io
local table = table
local util = require('awful.util')
local string = string
local assert = assert

module("uzful.getinfo")

--- Network Interfaces
-- @return list of all network interfaces (without `lo`)
function interfaces()
	local f = io.popen("ls /sys/class/net", "r")
	local out = assert(f:read("*a"))
	f:close()
	local ret = {}
	for w in string.gfind(out, "%w+") do
	  	f,emsg,enum = io.open("/sys/class/net/".. w .. "/device" ,"r")
		if (enum ~= 2 ) then 
			 table.insert(ret, w)
		 end
	end
	return ret
end

--- CPUs
-- @return list of all cpus
function local_cpus()
	local cpu_lines = {}
	local c = ""
	local v = ""
	for line in io.lines("/proc/stat") do
		v= nil
		v, c = string.find(line, "^(cpu%d+)")
		if v then
			table.insert(cpu_lines, string.sub(line,v,c))
		end
	end
	return cpu_lines
end

--- CPU Count
-- @return number of cpus
function cpu_count()
    return #local_cpus()
end

-- Operation System
-- @return list of OS information
function os()
	local ret = {}
	local uname = string.lower( util.pread("uname") )
	ret.version = util.pread("uname	-r")
	ret.name = util.pread("hostname")
	if string.match(uname, "bsd") then
		ret.BSD = ret.version
	elseif string.match(uname, "linux") then
		ret.LINUX = ret.version
	end
	return ret
end

