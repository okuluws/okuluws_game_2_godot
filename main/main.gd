extends Node2D



# TODO:
# !add account registration
# add chat
# add world hub
# add private worlds
# add auction house
# add npcs
# add more enemies
# add more player types
# add more player animations
# add player emote system
# add ping display
# add skills / collections
# add more stats, crit, mana, fortune
# !serverside validation of player packets
# add tablist
# add more player roles f.e vip / legend / tryhard
# add trading
# add mineable ores
# add enemy ai
# add server selection screen

# WORK IN PROGRESS:



func parse_os_arguments():
	# definitly not stolen code
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
	return arguments



func _ready():
	if OS.get_cmdline_args().has("serve"):
		var args = parse_os_arguments()
		Server.start(args.username, args.password, int(args["port"]))
		return




# NOTE: DELETE BEFORE RELEASE!
func _on_host_pressed():
	Server.start("host0", "K7bKo5GVgG2-mwo", 42000)
