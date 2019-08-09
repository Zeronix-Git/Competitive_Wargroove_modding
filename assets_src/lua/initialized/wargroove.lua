local OldWargroove = require "wargroove/wargroove"

local Wargroove = {}

function Wargroove.init()
  OldWargroove.isRNGEnabled = Wargroove.isRNGEnabled
end

function Wargroove.isRNGEnabled()
  return false
end

return Wargroove