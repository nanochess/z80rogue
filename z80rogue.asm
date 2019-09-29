	;
	; z80rogue para MSX
	;
	; por Óscar Toledo Gutiérrez
	;
	; (c) Copyright 2019 Óscar Toledo Gutiérrez
	;
	; Creación: 29-sep-2019.
	;

	fname "z80rogue.rom"

	org $4000,$7fff

	db $41,$42
	dw inicio
	dw 0
	dw 0
	dw 0

inicio:
	jr $

	ds $8000-$,$ff
