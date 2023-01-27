/*
 * Wrench
 */
/obj/item/tool/wrench
	name = "wrench"
	desc = "A wrench with many common uses. Can be usually found in your hand."
	icon = 'icons/obj/tools.dmi'
	icon_state = "wrench"
	item_state = "wrench"
	slot_flags = SLOT_BELT
	tool_behaviour = TOOL_WRENCH
	force = 6
	throw_force = 7
	w_class = ITEMSIZE_SMALL
	origin_tech = list(TECH_MATERIAL = 1, TECH_ENGINEERING = 1)
	matter = list(MAT_STEEL = 150)
	attack_verb = list("bashed", "battered", "bludgeoned", "whacked")
	tool_sound = 'sound/items/ratchet.ogg'
	tool_speed = 1
	drop_sound = 'sound/items/drop/wrench.ogg'
	pickup_sound = 'sound/items/pickup/wrench.ogg'
	var/random_color = TRUE

/obj/item/tool/wrench/Initialize(mapload)
	. = ..()
	if(random_color)
		switch(pick("nocolor","red","yellow","green","blue"))
			if ("nocolor")
				icon_state = "wrench"
			if ("red")
				icon_state = "wrench_red"
			if ("yellow")
				icon_state = "wrench_yellow"
			if ("green")
				icon_state = "wrench_green"
			if ("blue")
				icon_state = "wrench_blue"

/obj/item/tool/wrench/red
	icon_state = "wrench_red"

/obj/item/tool/wrench/goblin
	name = "short wrench"
	desc = "A short, rusty old wrench. It looks like it was made for a smaller species. "
	icon_state = "wrench_goblin"
	random_color = FALSE

/obj/item/tool/wrench/bone
	name = "primitive wrench"
	desc = "A primitive wrench carved from bone. It does not grip consistently."
	icon_state = "wrench_bone"
	tool_speed = 1.25
	random_color = FALSE

/obj/item/tool/wrench/brass
	name = "brass wrench"
	desc = "A brass plated wrench. Its finely tuned mechanism allows for a strong grip."
	icon_state = "wrench_brass"
	tool_speed = 0.75
	random_color = FALSE

/obj/item/tool/wrench/cyborg
	name = "automatic wrench"
	desc = "An advanced robotic wrench. Can be found in industrial synthetic shells."
	tool_sound = 'sound/items/drill_use.ogg'
	tool_speed = 0.5
	random_color = FALSE

/obj/item/tool/wrench/RIGset
	name = "integrated wrench"
	desc = "If you're seeing this, someone did a dum-dum."
	tool_sound = 'sound/items/drill_use.ogg'
	tool_speed = 0.7

/obj/item/tool/wrench/hybrid	// Slower and bulkier than normal power tools, but it has the power of reach.
	name = "strange wrench"
	desc = "A wrench with many common uses. Can be usually found in your hand."
	icon = 'icons/obj/tools.dmi'
	icon_state = "hybwrench"
	slot_flags = SLOT_BELT
	force = 8
	throw_force = 10
	w_class = ITEMSIZE_NORMAL
	slowdown = 0.1
	origin_tech = list(TECH_MATERIAL = 3, TECH_ENGINEERING = 3, TECH_PHORON = 2)
	attack_verb = list("bashed", "battered", "bludgeoned", "whacked", "warped", "blasted")
	tool_sound = 'sound/effects/stealthoff.ogg'
	tool_speed = 0.5
	reach = 2
	random_color = FALSE

/datum/category_item/catalogue/anomalous/precursor_a/alien_wrench
	name = "Precursor Alpha Object - Fastener Torque Tool"
	desc = "This is an object that has a distinctive tool shape. \
	It has a handle on one end, with a simple mechanism attached to it. \
	On the other end is the head of the tool, with two sides each glowing \
	a different color. The head opens up towards the top, in a similar shape \
	as a conventional wrench.\
	<br><br>\
	When an object is placed into the head section of the tool, the tool appears \
	to force the object to be turned in a specific direction. The direction can be \
	inverted by pressing down on the mechanism on the handle. It is not known if \
	this tool was intended by its creators to tighten fasteners or if it has a less obvious \
	purpose, however it is very well suited to act in a wrench's capacity regardless."
	value = CATALOGUER_REWARD_EASY

/obj/item/tool/wrench/alien
	name = "alien wrench"
	desc = "A polarized wrench. It causes anything placed between the jaws to turn."
	catalogue_data = list(/datum/category_item/catalogue/anomalous/precursor_a/alien_wrench)
	icon = 'icons/obj/abductor.dmi'
	icon_state = "wrench"
	tool_sound = 'sound/effects/empulse.ogg'
	tool_speed = 0.1
	origin_tech = list(TECH_MATERIAL = 5, TECH_ENGINEERING = 5)
	random_color = FALSE

/obj/item/tool/wrench/power
	name = "hand drill"
	desc = "A simple powered hand drill. It's fitted with a bolt bit."
	icon_state = "drill_bolt"
	item_state = "drill"
	tool_sound = 'sound/items/drill_use.ogg'
	matter = list(MAT_STEEL = 150, MAT_SILVER = 50)
	origin_tech = list(TECH_MATERIAL = 2, TECH_ENGINEERING = 2)
	force = 8
	w_class = ITEMSIZE_SMALL
	throw_force = 8
	attack_verb = list("drilled", "screwed", "jabbed")
	tool_speed = 0.25
	var/obj/item/tool/screwdriver/power/counterpart = null
	random_color = FALSE

/obj/item/tool/wrench/power/Initialize(mapload, no_counterpart = TRUE)
	. = ..()
	if(!counterpart && no_counterpart)
		counterpart = new(src, FALSE)
		counterpart.counterpart = src

/obj/item/tool/wrench/power/Destroy()
	if(counterpart)
		counterpart.counterpart = null // So it can qdel cleanly.
		QDEL_NULL(counterpart)
	return ..()

/obj/item/tool/wrench/power/attack_self(mob/user)
	playsound(get_turf(user),'sound/items/change_drill.ogg',50,1)
	user.temporarily_remove_from_inventory(src, INV_OP_FORCE | INV_OP_SHOULD_NOT_INTERCEPT | INV_OP_SILENT)
	if(!user.put_in_active_hand(counterpart))
		counterpart.forceMove(get_turf(user))
	forceMove(counterpart)
	to_chat(user, SPAN_NOTICE("You attach the screw driver bit to [src]."))
