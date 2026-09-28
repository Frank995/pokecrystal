CheckStringForErrors:
; Valid character ranges:
; $0, $5 - $13, $19 - $1c, $26 - $34, $3a - $3e, $40 - $48, $60 - $ff
.loop
	ld a, [de]
	inc de
	and a ; "<NULL>"
	jr z, .NextChar
	cp FIRST_REGULAR_TEXT_CHAR
	jr nc, .NextChar
	cp '<NEXT>'
	jr z, .NextChar
	cp '@'
	jr z, .Done
	cp 'ガ'
	jr c, .Fail
	cp '<PLAY_G>'
	jr c, .NextChar
	cp '<JP_18>' + 1
	jr c, .Fail
	cp '<NI>'
	jr c, .NextChar
	cp '<NO>' + 1
	jr c, .Fail
	cp '<ROUTE>'
	jr c, .NextChar
	cp '<GREEN>' + 1
	jr c, .Fail
	cp '<ENEMY>'
	jr c, .NextChar
	cp '<ENEMY>' + 1
	jr c, .Fail
	cp '<MOM>'
	jr c, .NextChar

.Fail:
	scf
	ret

.NextChar:
	dec c
	jr nz, .loop

.Done:
	and a
	ret
