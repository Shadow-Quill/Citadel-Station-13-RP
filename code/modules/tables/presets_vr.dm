/obj/structure/table/darkglass
	name = "darkglass table"
	desc = "Shiny!"
	icon = 'icons/obj/tables_vr.dmi'
	icon_state = "darkglass_table_preview"
	flipped = -1
	can_reinforce = FALSE
	can_plate = FALSE

/obj/structure/table/darkglass/New()
	material = get_material_by_name("darkglass")
	remove_obj_verb(src, /obj/structure/table/verb/do_flip)
	remove_obj_verb(src, /obj/structure/table/proc/do_put)

	..()

/obj/structure/table/darkglass/dismantle(obj/item/tool/wrench/W, mob/user)
	to_chat(user, SPAN_WARNING("You cannot dismantle \the [src]."))
	return
/obj/structure/table/alien/blue
	icon = 'icons/turf/shuttle_alien_blue.dmi'


/obj/structure/table/fancyblack
	name = "fancy table"
	desc = "Cloth!"
	icon = 'icons/obj/tablesfancy_vr.dmi'
	icon_state = "fancyblack"
	flipped = -1
	can_reinforce = FALSE
	can_plate = FALSE

/obj/structure/table/fancyblack/Initialize(mapload)
	material = get_material_by_name("fancyblack")
	remove_obj_verb(src, /obj/structure/table/verb/do_flip)
	remove_obj_verb(src, /obj/structure/table/proc/do_put)
	. = ..()

/obj/structure/table/fancyblack/dismantle(obj/item/tool/wrench/W, mob/user)
	to_chat(user, SPAN_WARNING("You cannot dismantle \the [src]."))
	return

/obj/structure/table/gold
	icon_state = "plain_preview"
	color = "#FFFF00"

/obj/structure/table/gold/Initialize(mapload)
	material = get_material_by_name(MAT_GOLD)
	. = ..()
