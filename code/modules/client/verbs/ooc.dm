/client/var/bypass_ooc_approval = 0
/client/verb/ooc(msg as text)
	set name = "OOC" //Gave this shit a shorter name so you only have to time out "ooc" rather than "ooc message" to use it --NeoFite
	set category = "OOC"

	if(say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return

	if(!mob)
		return
	if(IsGuestKey(key))
		to_chat(src, "Guests may not use OOC.")
		return

	msg = copytext(sanitize(msg), 1, MAX_MESSAGE_LEN)
	if(!msg)
		return

	if(!(prefs.chat_toggles & CHAT_OOC))
		to_chat(src, "<span class='danger'>You have OOC muted.</span>")
		return

	if(!holder)
		if(!ooc_allowed)
			to_chat(src, "<span class='danger'>OOC is globally muted.</span>")
			return
		if(!dooc_allowed && (mob.stat == DEAD))
			to_chat(usr, "<span class='danger'>OOC for dead mobs has been turned off.</span>")
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, "<span class='danger'>You cannot use OOC (muted).</span>")
			return
		if(src.mob)
			if(jobban_isbanned(src.mob, "OOC"))
				to_chat(src, "<span class='danger'>You have been banned from OOC.</span>")
				return
		if(handle_spam_prevention(msg,MUTE_OOC))
			return
		if(findtext(msg, "byond://"))
			to_chat(src, "<B>Advertising other servers is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to advertise in OOC: [msg]")
			message_admins("[key_name_admin(src)] has attempted to advertise in OOC: [msg]")
			return

	log_ooc("[mob.name]/[key] : [msg]")

	msg = pretty_filter(msg)

	var/raw_msg = msg

	msg = pretty_filter(msg)

	if((copytext(msg, 1, 2) in list(".",";",":","#")) || (findtext(lowertext(copytext(msg, 1, 5)), "say")))
		if(alert("Your message \"[raw_msg]\" looks like it was meant for in game communication, say it in OOC?", "Meant for OOC?", "No", "Yes") != "Yes")
			return

	if(!holder && !bypass_ooc_approval)
		var/regex/R = new("((\[a-z\]+://|www\\.)\\S+)", "ig")

		R.Find(msg)

		for(var/G in R.group)
			admin_link_approval(G)
			// Only request approval for the first link
			break

		msg = R.Replace(msg, "<b>(Link removed)</b>")
	else
		bypass_ooc_approval = 0

	var/keyname
	if(prefs.unlock_content && (prefs.toggles & MEMBER_PUBLIC))
		keyname = "<font color='[prefs.ooccolor ? prefs.ooccolor : normal_ooc_colour]'>"
		if(prefs.unlock_content & 1)
			keyname += "<img style='width:9px;height:9px;' class=icon src=\ref['icons/member_content.dmi'] iconstate=blag>"
		if(prefs.unlock_content & 2)
			keyname += "<img style='width:9px;height:9px;' class=icon src=\ref['icons/member_content.dmi'] iconstate=yogdon>"

	keyname += "[key]"
	webhook_send_ooc(key, msg)
	msg = emoji_parse(msg)

	for(var/client/C in clients)
		if(C.prefs.chat_toggles & CHAT_OOC)
			if(holder)
				if(!holder.fakekey || C.holder)
					var/tag = "[find_admin_rank(src)]"
					if(check_rights_for(src, R_ADMIN) || holder.rank.name == ("SeniorCoder" || "Coder"))
						to_chat(C, "<span class='adminooc'>[config.allow_admin_ooccolor && prefs.ooccolor ? "<font color=[prefs.ooccolor]>" :"" ]<span class='prefix'>[tag] OOC:</span> <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message'>[msg]</span></span></font>")
					else
						to_chat(C, "<span class='adminobserverooc'><span class='prefix'>OOC:</span> <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message'>[msg]</span></span>")
				else
					to_chat(C, "<font color='[normal_ooc_colour]'><span class='ooc'><span class='prefix'>OOC:</span> <EM>[holder.fakekey ? holder.fakekey : key]:</EM> <span class='message'>[msg]</span></span></font>")

			else if(!(key in C.prefs.ignoring))
				if(is_donator(src))
					to_chat(C, "<font color='[normal_ooc_colour]'><span class='ooc'><span class='prefix'>\[Donator\] OOC:</span> <EM>[keyname]:</EM> <span class='message'>[msg]</span></span></font>")
				else
					to_chat(C, "<font color='[normal_ooc_colour]'><span class='ooc'><span class='prefix'>OOC:</span> <EM>[keyname]:</EM> <span class='message'>[msg]</span></span></font>")


/proc/toggle_ooc(toggle = null)
	if(toggle != null) //if we're specifically en/disabling ooc
		if(toggle != ooc_allowed)
			ooc_allowed = toggle
		else
			return
	else //otherwise just toggle it
		ooc_allowed = !ooc_allowed
	to_chat(world, "<B>The OOC channel has been globally [ooc_allowed ? "enabled" : "disabled"].</B>")

var/global/normal_ooc_colour = OOC_COLOR

/client/proc/set_ooc(newColor as color)
	set name = "Set Player OOC Color"
	set desc = "Modifies player OOC Color"
	set category = "Fun"
	normal_ooc_colour = sanitize_ooccolor(newColor)

/client/proc/reset_ooc()
	set name = "Reset Player OOC Color"
	set desc = "Returns player OOC Color to default"
	set category = "Fun"
	normal_ooc_colour = OOC_COLOR

/client/verb/colorooc()
	set name = "Set Your OOC Color"
	set category = "Preferences"

	if(!holder || check_rights_for(src, R_ADMIN))
		if(!is_content_unlocked())
			return

	var/new_ooccolor = input(src, "Please select your OOC color.", "OOC color", prefs.ooccolor) as color|null
	if(new_ooccolor)
		prefs.ooccolor = sanitize_ooccolor(new_ooccolor)
		prefs.save_preferences()
	feedback_add_details("admin_verb","OC") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	return

/client/verb/resetcolorooc()
	set name = "Reset Your OOC Color"
	set desc = "Returns your OOC Color to default"
	set category = "Preferences"

	if(!holder || check_rights_for(src, R_ADMIN))
		if(!is_content_unlocked())
			return

		prefs.ooccolor = initial(prefs.ooccolor)
		prefs.save_preferences()

//Checks admin notice
/client/verb/admin_notice()
	set name = "Adminnotice"
	set category = "Admin"
	set desc ="Check the admin notice if it has been set"

	if(admin_notice)
		to_chat(src, "<span class='boldnotice'>Admin Notice:</span>\n \t [admin_notice]")
	else
		to_chat(src, "<span class='notice'>There are no admin notices at the moment.</span>")

/client/verb/motd()
	set name = "MOTD"
	set category = "OOC"
	set desc ="Check the Message of the Day"

	if(join_motd)
		to_chat(src, "<div class=\"motd\">[join_motd]</div>")
	else
		to_chat(src, "<span class='notice'>The Message of the Day has not been set.</span>")

/client/proc/self_notes()
	set name = "View Admin Notes"
	set category = "OOC"
	set desc = "View the notes that admins have written about you"

	if(!config.see_own_notes)
		to_chat(usr, "<span class='notice'>Sorry, that function is not enabled on this server.</span>")
		return

	show_note(usr, null, 1)

/client/proc/ignore_key(client)
	var/client/C = client
	if(C.key in prefs.ignoring)
		prefs.ignoring -= C.key
	else
		prefs.ignoring |= C.key
	to_chat(src, "You are [(C.key in prefs.ignoring) ? "now" : "no longer"] ignoring [C.key] on the OOC channel.")
	prefs.save_preferences()

/client/verb/select_ignore()
	set name = "Ignore"
	set category = "OOC"
	set desc ="Ignore a player's messages on the OOC channel"

	var/selection = input("Please, select a player!", "Ignore", null, null) as null|anything in sortKey(clients)
	if(!selection)
		return
	if(selection == src)
		to_chat(src, "You can't ignore yourself.")
		return
	ignore_key(selection)

/client/proc/find_admin_rank(client)
	var/client/C = client

	switch(C.holder.rank.name)

		if("CouncilMember")
			return "\[Council\]"

		if("Moderator")
			return "\[Mod\]"

		if("Administrator")
			return "\[Admin\]"

		if("ModeratorOnProbation")
			return "\[ModOnProbation\]"

		if("Bot")
			return "\[YogBot\]"

		if("RetiredAdmin")
			return "\[Retmin\]"

		else
			return "\[[C.holder.rank.name]\]"
