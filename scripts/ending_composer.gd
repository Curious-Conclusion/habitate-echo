class_name EndingComposer
## Composes the campaign epilogue from everything the player did — a pure
## read of GameState, so the suite can assert every permutation headless.
##
## Base ending = the Halcyon containment choice (the three flags are mutually
## exclusive; `contain` guarantees exactly one). The Okafor choice, continuity
## breaks, carried traumas, and Firewall standing each append their own weight.
## House style (per the editorial pass): nothing uninfected repeats a word;
## the counting motif belongs to the player now; never explain the horror.

static func compose() -> Dictionary:
	var id: StringName
	var title: String
	var paras: Array[String] = []
	var saved: bool = GameState.get_flag(&"researcher_saved") == true
	var culled: bool = GameState.get_flag(&"researcher_culled") == true

	if GameState.get_flag(&"network_exposed"):
		id = &"carrier"
		title = "CARRIER"
		paras.append(
			"The core went dark and stayed dark. Containment confirmed. Case closed."
		)
		paras.append(
			"But the script read your credentials on its way down, and these days"
			+ " doors open for you half a second before you reach them."
		)
		paras.append(
			"You haven't reported it. The counter-script worked; that's what the"
			+ " record says. Some nights you draft the message to your proxy and"
			+ " delete it. Trust me, the draft says. Trust me."
		)
	elif GameState.get_flag(&"halcyon_counterscript"):
		id = &"second_opinion"
		title = "SECOND OPINION"
		paras.append(
			"Sava's script worked because Okafor ran beside it, her steadied"
			+ " pattern ghosting your mesh inserts — one ego steadying another"
			+ " across the dark. Firewall's report says the source"
			+ " self-terminated. Let them think so."
		)
		paras.append(
			"She is resleeved now, somewhere green. She sends you one line, once a"
			+ " year: 'Still quiet.' You believe her."
		)
	elif GameState.get_flag(&"halcyon_vented"):
		id = &"clean_burn"
		title = "CLEAN BURN"
		paras.append(
			"Halcyon is a clean hole in the charts now. Your server logged the"
			+ " decision as decisive containment and attached a commendation you"
			+ " will never show anyone."
		)
		paras.append(
			"The manifest ran to one hundred and twelve names. Some nights you"
			+ " make it as far as ninety before sleep does."
		)
	elif GameState.get_flag(&"halcyon_burned"):
		id = &"empty_hands"
		title = "EMPTY HANDS"
		paras.append(
			"You came home with nothing. No payload, no proof, a docked bounty,"
			+ " and a proxy who looked at you for a long moment before signing"
			+ " off on it."
		)
		paras.append(
			"Everyone still hiding on Halcyon made the evacuation window. The"
			+ " relief logs surfaced a month later: one hundred and twelve egos,"
			+ " unharvested. Nothing in your record says you did that. You keep"
			+ " count anyway."
		)
	else:
		# No containment flag at all — a save from before the choice existed,
		# or one that's been tampered with. The record protects itself.
		id = &"record_sealed"
		title = "RECORD SEALED"
		paras.append(
			"The record of what you did at Halcyon is sealed above your"
			+ " clearance. You were there. That much survives."
		)

	# The Okafor thread, where it isn't already the spine of the ending.
	if id == &"carrier" and culled:
		paras.append(
			"Okafor could have run that script from the inside. You think about"
			+ " that more than you think about the doors."
		)
	elif id != &"second_opinion" and id != &"carrier":
		if saved:
			paras.append(
				"Okafor's recovery is slow, but real. She asked what happened at"
				+ " Halcyon; you told her, and she didn't flinch."
			)
		elif culled:
			paras.append(
				"No one asks about Okafor anymore. You signed that ledger too."
			)

	if GameState.continuity_breaks > 0:
		paras.append(
			"Restored from backup %s. The record reads seamless. You know where the seam is."
			% ("once" if GameState.continuity_breaks == 1
				else "%d times" % GameState.continuity_breaks)
		)

	if not GameState.traumas.is_empty():
		paras.append(
			"You never did sit for the last psychosurgery."
			+ " Some weights you keep on purpose."
		)

	if GameState.firewall_rep >= 4:
		paras.append(
			"Your proxy's last message: 'Best sentinel I never met."
			+ " The next one's always coming. Rest first.'"
		)
	elif GameState.firewall_rep <= 0:
		paras.append(
			"Your proxy's last message is two words: 'Accounts settled.'"
			+ " You don't hear from Firewall again for a long time."
		)
	else:
		paras.append(
			"Your proxy signs off the way they always do: 'You were never here.'"
			+ " For once, you wish that were true."
		)

	return {"id": id, "title": title, "paragraphs": paras}
