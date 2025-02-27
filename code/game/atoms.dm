/atom
	var/level = 2
	var/atom_flags = ATOM_FLAG_NO_TEMP_CHANGE
	var/list/blood_DNA
	var/was_bloodied
	var/blood_color
	var/last_bumped = 0
	var/pass_flags = 0
	var/throwpass = 0
	var/germ_level = GERM_LEVEL_AMBIENT // The higher the germ level, the more germ on the atom.
	var/simulated = 1 //filter for actions - used by lighting overlays
	var/fluorescent // Shows up under a UV light.
	var/datum/reagents/reagents // chemical contents.
	var/list/climbers
	var/climb_speed_mult = 1
	var/explosion_resistance = 0
	var/icon_scale_x = 1 // Holds state of horizontal scaling applied.
	var/icon_scale_y = 1 // Ditto, for vertical scaling.
	var/icon_rotation = 0 // And one for rotation as well.
	var/transform_animate_time = 0 // If greater than zero, transform-based adjustments (scaling, rotating) will visually occur over this time.

	var/tmp/currently_exploding = FALSE
	var/tmp/default_pixel_x
	var/tmp/default_pixel_y
	var/tmp/default_pixel_z

// This is called by the maploader prior to Initialize to perform static modifications to vars set on the map. Intended use case: adjust tag vars on duplicate templates.
/atom/proc/modify_mapped_vars(map_hash)
	SHOULD_CALL_PARENT(TRUE)

/atom/proc/reveal_blood()
	return

/atom/proc/assume_air(datum/gas_mixture/giver)
	return null

/atom/proc/remove_air(amount)
	return null

/atom/proc/return_air()
	if(loc)
		return loc.return_air()
	else
		return null

//return flags that should be added to the viewer's sight var.
//Otherwise return a negative number to indicate that the view should be cancelled.
/atom/proc/check_eye(user)
	if (istype(user, /mob/living/silicon/ai)) // WHYYYY
		return 0
	return -1

//Return flags that may be added as part of a mobs sight
/atom/proc/additional_sight_flags()
	return 0

/atom/proc/additional_see_invisible()
	return 0

/atom/proc/on_reagent_change()
	return

/atom/proc/Bumped(var/atom/movable/AM)
	return

/*//Convenience proc to see whether a container can be accessed in a certain way.

	proc/can_subract_container()
		return flags & EXTRACT_CONTAINER

	proc/can_add_container()
		return flags & INSERT_CONTAINER
*/

/atom/proc/CheckExit()
	return 1

// If you want to use this, the atom must have the PROXMOVE flag, and the moving
// atom must also have the PROXMOVE flag currently to help with lag. ~ ComicIronic
/atom/proc/HasProximity(atom/movable/AM)
	return

/atom/proc/emp_act(var/severity)
	return

/atom/proc/set_density(var/new_density)
	if(density != new_density)
		density = !!new_density

/atom/proc/bullet_act(obj/item/projectile/P, def_zone)
	P.on_hit(src, 0, def_zone)
	. = 0

/atom/proc/in_contents_of(container)//can take class or object instance as argument
	if(ispath(container))
		if(istype(src.loc, container))
			return 1
	else if(src in container)
		return 1
	return

/*
 *	atom/proc/search_contents_for(path,list/filter_path=null)
 * Recursevly searches all atom contens (including contents contents and so on).
 *
 * ARGS: path - search atom contents for atoms of this type
 *	   list/filter_path - if set, contents of atoms not of types in this list are excluded from search.
 *
 * RETURNS: list of found atoms
 */

/atom/proc/search_contents_for(path,list/filter_path=null)
	var/list/found = list()
	for(var/atom/A in src)
		if(istype(A, path))
			found += A
		if(filter_path)
			var/pass = 0
			for(var/type in filter_path)
				pass |= istype(A, type)
			if(!pass)
				continue
		if(A.contents.len)
			found += A.search_contents_for(path,filter_path)
	return found




/*
Beam code by Gunbuddy

Beam() proc will only allow one beam to come from a source at a time.  Attempting to call it more than
once at a time per source will cause graphical errors.
Also, the icon used for the beam will have to be vertical and 32x32.
The math involved assumes that the icon is vertical to begin with so unless you want to adjust the math,
its easier to just keep the beam vertical.
*/
/atom/proc/Beam(atom/BeamTarget,icon_state="b_beam",icon='icons/effects/beam.dmi',time=50, maxdistance=10)
	//BeamTarget represents the target for the beam, basically just means the other end.
	//Time is the duration to draw the beam
	//Icon is obviously which icon to use for the beam, default is beam.dmi
	//Icon_state is what icon state is used. Default is b_beam which is a blue beam.
	//Maxdistance is the longest range the beam will persist before it gives up.
	var/EndTime=world.time+time
	while(BeamTarget&&world.time<EndTime&&get_dist(src,BeamTarget)<maxdistance&&z==BeamTarget.z)
	//If the BeamTarget gets deleted, the time expires, or the BeamTarget gets out
	//of range or to another z-level, then the beam will stop.  Otherwise it will
	//continue to draw.

		set_dir(get_dir(src,BeamTarget))	//Causes the source of the beam to rotate to continuosly face the BeamTarget.

		for(var/obj/effect/overlay/beam/O in orange(10,src))	//This section erases the previously drawn beam because I found it was easier to
			if(O.BeamSource==src)				//just draw another instance of the beam instead of trying to manipulate all the
				qdel(O)							//pieces to a new orientation.
		var/Angle=round(Get_Angle(src,BeamTarget))
		var/icon/I=new(icon,icon_state)
		I.Turn(Angle)
		var/DX=(32*BeamTarget.x+BeamTarget.pixel_x)-(32*x+pixel_x)
		var/DY=(32*BeamTarget.y+BeamTarget.pixel_y)-(32*y+pixel_y)
		var/N=0
		var/length=round(sqrt((DX)**2+(DY)**2))
		for(N,N<length,N+=32)
			var/obj/effect/overlay/beam/X=new(loc)
			X.BeamSource=src
			if(N+32>length)
				var/icon/II=new(icon,icon_state)
				II.DrawBox(null,1,(length-N),32,32)
				II.Turn(Angle)
				X.icon=II
			else X.icon=I
			var/Pixel_x=round(sin(Angle)+32*sin(Angle)*(N+16)/32)
			var/Pixel_y=round(cos(Angle)+32*cos(Angle)*(N+16)/32)
			if(DX==0) Pixel_x=0
			if(DY==0) Pixel_y=0
			if(Pixel_x>32)
				for(var/a=0, a<=Pixel_x,a+=32)
					X.x++
					Pixel_x-=32
			if(Pixel_x<-32)
				for(var/a=0, a>=Pixel_x,a-=32)
					X.x--
					Pixel_x+=32
			if(Pixel_y>32)
				for(var/a=0, a<=Pixel_y,a+=32)
					X.y++
					Pixel_y-=32
			if(Pixel_y<-32)
				for(var/a=0, a>=Pixel_y,a-=32)
					X.y--
					Pixel_y+=32
			X.pixel_x=Pixel_x
			X.pixel_y=Pixel_y
		sleep(3)	//Changing this to a lower value will cause the beam to follow more smoothly with movement, but it will also be more laggy.
					//I've found that 3 ticks provided a nice balance for my use.
	for(var/obj/effect/overlay/beam/O in orange(10,src)) if(O.BeamSource==src) qdel(O)


// A type overriding /examine() should either return the result of ..() or return TRUE if not calling ..()
// Calls to ..() should generally not supply any arguments and instead rely on BYOND's automatic argument passing
// There is no need to check the return value of ..(), this is only done by the calling /examinate() proc to validate the call chain
/atom/proc/examine(mob/user, distance, infix = "", suffix = "")
	SHOULD_CALL_PARENT(TRUE)
	//This reformat names to get a/an properly working on item descriptions when they are bloody
	var/f_name = "\a [src][infix]."
	if(blood_color && !istype(src, /obj/effect/decal))
		if(gender == PLURAL)
			f_name = "some "
		else
			f_name = "a "
		f_name += "<font color ='[blood_color]'>stained</font> [name][infix]!"

	to_chat(user, "[html_icon(src)] That's [f_name] [suffix]")
	to_chat(user, desc)
	return TRUE

// called by mobs when e.g. having the atom as their machine, loc (AKA mob being inside the atom) or buckled var set.
// see code/modules/mob/mob_movement.dm for more.
/atom/proc/relaymove()
	return

//called to set the atom's dir and used to add behaviour to dir-changes
/atom/proc/set_dir(new_dir)
	SHOULD_CALL_PARENT(TRUE)
	. = new_dir != dir
	dir = new_dir
	if(.)
		if(light_source_solo)
			light_source_solo.source_atom.update_light()
		else if(light_source_multi)
			var/datum/light_source/L
			for(var/thing in light_source_multi)
				L = thing
				if(L.light_angle)
					L.source_atom.update_light()

/atom/proc/set_icon_state(var/new_icon_state)
	SHOULD_CALL_PARENT(TRUE)
	if(has_extension(src, /datum/extension/base_icon_state))
		var/datum/extension/base_icon_state/bis = get_extension(src, /datum/extension/base_icon_state)
		bis.base_icon_state = new_icon_state
		update_icon()
	else
		icon_state = new_icon_state

/atom/proc/update_icon()
	SHOULD_CALL_PARENT(TRUE)
	on_update_icon(arglist(args))

/atom/proc/on_update_icon()
	return

/atom/proc/get_contained_external_atoms()
	for(var/atom/movable/AM in contents)
		if(!QDELETED(AM) && AM.simulated)
			LAZYADD(., AM)

/atom/proc/dump_contents()
	for(var/thing in get_contained_external_atoms())
		var/atom/movable/AM = thing
		AM.dropInto(loc)
		if(ismob(AM))
			var/mob/M = AM
			if(M.client)
				M.client.eye = M.client.mob
				M.client.perspective = MOB_PERSPECTIVE

/atom/proc/physically_destroyed(var/skip_qdel)
	SHOULD_CALL_PARENT(TRUE)
	dump_contents()
	if(!skip_qdel && !QDELETED(src))
		qdel(src)
	. = TRUE

/atom/proc/try_detonate_reagents(var/severity = 3)
	if(reagents)
		for(var/rtype in reagents.reagent_volumes)
			var/decl/material/R = GET_DECL(rtype)
			R.explosion_act(src, severity)

/atom/proc/explosion_act(var/severity)
	SHOULD_CALL_PARENT(TRUE)
	if(!currently_exploding)
		currently_exploding = TRUE
		. = (severity <= 3)
		if(.)
			for(var/atom/movable/AM in contents)
				AM.explosion_act(severity++)
			try_detonate_reagents(severity)
		currently_exploding = FALSE

/atom/proc/emag_act(var/remaining_charges, var/mob/user, var/emag_source)
	return NO_EMAG_ACT

/atom/proc/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	return

/atom/proc/melt()
	return

/atom/proc/lava_act()
	visible_message("<span class='danger'>\The [src] sizzles and melts away, consumed by the lava!</span>")
	playsound(src, 'sound/effects/flare.ogg', 100, 3)
	qdel(src)
	. = TRUE

/atom/proc/hitby(atom/movable/AM, var/datum/thrownthing/TT)//already handled by throw impact
	SHOULD_CALL_PARENT(TRUE)
	if(isliving(AM))
		var/mob/living/M = AM
		M.apply_damage(TT.speed*5, BRUTE)

//returns 1 if made bloody, returns 0 otherwise
/atom/proc/add_blood(mob/living/carbon/human/M)
	if(atom_flags & ATOM_FLAG_NO_BLOOD)
		return 0

	if(!blood_DNA || !istype(blood_DNA, /list))	//if our list of DNA doesn't exist yet (or isn't a list) initialise it.
		blood_DNA = list()

	was_bloodied = 1
	blood_color = COLOR_BLOOD_HUMAN
	if(istype(M))
		if (!istype(M.dna, /datum/dna))
			M.dna = new /datum/dna(null)
			M.dna.real_name = M.real_name
		M.check_dna()
		blood_color = M.species.get_blood_color(M)
	. = 1
	return 1

/mob/living/proc/handle_additional_vomit_reagents(var/obj/effect/decal/cleanable/vomit/vomit)
	vomit.reagents.add_reagent(/decl/material/liquid/acid/stomach, 5)

/atom/proc/clean_blood()
	SHOULD_CALL_PARENT(TRUE)
	if(!simulated)
		return
	fluorescent = 0
	germ_level = 0
	blood_color = null
	if(istype(blood_DNA, /list))
		blood_DNA = null
		var/datum/extension/forensic_evidence/forensics = get_extension(src, /datum/extension/forensic_evidence)
		if(forensics)
			forensics.remove_data(/datum/forensics/blood_dna)
			forensics.remove_data(/datum/forensics/gunshot_residue)
		return TRUE

/atom/proc/get_global_map_pos()
	if(!islist(global.global_map) || !length(global.global_map)) return
	var/cur_x = null
	var/cur_y = null
	var/list/y_arr = null
	for(cur_x=1,cur_x<=global.global_map.len,cur_x++)
		y_arr = global.global_map[cur_x]
		cur_y = y_arr.Find(src.z)
		if(cur_y)
			break
//	log_debug("X = [cur_x]; Y = [cur_y]")

	if(cur_x && cur_y)
		return list("x"=cur_x,"y"=cur_y)
	else
		return 0

/atom/proc/checkpass(passflag)
	return pass_flags&passflag

// Show a message to all mobs and objects in sight of this atom
// Use for objects performing visible actions
// message is output to anyone who can see, e.g. "The [src] does something!"
// blind_message (optional) is what blind people will hear e.g. "You hear something!"
/atom/proc/visible_message(var/message, var/self_message, var/blind_message, var/range = world.view, var/checkghosts = null)
	var/turf/T = get_turf(src)
	var/list/mobs = list()
	var/list/objs = list()
	get_mobs_and_objs_in_view_fast(T,range, mobs, objs, checkghosts)

	for(var/o in objs)
		var/obj/O = o
		O.show_message(message, VISIBLE_MESSAGE, blind_message, AUDIBLE_MESSAGE)

	for(var/m in mobs)
		var/mob/M = m
		if(M.see_invisible >= invisibility)
			M.show_message(message, VISIBLE_MESSAGE, blind_message, AUDIBLE_MESSAGE)
		else if(blind_message)
			M.show_message(blind_message, AUDIBLE_MESSAGE)

// Show a message to all mobs and objects in earshot of this atom
// Use for objects performing audible actions
// message is the message output to anyone who can hear.
// deaf_message (optional) is what deaf people will see.
// hearing_distance (optional) is the range, how many tiles away the message can be heard.
/atom/proc/audible_message(var/message, var/deaf_message, var/hearing_distance = world.view, var/checkghosts = null, var/radio_message)
	var/turf/T = get_turf(src)
	var/list/mobs = list()
	var/list/objs = list()
	get_mobs_and_objs_in_view_fast(T, hearing_distance, mobs, objs, checkghosts)

	for(var/m in mobs)
		var/mob/M = m
		M.show_message(message,2,deaf_message,1)
	for(var/o in objs)
		var/obj/O = o
		O.show_message(message,2,deaf_message,1)

/atom/movable/proc/dropInto(var/atom/destination)
	while(istype(destination))
		var/atom/drop_destination = destination.onDropInto(src)
		if(!istype(drop_destination) || drop_destination == destination)
			return forceMove(destination)
		destination = drop_destination
	return forceMove(null)

/atom/proc/onDropInto(var/atom/movable/AM)
	return // If onDropInto returns null, then dropInto will forceMove AM into us.

/atom/movable/onDropInto(var/atom/movable/AM)
	return loc // If onDropInto returns something, then dropInto will attempt to drop AM there.

// Called when hitting the atom with a grab.
// Will skip attackby() and afterattack() if returning TRUE.
/atom/proc/grab_attack(var/obj/item/grab/G)
	return FALSE

/atom/proc/climb_on()

	set name = "Climb"
	set desc = "Climbs onto an object."
	set category = "Object"
	set src in oview(1)

	do_climb(usr)

/atom/proc/can_climb(var/mob/living/user, post_climb_check=0)
	if (!(atom_flags & ATOM_FLAG_CLIMBABLE) || !user.can_touch(src) || (!post_climb_check && climbers && (user in climbers)))
		return 0

	if (!user.Adjacent(src))
		to_chat(user, "<span class='danger'>You can't climb there, the way is blocked.</span>")
		return 0

	var/obj/occupied = turf_is_crowded(user)
	if(occupied)
		to_chat(user, "<span class='danger'>There's \a [occupied] in the way.</span>")
		return 0
	return 1

/mob/proc/can_touch(var/atom/touching)
	if(!touching.Adjacent(src) || incapacitated())
		return FALSE
	if(restrained())
		to_chat(src, SPAN_WARNING("You are restrained."))
		return FALSE
	if (buckled)
		to_chat(src, SPAN_WARNING("You are buckled down."))
	return TRUE

/atom/proc/turf_is_crowded(var/atom/ignore)
	var/turf/T = get_turf(src)
	if(!T || !istype(T))
		return 0
	for(var/atom/A in T.contents)
		if(ignore && ignore == A)
			continue
		if(A.atom_flags & ATOM_FLAG_CLIMBABLE)
			continue
		if(A.density && !(A.atom_flags & ATOM_FLAG_CHECKS_BORDER)) //ON_BORDER structures are handled by the Adjacent() check.
			return A
	return 0

/atom/proc/do_climb(var/mob/living/user)
	if (!can_climb(user))
		return 0

	add_fingerprint(user)
	user.visible_message("<span class='warning'>\The [user] starts climbing onto \the [src]!</span>")
	LAZYDISTINCTADD(climbers,user)

	if(!do_after(user,(issmall(user) ? MOB_CLIMB_TIME_SMALL : MOB_CLIMB_TIME_MEDIUM) * climb_speed_mult, src))
		LAZYREMOVE(climbers,user)
		return 0

	if(!can_climb(user, post_climb_check=1))
		LAZYREMOVE(climbers,user)
		return 0

	var/target_turf = get_turf(src)

	//climbing over border objects like railings
	if((atom_flags & ATOM_FLAG_CHECKS_BORDER) && get_turf(user) == target_turf)
		target_turf = get_step(src, dir)

	user.forceMove(target_turf)

	if (get_turf(user) == target_turf)
		user.visible_message("<span class='warning'>\The [user] climbs onto \the [src]!</span>")
	LAZYREMOVE(climbers,user)
	return 1

/atom/proc/object_shaken()
	for(var/mob/living/M in climbers)
		SET_STATUS_MAX(M, STAT_WEAK, 1)
		to_chat(M, "<span class='danger'>You topple as you are shaken off \the [src]!</span>")
		climbers.Cut(1,2)

	for(var/mob/living/M in get_turf(src))
		if(M.lying) return //No spamming this on people.

		SET_STATUS_MAX(M, STAT_WEAK, 3)
		to_chat(M, "<span class='danger'>You topple as \the [src] moves under you!</span>")

		if(prob(25))

			var/damage = rand(15,30)
			var/mob/living/carbon/human/H = M
			if(!istype(H))
				to_chat(H, "<span class='danger'>You land heavily!</span>")
				M.adjustBruteLoss(damage)
				return

			var/obj/item/organ/external/affecting = pick(H.organs)
			if(affecting)
				to_chat(M, "<span class='danger'>You land heavily on your [affecting.name]!</span>")
				affecting.take_external_damage(damage, 0)
				if(affecting.parent)
					affecting.parent.add_autopsy_data("Misadventure", damage)
			else
				to_chat(H, "<span class='danger'>You land heavily!</span>")
				H.adjustBruteLoss(damage)

			H.UpdateDamageIcon()
			H.updatehealth()
	return

/atom/proc/get_color()
	return color

/atom/proc/set_color(new_color)
	color = new_color

/atom/proc/get_cell()
	return

/atom/proc/building_cost()
	. = list()

/atom/Topic(href, href_list)
	var/mob/user = usr
	if(href_list["look_at_me"] && istype(user))
		var/turf/T = get_turf(src)
		if(T.CanUseTopic(user, global.view_topic_state) != STATUS_CLOSE)
			user.examinate(src)
			return TOPIC_HANDLED
	. = ..()

/atom/proc/get_heat()
	. = temperature

/atom/proc/isflamesource()
	. = FALSE

// Transform setters.
/atom/proc/set_rotation(new_rotation)
	icon_rotation = new_rotation
	update_transform()

/atom/proc/set_scale(new_scale_x, new_scale_y)
	if(isnull(new_scale_y))
		new_scale_y = new_scale_x
	if(new_scale_x != 0)
		icon_scale_x = new_scale_x
	if(new_scale_y != 0)
		icon_scale_y = new_scale_y
	update_transform()

/atom/proc/update_transform()
	var/matrix/M = matrix()
	M.Scale(icon_scale_x, icon_scale_y)
	M.Turn(icon_rotation)
	if(transform_animate_time)
		animate(src, transform = M, transform_animate_time)
	else
		transform = M
	return transform

// Walks up the loc tree until it finds a loc of the given loc_type
/atom/get_recursive_loc_of_type(var/loc_type)
	var/atom/check_loc = loc
	while(check_loc)
		if(istype(check_loc, loc_type))
			return check_loc
		check_loc = check_loc.loc
