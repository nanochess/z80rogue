	;
	; z80rogue for MSX/Colecovision
	;
	; by Óscar Toledo Gutiérrez
	;
	; (c) Copyright 2019 Óscar Toledo Gutiérrez
	;
	; Creation date: Sep/29/2019.
	;

	fname "z80rogue.rom"

COLECO:	equ 0
MSX: 	equ 1

    if COLECO
	org $8000,$bfff
	db $55,$aa	; Colecovision cartridge header (no Coleco logo)
	dw $0000
	dw $0000
	dw $0000
	dw $0000
	dw start	; Start of game

	jp 0		; rst $08
	jp 0		; rst $10
	jp 0		; rst $18
	jp 0		; rst $20
	jp 0		; rst $28
	jp 0		; rst $30
	jp 0		; rst $38

	jp nmi_vector

VDP:	equ $be
KEYSEL:	equ $80
JOYSEL:	equ $C0
JOY1:	equ $fc
JOY2:	equ $ff
PSG:	equ $ff
    endif

    if MSX
	org $4000,$7fff

	db $41,$42	; MSX cartridge header
	dw start	; Start of game
	dw 0
	dw 0
	dw 0

VDP.DR:	equ $0006	; Memory location with port number for VDP data read
VDP.DW:	equ $0007	; Memory location with port number for VDP data write

    endif

    if COLECO
SETRD:
	call nmi_off
	ld a,l
	out (VDP+1),a
	ld a,h
	and $3f
	out (VDP+1),a
	jp nmi_on

SETWRT:
	call nmi_off
	ld a,l
	out (VDP+1),a
	ld a,h
	or $40
	out (VDP+1),a
	jp nmi_on
    endif

WRTVDP:
    if MSX
	jp $0047
    endif
    if COLECO
	call nmi_off
	ld a,b
	out (VDP+1),a
	ld a,c
	or $80
	out (VDP+1),a
	jp nmi_on
    endif

RDVRM:
    if MSX
	jp $004a
    endif
    if COLECO
	call SETRD
	ex (sp),hl
	ex (sp),hl
	nop
	in a,(VDP)
	ret
    endif

WRTVRM:
    if MSX
	jp $004d
    endif
    if COLECO
	push af
	call SETWRT
	ex (sp),hl
	ex (sp),hl
	pop af
	out (VDP),a
	ret
    endif

FILVRM:
    if MSX
	jp $0056
    endif
    if COLECO
	push af
	call SETWRT
	ex (sp),hl
	ex (sp),hl
.1:	pop af
	out (VDP),a
	push af
	dec bc
	ld a,b
	or c
	jp nz,.1
	pop af
	ret
    endif

LDIRVM:
    if MSX
	jp $005c
    endif
    if COLECO
	ex de,hl
	call SETWRT
	ex (sp),hl
	ex (sp),hl
.1:	ld a,(de)
	out (VDP),a
	inc de
	dec bc
	ld a,b
	or c
	jr nz,.1
	ret
    endif

GTSTCK:
    if MSX
	jp $00d5
    endif
    if COLECO
	out (JOYSEL),a
	ex (sp),hl
	ex (sp),hl
	in a,(JOY1)
	ld b,a
	in a,(JOY2)
	and b
	and $0f
	ld e,a
	ld d,0
	ld hl,.1
	add hl,de
	ld a,(hl)
	ret

.1:
        db 0,0,0,6,0,0,8,7,0,4,0,5,2,3,1,0
    endif

GTTRIG:
    if MSX
	jp $00d8
    endif
    if COLECO
	out (JOYSEL),a
	ex (sp),hl
	ex (sp),hl
	in a,(JOY1)
	ld b,a
	in a,(JOY2)
	and b
	cpl
	and $40
	ret z
	ld a,$ff
	ret
    endif

ROW_WIDTH:      equ 40		; Width in bytes of each video row
BOX_MAX_WIDTH:  equ 11		; Max width of a room box
BOX_MAX_HEIGHT: equ 6		; Max height of a room box
BOX_WIDTH:      equ 13		; Width of box area on screen
BOX_HEIGHT:     equ 8		; Height of box area on screen

GR_VERT:        equ 0xba	; Vertical line graphic
GR_TOP_RIGHT:   equ 0xbb	; Top right graphic
GR_BOT_RIGHT:   equ 0xbc	; Bottom right graphic
GR_BOT_LEFT:    equ 0xc8	; Bottom left graphic
GR_TOP_LEFT:    equ 0xc9	; Top left graphic
GR_HORIZ:       equ 0xcd	; Horizontal line graphic

GR_TUNNEL:      equ 0xb1	; Tunnel graphic (shaded block)
GR_DOOR:        equ 0xce	; Door graphic (crosshair graphic)
GR_FLOOR:       equ 0xfa	; Floor graphic (middle point)

GR_HERO:        equ 0x01	; Hero graphic (smiling face)

GR_LADDER:      equ 0xf0	; Ladder graphic
GR_TRAP:        equ 0x04	; Trap graphic (diamond)
GR_FOOD:        equ 0x05	; Food graphic (clover)
GR_ARMOR:       equ 0x08	; Armor graphic (square with hole in center)
GR_YENDOR:      equ 0x0c	; Amulet of Yendor graphic (Female sign)
GR_GOLD:        equ 0x0f      ; Gold graphic (asterisk, like brightness)
GR_WEAPON:      equ 0x18      ; Weapon graphic (up arrow)

YENDOR_LEVEL:   equ 26		; Level of appearance for Amulet of Yendor

    if COLECO
nmi_off:
	push hl
	ld hl,nmi_data
	set 0,(hl)
	pop hl
	ret

nmi_on:
	push hl
	ld hl,nmi_data
	res 0,(hl)
	nop
	bit 1,(hl)
	pop hl
	ret z
	push af
	push hl
	ld hl,nmi_data
	res 1,(hl)
	jp nmi_vector.1

nmi_vector:
	push af
	push hl
	ld hl,nmi_data
	bit 0,(hl)
	jr z,.1
	set 1,(hl)
	pop hl
	pop af
	retn

.1:	push bc
	push de
	call int_handler
	pop de
	pop bc
	pop hl
	pop af
	retn
    endif

	;
	; Interruption handler
	;
int_handler:
    if MSX
	ld a,(VDP.DR)
	ld c,a
	inc c
	in a,(c)
    endif
    if COLECO
	in a,(VDP+1)
    endif

	ld hl,(ticks)
	inc hl
	ld (ticks),hl
	ld de,(lfsr)
	add hl,de
	ld (lfsr),hl

	ret

	;
	; Start of game
	;
start:
    if MSX
	ld sp,stack
	; Sound guaranteed to be off
	ld hl,int_handler
	ld ($fd9b),hl
	ld a,$c3
	ld ($fd9a),a
    endif
    if COLECO
	di
	ld sp,stack

	xor a
	ld (nmi_data),a

	in a,(VDP+1)
	ld a,$82
	out (VDP+1),a
	ld a,$81
	out (VDP+1),a

	in a,(VDP+1)
	ld a,$82
	out (VDP+1),a
	ld a,$81
	out (VDP+1),a

	ld a,$9f
	out (PSG),a
	ld a,$bf
	out (PSG),a
	ld a,$df
	out (PSG),a
	ld a,$ff
	out (PSG),a

    endif

	call vdp_mode_0

title_screen:
	ld hl,$3800
	ld bc,$0400
	xor a
	call FILVRM

	ld a,30
	ld (debounce),a

	ld hl,title_letters
	ld de,$3800+5*40
	ld bc,18*40
	call LDIRVM

	ld b,5
.1:	push bc
	ld bc,$a107
	call WRTVDP
	halt
	ld bc,$b107
	call WRTVDP
	halt
	ld bc,$f107
	call WRTVDP
	halt
	ld bc,$b107
	call WRTVDP
	halt
	ld bc,$a107
	call WRTVDP
	halt
	ld bc,$5107
	call WRTVDP
	halt
	pop bc
	djnz .1

	call read_stick

	xor a
	ld (level),a
	ld (armor),a
	ld a,1
	ld (yendor),a
	ld (weapon),a
	ld hl,16
	ld (hp),hl
	ld a,1
	ld (first),a

generate_dungeon:
	ld a,(yendor)
	ld b,a
	ld a,(level)
	add a,b
	ld (level),a
	or a
	jp z,game_won

	call update_level

	ld hl,(lfsr)
	ld a,h
	and $41
	or $1a
	ld h,a
	ld a,l
	and $82
	or $6d
	ld l,a
	ld (conn),hl

	ld a,$3c
	ld (page),a

	;
	; Clear the screen
	;
	ld h,a
	ld l,0
	ld bc,$0400
	xor a
	call FILVRM

	;
	; Draw the nine rooms
	;
	ld hl,ROW_WIDTH*(BOX_HEIGHT/2-2)+(BOX_WIDTH/2-2)
	ld a,(page)
	add a,h
	ld h,a
.7:
	push hl
	push hl
	ld de,ROW_WIDTH+2	; Get the center of room
	add hl,de
	ld de,(conn)
	srl d
	rr e
	ld (conn),de
	jr nc,.3
	push hl
	ld b,BOX_WIDTH
	ld a,GR_TUNNEL
	call WRTVRM
	inc hl
	djnz $-4
	pop hl

.3:	ld de,(conn)
	srl d
	rr e
	ld (conn),de
	jr nc,.5
	ld b,BOX_HEIGHT
	ld a,GR_TUNNEL
	ld de,ROW_WIDTH
.4:	call WRTVRM
	add hl,de
	djnz .4
.5:
	call random
	ld a,l
.8:	sub BOX_MAX_WIDTH-2
	jr nc,.8
	add a,BOX_MAX_WIDTH-1
	ld (box_w),a
	ld a,h
.9:	sub BOX_MAX_HEIGHT-2
	jr nc,.9
	add a,BOX_MAX_HEIGHT-1
	ld (box_h),a
	srl a
	ld l,a
	ld h,0
	add hl,hl	; x2
	add hl,hl	; x4
	add hl,hl	; x8
	ld d,h
	ld e,l
	add hl,hl	; x16
	add hl,hl	; x32
	add hl,de	; x40
	ld a,(box_w)
	srl a
	ld e,a
	ld d,0
	add hl,de
	ex de,hl
	pop hl
	or a
	sbc hl,de
	ld ix,GR_TOP_LEFT
	ld iy,GR_TOP_RIGHT*256+GR_HORIZ
	call fill
.10:	ld ix,GR_VERT
	ld iy,GR_VERT*256+GR_FLOOR
	call fill
	ld a,(box_h)
	dec a
	ld (box_h),a
	jp p,.10
	ld ix,GR_BOT_LEFT
	ld iy,GR_BOT_RIGHT*256+GR_HORIZ
	call fill
	pop hl
	ld de,BOX_WIDTH
	add hl,de
	ld a,l
	cp $fb
	jr z,.1
	cp $bb
	jr z,.1
	cp $7b
	jr nz,.6
.1:
	ld de,ROW_WIDTH*BOX_HEIGHT-BOX_WIDTH*3
	add hl,de
.6:
	ld a,l
	cp $14
	jp nz,.7

	;
	; Put the ladder at a random corner room
	;
	call random
	ld a,l
	and $06
	ld l,a
	ld h,0
	ld de,corners
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ex de,hl
	ld a,(page)
	add a,h
	ld h,a
	ld a,GR_LADDER
	call WRTVRM
	ex de,hl

	;
	; If the level is deep enough the put the Amulet of Vendor
	;
	ld a,(level)
	cp YENDOR_LEVEL
	jr c,.11
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ex de,hl
	ld a,(page)
	add a,h
	ld h,a
	ld a,GR_YENDOR
	call WRTVRM
	ex de,hl
.11:
	;
	; Switch video pages
	;
	ld hl,$3800
	ld bc,23*40
	xor a
	call FILVRM
	ld bc,$2107
	call WRTVDP

	;
	; Setup hero start
	;
	ld hl,19+(BOX_HEIGHT/2-1+BOX_HEIGHT)*ROW_WIDTH+$3800
	ld (hero),hl
game_loop:
	ld hl,(hero)
	ld de,-ROW_WIDTH-1
	add hl,de
	ld b,3
.1:	push hl
	call light
	inc hl
	call light
	inc hl
	call light
	pop hl
	ld de,ROW_WIDTH
	add hl,de
	djnz .1

	;
	; Show our hero
	;
	ld hl,(hero)
	call RDVRM
	push af
	ld a,GR_HERO	
	call WRTVRM
	push hl

	call update_hp

	ld a,(first)
	or a
	call nz,welcome

	call read_stick
	ld b,a

	pop hl
	pop af
	call WRTVRM

	ld a,b
	cp 1
	ld de,-40
	jr z,.2
	cp 3
	ld de,1
	jr z,.2
	cp 5
	ld de,40
	jr z,.2
	cp 7
	ld de,-1
	jp nz,game_loop
.2:
	add hl,de
	call RDVRM
	cp GR_LADDER
	jp z,ladder_found
	cp GR_DOOR
	jp z,move_over
	cp GR_FLOOR
	jp z,move_over
	cp GR_TUNNEL	
	jp z,move_over
	jp nc,move_cancel
	cp GR_TRAP
	jp z,trap_found
	jp c,move_cancel

	cp GR_WEAPON+1
	jp nc,battle

	push af
	ld a,GR_FLOOR
	call WRTVRM
	set 2,h
	call WRTVRM
	res 2,h
	pop af
	cp GR_WEAPON
	jp z,weapon_found
	cp GR_ARMOR
	jp z,armor_found
	cp GR_FOOD
	jp z,food_found
	cp GR_GOLD
	jp z,gold_found
	cp GR_YENDOR
	jp z,amulet_found

move_cancel:
	jp game_loop

move_over:
	ld (hero),hl
	jp game_loop

	;
	; Amulet of Yendor found!
	;
amulet_found:
	ld a,$ff
	ld (yendor),a
	jp move_over

        ; ______
        ; I    I
        ; I #X I
        ; I X# I
        ;  \__/
        ;   
armor_found:
	ld a,(armor)
	inc a		; Increase armor level
	ld (armor),a
	jp move_over

        ;
        ;       /| _____________
        ; (|===|oo>_____________>
        ;       \|
        ;
weapon_found:
	ld a,(weapon)
	inc a		; Increase weapon level
	ld (weapon),a
	jp move_over

gold_found:
	jp move_over

        ;
        ;     /--\
        ; ====    I
        ;     \--/
        ;
food_found:
	push hl
	call random
	ld a,l
	pop hl
.1:	sub 6
	jr nc,.1
	add a,7
	push hl
	ld l,a
	ld h,0
	call add_hp
	pop hl
	jp move_over

	;
	; Aaaargghhhhhh!
	;
trap_found:
	push hl
	call random
	ld a,l
	pop hl
.1:	sub 6
	jr nc,.1
	add a,7
	neg 
	push hl
	ld l,a
	ld h,$ff
	call add_hp
	pop hl
	jp move_over

	;
	; Let's battle!!!
	;
battle:
	push hl
	and $1f
	add a,a
	ld l,a
	ld h,0
	ld (monster_hp),hl
	ld (attack),a
	; Player's attack
.1:	call random
	ld a,(weapon)
	ld b,a
	ld a,l
.2:	sub b
	jr nc,.2
	add a,b
	ld e,a
	ld d,0
	inc de
	ld hl,(monster_hp)
	or a
	sbc hl,de
	ld (monster_hp),hl
	jp c,.3

	call random
	ld a,(armor)
	ld c,a
	ld a,(attack)
	ld b,a
	ld a,l
.4:	sub b
	jr nc,.4
	add a,b
	inc a
	sub c
	jr c,.5
	or a
	jr z,.5
	neg
	ld l,a
	ld h,$ff
	call add_hp
	call update_hp
.5:
	call read_stick
	jp .1

.3:	pop hl
	;
	; Remove monster from screen
	;
	ld a,GR_FLOOR
	call WRTVRM
	set 2,h
	call WRTVRM
	res 2,h
	jp move_over

add_hp:
	ex de,hl
	ld hl,(hp)
	add hl,de
	ld (hp),hl
	ld a,h
	or l
	jr z,.1
	bit 7,h
	ret z
.1:
	;
	; Player is dead
	;
	ld hl,.2
	call show_message
	ld b,120
	halt
	djnz $-1

	call read_stick
	jp title_screen

.2:
	db "You are dead!",0

	;
	; Show message
	;
show_message:
	ld de,$3800
.1:	ld a,(hl)
	or a
	ret z
	ex de,hl
	call WRTVRM
	ex de,hl
	inc de
	inc hl
	jr .1

	;
	; Update Level on screen
	;
update_level:
	ld hl,.1
	ld de,$3800+23*ROW_WIDTH+1
	ld bc,7
	call LDIRVM
	ld hl,$3800+23*ROW_WIDTH+10
	exx
	ld a,(level)
	ld l,a
	ld h,0
	exx
	jp show_number

.1:	db "Level: "

	;
	; Update HP on screen
	;
update_hp:
	ld hl,$3800+23*ROW_WIDTH+38
	exx
	ld hl,(hp)
	exx
	jp show_number

show_number:

.2:	exx
	ld de,10
	ld bc,-1

.1:	inc bc
	or a
	sbc hl,de
	jr nc,.1
	add hl,de
	ld a,l
	add a,$30
	exx
	call WRTVRM
	dec hl
	exx
	ld h,b
	ld l,c
	ld a,b
	or c
	exx
	jp nz,.2
	ld a,$20
	jp WRTVRM

        ;
        ;     I--
        ;   I--
        ; I--
        ;
ladder_found:
        jp generate_dungeon

	;
	; "Light" a screen square
	;
light:
	set 2,h		; Read from hidden page
	call RDVRM
	res 2,h		; Write to visible page
	jp WRTVRM

	;
	; Read the stick with debouncing
	;
read_stick:
	halt
	ld a,(debounce)
	or a
	jr z,.1
	dec a
	ld (debounce),a
	jr read_stick

.1:	push hl
	xor a
	call GTSTCK	
	pop hl
	or a
	jr nz,.2

	push hl
	xor a
	call GTTRIG
	pop hl
	or a
	jr z,read_stick
	ld a,10
	push af
	ld a,10
	ld (debounce),a
	pop af
	ret

.2:
	push af
	ld a,10
	ld (debounce),a
	pop af
	cp 1
	ret z
	cp 3
	ret z
	cp 5
	ret z
	cp 7
	ret z
	xor a
	ret

game_won:
	ld hl,.1
	call show_message
	ld b,120
	halt
	djnz $-1

	call read_stick
	jp title_screen

.1:
	db "You have made it to the surface!",0

welcome:
	xor a
	ld (first),a
	ld hl,.1
	call show_message
	call read_stick
	ld hl,$3800
	ld bc,32
	xor a
	jp FILVRM

.1:
	db "Welcome to the dungeons of doom!",0

corners:
	dw (BOX_HEIGHT/2-1)*ROW_WIDTH+(BOX_WIDTH/2)
	dw (BOX_HEIGHT/2-1)*ROW_WIDTH+(BOX_WIDTH/2)+BOX_WIDTH*2
	dw (BOX_HEIGHT/2-1+BOX_HEIGHT*2)*ROW_WIDTH+(BOX_WIDTH/2)
	dw (BOX_HEIGHT/2-1+BOX_HEIGHT*2)*ROW_WIDTH+(BOX_WIDTH/2)+BOX_WIDTH*2
	dw (BOX_HEIGHT/2-1)*ROW_WIDTH+(BOX_WIDTH/2)

	;
	; Fill a row on screen for a room
	;
fill:	push hl
	ld a,ixl
	call door
	ld a,(box_w)
	inc a
	ld b,a
.1:
	ld a,iyl
	call door
	djnz .1
	ld a,iyh
	call door
	pop hl
	ld de,ROW_WIDTH
	add hl,de
	ret

	;
	; Draw a room character on screen
	;
door:
	cp GR_FLOOR
	jr nz,.3
	push af
	push hl
	call random
	ld a,l
	and $3f
	cp 5
	jr nc,.4
	ld c,a
	ld a,(level)
	add a,c
	dec a
.6:
	cp $1a
	jr c,.5
	sub 5
	jr .6
.5:
	add a,$41
	pop hl
	pop de
	jr .3

.4:	cp 14
	jr nc,.7
	ld hl,items-5
	ld e,a
	ld d,0
	add hl,de
	ld a,(hl)
	pop hl
	pop de
	jr .3

.7:	pop hl
	pop af
.3:
	cp GR_HORIZ
	jr z,.1
	cp GR_VERT
	jr nz,.2
.1:
	ld c,a
	call RDVRM
	cp GR_TUNNEL
	ld a,c
	jr nz,.2
	ld a,GR_DOOR
.2:	call WRTVRM
	inc hl
	ret

items:
	db GR_FOOD
	db GR_TRAP
	db GR_FOOD
	db GR_ARMOR
	db GR_GOLD
	db GR_WEAPON
	db GR_FOOD
	db GR_GOLD
	db GR_GOLD

        ;
        ; Mode 0 table (text 40x24)
        ;
mode_0_table:
        DB $00          ; Register 0 - Mode 0
        DB $B0          ; Register 1 - Mode 0, turn off video
        DB $0E          ; Register 2 - Screen patterns $3800
        DB $FF          ; Register 3 - Color table $2000 (not used)
        DB $00          ; Register 4 - Bitmap table $0000
        DB $7F          ; Register 5 - Sprites attributes $3F80 (not used)
        DB $03          ; Register 6 - Sprites bitmaps $1800 (not used)
        DB $21          ; Register 7 - Green letters, black background

	;
	; Pone el modo de video 0 (40x24 columnas)
	;
vdp_mode_0:
	ld hl,mode_0_table
	ld bc,$0800
.1:	push bc
	ld b,(hl)
	call WRTVDP
	pop bc
	inc c
	inc hl
	djnz .1

	ld hl,letters_bitmaps
	ld de,$0000
	ld bc,$0800
	call LDIRVM

	ld hl,$3800
	ld bc,$0400
	ld a,$20
	call FILVRM

	ld hl,test
	ld de,$3800
	ld bc,16
	call LDIRVM

	ld a,$38
	ld (page),a

	ld bc,$f001	; Enable screen
	jp WRTVDP

	;
	; Generates a pseudorandom number
	; Maximum longitude LFSR per our friend: Internet
	;
random:
	push bc
        ld hl,(lfsr)
        ld a,h
        or l
        jr nz,.0
        ld hl,$7811
.0:     ld a,h
        and $80
        ld b,a
        ld a,h
        and $02
        rrca
        rrca
        xor b
        ld b,a
        ld a,h
        and $01
        rrca
        xor b
        ld b,a
        ld a,l
        and $20
        rlca
        rlca
        xor b
        rlca
        rr h
        rr l
        ld (lfsr),hl
	pop bc
        ret

test:
	db "OSCAR WAS HERE ",$01

title_letters:
	db "     _______                            "
	db "    | _ | _ |                           "
	db "  ___\V/||/'|_ __ ___   __ _ _   _  ___ "
	db " |_ //_\| /|| '__/ _ \ / _` | | | |/ _ \"
	db "  //||_|\|_// | | (_) | (_| | |_| |  __/"
	db " /__\___/\_/|_|  \___/ \__, |\__,_|\___|"
	db " \        A________     __/ |          /"          
	db "  \    )==o________>   |___/          / "
	db "   \______V__________________________/  "
	db "                                        "
	db "           by Oscar Toledo G.           "
	db "                                        "
	db "                                        "

    if MSX
	db "              MSX version               "
    endif
    if COLECO
	db "          Colecovision version          "
    endif

	db "                                        "
	db "                                        "
	db "                                        "
    if MSX
	db "          Press Space to start          "
    endif
    if COLECO
	db "         Press button to start          "
    endif

letters_bitmaps:
	db $00,$00,$00,$00,$00,$00,$00,$00	; $00
	db $78,$fc,$b4,$fc,$fc,$b4,$84,$78	; $01 - Happy face
	db $00,$00,$00,$00,$00,$00,$00,$00	; $02
	db $00,$00,$00,$00,$00,$00,$00,$00	; $03
	db $00,$20,$70,$f8,$70,$20,$00,$00	; $04
	db $30,$30,$d8,$d8,$30,$30,$78,$00	; $05
	db $00,$00,$00,$00,$00,$00,$00,$00	; $06
	db $00,$00,$00,$00,$00,$00,$00,$00	; $07

	db $fc,$fc,$ec,$c4,$c4,$ec,$fc,$fc	; $08
	db $00,$00,$00,$00,$00,$00,$00,$00	; $09
	db $00,$00,$00,$00,$00,$00,$00,$00	; $0a
	db $00,$00,$00,$00,$00,$00,$00,$00	; $0b
	db $70,$88,$70,$20,$f8,$20,$20,$00	; $0c
	db $00,$00,$00,$00,$00,$00,$00,$00	; $0d
	db $00,$00,$00,$00,$00,$00,$00,$00	; $0e
	db $20,$a8,$70,$d8,$70,$a8,$20,$00	; $0f

	db $00,$00,$00,$00,$00,$00,$00,$00	; $10
	db $00,$00,$00,$00,$00,$00,$00,$00	; $11
	db $00,$00,$00,$00,$00,$00,$00,$00	; $12
	db $00,$00,$00,$00,$00,$00,$00,$00	; $13
	db $00,$00,$00,$00,$00,$00,$00,$00	; $14
	db $00,$00,$00,$00,$00,$00,$00,$00	; $15
	db $00,$00,$00,$00,$00,$00,$00,$00	; $16
	db $00,$00,$00,$00,$00,$00,$00,$00	; $17

	db $20,$70,$f8,$20,$20,$20,$20,$00	; $18
	db $00,$00,$00,$00,$00,$00,$00,$00	; $19
	db $00,$00,$00,$00,$00,$00,$00,$00	; $1a
	db $00,$00,$00,$00,$00,$00,$00,$00	; $1b
	db $00,$00,$00,$00,$00,$00,$00,$00	; $1c
	db $00,$00,$00,$00,$00,$00,$00,$00	; $1d
	db $00,$00,$00,$00,$00,$00,$00,$00	; $1e
	db $00,$00,$00,$00,$00,$00,$00,$00	; $1f

	db $00,$00,$00,$00,$00,$00,$00,$00	; $20
	db $20,$20,$20,$20,$20,$00,$20,$00	; $21
	db $50,$50,$00,$00,$00,$00,$00,$00	; $22
	db $50,$50,$f8,$50,$f8,$50,$50,$00	; $23
	db $20,$78,$a0,$70,$28,$f0,$20,$00	; $24
	db $c0,$c8,$10,$20,$40,$98,$98,$00	; $25
	db $60,$90,$60,$90,$94,$98,$68,$00	; $26
	db $20,$20,$40,$00,$00,$00,$00,$00	; $27

	db $08,$10,$20,$20,$20,$10,$08,$00	; $28
	db $80,$40,$20,$20,$20,$40,$80,$00	; $29
	db $00,$20,$20,$f8,$50,$88,$00,$00	; $2a
	db $00,$20,$20,$f8,$20,$20,$00,$00	; $2b
	db $00,$00,$00,$00,$00,$30,$10,$20	; $2c
	db $00,$00,$00,$f8,$00,$00,$00,$00	; $2d
	db $00,$00,$00,$00,$00,$30,$30,$00	; $2e
	db $00,$08,$10,$20,$40,$80,$00,$00	; $2f

	db $70,$88,$98,$a8,$c8,$88,$70,$00	; $30
	db $20,$60,$20,$20,$20,$20,$70,$00	; $31
	db $70,$88,$10,$20,$40,$80,$f8,$00	; $32
	db $70,$88,$08,$30,$08,$88,$70,$00	; $33
	db $10,$30,$50,$90,$f8,$10,$10,$00	; $34
	db $f8,$80,$f0,$08,$08,$08,$f0,$00	; $35
	db $78,$80,$80,$f0,$88,$88,$70,$00	; $36
	db $f8,$08,$08,$10,$20,$20,$20,$00	; $37

	db $70,$88,$88,$70,$88,$88,$70,$00	; $38
	db $70,$88,$88,$78,$08,$88,$70,$00	; $39
	db $00,$30,$30,$00,$30,$30,$00,$00	; $3a
	db $00,$30,$30,$00,$30,$30,$10,$20	; $3b
	db $00,$18,$60,$80,$60,$18,$00,$00	; $3c
	db $00,$00,$f8,$00,$f8,$00,$00,$00	; $3d
	db $00,$c0,$30,$08,$30,$c0,$00,$00	; $3e
	db $70,$88,$08,$10,$20,$00,$20,$00	; $3f

	db $70,$88,$98,$a8,$98,$80,$78,$00	; $40
	db $20,$50,$88,$88,$f8,$88,$88,$00	; $41
	db $f0,$88,$88,$f0,$88,$88,$f0,$00	; $42
	db $70,$88,$80,$80,$80,$88,$70,$00	; $43
	db $f0,$88,$88,$88,$88,$88,$f0,$00	; $44
	db $f8,$80,$80,$f0,$80,$80,$f8,$00	; $45
	db $f8,$80,$80,$f0,$80,$80,$80,$00	; $46
	db $70,$88,$80,$98,$88,$88,$70,$00	; $47

	db $88,$88,$88,$f8,$88,$88,$88,$00	; $48
	db $70,$20,$20,$20,$20,$20,$70,$00	; $49
	db $08,$08,$08,$08,$88,$88,$70,$00	; $4a
	db $88,$90,$a0,$c0,$a0,$90,$88,$00	; $4b
	db $80,$80,$80,$80,$80,$80,$f8,$00	; $4c
	db $88,$d8,$a8,$a8,$88,$88,$88,$00	; $4d
	db $88,$88,$c8,$a8,$98,$88,$88,$00	; $4e
	db $70,$88,$88,$88,$88,$88,$70,$00	; $4f

	db $f0,$88,$88,$f0,$80,$80,$80,$00	; $50
	db $70,$88,$88,$88,$88,$a8,$70,$08	; $51
	db $f0,$88,$88,$f0,$a0,$90,$88,$00	; $52
	db $78,$80,$80,$70,$08,$08,$f0,$00	; $53
	db $f8,$20,$20,$20,$20,$20,$20,$00	; $54
	db $88,$88,$88,$88,$88,$88,$70,$00	; $55
	db $88,$88,$88,$88,$88,$50,$20,$00	; $56
	db $88,$88,$88,$88,$a8,$a8,$50,$00	; $57

	db $88,$88,$50,$20,$50,$88,$88,$00	; $58
	db $88,$88,$50,$20,$20,$20,$20,$00	; $59
	db $f8,$08,$10,$20,$40,$80,$f8,$00	; $5a
	db $70,$60,$60,$60,$60,$60,$70,$00	; $5b
	db $00,$80,$40,$20,$10,$08,$00,$00	; $5c
	db $70,$30,$30,$30,$30,$30,$70,$00	; $5d
	db $20,$50,$88,$00,$00,$00,$00,$00	; $5e
	db $00,$00,$00,$00,$00,$00,$00,$fc	; $5f

	db $20,$20,$40,$00,$00,$00,$00,$00	; $60
	db $00,$00,$68,$98,$88,$98,$68,$00	; $61
	db $80,$80,$f0,$88,$88,$88,$f0,$00	; $62
	db $00,$00,$78,$80,$80,$80,$78,$00	; $63
	db $08,$08,$68,$98,$88,$98,$68,$00	; $64
	db $00,$00,$70,$88,$f8,$80,$70,$00	; $65
	db $18,$20,$20,$70,$20,$20,$70,$00	; $66
	db $00,$00,$70,$88,$88,$78,$08,$70	; $67

	db $80,$80,$b0,$c8,$88,$88,$88,$00	; $68
	db $20,$00,$70,$20,$20,$20,$70,$00	; $69
	db $00,$00,$08,$08,$88,$88,$70,$00	; $6a
	db $80,$80,$90,$a0,$e0,$90,$88,$00	; $6b
	db $60,$20,$20,$20,$20,$20,$70,$00	; $6c
	db $00,$00,$d0,$a8,$a8,$a8,$a8,$00	; $6d
	db $00,$00,$b0,$c8,$88,$88,$88,$00	; $6e
	db $00,$00,$70,$88,$88,$88,$70,$00	; $6f

	db $00,$00,$b0,$c8,$c8,$b0,$80,$80	; $70
	db $00,$00,$68,$98,$98,$68,$08,$08	; $71
	db $00,$00,$b0,$c8,$80,$80,$80,$00	; $72
	db $00,$00,$78,$80,$70,$08,$f0,$00	; $73
	db $20,$20,$f8,$20,$20,$20,$18,$00	; $74
	db $00,$00,$88,$88,$88,$98,$68,$00	; $75
	db $00,$00,$88,$88,$88,$50,$20,$00	; $76
	db $00,$00,$88,$a8,$a8,$a8,$50,$00	; $77

	db $00,$00,$88,$50,$20,$50,$88,$00	; $78
	db $00,$00,$88,$88,$98,$68,$08,$f0	; $79
	db $00,$00,$f8,$10,$20,$40,$f8,$00	; $7a
	db $30,$40,$40,$20,$40,$40,$30,$00	; $7b
	db $20,$20,$20,$20,$20,$20,$20,$20	; $7c
	db $60,$10,$10,$20,$10,$10,$60,$00	; $7d
	db $40,$a8,$10,$00,$00,$00,$00,$00	; $7e
	db $00,$00,$70,$88,$88,$f8,$00,$00	; $7f

	db $00,$00,$00,$00,$00,$00,$00,$00	; $80
	db $00,$00,$00,$00,$00,$00,$00,$00	; $81
	db $00,$00,$00,$00,$00,$00,$00,$00	; $82
	db $00,$00,$00,$00,$00,$00,$00,$00	; $83
	db $00,$00,$00,$00,$00,$00,$00,$00	; $84
	db $00,$00,$00,$00,$00,$00,$00,$00	; $85
	db $00,$00,$00,$00,$00,$00,$00,$00	; $86
	db $00,$00,$00,$00,$00,$00,$00,$00	; $87

	db $00,$00,$00,$00,$00,$00,$00,$00	; $88
	db $00,$00,$00,$00,$00,$00,$00,$00	; $89
	db $00,$00,$00,$00,$00,$00,$00,$00	; $8a
	db $00,$00,$00,$00,$00,$00,$00,$00	; $8b
	db $00,$00,$00,$00,$00,$00,$00,$00	; $8c
	db $00,$00,$00,$00,$00,$00,$00,$00	; $8d
	db $00,$00,$00,$00,$00,$00,$00,$00	; $8e
	db $00,$00,$00,$00,$00,$00,$00,$00	; $8f

	db $00,$00,$00,$00,$00,$00,$00,$00	; $90
	db $00,$00,$00,$00,$00,$00,$00,$00	; $91
	db $00,$00,$00,$00,$00,$00,$00,$00	; $92
	db $00,$00,$00,$00,$00,$00,$00,$00	; $93
	db $00,$00,$00,$00,$00,$00,$00,$00	; $94
	db $00,$00,$00,$00,$00,$00,$00,$00	; $95
	db $00,$00,$00,$00,$00,$00,$00,$00	; $96
	db $00,$00,$00,$00,$00,$00,$00,$00	; $97

	db $00,$00,$00,$00,$00,$00,$00,$00	; $98
	db $00,$00,$00,$00,$00,$00,$00,$00	; $99
	db $00,$00,$00,$00,$00,$00,$00,$00	; $9a
	db $00,$00,$00,$00,$00,$00,$00,$00	; $9b
	db $00,$00,$00,$00,$00,$00,$00,$00	; $9c
	db $00,$00,$00,$00,$00,$00,$00,$00	; $9d
	db $00,$00,$00,$00,$00,$00,$00,$00	; $9e
	db $00,$00,$00,$00,$00,$00,$00,$00	; $9f

	db $00,$00,$00,$00,$00,$00,$00,$00	; $a0
	db $00,$00,$00,$00,$00,$00,$00,$00	; $a1
	db $00,$00,$00,$00,$00,$00,$00,$00	; $a2
	db $00,$00,$00,$00,$00,$00,$00,$00	; $a3
	db $00,$00,$00,$00,$00,$00,$00,$00	; $a4
	db $00,$00,$00,$00,$00,$00,$00,$00	; $a5
	db $00,$00,$00,$00,$00,$00,$00,$00	; $a6
	db $00,$00,$00,$00,$00,$00,$00,$00	; $a7

	db $00,$00,$00,$00,$00,$00,$00,$00	; $a8
	db $00,$00,$00,$00,$00,$00,$00,$00	; $a9
	db $00,$00,$00,$00,$00,$00,$00,$00	; $aa
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ab
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ac
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ad
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ae
	db $00,$00,$00,$00,$00,$00,$00,$00	; $af

	db $00,$00,$00,$00,$00,$00,$00,$00	; $b0
	db $a8,$54,$a8,$54,$a8,$54,$a8,$54	; $b1
	db $00,$00,$00,$00,$00,$00,$00,$00	; $b2
	db $00,$00,$00,$00,$00,$00,$00,$00	; $b3
	db $00,$00,$00,$00,$00,$00,$00,$00	; $b4
	db $00,$00,$00,$00,$00,$00,$00,$00	; $b5
	db $00,$00,$00,$00,$00,$00,$00,$00	; $b6
	db $00,$00,$00,$00,$00,$00,$00,$00	; $b7

	db $00,$00,$00,$00,$00,$00,$00,$00	; $b8
	db $00,$00,$00,$00,$00,$00,$00,$00	; $b9
	db $28,$28,$28,$28,$28,$28,$28,$28	; $ba
	db $00,$00,$f8,$08,$e8,$28,$28,$28	; $bb
	db $28,$28,$e8,$08,$f8,$00,$00,$00	; $bc
	db $00,$00,$00,$00,$00,$00,$00,$00	; $bd
	db $00,$00,$00,$00,$00,$00,$00,$00	; $be
	db $00,$00,$00,$00,$00,$00,$00,$00	; $bf

	db $00,$00,$00,$00,$00,$00,$00,$00	; $c0
	db $00,$00,$00,$00,$00,$00,$00,$00	; $c1
	db $00,$00,$00,$00,$00,$00,$00,$00	; $c2
	db $00,$00,$00,$00,$00,$00,$00,$00	; $c3
	db $00,$00,$00,$00,$00,$00,$00,$00	; $c4
	db $00,$00,$00,$00,$00,$00,$00,$00	; $c5
	db $00,$00,$00,$00,$00,$00,$00,$00	; $c6
	db $00,$00,$00,$00,$00,$00,$00,$00	; $c7

	db $28,$28,$2c,$20,$3c,$00,$00,$00	; $c8
	db $00,$00,$3c,$20,$2c,$28,$28,$28	; $c9
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ca
	db $00,$00,$00,$00,$00,$00,$00,$00	; $cb
	db $00,$00,$00,$00,$00,$00,$00,$00	; $cc
	db $00,$00,$fc,$00,$fc,$00,$00,$00	; $cd
	db $28,$28,$ec,$00,$ec,$28,$28,$28	; $ce
	db $00,$00,$00,$00,$00,$00,$00,$00	; $cf

	db $00,$00,$00,$00,$00,$00,$00,$00	; $d0
	db $00,$00,$00,$00,$00,$00,$00,$00	; $d1
	db $00,$00,$00,$00,$00,$00,$00,$00	; $d2
	db $00,$00,$00,$00,$00,$00,$00,$00	; $d3
	db $00,$00,$00,$00,$00,$00,$00,$00	; $d4
	db $00,$00,$00,$00,$00,$00,$00,$00	; $d5
	db $00,$00,$00,$00,$00,$00,$00,$00	; $d6
	db $00,$00,$00,$00,$00,$00,$00,$00	; $d7

	db $00,$00,$00,$00,$00,$00,$00,$00	; $d8
	db $00,$00,$00,$00,$00,$00,$00,$00	; $d9
	db $00,$00,$00,$00,$00,$00,$00,$00	; $da
	db $00,$00,$00,$00,$00,$00,$00,$00	; $db
	db $00,$00,$00,$00,$00,$00,$00,$00	; $dc
	db $00,$00,$00,$00,$00,$00,$00,$00	; $dd
	db $00,$00,$00,$00,$00,$00,$00,$00	; $de
	db $00,$00,$00,$00,$00,$00,$00,$00	; $df

	db $00,$00,$00,$00,$00,$00,$00,$00	; $e0
	db $00,$00,$00,$00,$00,$00,$00,$00	; $e1
	db $00,$00,$00,$00,$00,$00,$00,$00	; $e2
	db $00,$00,$00,$00,$00,$00,$00,$00	; $e3
	db $00,$00,$00,$00,$00,$00,$00,$00	; $e4
	db $00,$00,$00,$00,$00,$00,$00,$00	; $e5
	db $00,$00,$00,$00,$00,$00,$00,$00	; $e6
	db $00,$00,$00,$00,$00,$00,$00,$00	; $e7

	db $00,$00,$00,$00,$00,$00,$00,$00	; $e8
	db $00,$00,$00,$00,$00,$00,$00,$00	; $e9
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ea
	db $00,$00,$00,$00,$00,$00,$00,$00	; $eb
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ec
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ed
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ee
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ef

	db $fc,$84,$fc,$84,$fc,$84,$fc,$fc	; $f0
	db $00,$00,$00,$00,$00,$00,$00,$00	; $f1
	db $00,$00,$00,$00,$00,$00,$00,$00	; $f2
	db $00,$00,$00,$00,$00,$00,$00,$00	; $f3
	db $00,$00,$00,$00,$00,$00,$00,$00	; $f4
	db $00,$00,$00,$00,$00,$00,$00,$00	; $f5
	db $00,$00,$00,$00,$00,$00,$00,$00	; $f6
	db $00,$00,$00,$00,$00,$00,$00,$00	; $f7

	db $00,$00,$00,$00,$00,$00,$00,$00	; $f8
	db $00,$00,$00,$00,$00,$00,$00,$00	; $f9
	db $00,$00,$00,$20,$00,$00,$00,$00	; $fa
	db $00,$00,$00,$00,$00,$00,$00,$00	; $fb
	db $00,$00,$00,$00,$00,$00,$00,$00	; $fc
	db $00,$00,$00,$00,$00,$00,$00,$00	; $fd
	db $00,$00,$00,$00,$00,$00,$00,$00	; $fe
	db $00,$00,$00,$00,$00,$00,$00,$00	; $ff

    if MSX
	ds $6000-$,$ff
    endif
    if COLECO
       ds $a000-$,$ff
    endif

	;
	; Variables del juego
	;
    if MSX
	org $e000
    endif
    if COLECO
	org $7000
    endif

    if COLECO
nmi_data:	rb 1
    endif
ticks:	rb 2
page:	rb 1
weapon:	rb 1
armor:	rb 1
yendor:	rb 1
level:	rb 1
hp:	rb 2
lfsr:	rb 2
conn:	rb 2
box_w:	rb 1
box_h:	rb 1
hero:	rb 2
debounce: rb 1
monster_hp:	rb 2
attack:	rb 1
first:	rb 1

    if MSX
	org $e400
    endif
    if COLECO
	org $7400
    endif
stack:
