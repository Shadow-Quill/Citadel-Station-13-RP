/obj/structure/bed/chair/e_chair
	name = "electric chair"
	desc = "Looks absolutely SHOCKING!"
	icon_state = "echair0"
	var/on = 0
	var/obj/item/assembly/shock_kit/part = null
	var/last_time = 1.0

/obj/structure/bed/chair/e_chair/Initialize(mapload)
	. = ..()
	add_overlay(image('icons/obj/objects.dmi', src, "echair_over", MOB_LAYER + 1, dir))

/obj/structure/bed/chair/e_chair/attackby(obj/item/W as obj, mob/user as mob)
	if(W.is_wrench())
		var/obj/structure/bed/chair/C = new /obj/structure/bed/chair(loc)
		playsound(src, W.tool_sound, 50, 1)
		C.setDir(dir)
		part.loc = loc
		part.master = null
		part = null
		qdel(src)
		return
	return

/obj/structure/bed/chair/e_chair/verb/toggle()
	set name = "Toggle Electric Chair"
	set category = "Object"
	set src in oview(1)

	if(on)
		on = 0
		icon_state = "echair0"
	else
		on = 1
		icon_state = "echair1"
	to_chat(usr, SPAN_NOTICE("You switch [on ? "on" : "off"] [src]."))
	return

/obj/structure/bed/chair/e_chair/rotate_clockwise()
	. = ..()
	cut_overlays()
	add_overlay(image('icons/obj/objects.dmi', src, "echair_over", MOB_LAYER + 1, dir))	//there's probably a better way of handling this, but eh. -Pete

/obj/structure/bed/chair/e_chair/proc/shock()
	if(!on)
		return
	if(last_time + 50 > world.time)
		return
	last_time = world.time

	// special power handling
	var/area/A = get_area(src)
	if(!isarea(A))
		return
	if(!A.powered(EQUIP))
		return
	A.use_power_oneoff(EQUIP, 5000)
	var/light = A.power_light
	A.updateicon()

	flick("echair1", src)
	var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
	s.set_up(12, 1, src)
	s.start()
	if(has_buckled_mobs())
		for(var/a in buckled_mobs)
			var/mob/living/L = a
			L.burn_skin(85)
			to_chat(L, SPAN_DANGER("You feel a deep shock course through your body!"))
			sleep(1)
			L.burn_skin(85)
			L.Stun(600)
	visible_message(SPAN_DANGER("The electric chair went off!"), SPAN_DANGER("You hear a deep sharp shock!"))

	A.power_light = light
	A.updateicon()
	return
