/obj/machinery/atmospherics/component/unary/heat_exchanger
	name = "Heat Exchanger"
	desc = "Exchanges heat between two input gases. Setup for fast heat transfer"
	icon = 'icons/obj/atmospherics/heat_exchanger.dmi'
	icon_state = "intact"
	pipe_state = "heunary"
	density = FALSE

	var/obj/machinery/atmospherics/component/unary/heat_exchanger/partner = null
	var/update_cycle

/obj/machinery/atmospherics/component/unary/heat_exchanger/update_icon()
	if(node)
		icon_state = "intact"
	else
		icon_state = "exposed"
	return

/obj/machinery/atmospherics/component/unary/heat_exchanger/atmos_init()
	if(!partner)
		var/partner_connect = turn(dir,180)

		for(var/obj/machinery/atmospherics/component/unary/heat_exchanger/target in get_step(src,partner_connect))
			if(target.dir & get_dir(src,target))
				partner = target
				partner.partner = src
				break

	..()

/obj/machinery/atmospherics/component/unary/heat_exchanger/process()
	..()
	if(!partner)
		return 0

	if(!air_master || air_master.current_cycle <= update_cycle)
		return 0

	update_cycle = air_master.current_cycle
	partner.update_cycle = air_master.current_cycle

	var/air_heat_capacity = air_contents.heat_capacity()
	var/other_air_heat_capacity = partner.air_contents.heat_capacity()
	var/combined_heat_capacity = other_air_heat_capacity + air_heat_capacity

	var/old_temperature = air_contents.temperature
	var/other_old_temperature = partner.air_contents.temperature

	if(combined_heat_capacity > 0)
		var/combined_energy = partner.air_contents.temperature*other_air_heat_capacity + air_heat_capacity*air_contents.temperature

		var/new_temperature = combined_energy/combined_heat_capacity
		air_contents.temperature = new_temperature
		partner.air_contents.temperature = new_temperature

	if(network)
		if(abs(old_temperature-air_contents.temperature) > 1)
			network.update = 1

	if(partner.network)
		if(abs(other_old_temperature-partner.air_contents.temperature) > 1)
			partner.network.update = 1

	return 1

/obj/machinery/atmospherics/component/unary/heat_exchanger/attackby(var/obj/item/W as obj, var/mob/user as mob)
	if (!W.is_wrench())
		return ..()
	var/turf/T = src.loc
	if (level==1 && isturf(T) && !T.is_plating())
		to_chat(user, SPAN_WARNING("You must remove the plating first."))
		return 1
	if(unsafe_pressure())
		to_chat(user, SPAN_WARNING("You feel a gust of air blowing in your face as you try to unwrench [src]. Maybe you should reconsider.."))
	add_fingerprint(user)
	playsound(src, W.tool_sound, 50, 1)
	to_chat(user, SPAN_NOTICE("You begin to unfasten \the [src]..."))
	if (do_after(user, 40 * W.tool_speed))
		user.visible_message( \
			SPAN_NOTICE("\The [user] unfastens \the [src]."), \
			SPAN_NOTICE("You have unfastened \the [src]."), \
			"You hear a ratchet.")
		deconstruct()
