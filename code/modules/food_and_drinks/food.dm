////////////////////////////////////////////////////////////////////////////////
/// Food.
////////////////////////////////////////////////////////////////////////////////

#define HATE_MESSAGES list(	"What the hell was that?! I hate <b>$TYPE</b>, I'm $ASPECIES!", "That was awful! As a self-respecting $ASPECIES I can't eat <b>$TYPE</b>.", "God, that was outright dangerous! <b>$CAPITALTYPE</b> $IS not good for $PLURALSPECIES!")
#define DISLIKE_MESSAGES list("That wasn't very good. I should probably stay away from <b>$TYPE</b>, since I'm $ASPECIES.", "<b>$CAPITALTYPE</b> $ISn't great for $PLURALSPECIES. Let's not eat that again.", "Eugh. <b>$CAPITALTYPE</b> really $ISn't something $ASPECIES should be eating.")
#define LOVE_MESSAGES list("Delicious! I love <b>$TYPE</b>.", "Scrump. I was born to eat <b>$TYPE</b>.", "I love this taste. <b>$CAPITALTYPE</b> $IS great.", "<b>$CAPITALTYPE</b> $IS amazing. I should eat more of this stuff.")

/obj/item/reagent_containers/food
	possible_transfer_amounts = null
	volume = 50 //Sets the default container amount for all food items.
	var/filling_color = "#FFFFFF" //Used by sandwiches.
	var/junkiness = 0  //for junk food. used to lower human satiety.
	var/bitesize = 2
	var/consume_sound = 'sound/items/eatfood.ogg'
	var/apply_type = REAGENT_INGEST
	var/apply_method = "swallow"
	var/transfer_efficiency = 1.0
	var/instant_application = 0 //if we want to bypass the forcedfeed delay
	var/can_taste = TRUE//whether you can taste eating from this
	var/antable = TRUE // Will ants come near it?
	var/ant_location = null
	var/ant_timer = null
	var/foodtype = NONE
	var/last_check_time
	resistance_flags = FLAMMABLE
	container_type = INJECTABLE

/obj/item/reagent_containers/food/Initialize(mapload)
	. = ..()
	pixel_x = rand(-5, 5) //Randomizes postion
	pixel_y = rand(-5, 5)
	if(antable)
		ant_location = get_turf(src)
		ant_timer = addtimer(CALLBACK(src, .proc/check_for_ants), 3000, TIMER_STOPPABLE)

/obj/item/reagent_containers/food/Destroy()
	ant_location = null
	if(ant_timer)
		deltimer(ant_timer)
	return ..()

/obj/item/reagent_containers/food/set_APTFT()
	set hidden = TRUE
	..()

/obj/item/reagent_containers/food/proc/check_for_ants()
	if(!antable)
		return
	var/turf/T = get_turf(src)
	if(isturf(loc) && (T.temperature in 280 to 325) && !locate(/obj/structure/table) in T)
		if(ant_location == T)
			if(prob(15))
				if(!locate(/obj/effect/decal/ants) in T)
					new /obj/effect/decal/ants(T)
					antable = FALSE
					desc += " It appears to be infested with space ants. Yuck!"
					reagents.add_reagent("ants", 1) // Don't eat things with ants in i you weirdo.
					if(ant_timer)
						deltimer(ant_timer)
		else
			ant_location = T
	if(ant_timer)
		deltimer(ant_timer)
	ant_timer = addtimer(CALLBACK(src, .proc/check_for_ants), 3000, TIMER_STOPPABLE)

/obj/item/reagent_containers/food/proc/check_liked(var/fraction, mob/M)
	if(last_check_time + 50 < world.time)
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(foodtype & H.dna.species.toxic_food)
				var/type_string = matched_food_type(foodtype & H.dna.species.toxic_food)
				to_chat(H, "<span class='warning'>[format_message(type_string, HATE_MESSAGES, H.dna.species)]</span>")

				H.AdjustDisgust(25 + 30 * fraction)
			else if(foodtype & H.dna.species.disliked_food)
				var/type_string = matched_food_type(foodtype & H.dna.species.disliked_food)
				to_chat(H, "<span class='warning'>[format_message(type_string, DISLIKE_MESSAGES, H.dna.species)]</span>")

				H.AdjustDisgust(11 + 15 * fraction)
			else if(foodtype & H.dna.species.liked_food)
				var/type_string = matched_food_type(foodtype & H.dna.species.liked_food)
				to_chat(H, "<span class='notice'>[format_message(type_string, LOVE_MESSAGES, H.dna.species)]</span>")

				H.AdjustDisgust(-5 + -2.5 * fraction)
			last_check_time = world.time

/obj/item/reagent_containers/food/proc/format_message(var/type, var/list/messages, var/datum/species/species)
	var/plural = cmptext(type[length(type)], "s") ? "are" : "is"

	var/with_type = replacetext(pick(messages), "$TYPE", type)
	var/with_capital_type = replacetext(with_type, "$CAPITALTYPE", capitalize(type))
	var/with_species = replacetext(with_capital_type, "$SPECIES", species.name)
	var/with_plural_species = replacetext(with_species, "$PLURALSPECIES", species.name_plural)
	var/with_a_species = replacetext(with_plural_species, "$ASPECIES", "[species.a] [species.name]")
	return replacetext(with_a_species, "$IS", plural)


/obj/item/reagent_containers/food/proc/matched_food_type(var/matching_flags)
	if(matching_flags & MEAT)
		return pick("meat", "flesh", "dead animals")
	if(matching_flags & VEGETABLES)
		return pick("vegetables", "veggies")
	if(matching_flags & RAW)
		return pick("raw food", "uncooked food", "tartare")
	if(matching_flags & FRUIT)
		return "fruit"
	if(matching_flags & DAIRY)
		return "dairy"
	if(matching_flags & FRIED)
		return pick("fried food", "deep fried stuff")
	if(matching_flags & ALCOHOL)
		return pick("alcohol", "booze")
	if(matching_flags & SUGAR)
		return pick("sugary food", "sweets")
	if(matching_flags & GRAIN)
		return pick("grain products", "carbs")
	if(matching_flags & EGG)
		return pick("eggs")
	if(matching_flags & GROSS)
		return pick("gross stuff", "garbage")
	if(matching_flags & TOXIC)
		return pick("toxic garbage", "toxins", "literally poison")
	if(matching_flags & JUNKFOOD)
		return "junk food"
