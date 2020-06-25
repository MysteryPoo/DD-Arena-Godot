local nk = require("nakama")
local pokeapi = require("pokeapi")

local function get_pokemon(_, payload)
  -- We'll assume payload was sent as JSON and decode it.
  local json = nk.json_decode(payload)

  local success, result = pcall(pokeapi.lookup_pokemon, json.PokemonName)
  if (not success) then
    error("Unable to lookup pokemon.")
  else
    local pokemon = {
      name = result.name,
      height = result.height,
      weight = result.weight,
      image = result.sprites.front_default
    }
    return nk.json_encode(pokemon)
  end
end

nk.register_rpc(get_pokemon, "get_pokemon")
