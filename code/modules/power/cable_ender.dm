//
// Super Duper Ender Cable - Luckily these are not constructable!
//

//if powernetless_only = 1, will only get connections without powernet
/obj/structure/cable/ender
	// Pretend to be heavy duty power cable
	icon = 'icons/obj/power_cond_heavy.dmi'
	name = "large power cable"
	desc = "This cable is tough. It cannot be cut with simple hand tools."
	plane = TURF_PLANE
	layer = HEAVYDUTY_WIRE_LAYER //Just below pipes
	color = null
	unacidable = 1
	var/id = null

/obj/structure/cable/ender/get_connections(var/powernetless_only = 0)
	. = ..() // Do the normal stuff
	if(id)
		for(var/obj/structure/cable/ender/target in cable_list)
			if(target.id == id)
				if (!powernetless_only || !target.powernet)
					. |= target

/obj/structure/cable/ender/attackby(obj/item/W, mob/user)
	src.add_fingerprint(user)
	if(W.is_wirecutter())
		to_chat(user,  SPAN_NOTICE(" These cables are too tough to be cut with those [W.name]."))
		return
	else if(istype(W, /obj/item/stack/cable_coil))
		to_chat(user,  SPAN_NOTICE(" You will need heavier cables to connect to these."))
		return
	else
		..()

// Because they cannot be rebuilt, they are hard to destroy
/obj/structure/cable/ender/legacy_ex_act(severity)
	return
