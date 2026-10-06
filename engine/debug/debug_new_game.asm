DEF DEBUG_PARTY_LEVEL EQU MAX_LEVEL

DebugNewGame:
; Replaces Oak's speech in debug builds: set the clock and the day of the week
; (normally asked by Mom), use the default names, and give a full party.
	farcall InitClock
	farcall SetDayOfWeek

	ld hl, .ChrisName
	ld a, [wPlayerGender]
	bit PLAYERGENDER_FEMALE_F, a
	jr z, .got_player_name
	ld hl, .KrisName
.got_player_name
	ld de, wPlayerName
	ld bc, NAME_LENGTH
	call CopyBytes

	ld hl, .RivalName
	ld de, wRivalName
	ld bc, NAME_LENGTH
	call CopyBytes

	jr DebugNewGame_GiveParty

.ChrisName:
	dname "CHRIS", NAME_LENGTH
.KrisName:
	dname "KRIS", NAME_LENGTH
.RivalName:
	dname "SILVER", NAME_LENGTH

DebugNewGame_GiveParty:
; Give each DebugNewGameParty mon at DEBUG_PARTY_LEVEL,
; with max DVs, max stat experience, and full HP and PP.
	ld hl, DebugNewGameParty
.loop
	ld a, [hli]
	cp -1
	ret z
	ld [wCurPartySpecies], a
	ld a, DEBUG_PARTY_LEVEL
	ld [wCurPartyLevel], a
	xor a ; PARTYMON
	ld [wMonType], a
	push hl
	predef TryAddMonToParty
	ld a, [wPartyCount]
	dec a
	ld [wCurPartyMon], a
	pop hl

; Held item
	ld a, [hli]
	ld b, a
	ld a, MON_ITEM
	push hl
	call GetPartyParamLocation
	ld [hl], b
	pop hl

; Moves, with full PP
	ld a, MON_MOVES
	push hl
	call GetPartyParamLocation
	ld d, h
	ld e, l
	pop hl
	ld bc, NUM_MOVES
	call CopyBytes
	push hl
	ld a, MON_PP
	call GetPartyParamLocation
	ld d, h
	ld e, l
	ld a, MON_MOVES
	call GetPartyParamLocation
	predef FillPP

; Max DVs and stat experience
	ld a, MON_DVS
	call GetPartyParamLocation
	ld a, $ff
	ld [hli], a
	ld [hl], a
	ld a, MON_STAT_EXP
	call GetPartyParamLocation
	ld bc, MON_DVS - MON_STAT_EXP
	ld a, $ff
	call ByteFill

; Recalculate stats (wBaseStats is still loaded for this species)
	ld a, MON_MAXHP
	call GetPartyParamLocation
	ld d, h
	ld e, l
	ld a, MON_STAT_EXP - 1
	call GetPartyParamLocation
	ld b, TRUE
	predef CalcMonStats

; Full HP
	ld a, MON_MAXHP
	call GetPartyParamLocation
	ld a, [hli]
	ld b, a
	ld c, [hl]
	ld a, MON_HP
	call GetPartyParamLocation
	ld a, b
	ld [hli], a
	ld [hl], c

	pop hl
	jp .loop

DebugNewGameParty:
; A balanced team of unique species and held items, so any three of them can
; enter the Battle Tower.
; Skarmory knows FLY, Lapras SURF, and Ampharos FLASH; other field moves do not
; need to be known in debug builds (see CheckPartyMove).
	; species,  item,         moves
	db TYPHLOSION, CHARCOAL,     FLAMETHROWER, THUNDERPUNCH, EARTHQUAKE,   CUT
	db LAPRAS,     LEFTOVERS,    SURF,         WHIRLPOOL,    THUNDERBOLT,  WATERFALL
	db EXEGGUTOR,  MIRACLE_SEED, PSYCHIC_M,    GIGA_DRAIN,   STRENGTH,     SLUDGE_BOMB
	db AMPHAROS,   MAGNET,       THUNDERBOLT,  FIRE_PUNCH,   THUNDER_WAVE, FLASH
	db TYRANITAR,  BLACKGLASSES, CRUNCH,       EARTHQUAKE,   ROCK_SLIDE,   FIRE_BLAST
	db SKARMORY,   METAL_COAT,   FLY,          DRILL_PECK,   STEEL_WING,   TOXIC
	db -1 ; end
	assert @ - DebugNewGameParty == PARTY_LENGTH * (2 + NUM_MOVES) + 1

DebugNewGameScript:
; Run after InitializeEventsScript in debug builds. Skips the scripted
; introduction, leaving the world as if the player had just returned the
; Mystery Egg to Prof. Elm (Cyndaquil taken as the starter).

; Mom gives the Pokégear
	setflag ENGINE_POKEGEAR
	setflag ENGINE_PHONE_CARD
	addcellnum PHONE_MOM
	setevent EVENT_PLAYERS_HOUSE_MOM_1
	clearevent EVENT_PLAYERS_HOUSE_MOM_2
	setmapscene PLAYERS_HOUSE_1F, SCENE_PLAYERSHOUSE1F_NOOP

; Prof. Elm gives a starter and the aide gives a Potion
	setevent EVENT_GOT_CYNDAQUIL_FROM_ELM
	setevent EVENT_CYNDAQUIL_POKEBALL_IN_ELMS_LAB
	setevent EVENT_GOT_A_POKEMON_FROM_ELM
	addcellnum PHONE_ELM
	giveitem POTION
	setmapscene NEW_BARK_TOWN, SCENE_NEWBARKTOWN_NOOP

; The guide gent gives the Map Card
	setflag ENGINE_MAP_CARD
	setevent EVENT_GUIDE_GENT_IN_HIS_HOUSE
	clearevent EVENT_GUIDE_GENT_VISIBLE_IN_CHERRYGROVE

; Mr. Pokémon gives the Mystery Egg, Prof. Oak gives the Pokédex,
; and the rival steals Totodile
	setflag ENGINE_POKEDEX
	setevent EVENT_GOT_MYSTERY_EGG_FROM_MR_POKEMON
	setevent EVENT_MR_POKEMONS_HOUSE_OAK
	setevent EVENT_RIVAL_NEW_BARK_TOWN
	setevent EVENT_PLAYERS_HOUSE_1F_NEIGHBOR
	clearevent EVENT_PLAYERS_NEIGHBORS_HOUSE_NEIGHBOR
	setevent EVENT_TOTODILE_POKEBALL_IN_ELMS_LAB
	setmapscene MR_POKEMONS_HOUSE, SCENE_MRPOKEMONSHOUSE_NOOP

; Back at the lab, the Mystery Egg is given to Prof. Elm
; and the aide gives Poké Balls
	setevent EVENT_GAVE_MYSTERY_EGG_TO_ELM
	clearevent EVENT_ROUTE_30_YOUNGSTER_JOEY
	setevent EVENT_ROUTE_30_BATTLE
	giveitem POKE_BALL, 5
	setmapscene ELMS_LAB, SCENE_ELMSLAB_NOOP

; The catching tutorial on Route 29
	setevent EVENT_DUDE_TALKED_TO_YOU
	setevent EVENT_LEARNED_TO_CATCH_POKEMON

; Debug: ride the ship (the Olivine Port sailor stops blocking it before the
; Hall of Fame) and the Magnet Train (which runs before power is restored)
	giveitem S_S_TICKET
	giveitem PASS
	setevent EVENT_OLIVINE_PORT_SPRITES_BEFORE_HALL_OF_FAME
	clearevent EVENT_OLIVINE_PORT_SPRITES_AFTER_HALL_OF_FAME
	end
