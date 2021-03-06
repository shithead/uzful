--------------------------------------------------------------------------------
-- @author dodo
-- @copyright 2011 https://github.com/dodo
-- @release v3.4-503-g4972a28
--------------------------------------------------------------------------------

require("uzful.widget.util")
require("uzful.widget.span")
require("uzful.widget.netgraphs")
require("uzful.widget.cpugraphs")
require("uzful.widget.progressimage")
require("uzful.widget.calendar")
require("uzful.widget.titlebar")
local graph = require("uzful.widget.bandgraph")


local util = require("uzful.widget.util")

module("uzful.widget")

wibox = util.wibox
infobox = util.infobox
set_properties = util.set_properties
bandgraph = graph

