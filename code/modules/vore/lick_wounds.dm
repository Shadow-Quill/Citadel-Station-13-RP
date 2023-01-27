/mob/living/carbon/human/proc/lick_wounds(var/mob/living/carbon/M in living_mobs(1))
	set name = "Lick Wounds"
	set category = "Abilities"
	set desc = "Disinfect and heal small wounds with your saliva."

	if(nutrition < 50)
		to_chat(src, SPAN_WARNING("You need more energy to produce antiseptic enzymes. Eat something and try again."))
		return

	if ( ! (istype(src, /mob/living/carbon/human) || \
			istype(src, /mob/living/silicon)) )
		to_chat(src, SPAN_WARNING("If you even have a tongue, it doesn't work that way."))
		return

	if (istype(M, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = M
		var/obj/item/organ/external/affecting = H.get_organ(zone_sel.selecting)

		if(!affecting)
			to_chat(src, SPAN_WARNING("No body part there to work on!"))
			return

		if(affecting.organ_tag == BP_HEAD)
			if(H.head && istype(H.head,/obj/item/clothing/head/helmet/space))
				to_chat(src, SPAN_WARNING("You can't seem to lick through [H.head]!"))
				return

		else
			if(H.wear_suit && istype(H.wear_suit,/obj/item/clothing/suit/space))
				to_chat(src, SPAN_WARNING("You can't lick your way through [H.wear_suit]!"))
				return

		if(affecting.robotic == ORGAN_ROBOT)
			to_chat(src, SPAN_WARNING("You don't think your spit will help a robotic limb."))
			return

		if(affecting.robotic >= ORGAN_LIFELIKE)
			to_chat(src, SPAN_WARNING("You lick [M]'s [affecting.name], but it seems to have no effect..."))
			return

		if(affecting.open)
			to_chat(src, SPAN_NOTICE("The [affecting.name] is cut open, you don't think your spit will help them!"))
			return

		if(affecting.is_bandaged() && affecting.is_salved())
			to_chat(src, SPAN_WARNING("The wounds on [M]'s [affecting.name] have already been treated."))
			return

		else
			visible_message(SPAN_NOTICE("\The [src] starts licking the wounds on [M]'s [affecting.name] clean."), \
					             SPAN_NOTICE("You start licking the wounds on [M]'s [affecting.name] clean.") )

			for (var/datum/wound/W in affecting.wounds)

				if(W.bandaged && W.salved && W.disinfected)
					continue

				if(!do_mob(src, M, W.damage/5))
					to_chat(src, SPAN_NOTICE("You must stand still to clean wounds."))
					break

				if(affecting.is_bandaged() && affecting.is_salved()) // We do a second check after the delay, in case it was bandaged after the first check.
					to_chat(src, SPAN_WARNING("The wounds on [M]'s [affecting.name] have already been treated."))
					return

				else
					visible_message("<span class='notice'>\The [src] [pick("slathers \a [W.desc] on [M]'s [affecting.name] with their spit.",
																			   "drags their tongue across \a [W.desc] on [M]'s [affecting.name].",
																			   "drips saliva onto \a [W.desc] on [M]'s [affecting.name].",
																			   "uses their tongue to disinfect \a [W.desc] on [M]'s [affecting.name].",
																			   "licks \a [W.desc] on [M]'s [affecting.name], cleaning it.")]</span>", \
					                        	SPAN_NOTICE("You treat \a [W.desc] on [M]'s [affecting.name] with your antiseptic saliva.") )
					nutrition -= 20
					W.salve()
					W.bandage()
					W.disinfect()
					H.UpdateDamageIcon()
					playsound(src, 'sound/effects/ointment.ogg', 25)
