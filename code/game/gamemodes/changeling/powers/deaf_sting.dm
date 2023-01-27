/datum/power/changeling/deaf_sting
	name = "Deaf Sting"
	desc = "We silently sting a human, completely deafening them for a short time."
	enhancedtext = "Deafness duration is extended."
	ability_icon_state = "ling_sting_deafen"
	genomecost = 1
	allowduringlesserform = 1
	verbpath = /mob/proc/changeling_deaf_sting


/mob/proc/changeling_deaf_sting()
	set category = "Changeling"
	set name = "Deaf sting (5)"
	set desc="Sting target:"

	var/mob/living/carbon/T = changeling_sting(5,/mob/proc/changeling_deaf_sting)
	if(!T)	return 0
	add_attack_logs(src,T,"Deaf sting (changeling)")
	var/duration = 300
	if(src.mind.changeling.recursive_enhancement)
		duration = duration + 100
		to_chat(src, SPAN_NOTICE("They will be unable to hear for a little longer."))
	to_chat(T, SPAN_DANGER("Your ears pop and begin ringing loudly!"))
	T.sdisabilities |= SDISABILITY_DEAF
	spawn(duration)	T.sdisabilities &= ~SDISABILITY_DEAF
	feedback_add_details("changeling_powers","DS")
	return 1
