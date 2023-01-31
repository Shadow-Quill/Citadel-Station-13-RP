#define PER_LIMB_STEEL_COST (10000 / 10)
////
//  One-part Refactor
////
/mob/living/carbon/human/proc/nano_partswap()
	set name = "Ref - Single Limb"
	set desc = "Allows you to replace and reshape your limbs as you see fit."
	set category = "Abilities"
	set hidden = TRUE

	if(stat)
		to_chat(src,SPAN_WARNING("You must be awake and standing to perform this action!"))
		return

	var/obj/item/organ/internal/nano/refactory/refactory = nano_get_refactory()
	//Missing the organ that does this
	if(!istype(refactory))
		to_chat(src,SPAN_WARNING("You don't have a working refactory module!"))
		return


	var/choice = input(src,"Pick the bodypart to change:", "Refactor - One Bodypart") as null|anything in species.has_limbs
	if(!choice)
		return

	//Organ is missing, needs restoring
	if(!organs_by_name[choice] || istype(organs_by_name[choice], /obj/item/organ/external/stump)) //allows limb stumps to regenerate like removed limbs.
		if(refactory.get_stored_material(MAT_STEEL) < PER_LIMB_STEEL_COST)
			to_chat(src,SPAN_WARNING("You're missing that limb, and need to store at least [PER_LIMB_STEEL_COST] steel to regenerate it."))
			return
		var/regen = alert(src,"That limb is missing, do you want to regenerate it in exchange for [PER_LIMB_STEEL_COST] steel?","Regenerate limb?","Yes","No")
		if(regen != "Yes")
			return
		if(organs_by_name[choice])
			var/obj/item/organ/external/oldlimb = organs_by_name[choice]
			oldlimb.removed()
			qdel(oldlimb)

		// var/mob/living/simple_mob/protean_blob/blob = nano_intoblob()
		active_regen = TRUE
		src.visible_message("<B>[src]</B>'s flesh begins to bubble, growing oily tendrils from their limb stump...")  // Gives a visualization for regenerating limbs.
		if(do_after(src,5 SECONDS))  // Makes you not need to blob to regen a single limb. I'm keeping the full-body regen as blob-only, though
			if(!refactory.use_stored_material(MAT_STEEL,PER_LIMB_STEEL_COST))
				return
			var/list/limblist = species.has_limbs[choice]
			var/limbpath = limblist["path"]
			var/obj/item/organ/external/new_eo = new limbpath(src)
			organs_by_name[choice] = new_eo
			new_eo.robotize(synthetic ? synthetic.company : null) //Use the base we started with
			regenerate_icons()
			visible_message("<B>[src]</B>'s tendrils solidify into a [new_eo].")
		active_regen = FALSE
		// nano_outofblob(blob)  No longer needed as we're not going to blob
		return

	//Organ exists, let's reshape it
	var/list/usable_manufacturers = list()
	for(var/company in GLOB.chargen_robolimbs)
		var/datum/robolimb/M = GLOB.chargen_robolimbs[company]
		if(!(choice in M.parts))
			continue
		if(impersonate_bodytype_legacy in M.species_cannot_use)
			continue
		if(M.whitelisted_to && !(ckey in M.whitelisted_to))
			continue
		usable_manufacturers[company] = M
	if(!usable_manufacturers.len)
		return
	var/manu_choice = input(src, "Which manufacturer do you wish to mimic for this limb?", "Manufacturer for [choice]") as null|anything in usable_manufacturers

	if(!manu_choice)
		return //Changed mind

	var/obj/item/organ/external/eo = organs_by_name[choice]
	if(!eo)
		return //Lost it meanwhile

	eo.robotize(manu_choice)
	visible_message("<B>[src]</B>'s [eo] subtly contorts.")
	update_icons_body()

////
//  Full Refactor
////
/mob/living/carbon/human/proc/nano_regenerate() //fixed the proc, it used to leave active_regen true.
	set name = "Ref - Whole Body"
	set desc = "Allows you to regrow limbs and replace organs, given you have enough materials."
	set category = "Abilities"
	set hidden = TRUE

	if(stat)
		to_chat(src,SPAN_WARNING("You must be awake and standing to perform this action!"))
		return

	var/obj/item/organ/internal/nano/refactory/refactory = nano_get_refactory()
	//Missing the organ that does this
	if(!istype(refactory))
		to_chat(src,SPAN_WARNING("You don't have a working refactory module!"))
		return

	//Already regenerating
	if(active_regen)
		to_chat(src, SPAN_WARNING("You are already refactoring!"))
		return

	var/swap_not_rebuild = alert(src,"Do you want to rebuild, or reshape?","Rebuild or Reshape","Reshape","Cancel","Rebuild")
	if(swap_not_rebuild == "Cancel")
		return
	if(swap_not_rebuild == "Reshape")
		var/list/usable_manufacturers = list()
		for(var/company in GLOB.chargen_robolimbs)
			var/datum/robolimb/M = GLOB.chargen_robolimbs[company]
			if(!(BP_TORSO in M.parts))
				continue
			if(impersonate_bodytype_legacy in M.species_cannot_use)
				continue
			if(M.whitelisted_to && !(ckey in M.whitelisted_to))
				continue
			usable_manufacturers[company] = M
		if(!usable_manufacturers.len)
			return
		var/manu_choice = input(src, "Which manufacturer do you wish to mimic?", "Manufacturer") as null|anything in usable_manufacturers

		if(!manu_choice)
			return //Changed mind
		if(!organs_by_name[BP_TORSO])
			return //Ain't got a torso!

		var/obj/item/organ/external/torso = organs_by_name[BP_TORSO]
		to_chat(src, SPAN_DANGER("Remain still while the process takes place! It will take 5 seconds."))
		visible_message("<B>[src]</B>'s form collapses into an amorphous blob of black ichor...")

		var/mob/living/simple_mob/protean_blob/blob = nano_intoblob()
		active_regen = TRUE
		if(do_after(blob,5 SECONDS))
			synthetic = usable_manufacturers[manu_choice]
			torso.robotize(manu_choice) //Will cascade to all other organs.
			regenerate_icons()
			visible_message("<B>[src]</B>'s form reshapes into a new one...")
		active_regen = FALSE
		nano_outofblob(blob)
		return

	//Not enough resources (AND spends the resources, should be the last check)
	if(refactory.get_stored_material(MAT_STEEL) < min(10000, refactory.max_storage))
		to_chat(src, SPAN_WARNING("You need to be maxed out on normal metal to do this!"))
		return

	var/delay_length = round(active_regen_delay * species.active_regen_mult)
	to_chat(src, SPAN_DANGER("Remain still while the process takes place! It will take [delay_length/10] seconds."))
	visible_message("<B>[src]</B>'s form begins to shift and ripple as if made of oil...")
	active_regen = TRUE

	var/mob/living/simple_mob/protean_blob/blob = nano_intoblob()
	if(do_after(blob, delay_length, null, 0))
		if(stat != DEAD && refactory)
			//Not enough resources (AND spends the resources, should be the last check)
			if(!refactory.use_stored_material(MAT_STEEL,refactory.max_storage))
				to_chat(src, SPAN_WARNING("You need to be maxed out on normal metal to do this!"))
				return
			var/list/holder = refactory.materials
			species.create_organs(src)
			var/obj/item/organ/external/torso = organs_by_name[BP_TORSO]
			torso.robotize() //synthetic wasn't defined here.
			LAZYCLEARLIST(blood_DNA)
			LAZYCLEARLIST(feet_blood_DNA)
			blood_color = null
			feet_blood_color = null
			regenerate_icons() //Probably worth it, yeah.
			var/obj/item/organ/internal/nano/refactory/new_refactory = locate() in internal_organs
			if(!new_refactory)
				log_debug(SPAN_DEBUGWARNING("[src] protean-regen'd but lacked a refactory when done."))
			else
				new_refactory.materials = holder
			to_chat(src, SPAN_NOTICE("Your refactoring is complete.")) //Guarantees the message shows no matter how bad the timing.
			to_chat(blob, SPAN_NOTICE("Your refactoring is complete!"))
		else
			to_chat(src,  SPAN_CRITICAL("Your refactoring has failed."))
			to_chat(blob, SPAN_CRITICAL("Your refactoring has failed!"))
	else
		to_chat(src,  SPAN_CRITICAL("Your refactoring is interrupted."))
		to_chat(blob, SPAN_CRITICAL("Your refactoring is interrupted!"))
	active_regen = FALSE
	nano_outofblob()


////
//  Storing metal
////
/mob/living/carbon/human/proc/nano_metalnom()
	set name = "Ref - Store Metals"
	set desc = "If you're holding a stack of material, you can consume some and store it for later."
	set category = "Abilities"
	set hidden = TRUE

	var/obj/item/organ/internal/nano/refactory/refactory = nano_get_refactory()
	//Missing the organ that does this
	if(!istype(refactory))
		to_chat(src,SPAN_WARNING("You don't have a working refactory module!"))
		return

	var/held = get_active_held_item()
	if(!istype(held,/obj/item/stack/material))
		to_chat(src,SPAN_WARNING("You aren't holding a stack of materials in your active hand...!"))
		return

	var/obj/item/stack/material/matstack = held
	var/substance = matstack.material.name
	var/list/edible_materials = list(MAT_STEEL, MAT_SILVER, MAT_GOLD, MAT_URANIUM, MAT_METALHYDROGEN) //Can't eat all materials, just useful ones.
	var allowed = FALSE
	for(var/material in edible_materials)
		if(material == substance) allowed = TRUE
	if(!allowed)
		to_chat(src,SPAN_WARNING("You can't process [substance]!"))
		return //Only a few things matter, the rest are best not cluttering the lists.

	var/howmuch = input(src,"How much do you want to store? (0-[matstack.amount])","Select amount") as null|num
	if(!howmuch || matstack != get_active_held_item() || howmuch > matstack.amount)
		return //Quietly fail

	var/actually_added = refactory.add_stored_material(substance,howmuch*matstack.perunit)
	matstack.use(CEILING((actually_added/matstack.perunit), 1))
	if(actually_added && actually_added < howmuch)
		to_chat(src,SPAN_WARNING("Your refactory module is now full, so only [actually_added] units were stored."))
		visible_message(SPAN_NOTICE("[src] nibbles some of the [substance] right off the stack!"))
	else if(actually_added)
		to_chat(src,SPAN_NOTICE("You store [actually_added] units of [substance]."))
		visible_message(SPAN_NOTICE("[src] devours some of the [substance] right off the stack!"))
	else
		to_chat(src,SPAN_NOTICE("You're completely capped out on [substance]!"))
// toggling buffs
/mob/living/carbon/human/proc/nano_togglebuff()
	set name = "Ref - Toggle Material Augment"
	set desc = "Toggle your consumption of stored diamonds, mhydrogen and plasteel."
	set category = "Abilities"
	set hidden = TRUE

	var/obj/item/organ/internal/nano/refactory/refactory = nano_get_refactory()
	//Missing the organ that does this
	if(!istype(refactory))
		to_chat(temporary_form? temporary_form : src, SPAN_WARNING("You don't have a working refactory module!"))
		return
	if(refactory.processingbuffs)
		to_chat(temporary_form? temporary_form : src, SPAN_WARNING("You toggle material consumption off."))
		refactory.processingbuffs = FALSE
	else
		refactory.processingbuffs = TRUE
		to_chat(temporary_form? temporary_form : src, SPAN_WARNING("You toggle material consumption on."))

////
//  Blob Form
////
/mob/living/carbon/human/proc/nano_blobform()
	set name = "Toggle Blobform"
	set desc = "Switch between amorphous and humanoid forms."
	set category = "Abilities"
	set hidden = TRUE

	//Blob form
	if(temporary_form)
		var/datum/species/protean/P = species
		ASSERT(istype(P))
		if(P.getActualDamage(src) > P.damage_to_blob) //Reforming HP threshold.
			to_chat(temporary_form,SPAN_WARNING("You need to regenerate more nanites first!"))
		else if(temporary_form.stat)
			to_chat(temporary_form,SPAN_WARNING("You can only do this while not stunned."))
		else
			nano_outofblob(temporary_form)

	//Human form
	else if(stat)
		to_chat(src,SPAN_WARNING("You can only do this while not stunned."))
		return
	else if(HAS_TRAIT(src, TRAIT_DISRUPTED))
		to_chat(src,SPAN_WARNING("You can't do this while disrupted!"))
		return
	else
		nano_intoblob()

////
//  Change fitting
////
/mob/living/carbon/human/proc/nano_change_fitting()
	set name = "Change Species Fit"
	set desc = "Tweak your shape to change what suits you fit into (and their sprites!)."
	set category = "Abilities"

	if(stat)
		to_chat(src,SPAN_WARNING("You must be awake and standing to perform this action!"))
		return

	var/new_species_id = input("Please select a species to emulate.", "Shapeshifter Body") as null|anything in SScharacters.playable_species
	var/datum/species/new_species = SScharacters.resolve_species_id(new_species_id)
	if(new_species)
		impersonate_bodytype_legacy = new_species.get_bodytype_legacy()
		impersonate_bodytype = new_species.default_bodytype
		regenerate_icons() //Expensive, but we need to recrunch all the icons we're wearing

////
//  Change size
////
/mob/living/carbon/human/proc/nano_set_size()
	set name = "Adjust Volume"
	set category = "Abilities"
	set hidden = TRUE

	var/mob/living/user = temporary_form || src

	var/obj/item/organ/internal/nano/refactory/refactory = nano_get_refactory()
	//Missing the organ that does this
	if(!istype(refactory))
		to_chat(user,SPAN_WARNING("You don't have a working refactory module!"))
		return

	var/nagmessage = "Adjust your mass to be a size between 75 to 200%. Up-sizing consumes metal, downsizing returns metal."
	var/new_size = input(user, nagmessage, "Pick a Size", user.size_multiplier*100) as num|null
	if(!new_size || !ISINRANGE(new_size, 75, 200))
		return

	var/size_factor = new_size/100

	//Will be: -1.75 for 200->25, and 1.75 for 25->200
	var/sizediff = size_factor - user.size_multiplier

	//Negative if shrinking, positive if growing
	//Will be (PLSC*2)*-1.75 to 1.75
	//For 2000 PLSC that's -7000 to 7000
	var/cost = (PER_LIMB_STEEL_COST*2)*sizediff

	//Sizing up
	if(cost > 0)
		if(refactory.use_stored_material(MAT_STEEL,cost))
			user.resize(size_factor, TRUE)
		else
			to_chat(user,SPAN_WARNING("That size change would cost [cost] steel, which you don't have."))
	//Sizing down (or not at all)
	else if(cost <= 0)
		cost = abs(cost)
		var/actually_added = refactory.add_stored_material(MAT_STEEL,cost)
		user.resize(size_factor, TRUE)
		if(actually_added != cost)
			to_chat(user,SPAN_WARNING("Unfortunately, [cost-actually_added] steel was lost due to lack of storage space."))

	user.visible_message(SPAN_NOTICE("Black mist swirls around [user] as they change size."))

/// /// /// A helper to reuse
/mob/living/proc/nano_get_refactory(obj/item/organ/internal/nano/refactory/R)
	if(istype(R))
		if(!(R.status & ORGAN_DEAD))
			return R
	return

/mob/living/simple_mob/protean_blob/nano_get_refactory()
	if(refactory)
		return ..(refactory)
	if(humanform)
		return humanform.nano_get_refactory()

/mob/living/carbon/human/nano_get_refactory()
	return ..(locate(/obj/item/organ/internal/nano/refactory) in internal_organs)



/// /// /// Ability objects for stat panel
/obj/effect/protean_ability
	name = "Activate"
	desc = ""
	icon = 'icons/mob/clothing/species/protean/protean_powers.dmi'
	var/ability_name
	var/to_call

/obj/effect/protean_ability/proc/atom_button_text()
	return src

/obj/effect/protean_ability/statpanel_click(client/C, action, auth)
	Click()

/obj/effect/protean_ability/Click(var/location, var/control, var/params)
	var/list/clickprops = params2list(params)
	var/opts = clickprops["shift"]

	if(opts)
		to_chat(usr,SPAN_NOTICE("<b>[ability_name]</b> - [desc]"))
	else
		//Humanform using it
		if(ishuman(usr))
			do_ability(usr)
		//Blobform using it
		else
			var/mob/living/simple_mob/protean_blob/blob = usr
			do_ability(blob.humanform)

/obj/effect/protean_ability/proc/do_ability(var/mob/living/L)
	if(istype(L))
		call(L,to_call)()
	return FALSE

/// The actual abilities
/obj/effect/protean_ability/into_blob
	ability_name = "Toggle Blobform"
	desc = "Discard your shape entirely, changing to a low-energy blob that can fit into small spaces. You'll consume steel to repair yourself in this form."
	icon_state = "blob"
	to_call = /mob/living/carbon/human/proc/nano_blobform

/obj/effect/protean_ability/change_volume
	ability_name = "Change Volume"
	desc = "Alter your size by consuming steel to produce additional nanites, or regain steel by reducing your size and reclaiming them."
	icon_state = "volume"
	to_call = /mob/living/carbon/human/proc/nano_set_size

/obj/effect/protean_ability/reform_limb
	ability_name = "Ref - Single Limb"
	desc = "Rebuild or replace a single limb, assuming you have 2000 steel."
	icon_state = "limb"
	to_call = /mob/living/carbon/human/proc/nano_partswap

/obj/effect/protean_ability/reform_body
	ability_name = "Ref - Whole Body"
	desc = "Rebuild your entire body into whatever design you want, assuming you have 10,000 metal."
	icon_state = "body"
	to_call = /mob/living/carbon/human/proc/nano_regenerate

/obj/effect/protean_ability/metal_nom
	ability_name = "Ref - Store Metals"
	desc = "Store the metal you're holding. Your refactory can only store steel, and all other metals will be converted into nanites ASAP for various effects."
	icon_state = "metal"
	to_call = /mob/living/carbon/human/proc/nano_metalnom


/obj/effect/protean_ability/toggle_buff
	ability_name = "Ref - Toggle Material Augment"
	desc = "Toggle your consumption of augmenting materials such as diamonds, plasteel and metallic hydrogen. Toggling this on will cause these materials to be consumed to provide special effects."
	icon_state = "togglebuff"
	to_call = /mob/living/carbon/human/proc/nano_togglebuff


#undef PER_LIMB_STEEL_COST
