/datum/round_event_control/weightless
	name = "Gravity Systems Failure"
	typepath = /datum/round_event/weightless
	weight = 15

/datum/round_event/weightless
	startWhen = 5
	endWhen = 65
	announceWhen	= 1

/datum/round_event/weightless/setup()
	startWhen = rand(0,10)
	endWhen = rand(40,80)

/datum/round_event/weightless/announce()
	priority_announce("Warning: Failsafes for the station's artificial gravity arrays have been triggered. Please be aware that if this problem recurs it may result in formation of gravitational anomalies. Nanotrasen wishes to remind you that the unauthorised formation of anomalies within Nanotrasen facilities is strictly prohibited by health and safety regulation [rand(99,9999)][pick("a","b","c")]: subclause[rand(1,20)][pick("a","b","c")].")

/datum/round_event/weightless/start()
	for(var/obj/machinery/gravity_generator/main/G in world)
		if(G.breaker)
			G.breaker = !G.breaker
			G.toggleable = FALSE
			G.set_power()
			G.charge_count = 20

/datum/round_event/weightless/end()
	for(var/obj/machinery/gravity_generator/main/G in world)
		if(!G.toggleable)
			G.breaker = !G.breaker
			G.toggleable = TRUE
			G.set_power()

	if(announceWhen >= 0)
		priority_announce("Artificial gravity arrays are now functioning within normal parameters. Please report any irregularities to your respective head of staff.")
