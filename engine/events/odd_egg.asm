GiveOddEgg:
	; Figure out which egg to give.

	; Compare a random word to probabilities out of $ffff.
	call Random
	ld hl, OddEggProbabilities
	ld c, 0
	ld b, c
.loop
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a

	; Break on $ffff.
	ld a, d
	cp HIGH($ffff)
	jr nz, .not_done
	ld a, e
	cp LOW($ffff)
	jr z, .done
.not_done

	; Break when the random word <= the next probability in de.
	ldh a, [hRandomSub]
	cp d
	jr c, .done
	jr z, .ok
	jr .next
.ok
	ldh a, [hRandomAdd]
	cp e
	jr c, .done
	jr z, .done
.next
	inc bc
	jr .loop
.done

	ld hl, OddEggs
	ld a, NICKNAMED_MON_STRUCT_LENGTH
	call AddNTimes

	; Writes to wOddEgg, wOddEggName, and wOddEggOT,
	; even though OddEggs does not have data for wOddEggOT
	ld de, wOddEgg
	ld bc, NICKNAMED_MON_STRUCT_LENGTH + NAME_LENGTH
	call CopyBytes

	ld a, EGG_TICKET
	ld [wCurItem], a
	ld a, 1
	ld [wItemQuantityChange], a
	ld a, -1
	ld [wCurItemQuantity], a
	ld hl, wNumItems
	call TossItem

	; load species in wGiftMonSpecies
	ld a, EGG
	ld [wGiftMonMiscSpecies], a

	; load pointer to (wGiftMonSpecies - 1) in wGiftMonSpeciesPointer
	ld a, LOW(wGiftMonMiscSpecies - 1)
	ld [wGiftMonSpeciesPointer], a
	ld a, HIGH(wGiftMonMiscSpecies - 1)
	ld [wGiftMonSpeciesPointer + 1], a
	; load pointer to wOddEgg in wGiftMonStructPointer
	ld a, LOW(wOddEgg)
	ld [wGiftMonStructPointer], a
	ld a, HIGH(wOddEgg)
	ld [wGiftMonStructPointer + 1], a

	; load Odd Egg Name in wTempOddEggNickname
	ld hl, .Odd
	ld de, wTempOddEggNickname
	ld bc, MON_NAME_LENGTH
	call CopyBytes

	; load pointer to wTempOddEggNickname in wGiftMonOTPointer
	ld a, LOW(wTempOddEggNickname)
	ld [wGiftMonOTPointer], a
	ld a, HIGH(wTempOddEggNickname)
	ld [wGiftMonOTPointer + 1], a
	; load pointer to wOddEggName in wGiftMonNicknamePointer
	ld a, LOW(wOddEggName)
	ld [wGiftMonNicknamePointer], a
	ld a, HIGH(wOddEggName)
	ld [wGiftMonNicknamePointer + 1], a
	jp AddOddEggToParty

.Odd:
	dname "ODD", MON_NAME_LENGTH + 1

INCLUDE "data/events/odd_eggs.asm"

AddOddEggToParty:
	ld hl, wPartyCount
	ld a, [hl]
	ld e, a
	inc [hl]

	ld a, [wGiftMonSpeciesPointer]
	ld l, a
	ld a, [wGiftMonSpeciesPointer + 1]
	ld h, a
	inc hl
	ld bc, wPartySpecies
	ld d, e
.loop1
	inc bc
	dec d
	jr nz, .loop1
	ld a, e
	ld [wCurPartyMon], a
	ld a, [hl]
	ld [bc], a
	inc bc
	ld a, -1
	ld [bc], a

	ld hl, wPartyMon1Species
	ld bc, PARTYMON_STRUCT_LENGTH
	ld a, e
	ld [wGiftMonIndex], a
.loop2
	add hl, bc
	dec a
	and a
	jr nz, .loop2
	ld e, l
	ld d, h
	ld a, [wGiftMonStructPointer]
	ld l, a
	ld a, [wGiftMonStructPointer + 1]
	ld h, a
	ld bc, PARTYMON_STRUCT_LENGTH
	call CopyBytes

	ld hl, wPartyMonOTs
	ld bc, NAME_LENGTH
	ld a, [wGiftMonIndex]
.loop3
	add hl, bc
	dec a
	and a
	jr nz, .loop3
	ld e, l
	ld d, h
	ld a, [wGiftMonOTPointer]
	ld l, a
	ld a, [wGiftMonOTPointer + 1]
	ld h, a
	ld bc, MON_NAME_LENGTH - 1
	call CopyBytes
	ld a, '@'
	ld [de], a

	ld hl, wPartyMonNicknames
	ld bc, MON_NAME_LENGTH
	ld a, [wGiftMonIndex]
.loop4
	add hl, bc
	dec a
	and a
	jr nz, .loop4
	ld e, l
	ld d, h
	ld a, [wGiftMonNicknamePointer]
	ld l, a
	ld a, [wGiftMonNicknamePointer + 1]
	ld h, a
	ld bc, MON_NAME_LENGTH - 1
	call CopyBytes
	ld a, '@'
	ld [de], a

	ld hl, sPartyMail
	ld bc, MAIL_STRUCT_LENGTH
	ld a, [wGiftMonIndex]
.loop5
	add hl, bc
	dec a
	and a
	jr nz, .loop5
	ld a, BANK(sPartyMail)
	call OpenSRAM
	ld e, l
	ld d, h
	ld a, [wGiftMonMailPointer]
	ld l, a
	ld a, [wGiftMonMailPointer + 1]
	ld h, a
	ld bc, MAIL_STRUCT_LENGTH
	call CopyBytes

	call CloseSRAM
	ret
