//Holds defibs does NOT recharge them
//You can activate the mount with an empty hand to grab the paddles
//Not being adjacent will cause the paddles to snap back
/obj/machinery/defibrillator_mount
	name = "defibrillator mount"
	desc = "Holds defibrillators. You can grab the paddles if one is mounted."
	icon = 'icons/obj/machines/defib_mount.dmi'
	icon_state = "defibrillator_mount"
	density = FALSE
	use_power = USE_POWER_OFF
	power_channel = EQUIP
	req_one_access = list(access_medical, access_heads, access_security) //Who can access a mount during normal operation
/// The mount's defib
	var/obj/item/defib_kit/defib
/// if true, and a defib is loaded, it can't be removed without unlocking the clamps
	var/clamps_locked = FALSE
/// the type of wallframe it 'disassembles' into
	var/wallframe_type = /obj/item/circuitboard/defib_mount

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/defibrillator_mount, 28)

/obj/machinery/defibrillator_mount/loaded/Initialize(mapload) //loaded subtype for mapping use
	. = ..()
	defib = new/obj/item/defib_kit/loaded(src)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/defibrillator_mount/loaded, 28)

/obj/machinery/defibrillator_mount/Destroy()
	if(defib)
		QDEL_NULL(defib)
		STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/machinery/defibrillator_mount/examine(mob/user)
	. = ..()
	if(defib)
		. += SPAN_NOTICE("There is a defib unit hooked up. Alt-click to remove it.")
		if(GLOB.security_level >= SEC_LEVEL_RED)
			. += SPAN_NOTICE("Due to a security situation, its locking clamps can be toggled by swiping any ID.")
		else
			. += SPAN_NOTICE("Its locking clamps can be [clamps_locked ? "dis" : ""]engaged by swiping an ID with access.")

/obj/machinery/defibrillator_mount/update_overlays()
	. = ..()

	if(!defib)
		return

	. += "defib"

	if(defib.paddles)
		. += (defib.paddles.safety ? "online" : "emagged")

		if(defib.paddles.loc == defib)
			. += "paddles"

	if(defib.bcell)
		var/obj/item/cell/C = get_cell()
		var/ratio = C.charge / C.maxcharge
		ratio = CEILING(ratio * 4, 1) * 25
		. += "charge[ratio]"

	if(clamps_locked)
		. += "clamps"

/obj/machinery/defibrillator_mount/get_cell()
	if(defib)
		return defib.bcell

//defib interaction
/obj/machinery/defibrillator_mount/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!defib)
		to_chat(user, SPAN_WARNING("There's no defibrillator unit loaded!"))
		return
	if(defib.paddles.loc != defib)
		to_chat(user, SPAN_WARNING("[defib.paddles.loc == user ? "You are already" : "Someone else is"] holding [defib]'s paddles!"))
		return
	if(!in_range(src, user))
		to_chat(user, SPAN_WARNING("[defib]'s paddles overextend and come out of your hands!"))
		return
	user.put_in_hands(defib.paddles)

/obj/machinery/defibrillator_mount/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/defib_kit))
		if(defib)
			to_chat(user, SPAN_WARNING("There's already a defibrillator in [src]!"))
			return
		var/obj/item/defib_kit/D = I
		if(!D.bcell)
			to_chat(user, SPAN_WARNING("Only defibrilators containing a cell can be hooked up to [src]!"))
			return
		if(HAS_TRAIT(I, TRAIT_ITEM_NODROP) || !user.transfer_item_to_loc(I, src))
			to_chat(user, SPAN_WARNING("[I] is stuck to your hand!"))
			return
		user.visible_message(SPAN_NOTICE("[user] hooks up [I] to [src]!"), \
		SPAN_NOTICE("You press [I] into the mount, and it clicks into place."))
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		// Make sure the defib is set before processing begins.
		defib = I
		START_PROCESSING(SSobj, src)
		update_appearance()
		return

	else if(defib && I == defib.paddles)
		defib.reattach_paddles(user)
		return

	var/obj/item/card/id = I.GetID()
	if(id)
		if(check_access(id) || GLOB.security_level >= SEC_LEVEL_RED) //anyone can toggle the clamps in red alert!
			if(!defib)
				to_chat(user, SPAN_WARNING("You can't engage the clamps on a defibrillator that isn't there."))
				return
			clamps_locked = !clamps_locked
			to_chat(user, SPAN_NOTICE("Clamps [clamps_locked ? "" : "dis"]engaged."))
			update_appearance()
		else
			to_chat(user, SPAN_WARNING("Insufficient access."))
		return
	..()

/obj/machinery/defibrillator_mount/multitool_act(mob/living/user, obj/item/multitool)
	..()
	if(!defib)
		to_chat(user, SPAN_WARNING("There isn't any defibrillator to clamp in!"))
		return TRUE

	if(!clamps_locked)
		to_chat(user, SPAN_WARNING("[src]'s clamps are disengaged!"))
		return TRUE

	user.visible_message(SPAN_NOTICE("[user] presses [multitool] into [src]'s ID slot..."), \
	SPAN_NOTICE("You begin overriding the clamps on [src]..."))
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)

	if(!do_after(user, 10 SECONDS, target = src) || !clamps_locked)
		return

	user.visible_message(SPAN_NOTICE("[user] pulses [multitool], and [src]'s clamps slide up."), \
	SPAN_NOTICE("You override the locking clamps on [src]!"))
	playsound(src, 'sound/machines/locktoggle.ogg', 50, TRUE)
	clamps_locked = FALSE
	update_appearance()
	return TRUE

/obj/machinery/defibrillator_mount/wrench_act(mob/living/user, obj/item/I)
	if(!wallframe_type)
		return ..()

	if(defib)
		user.action_feedback(SPAN_WARNING("The mount can't be deconstructed while a defibrillator unit is loaded!"))
		..()
		return TRUE

	new wallframe_type(get_turf(src))
	qdel(src)
	playsound(src, I.tool_sound, 50, TRUE)
	user.action_feedback(SPAN_NOTICE("You remove [src] from the wall."))
	return TRUE

/obj/machinery/defibrillator_mount/AltClick(mob/living/carbon/user)
	if(!istype(user) || !user.canUseTopic(src, be_close = TRUE))
		return
	if(!defib)
		user.action_feedback(SPAN_WARNING("It'd be hard to remove a defib unit from a mount that has none."))
		return

	if(clamps_locked)
		user.action_feedback(SPAN_WARNING("You try to tug out [defib], but the mount's clamps are locked tight!"))
		return

	if(!user.put_in_hands(defib))
		user.action_feedback(SPAN_WARNING("You need a free hand!"))
		user.visible_message(SPAN_NOTICE("[user] unhooks [defib] from [src], dropping it on the floor."), \
		SPAN_NOTICE("You slide out [defib] from [src] and unhook the charging cables, dropping it on the floor."))

	else
		user.visible_message(SPAN_NOTICE("[user] unhooks [defib] from [src]."), \
		SPAN_NOTICE("You slide out [defib] from [src] and unhook the charging cables."))

	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
	// Make sure processing ends before the defib is nulled
	STOP_PROCESSING(SSobj, src)
	defib = null
	update_appearance()

/obj/machinery/defibrillator_mount/charging
	name = "PENLITE defibrillator mount"
	desc = "Holds defibrillators. You can grab the paddles if one is mounted. This PENLITE variant also allows for slow recharging of the defibrillator."
	icon_state = "penlite_mount"
	use_power = USE_POWER_IDLE
	wallframe_type = /obj/item/circuitboard/defib_mount/charging


/obj/machinery/defibrillator_mount/charging/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/machinery/defibrillator_mount/charging/process(delta_time)
	var/obj/item/cell/C = defib.bcell
	if(!C || !operable())
		return
	if(C.charge < C.maxcharge)
		use_power(active_power_usage * delta_time)
		C.give(40 * delta_time)
		defib.update_icon()
		update_overlays()

// //wallframe, for attaching the mounts easily
// /obj/item/wallframe/defib_mount
// 	name = "unhooked defibrillator mount"
// 	desc = "A frame for a defibrillator mount. Once placed, it can be removed with a wrench."
// 	icon = 'icons/obj/machines/defib_mount.dmi'
// 	icon_state = "defibrillator_mount"
// 	custom_materials = list(/datum/material/iron = 300, /datum/material/glass = 100)
// 	w_class = WEIGHT_CLASS_BULKY
// 	result_path = /obj/machinery/defibrillator_mount
// 	pixel_shift = 28

// /obj/item/wallframe/defib_mount/charging
// 	name = "unhooked PENLITE defibrillator mount"
// 	desc = "A frame for a PENLITE defibrillator mount. Unlike the normal mount, it can passively recharge the unit inside."
// 	icon_state = "penlite_mount"
// 	custom_materials = list(/datum/material/iron = 300, /datum/material/glass = 100, /datum/material/silver = 50)
// 	result_path = /obj/machinery/defibrillator_mount/charging
