//RD 'gun'
/obj/item/bluespace_harpoon
	name = "bluespace harpoon"
	desc = "For climbing on bluespace mountains!"

	icon = 'icons/obj/gun/energy.dmi'
	icon_state = "harpoon-2"

	w_class = ITEMSIZE_NORMAL

	throw_speed = 4
	throw_range = 20

	origin_tech = list(TECH_BLUESPACE = 5)

	var/mode = 1  // 1 mode - teleport you to turf  0 mode teleport turf to you
	var/last_fire = 0
	var/transforming = 0
	var/cooldown = 20 SECONDS
	var/wallhack = TRUE
	var/range = 8
	var/failchance = 5
	var/failrange = 24

/obj/item/bluespace_harpoon/afterattack(atom/A, mob/user as mob)
	var/current_fire = world.time
	if(!user || !A)
		return
	if(transforming)
		to_chat(user,SPAN_WARNING("You can't fire while \the [src] transforming!"))
		return
	if(!((wallhack && (get_dist(A, get_turf(user)) <= range)) || (A in view(get_turf(user), range))))
		to_chat(user, SPAN_WARNING("The target is either out of range, or you couldn't see it clearly enough to lock on!"))
		return
	if((current_fire - last_fire) <= cooldown)
		to_chat(user,SPAN_WARNING("\The [src] is recharging..."))
		return
	if(is_jammed(A) || is_jammed(user))
		to_chat(user,SPAN_WARNING("\The [src] shot fizzles due to interference!"))
		last_fire = current_fire
		playsound(user, 'sound/weapons/wave.ogg', 60, 1)
		return
	var/turf/T = get_turf(A)
	if(!T || T.check_density(ignore_border = TRUE))
		to_chat(user,SPAN_WARNING("That's a little too solid to harpoon into!"))
		return
	if(get_area(A).area_flags & AREA_FLAG_BLUE_SHIELDED)
		to_chat(user, SPAN_WARNING("The target area protected by bluespace shielding!"))
		return

	last_fire = current_fire
	playsound(user, 'sound/weapons/wave.ogg', 60, 1)

	user.visible_message(SPAN_WARNING("[user] fires \the [src]!"),SPAN_WARNING("You fire \the [src]!"))

	var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
	s.set_up(4, 1, A)
	s.start()
	s = new /datum/effect_system/spark_spread
	s.set_up(4, 1, user)
	s.start()

	var/turf/FromTurf = mode ? get_turf(user) : get_turf(A)
	var/turf/ToTurf = mode ? get_turf(A) : get_turf(user)

	for(var/atom/movable/AM in FromTurf)
		if(!isobj(AM) && !isliving(AM))
			continue
		if(AM.anchored)
			continue
		var/turf/real_target = prob(failchance)? pick(trange(failrange, user)) : ToTurf
		AM.locationTransitForceMove(real_target, allow_pulled = FALSE, allow_grabbed = GRAB_AGGRESSIVE)

/obj/item/bluespace_harpoon/attack_self(mob/living/user as mob)
	return chande_fire_mode(user)

/obj/item/bluespace_harpoon/verb/chande_fire_mode(mob/user as mob)
	set name = "Change fire mode"
	set category = "Object"
	set src in oview(1)
	if(transforming) return
	mode = !mode
	transforming = 1
	to_chat(user,SPAN_INFO("You change \the [src]'s mode to [mode ? "transmiting" : "receiving"]."))
	update_icon()

/obj/item/bluespace_harpoon/update_icon()
	if(transforming)
		switch(mode)
			if(0)
				flick("harpoon-2-change", src)
				icon_state = "harpoon-1"
			if(1)
				flick("harpoon-1-change",src)
				icon_state = "harpoon-2"
		transforming = 0
