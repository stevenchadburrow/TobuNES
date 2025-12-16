
; A port of Tobu Tobu Girl for the NES


; TobuNES-Code.asm

; To compile
; ./asm6/asm6.o TobuNES-Code.asm TobuNES-ProgramROM.bin

; To convert
; ./NesGameDev-Converter.o TobuNES-PatternTable0.bmp TobuNES-PatternTable1.bmp TobuNES-CharacterROM.bin

; To combine
; ./NesGameDev-Combiner.o TobuNES-ProgramROM.bin TobuNES-CharacterROM.bin TOBUNES.NES

; To simulate
; ./PICnes.o TOBUNES.NES


; variables

vblank_ready .EQU $00
button_value .EQU $01
math_slot0 .EQU $02
math_slot1 .EQU $03

char_pos_x .EQU $04
char_pos_y .EQU $05
char_dir_x .EQU $06
char_vel_y .EQU $07
char_dir_y .EQU $08
char_fly_cnt .EQU $09
char_fly_val .EQU $0A
char_dash_cnt .EQU $0B
char_dash_val .EQU $0C
char_dash_x .EQU $0D
char_dash_y .EQU $0E
char_dash_held .EQU $0F

map_y_low .EQU $10
map_y_high .EQU $11

spawn_cnt .EQU $12
spawn_pos .EQU $13
spawn_prev .EQU $14

anim_cnt .EQU $16
anim_val .EQU $17

quad_oam .EQU $18
quad_y .EQU $19
quad_chr .EQU $1A
quad_dir .EQU $1B
quad_pal .EQU $1C
quad_x .EQU $1D

char_intro .EQU $1E
char_death .EQU $1F
char_fin .EQU $20
char_skin .EQU $21

cloud_val .EQU $22
cloud_x .EQU $23
cloud_y .EQU $24

clock_val .EQU $25
clock_x .EQU $26
clock_y .EQU $27
clock_apr .EQU $28
clock_freq .EQU $29

map_timer .EQU $2A
map_fin .EQU $2B
map_len .EQU $2C
map_mul .EQU $2D
map_prev_low .EQU $2E
map_prev_high .EQU $2F

mini_low .EQU $30
mini_high .EQU $31

back_out .EQU $32
back_in .EQU $33

title_val .EQU $34
title_x .EQU $35
title_y .EQU $36

menu_pos .EQU $37
menu_wait .EQU $38
menu_prog .EQU $39

bob_y .EQU $3A
bob_dir .EQU $3B

time_low .EQU $3C
time_high .EQU $3D
pts_hit .EQU $3E
pts_miss .EQU $3F

spkl_cnt .EQU $40
spkl_val .EQU $41
spkl_dir .EQU $42

wipe_low .EQU $43
wipe_high .EQU $44
wipe_tile .EQU $45
wipe_pal .EQU $46 ; uses 4 bytes

str_x .EQU $4A
str_y .EQU $4B

dec_val .EQU $4C

ext_x .EQU $4D
ext_y .EQU $4E

rand_val .EQU $4F

rand_func .EQU $50 ; uses 12 bytes, current = 5 * previous + 17

dec_array .EQU $5C ; uses 4 bytes

enem_dice .EQU $60 ; uses 16 bytes
enem_pal .EQU $70 ; uses 16 bytes

str_array .EQU $80 ; uses 16 bytes

; add more variables here

oam_page .EQU $0200 ; sprite oam data ready for dma

enem_page .EQU $0300 ; oam, x, y, chr, x-dir, pal, x-vel, x-sway

score_page .EQU $0400 ; grade, space, score_high, score_low, space, time_high, colon, time_low, space, space, space, end. repeat 16x

ppu_ctrl .EQU $2000
ppu_mask .EQU $2001
ppu_status .EQU $2002
ppu_scroll .EQU $2005
ppu_addr .EQU $2006
ppu_data .EQU $2007

oam_dma .EQU $4014
snd_chn .EQU $4015
joy_one .EQU $4016
joy_two .EQU $4017

; code

	.ORG $8000

reset
	; disable irq and decimal mode
	SEI
	CLD

	; set stack pointer
	LDX #$FF
	TXS

	; randomizer function creation
	LDA #$A5 ; LDAz
	STA rand_func+0
	LDA #<rand_val
	STA rand_func+1
	LDA #$0A ; ASL A
	STA rand_func+2
	LDA #$0A ; ASL A
	STA rand_func+3
	LDA #$18 ; CLC
	STA rand_func+4
	LDA #$65 ; ADCz
	STA rand_func+5
	LDA #<rand_val
	STA rand_func+6
	LDA #$69 ; ADC#
	STA rand_func+7
	LDA #$11 ; 17
	STA rand_func+8
	LDA #$85 ; STAz
	STA rand_func+9
	LDA #<rand_val
	STA rand_func+10
	LDA #$60 ; RTS
	STA rand_func+11

	; make sure randomizer is working
	JSR rand_func
	JSR rand_func
	JSR rand_func

	; disable rendering
	LDA #$00
	STA ppu_ctrl
	STA ppu_mask
	LDA #$00
	STA snd_chn

	; wait for two v-blank flags
	BIT ppu_status
reset_wait_one
	BIT ppu_status
	BPL reset_wait_one
reset_wait_two
	BIT ppu_status
	BPL reset_wait_two

	; reset ppu scroll
	LDA ppu_status
	LDA #$90
	STA ppu_ctrl
	LDA #$00
	STA ppu_scroll
	LDA #$00
	STA ppu_scroll

	; trigger oam dma
	LDA #$02
	STA oam_dma

	; reset menu position, wait state, and progress
	LDA #$00
	STA menu_pos
	LDA #$00
	STA menu_wait
	LDA #$00 ; change for debugging
	STA menu_prog

	; reset character skin
	LDA #$00
	STA char_skin

	; reset extra sprite coordinates
	LDA #$FF
	STA ext_x
	STA ext_y

	; reset high score strings
	LDX #$00
reset_score_one
	LDA #$30
	STA score_page,X
	TXA
	CLC
	ADC #$01
	AND #$0F
	BNE reset_score_two
	LDA #$80
	STA score_page,X
reset_score_two
	INX
	BNE reset_score_one

	; clear the screen
	JSR clear

	; enable rendering
	LDA #$1E
	STA ppu_mask

story
	; wipe effect
	LDA #$2C
	STA wipe_tile
	JSR wipe

	; story scene
	JSR scene

	; wipe effect
	LDA #$2C
	STA wipe_tile
	JSR wipe

	; return to normal
	JMP boot_fast

boot
	; wipe effect
	LDA #$2C
	STA wipe_tile
	JSR wipe

boot_fast
	; title menu screen
	JSR menu

	; wipe effect
	LDA #$FF
	STA wipe_tile
	JSR wipe

	; reset previous position flag outside of setup
	LDA #$00
	STA map_prev_low
	STA map_prev_high

init
	; disable rendering
	LDA #$00
	STA ppu_mask

	; setup variables for game
	JSR setup

	; enable rendering
	LDA #$1E
	STA ppu_mask
	
	; clear v-blank flag
	LDA #$00
	STA vblank_ready

main
	; wait for v-blank flag
	LDA vblank_ready
	BEQ main

	; clear v-blank flag
	LDA #$00
	STA vblank_ready

	; keep background and sprites visible
	LDA #$1E
	STA ppu_mask

	; change palettes, name table, and attribute table here

	; set vertical scrolling
	LDA map_y_low
	CMP #$11 ; cannot be $10 or less
	BCS main_next_one
	LDA #$11
	STA map_y_low
main_next_one
	LDA ppu_status
	LDA #$00
	STA ppu_scroll
	LDA #$00
	SEC
	SBC map_y_low
	STA ppu_scroll
	LDA map_y_high
	AND #$01
	ASL A
	ORA #$90
	STA ppu_ctrl

	; trigger oam dma
	LDA #$02
	STA oam_dma

	; time keeping
	LDA char_fin
	BNE main_next_two
	INC time_low
	LDA time_low
	CMP #$3C ; 60 Hz
	BCC main_next_two
	LDA #$00
	STA time_low
	INC time_high ; measured in seconds

main_next_two
	; animate enemies
	DEC anim_cnt
	BNE main_next_four
	LDA #$07
	STA anim_cnt
	INC anim_val
	LDA anim_val
	AND #$01
	STA anim_val

	; fly animation countdown
	LDA char_fly_val
	SEC
	SBC #$01
	STA char_fly_val
	BCS main_next_three
	LDA #$00
	STA char_fly_val

main_next_three
	; timer countdown
	LDA char_death
	BNE main_next_four
	LDA map_timer
	SEC
	SBC #$01 ; timer speed
	STA map_timer
	BCS main_next_four
	LDA #$00
	STA map_timer
	LDA #$40 ; death length
	STA char_death

main_next_four
	; run sub-routines
	JSR buttons
	JSR compute
	JSR redraw

	; if pressing select, change skin
	LDA button_value
	AND #$20 ; select
	BEQ main_next_six
	LDA char_skin
	CLC
	ADC #$20
	AND #$20
	STA char_skin

main_next_five
	; wait until not pressing buttons
	JSR buttons
	LDA button_value
	BNE main_next_five
	
	; loop back
	JMP main

main_next_six
	; if pressing start, go back to menu
	LDA button_value
	AND #$10 ; start
	BEQ main_next_eight

main_next_seven
	; wait until not pressing buttons
	JSR buttons
	LDA button_value
	BNE main_next_seven

	; back to menu
	JMP boot

main_next_eight
	; turn off display
	; only for debugging
	;LDA #$00
	;STA ppu_mask

	; loop back
	JMP main

; clear the screen
clear
	; disable rendering
	LDA #$00
	STA ppu_mask

	; clear palettes
	LDA ppu_status
	LDA #$3F
	STA ppu_addr
	LDA #$00
	STA ppu_addr
	LDX #$20
	LDA #$0F ; black
clear_palettes
	STA ppu_data
	DEX
	BNE clear_palettes

	; clear name table
	LDY #$20
	LDA ppu_status
	STY ppu_addr
	LDA #$00
	STA ppu_addr
	LDX #$00
clear_nametable
	LDA #$B0 ; blank
	STA ppu_data
	INX
	BNE clear_nametable
	INY
	LDA ppu_status
	STY ppu_addr
	LDA #$00
	STA ppu_addr
	CPY #$24
	BNE clear_nametable

	; clear attribute table
	LDA ppu_status
	LDA #$23	
	STA ppu_addr
	LDA #$C0
	STA ppu_addr
	LDX #$40
clear_attributetable
	LDA #$00 ; first palette
	STA ppu_data
	DEX
	BNE clear_attributetable

	; clear sprites
	LDA #$EF
	LDX #$00
clear_sprites
	STA oam_page+0,X
	INX
	INX
	INX
	INX
	BNE clear_sprites

	; reset ppu scroll
	LDA ppu_status
	LDA #$90
	STA ppu_ctrl
	LDA #$00
	STA ppu_scroll
	LDA #$00
	STA ppu_scroll

	; trigger oam dma
	LDA #$02
	STA oam_dma

	RTS


; setup game variables
setup
	; make all sprites not drawn
	LDX #$00
	LDA #$EF
setup_sprites
	STA oam_page,X
	INX
	INX
	INX
	INX
	BNE setup_sprites

	; set ppu address to background palettes
	LDA ppu_status
	LDA #$3F
	STA ppu_addr
	LDA #$00
	STA ppu_addr

	; set level data (64 bytes each)
	LDA #$00
	LDX menu_pos
setup_level_one
	CPX #$00
	BEQ setup_level_two
	DEX
	CLC
	ADC #$40 ; add 64
	BNE setup_level_one
setup_level_two
	TAX

	; set background palette
	LDA level_data+0,X
	STA ppu_data
	LDA level_data+1,X
	STA ppu_data
	LDA level_data+2,X
	STA ppu_data
	LDA level_data+3,X
	STA ppu_data
	LDA level_data+4,X
	STA ppu_data
	LDA level_data+5,X
	STA ppu_data
	LDA level_data+6,X
	STA ppu_data
	LDA level_data+7,X
	STA ppu_data

	LDA level_data+8,X
	STA ppu_data
	LDA level_data+9,X
	STA ppu_data
	LDA level_data+10,X
	STA ppu_data
	LDA level_data+11,X
	STA ppu_data
	LDA level_data+12,X
	STA ppu_data
	LDA level_data+13,X
	STA ppu_data
	LDA level_data+14,X
	STA ppu_data
	LDA level_data+15,X
	STA ppu_data

	; increment level data
	TXA
	CLC
	ADC #$10
	TAX

	; set ppu address to sprite palettes
	LDA ppu_status
	LDA #$3F
	STA ppu_addr
	LDA #$10
	STA ppu_addr

	; set sprite palette
	LDA level_data+0,X
	STA ppu_data
	LDA level_data+1,X
	STA ppu_data
	LDA level_data+2,X
	STA ppu_data
	LDA level_data+3,X
	STA ppu_data
	LDA level_data+4,X
	STA ppu_data
	LDA level_data+5,X
	STA ppu_data
	LDA level_data+6,X
	STA ppu_data
	LDA level_data+7,X
	STA ppu_data

	LDA level_data+8,X
	STA ppu_data
	LDA level_data+9,X
	STA ppu_data
	LDA level_data+10,X
	STA ppu_data
	LDA level_data+11,X
	STA ppu_data
	LDA level_data+12,X
	STA ppu_data
	LDA level_data+13,X
	STA ppu_data
	LDA level_data+14,X
	STA ppu_data
	LDA level_data+15,X
	STA ppu_data

	; increment level data
	TXA
	CLC
	ADC #$10
	TAX

	; set up enemy random selection
	LDY #$00
setup_dice_one
	LDA level_data,X
	AND #$0F
	CMP #$04
	BCS setup_dice_two
	ASL A
	ASL A
	CLC
	ADC #$40
	BNE setup_dice_three
setup_dice_two
	SEC
	SBC #$04
	ASL A
	ASL A
	CLC
	ADC #$60
setup_dice_three
	STA enem_dice,Y
	LDA level_data,X
	AND #$F0
	LSR A
	LSR A
	LSR A
	LSR A
	STA enem_pal,Y
	INX
	INY
	CPY #$10
	BNE setup_dice_one

	; set up background
	LDA level_data+0,X
	STA back_in
	LDA level_data+1,X
	STA back_out
	JSR back
	
	; set map height and multiplier amount for flags
	LDA level_data+2,X
	STA map_len
	TXA
	PHA
	LDA level_data+2,X
	STA math_slot0
	LDX #$00
setup_height_one
	LDA math_slot0
	AND #$80
	BNE setup_height_two
	INX
	LDA math_slot0
	ASL A
	STA math_slot0
	BNE setup_height_one
setup_height_two
	STX map_mul
	PLA
	TAX

	; set clock frequency
	LDA level_data+3,X
	STA clock_freq

	; clear enemy info page
	LDX #$00
	LDA #$00
setup_clear
	STA enem_page,X
	INX
	BNE setup_clear

	; first enemy always present at beginning
	LDX #$00
	LDA #$20
	STA enem_page+0,X
	LDA #$68
	STA enem_page+1,X
	LDA #$C0
	STA enem_page+2,X
	LDA #$40
	STA enem_page+3,X
	LDA #$00
	STA enem_page+4,X
	LDA #$01
	STA enem_page+5,X
	LDA #$00
	STA enem_page+6,X
	STA enem_page+7,X

	; second enemy always present at beginning
	LDX #$08
	LDA #$30
	STA enem_page+0,X
	LDA #$90
	STA enem_page+1,X
	LDA #$9C
	STA enem_page+2,X
	LDA #$40
	STA enem_page+3,X
	LDA #$00
	STA enem_page+4,X
	LDA #$01
	STA enem_page+5,X
	LDA #$00
	STA enem_page+6,X
	STA enem_page+7,X

	; third enemy always present at beginning
	LDX #$10
	LDA #$40
	STA enem_page+0,X
	LDA #$40
	STA enem_page+1,X
	LDA #$78
	STA enem_page+2,X
	LDA #$40
	STA enem_page+3,X
	LDA #$00
	STA enem_page+4,X
	LDA #$01
	STA enem_page+5,X
	LDA #$00
	STA enem_page+6,X
	STA enem_page+7,X

	; remember the place
	STX spawn_prev

	; set character pos/vel/dir
	LDA #$68
	STA char_pos_x
	LDA #$80
	STA char_pos_y
	LDA #$00
	STA char_vel_y
	LDA #$01
	STA char_dir_x
	LDA #$01
	STA char_dir_y
	LDA #$FF
	STA char_fly_cnt
	LDA #$00
	STA char_fly_val
	LDA #$03
	STA char_dash_cnt
	LDA #$00
	STA char_dash_val
	LDA #$00
	STA char_dash_x
	LDA #$00
	STA char_dash_y
	LDA #$00
	STA char_dash_held

	; set paused sequences
	LDA #$40
	STA char_intro
	LDA #$00
	STA char_death
	LDA #$00
	STA char_fin

	; set map scroll
	LDA #$18 ; affects where clocks appear
	STA map_y_low
	LDA #$00
	STA map_y_high

	; set enemy spawn values
	LDA #$78 ; seems to work?
	STA spawn_cnt
	LDA #$18 ; start of fourth spawn
	STA spawn_pos

	; set enemy animations
	LDA #$0F
	STA anim_cnt
	LDA #$00
	STA anim_val
	
	; set other variables
	LDA #$00
	STA cloud_val
	LDA #$00
	STA clock_val
	LDA #$80
	STA clock_apr
	LDA #$FF
	STA map_timer
	LDA #$00
	STA map_fin

	LDA #$00
	STA time_low
	LDA #$00
	STA time_high
	LDA #$00
	STA pts_hit
	LDA #$00
	STA pts_miss

	LDA ext_y
	CMP #$FF
	BEQ setup_exit
	LDA #$EF
	STA ext_y
setup_exit
	RTS

; shifts through joy one buttons
; values are reversed!
buttons
	LDA #$01
	STA joy_one
	LDA #$00
	STA joy_one
	LDA #$00
	STA button_value
	LDX #$08
buttons_loop
	ASL button_value
	LDA joy_one
	AND #$01
	ORA button_value
	STA button_value
	DEX
	BNE buttons_loop
	RTS

; main computation sub-routine
compute
	; check for intro
	LDA char_intro
	BEQ compute_check_one
	DEC char_intro
	JMP compute_bounds_one

compute_check_one
	; check for death
	LDA char_death
	BEQ compute_check_two
	DEC char_death
	BNE compute_check_four
	JMP init ; restart level

compute_check_two
	; bound player at top of level
	LDA map_fin
	BEQ compute_apply_one
	LDA char_pos_y
	CMP #$20
	BCS compute_check_three
	LDA #$20
	STA char_pos_y
	LDA #$00
	STA char_vel_y

compute_check_three
	; check if finish
	LDA char_fin
	BEQ compute_apply_one
	DEC char_fin
	BNE compute_check_four
	
	; compute score
	JSR score
	JMP boot ; back to menu level

compute_check_four
	RTS

compute_apply_one
	; apply dash
	LDA char_dash_val
	BEQ compute_gravity_one
	DEC char_dash_val
	LDA #$08 ; velocity after dash
	STA char_vel_y
	LDA char_dash_x
	BEQ compute_apply_three
	CMP #$80
	BCC compute_apply_two
	LDA #$FF
	STA char_dir_x
	BNE compute_apply_three
compute_apply_two
	LDA #$01
	STA char_dir_x
compute_apply_three
	LDA #$FF
	STA char_dir_y
	LDA char_dash_y
	BEQ compute_apply_four
	CMP #$80
	BCS compute_apply_four
	LDA #$01
	STA char_dir_y
compute_apply_four
	LDA char_pos_x
	CLC
	ADC char_dash_x
	STA char_pos_x
	LDA char_pos_y
	CLC
	ADC char_dash_y
	STA char_pos_y
	JMP compute_gravity_three

compute_gravity_one
	; check character direction
	LDA char_dir_y
	CMP #$80
	BCC compute_gravity_two

	; apply gravity for upward direction
	LDA char_vel_y
	LSR A
	LSR A
	LSR A
	STA math_slot0
	LDA char_pos_y
	SEC
	SBC math_slot0
	STA char_pos_y
	LDA char_vel_y
	SEC
	SBC #$01
	STA char_vel_y
	BCS compute_gravity_three

	; back down after peak
	LDA #$08
	STA char_vel_y
	LDA #$01
	STA char_dir_y
	BNE compute_gravity_three

compute_gravity_two
	; apply gravity for downward direction
	LDA char_vel_y
	LSR A
	LSR A
	LSR A
	CLC
	ADC char_pos_y
	STA char_pos_y
	INC char_vel_y
	LDA char_vel_y
	CMP #$1E
	BCC compute_gravity_three
	LDA #$1E ; terminal velocity
	STA char_vel_y

compute_gravity_three
	; game over if player hits bottom of screen
	LDA char_pos_y
	CMP #$F0
	BCC compute_moves_one
	LDA #$40 ; death length
	STA char_death
	
compute_flag_one
	; store position for flag
	LDA map_y_high
	CMP map_prev_high
	BCC compute_flag_three
	BEQ compute_flag_two
	LDA map_y_low
	STA map_prev_low
	LDA map_y_high
	STA map_prev_high
	JMP compute_flag_three
compute_flag_two
	LDA map_y_low
	CMP map_prev_low
	BCC compute_flag_three
	LDA map_y_low
	STA map_prev_low
	LDA map_y_high
	STA map_prev_high
compute_flag_three
	RTS

compute_moves_one
	; if dashing, skip other buttons
	LDA char_dash_val
	BEQ compute_moves_two
	JMP compute_bounds_one

compute_moves_two
	; if pressing right, move right
	LDA button_value
	AND #$01 ; right
	BEQ compute_moves_three
	JSR rand_func ; helps randomize
	LDA #$01
	STA char_dir_x
	LDA char_pos_x
	CLC
	ADC #$02
	STA char_pos_x

compute_moves_three
	; if pressing left, move left
	LDA button_value
	AND #$02 ; left
	BEQ compute_moves_four
	JSR rand_func ; helps randomize
	LDA #$FF
	STA char_dir_x
	LDA char_pos_x
	SEC
	SBC #$02
	STA char_pos_x

compute_moves_four
	; if pressing B, fly upward
	LDA button_value
	AND #$40 ; B
	BEQ compute_react_one
	JSR rand_func ; helps randomize
	LDA char_fly_cnt
	CMP #$02
	BCC compute_react_one
	SEC
	SBC #$02 ; drain amount
	STA char_fly_cnt
	LDA cloud_val
	BNE compute_moves_five

	; cloud below character
	LDA #$FF
	STA cloud_val
	LDA char_pos_x
	STA cloud_x
	LDA char_pos_y
	STA cloud_y

compute_moves_five
	; decide which vertical direction
	LDA #$02 ; animation length
	STA char_fly_val
	LDA char_dir_y
	CMP #$80
	BCC compute_moves_six

	; if going upward, go faster
	LDA char_vel_y
	CLC
	ADC #$02
	STA char_vel_y
	CMP #$1E
	BCC compute_react_one
	LDA #$1E ; terminal velocity
	STA char_vel_y
	BNE compute_react_one

compute_moves_six
	; if going downward, slow down
	LDA char_vel_y
	SEC
	SBC #$02
	STA char_vel_y
	BCS compute_react_one

	; if zero velocity, turn around
	LDA #$02
	STA char_vel_y
	LDA #$FF
	STA char_dir_y

compute_react_one
	; if pressing A, dash
	LDA button_value
	AND #$80 ; A
	BNE compute_react_two
	JSR rand_func ; helps randomize
	LDA #$00
	STA char_dash_held
	BEQ compute_bounds_one
compute_react_two
	LDA char_dash_held
	BNE compute_bounds_one
	LDA char_dash_val
	BNE compute_bounds_one
	LDA char_dash_cnt
	BEQ compute_bounds_one
	LDA #$00
	STA char_dash_x
	STA char_dash_y

	; cloud below character
	LDA #$FF
	STA cloud_val
	LDA char_pos_x
	STA cloud_x
	LDA char_pos_y
	STA cloud_y
	
	; decide dash directions
	LDA button_value
	AND #$01 ; right
	BEQ compute_react_three
	LDA char_dash_x
	CLC
	ADC #$04 ; dash speed
	STA char_dash_x
compute_react_three
	LDA button_value
	AND #$02 ; left
	BEQ compute_react_four
	LDA char_dash_x
	SEC
	SBC #$04 ; dash speed
	STA char_dash_x
compute_react_four
	LDA button_value
	AND #$04 ; down
	BEQ compute_react_five
	LDA char_dash_y
	CLC
	ADC #$04 ; dash speed
	STA char_dash_y
compute_react_five
	LDA button_value
	AND #$08 ; up
	BEQ compute_react_six
	LDA char_dash_y
	SEC
	SBC #$04 ; dash speed
	STA char_dash_y

compute_react_six
	; check if going in direction
	LDA char_dash_x
	BNE compute_react_seven
	LDA char_dash_y
	BNE compute_react_seven
	BEQ compute_bounds_one

compute_react_seven
	; if going in direction, start dash
	DEC char_dash_cnt
	LDA #$0C ; dash duration
	STA char_dash_val
	LDA #$01
	STA char_dash_held
	
compute_bounds_one
	; bound right side
	LDA char_pos_x
	CMP #$B0
	BCC compute_bounds_two
	LDA #$B0 ; right side
	STA char_pos_x

compute_bounds_two
	; bound left side
	LDA char_pos_x
	CMP #$20
	BCS compute_bounds_three
	LDA #$20 ; left side
	STA char_pos_x

compute_bounds_three
	; check for clock
	LDA clock_val
	BEQ compute_bounds_five
	LDA clock_y
	CMP #$E8 ; lowest clock height
	BCS compute_bounds_four
	LDA clock_y
	SEC
	SBC #$08
	SEC
	SBC char_pos_y
	BCS compute_bounds_five
	LDA char_pos_y
	SEC
	SBC #$0C
	SEC
	SBC clock_y
	BCS compute_bounds_five
	LDA clock_x
	SEC
	SBC #$10
	SEC
	SBC char_pos_x
	BCS compute_bounds_five
	LDA char_pos_x
	SEC
	SBC #$10
	SEC
	SBC clock_x
	BCS compute_bounds_five

	; add time
	LDA map_timer
	CLC
	ADC #$20 ; timer bonus
	STA map_timer
	BCC compute_bounds_four
	LDA #$FF
	STA map_timer
	
compute_bounds_four
	; remove clock
	LDX #$D0
	LDA #$EF ; remove sprites
	STA oam_page,X
	STA oam_page+4,X
	STA oam_page+8,X
	STA oam_page+12,X
	LDA #$00 ; remove clock
	STA clock_val

compute_bounds_five
	; start of enemy array
	LDX #$00

compute_bounds_six
	; check enemy collisions
	LDA enem_page+0,X
	BEQ compute_enemies_three
	LDA enem_page+2,X
	SEC
	SBC #$08
	SEC
	SBC char_pos_y
	BCS compute_enemies_three
	LDA char_pos_y
	SEC
	SBC #$0C
	SEC
	SBC enem_page+2,X
	BCS compute_enemies_three
	LDA enem_page+1,X
	SEC
	SBC #$10
	SEC
	SBC char_pos_x
	BCS compute_enemies_three
	LDA char_pos_x
	SEC
	SBC #$10
	SEC
	SBC enem_page+1,X
	BCS compute_enemies_three

	; check if warp at end of level
	LDA map_fin
	BEQ compute_enemies_two
	CPX spawn_pos
	BNE compute_enemies_two
	LDA #$40 ; finish length
	STA char_fin
	LDA menu_pos
	CMP menu_prog
	BCC compute_enemies_zero
	CLC
	ADC #$01
	STA menu_prog ; update menu progress

compute_enemies_zero
	; change kitty
	LDA enem_page+3,X
	CMP #$6E ; check for kitty
	BNE compute_enemies_one
	LDA char_skin
	CLC
	ADC #$0C ; holding kitty image
	STA enem_page+3,X
	LDA #$00
	STA enem_page+4,X
	STA enem_page+5,X
	STA enem_page+6,X
	STA enem_page+7,X

	; draw extra sprites
	LDA enem_page+1,X
	STA ext_x
	LDA enem_page+2,X
	STA ext_y
	LDA #$01
	STA char_dir_x

compute_enemies_one
	; exit
	RTS

compute_enemies_two
	; game over if hitting an enemy while going up
	LDA char_dir_y
	CMP #$80
	BCC compute_enemies_four
	LDA #$40 ; death length
	STA char_death

	; store position for flag
	JMP compute_flag_one

compute_enemies_three
	; branches were out of range...
	JMP compute_enemies_seven

compute_enemies_four
	; game over if hitting spikes
	LDA enem_page+3,X
	AND #$F0
	CMP #$60
	BNE compute_enemies_five
	LDA #$40 ; death length
	STA char_death
	
	; store position for flag
	JMP compute_flag_one

compute_enemies_five
	; if dashing (downward), then enemies goes away
	LDA char_dash_val
	BEQ compute_enemies_six
	TXA
	PHA
	LDA enem_page+0,X
	TAX
	LDA #$EF ; remove sprites
	STA oam_page,X
	STA oam_page+4,X
	STA oam_page+8,X
	STA oam_page+12,X
	PLA
	TAX
	LDA #$00 ; remove enemy
	STA enem_page+0,X
	LDA #$FF ; cloud length
	STA cloud_val
	LDA enem_page+1,X
	STA cloud_x
	LDA enem_page+2,X
	SEC
	SBC #$08
	STA cloud_y

	; add hit
	INC pts_hit

	; refill energy
	LDA char_fly_cnt
	CLC
	ADC #$40 ; refill amount
	STA char_fly_cnt
	BCC compute_enemies_six
	LDA #$FF
	STA char_fly_cnt

compute_enemies_six
	; bounce character
	LDA #$1E ; high bounce
	STA char_vel_y
	LDA char_pos_y
	SEC
	SBC #$08
	STA char_pos_y
	LDA #$FF
	STA char_dir_y
	LDA #$03
	STA char_dash_cnt
	LDA char_dash_val
	PHA
	LDA #$00
	STA char_dash_val
	PLA
	BNE compute_enemies_seven
	LDA enem_page+3,X
	AND #$0F
	BEQ compute_enemies_seven
	CMP #$04
	BEQ compute_enemies_seven
	LDA #$10 ; low bounce
	STA char_vel_y

	; remove ghosts on bounce
	LDA enem_page+3,X
	AND #$0F
	CMP #$0C
	BNE compute_enemies_seven
	LDA #$1E ; retain high bounce
	STA char_vel_y
	TXA
	PHA
	LDA enem_page+0,X
	TAX
	LDA #$EF ; remove sprites
	STA oam_page,X
	STA oam_page+4,X
	STA oam_page+8,X
	STA oam_page+12,X
	PLA
	TAX
	LDA #$00 ; remove enemy
	STA enem_page+0,X
	LDA #$FF ; cloud length
	STA cloud_val
	LDA enem_page+1,X
	STA cloud_x
	LDA enem_page+2,X
	SEC
	SBC #$08
	STA cloud_y

compute_enemies_seven
	; repeat for all enemies
	TXA
	CLC
	ADC #$08
	TAX
	CMP #$80 ; 16 enemies
	BEQ compute_enemies_eight
	JMP compute_bounds_six

compute_enemies_eight
	; check if scrolling upward
	LDA #$80
	SEC
	SBC char_pos_y
	BCS compute_enemies_nine
	JMP compute_patrol_one

compute_enemies_nine
	; add to spawn counter
	TAY
	CLC
	ADC spawn_cnt
	STA spawn_cnt
	CMP #$28
	BCS compute_enemies_ten
	JMP compute_shift_one

compute_enemies_ten
	; loop back array
	SEC
	SBC #$28
	STA spawn_cnt
	
	; do not spawn enemies if finished
	LDA map_fin
	BEQ compute_enemies_twelve
	CMP #$01 ; warp not yet drawn
	BNE compute_enemies_eleven

	; create warp at end
	LDA spawn_pos
	TAX
	ASL A
	CLC
	ADC #$20
	STA enem_page+0,X
	LDA #$68
	STA enem_page+1,X
	LDA #$00
	STA enem_page+2,X
	LDA #$00
	STA enem_page+5,X
	LDA #$80
	STA enem_page+7,X
	LDA #$02 ; warp is now drawn
	STA map_fin

	; decide if warp or kitty
	LDA #$6C ; warp pattern
	STA enem_page+3,X
	LDA #$00
	STA enem_page+4,X
	STA enem_page+6,X
	LDA menu_pos
	CMP #$03 ; last level
	BNE compute_enemies_eleven
	LDA #$6E ; kitty pattern
	STA enem_page+3,X
	LDA #$01
	STA enem_page+4,X
	STA enem_page+6,X

compute_enemies_eleven
	; branches were out of range...
	JMP compute_shift_one	

compute_enemies_twelve
	; add new enemy here
	LDA spawn_pos
	TAX
	ASL A
	CLC
	ADC #$20
	STA enem_page+0,X
	LDA spawn_pos
	CLC
	ADC #$08
	AND #$3F
	STA spawn_pos

	TYA
	PHA
compute_spawn_one
	; set randomized x-value
	JSR rand_func
	LDA rand_val
	AND #$07
	ASL A
	ASL A
	ASL A
	ASL A
	CLC
	ADC #$30
	STA enem_page+1,X
	LDY spawn_prev
	CMP enem_page+1,Y
	BEQ compute_spawn_one
	PLA
	TAY

	; set y-value
	LDA spawn_cnt
	STA enem_page+2,X

	; set type and palette
	TXA
	PHA
	JSR rand_func
	LDA rand_val
	AND #$07
	STA math_slot0
	LDA map_len
	LSR A
	CMP map_y_high
	BCS compute_spawn_two	
	LDA math_slot0
	CLC
	ADC #$08
	STA math_slot0
compute_spawn_two
	LDX math_slot0
	LDA enem_dice,X
	STA math_slot0
	LDA enem_pal,X
	STA math_slot1
	PLA
	TAX
	LDA math_slot0
	STA enem_page+3,X
	LDA math_slot1
	STA enem_page+5,X

	TYA
	PHA	
compute_spawn_three
	; set x-direction
	JSR rand_func
	LDA rand_val
	AND #$01
	STA math_slot0
	LDA #$FF
	CLC
	ADC math_slot0
	CLC
	ADC math_slot0
	STA enem_page+4,X
	LDY spawn_prev
	CMP enem_page+4,Y
	BEQ compute_spawn_three
	PLA
	TAY

	; set spawn previous index
	STX spawn_prev

	; x-velocity
	LDA #$00
	STA enem_page+6,X
	STA enem_page+7,X
	LDA enem_page+3,X
	AND #$0F
	LSR A
	LSR A
	BEQ compute_shift_one
	CMP #$02
	BEQ compute_shift_one
	LDA enem_page+4,X
	STA enem_page+6,X
	
	; x-sway
	LDA enem_page+3,X
	CMP #$4C
	BNE compute_shift_one
	LDA #$80 ; starting from middle
	STA enem_page+7,X

compute_shift_one
	; check map finished
	LDA map_fin
	BEQ compute_shift_two
	LDA map_y_low
	CMP #$80 ; scroll a little further to prevent issues
	BCC compute_shift_two
	JMP compute_patrol_one

compute_shift_two
	; scroll map upward
	TYA
	CLC
	ADC map_y_low
	STA map_y_low
	BCC compute_shift_three
	CLC
	ADC #$10 ; add 16 because only 240 pixels vertically
	STA map_y_low
	INC map_y_high

	; add to clock appearing
	LDA clock_apr
	CLC
	ADC #$01
	STA clock_apr
	CMP clock_freq ; frequency of clocks
	BCC compute_shift_three
	LDA #$00
	STA clock_apr

	; make clock appear
	LDA #$01
	STA clock_val
	JSR rand_func
	LDA rand_val
	AND #$07
	ASL A
	ASL A
	ASL A
	ASL A
	CLC
	ADC #$20
	STA clock_x
	LDA #$08
	STA clock_y

	; check map progress, needs work
	LDA map_y_high
	CMP map_len ; how high map goes
	BCC compute_shift_three
	LDA #$01
	STA map_fin

compute_shift_three
	; get enemy loop ready
	LDX #$00

	; character stays in center of screen
	LDA #$80
	STA char_pos_y

	; scroll cloud downward
	TYA
	CLC
	ADC cloud_y
	STA cloud_y

	; scroll clock downward
	TYA
	CLC
	ADC clock_y
	STA clock_y
	CMP #$F0
	BCC compute_shift_four
	TXA
	PHA
	LDX #$C0
	LDA #$EF ; remove sprites
	STA oam_page,X
	STA oam_page+4,X
	STA oam_page+8,X
	STA oam_page+12,X
	PLA
	TAX
	LDA #$00 ; remove clock
	STA clock_val

compute_shift_four
	; scroll enemies downward
	LDA enem_page+0,X
	BEQ compute_shift_five
	TYA
	CLC
	ADC enem_page+2,X
	STA enem_page+2,X
	CMP #$F0
	BCC compute_shift_five

	; make enemy disappear at bottom
	TXA
	PHA
	LDA enem_page+0,X
	TAX
	LDA #$EF ; remove sprites
	STA oam_page,X
	STA oam_page+4,X
	STA oam_page+8,X
	STA oam_page+12,X
	PLA
	TAX
	LDA #$00 ; remove enemy
	STA enem_page+0,X

	; add miss for non-spikes
	LDA enem_page+3,X
	CMP #$60
	BCS compute_shift_five
	INC pts_miss

compute_shift_five
	; repeat for all enemies
	TXA
	CLC
	ADC #$08
	TAX
	CMP #$80
	BNE compute_shift_four

compute_patrol_one
	; move enemies horizontally
	LDA anim_cnt
	AND #$01
	BNE compute_patrol_seven
	LDX #$00
compute_patrol_two
	LDA enem_page+1,X
	CLC
	ADC enem_page+6,X
	STA enem_page+1,X
	CMP #$B0 ; right border
	BCC compute_patrol_three
	LDA #$FF
	STA enem_page+4,X
	STA enem_page+6,X
compute_patrol_three
	CMP #$20 ; left border
	BCS compute_patrol_four
	LDA #$01
	STA enem_page+4,X
	STA enem_page+6,X

compute_patrol_four
	; check for sway
	LDA enem_page+7,X
	BEQ compute_patrol_six
	LDA enem_page+7,X
	CLC
	ADC enem_page+6,X
	STA enem_page+7,X
	CMP #$88 ; one block right
	BCC compute_patrol_five 
	LDA #$FF
	STA enem_page+4,X
	STA enem_page+6,X
compute_patrol_five
	CMP #$78 ; one block left
	BCS compute_patrol_six
	LDA #$01
	STA enem_page+4,X
	STA enem_page+6,X

compute_patrol_six
	; repeat for all enemies
	TXA
	CLC
	ADC #$08
	TAX
	CMP #$80
	BNE compute_patrol_two

compute_patrol_seven
	RTS


; main drawing sub-routine
redraw
	; skip drawing character if through warp
	LDA char_fin
	BNE redraw_char_six

	; load quad for character
	LDA #$10
	STA quad_oam
	LDA char_pos_x
	STA quad_x
	LDA char_pos_y
	STA quad_y
	LDA char_dir_x
	STA quad_dir
	LDA #$00
	STA quad_pal
	
	; check for intro
	LDA char_intro
	BEQ redraw_char_zero
	LDA anim_val
	ASL A
	SEC
	SBC #$01
	STA char_dir_x
	LDA #$6C
	STA quad_chr
	BNE redraw_char_five

redraw_char_zero
	; check for death
	LDA char_death
	BEQ redraw_char_one
	LDA char_skin
	CLC
	ADC #$0A
	STA quad_chr
	BNE redraw_char_five

redraw_char_one
	; check for fly animation
	LDA char_fly_val
	BEQ redraw_char_two
	LDA anim_val
	ASL A
	CLC
	ADC char_skin
	CLC
	ADC #$04
	STA quad_chr
	BNE redraw_char_five

redraw_char_two
	; check for dash animation
	LDA char_dash_val
	BEQ redraw_char_three
	LDA char_skin
	CLC
	ADC #$08
	STA quad_chr
	BNE redraw_char_five
	
redraw_char_three
	; check character y-direction
	LDA char_dir_y
	CMP #$80
	BCC redraw_char_four

	; draw quad for upward movement
	LDA char_skin
	STA quad_chr
	JMP redraw_char_five

redraw_char_four
	; draw quad for downward movement
	LDA char_skin
	CLC
	ADC #$02
	STA quad_chr
	
redraw_char_five
	; draw quad
	JSR quad
	JMP redraw_char_seven

redraw_char_six
	; remove character sprites
	LDA #$EF
	STA oam_page+16
	STA oam_page+20
	STA oam_page+24
	STA oam_page+28

redraw_char_seven
	; draw ticks, always at $E0 oam
	JSR ticks

	; draw flags, always at $E4 oam
	JSR flags

	LDX #$00
redraw_enemies_one
	; draw quad for each enemy
	LDA enem_page+0,X
	BEQ redraw_enemies_three
	STA quad_oam
	LDA enem_page+1,X
	STA quad_x
	LDA enem_page+2,X
	STA quad_y
	LDA #$FF ; used to stop kitty animation
	PHA
	LDA map_fin
	BEQ redraw_enemies_two
	CPX spawn_pos
	BNE redraw_enemies_two

	; warp or kitty at end of level
	PLA
	LDA #$00
	PHA
	LDA enem_page+3,X
	CMP #$6C ; check for warp
	BNE redraw_enemies_two
	LDA enem_page+3,X
	STA quad_chr
	LDA #$FF
	CLC
	ADC anim_val
	CLC
	ADC anim_val
	STA quad_dir
	LDA enem_page+5,X
	STA quad_pal
	JSR quad
	PLA
	JMP redraw_enemies_three

redraw_enemies_two
	; regular enemy
	LDA anim_val
	CLC
	ADC anim_val
	STA math_slot0
	PLA
	AND math_slot0
	CLC
	ADC enem_page+3,X
	STA quad_chr
	LDA enem_page+4,X
	STA quad_dir
	LDA enem_page+5,X
	STA quad_pal
	JSR quad

redraw_enemies_three
	; repeat for all enemies
	TXA
	CLC
	ADC #$08
	TAX
	CMP #$80 ; 16 enemies
	BNE redraw_enemies_one

	; draw timer wheel, always at $A0 oam
	JSR wheel

	; draw fly bar, always at $B0 oam
	JSR bar

	; draw cloud, always $C0 oam
	JSR cloud

	LDA ext_y
	CMP #$FF
	BNE redraw_enemies_four
	JMP redraw_enemies_five
redraw_enemies_four
	LDX #$F0 ; last sprites!
	LDA ext_y
	STA oam_page+0,X
	STA oam_page+4,X
	CLC
	ADC #$08
	STA oam_page+8,X
	STA oam_page+12,X
	LDA char_skin
	CLC
	ADC #$0E
	STA oam_page+1,X
	CLC
	ADC #$01
	STA oam_page+5,X
	CLC
	ADC #$0F
	STA oam_page+9,X
	CLC
	ADC #$01
	STA oam_page+13,X
	LDA #$00
	STA oam_page+2,X
	STA oam_page+6,X
	STA oam_page+10,X
	STA oam_page+14,X
	LDA ext_x
	STA oam_page+3,X
	STA oam_page+11,X
	CLC
	ADC #$08
	STA oam_page+7,X
	STA oam_page+15,X
redraw_enemies_five

	; draw clock
	LDA clock_val
	BEQ redraw_hud_one
	LDA #$D0
	STA quad_oam
	LDA clock_x
	STA quad_x
	LDA clock_y
	STA quad_y
	LDA anim_val
	ASL A
	CLC
	ADC #$68
	STA quad_chr
	LDA #$00
	STA quad_dir
	LDA #$00
	STA quad_pal
	JSR quad

redraw_hud_one

	RTS


; draw background in name and attribute tables
back
	TXA
	PHA

	; load name table
	LDY #$20
back_sub_one
	LDA ppu_status
	STY ppu_addr
	LDA #$00
	STA ppu_addr
	LDX #$00
	TYA
	AND #$08
	ASL A
	ASL A ; makes it seamless
	STA math_slot0
	STA math_slot1
back_sub_two
	TXA
	AND #$0F
	BNE back_sub_three
	LDA math_slot0
	AND #$F8
	STA math_slot0
	STA math_slot1
back_sub_three
	TXA
	AND #$1F
	CMP #$04
	BCC back_sub_four
	CMP #$18
	BCS back_sub_four
	LDA math_slot0
	AND #$33
	CLC
	ADC back_in
	STA ppu_data
	INC math_slot0
	JMP back_sub_five
back_sub_four
	LDA math_slot1
	AND #$33
	CLC
	ADC back_out
	STA ppu_data
	INC math_slot1
back_sub_five
	INX
	BNE back_sub_two
	INY
	TYA
	AND #$F4
	CMP #$24
	BNE back_sub_one

	; load attribute table
	LDA ppu_status
	TYA
	SEC
	SBC #$01
	STA ppu_addr
	LDA #$C0
	STA ppu_addr
	LDX #$40
back_sub_six
	LDA #$55
	STA ppu_data
	LDA #$00
	STA ppu_data
	STA ppu_data
	STA ppu_data
	STA ppu_data
	STA ppu_data
	LDA #$55
	STA ppu_data
	LDA #$AA
	STA ppu_data
	TXA
	SEC
	SBC #$08
	TAX
	BNE back_sub_six
	
	; started at $2000,
	; now repeat for $2800
	TYA
	CMP #$2C
	BEQ back_sub_seven
	LDY #$28
	JMP back_sub_one

back_sub_seven

	PLA
	TAX
	RTS


; draw four 8x8 sprites in a quad
quad
	TXA
	PHA
	LDX quad_oam
	LDA quad_dir
	CMP #$80
	BCS quad_skip
	
	LDA quad_y
	SEC
	SBC #$08
	STA oam_page+0,X
	STA oam_page+4,X
	SEC
	SBC #$08
	STA oam_page+8,X
	STA oam_page+12,X

	LDA quad_chr
	STA oam_page+9,X
	CLC
	ADC #$01
	STA oam_page+13,X
	CLC
	ADC #$0F
	STA oam_page+1,X
	CLC
	ADC #$01
	STA oam_page+5,X

	LDA quad_pal
	STA oam_page+2,X
	STA oam_page+6,X
	STA oam_page+10,X
	STA oam_page+14,X

	LDA quad_x
	STA oam_page+3,X
	STA oam_page+11,X
	CLC
	ADC #$08
	STA oam_page+7,X
	STA oam_page+15,X

	PLA
	TAX
	RTS

quad_skip

	LDA quad_y
	SEC
	SBC #$08
	STA oam_page+0,X
	STA oam_page+4,X
	SEC
	SBC #$08
	STA oam_page+8,X
	STA oam_page+12,X

	LDA quad_chr
	STA oam_page+13,X
	CLC
	ADC #$01
	STA oam_page+9,X
	CLC
	ADC #$0F
	STA oam_page+5,X
	CLC
	ADC #$01
	STA oam_page+1,X

	LDA quad_pal
	ORA #$40
	STA oam_page+2,X
	STA oam_page+6,X
	STA oam_page+10,X
	STA oam_page+14,X

	LDA quad_x
	STA oam_page+3,X
	STA oam_page+11,X
	CLC
	ADC #$08
	STA oam_page+7,X
	STA oam_page+15,X

	PLA
	TAX
	RTS
	

; draws ticks 
ticks
	TXA
	PHA

	; draw dash count
	LDX #$E0
	LDA char_intro
	BNE ticks_sub_five
	LDA char_fin
	BNE ticks_sub_four
	LDA char_pos_y
	SEC
	SBC #$1A
	STA oam_page+0,X
	LDA char_pos_x
	CLC
	ADC #$04
	STA oam_page+3,X
	LDA #$00
	STA oam_page+2,X
	LDA char_dash_cnt
	BEQ ticks_sub_one
	CMP #$01
	BEQ ticks_sub_two
	CMP #$02
	BEQ ticks_sub_three
	LDA #$88
	STA oam_page+1,X
	JMP ticks_sub_five
ticks_sub_one
	LDA #$99
	STA oam_page+1,X
	JMP ticks_sub_five
ticks_sub_two
	LDA #$98
	STA oam_page+1,X
	JMP ticks_sub_five
ticks_sub_three
	LDA #$89
	STA oam_page+1,X
	JMP ticks_sub_five
ticks_sub_four
	; remove dash sprite
	LDA #$EF
	STA oam_page+0,X
ticks_sub_five
		
	PLA
	TAX
	RTS

; draw flags
flags
	TXA
	PHA

	; draw previous position flag
	LDX #$E4
	LDA map_prev_low
	STA mini_low
	LDA map_prev_high
	STA mini_high
	JSR mini
	STA math_slot0
	LDA #$A0
	SEC
	SBC math_slot0
	STA oam_page+0,X
	LDA #$8B
	STA oam_page+1,X
	LDA #$00
	STA oam_page+2,X
	LDA #$E8
	STA oam_page+3,X
	
	; draw current position head
	INX
	INX
	INX
	INX
	LDA map_y_low
	STA mini_low
	LDA map_y_high
	STA mini_high
	JSR mini
	STA math_slot0
	LDA #$A0
	SEC
	SBC math_slot0
	STA oam_page+0,X
	STA oam_page+4,X
	LDA #$8A
	STA oam_page+1,X
	STA oam_page+5,X
	LDA #$00
	STA oam_page+2,X
	LDA #$40
	STA oam_page+6,X
	LDA #$E4
	STA oam_page+3,X
	LDA #$EC
	STA oam_page+7,X

	PLA
	TAX
	RTS

; get position for flags, returns A
mini
	TXA
	PHA
	
	LDX map_mul
	LDA mini_high
mini_sub_one
	ASL A
	DEX
	BNE mini_sub_one
	STA math_slot0

	LDA #$08
	SEC
	SBC map_mul
	TAX
	LDA mini_low
mini_sub_two
	LSR A
	DEX
	BNE mini_sub_two
	CLC
	ADC math_slot0
	LSR A
	STA math_slot0

	PLA
	TAX
	LDA math_slot0
	RTS


; draws wheel
wheel
	TXA
	PHA

	; set top-left corner
	LDX #$A0
	LDA #$40 ; y-value
	STA oam_page+0,X
	LDA #$E4 ; x-value
	STA oam_page+3,X
	LDA #$40
	STA oam_page+2,X
	LDA map_timer ; counter
	CMP #$28
	BCC wheel_topleft_one
	LDA #$80	
	STA oam_page+1,X
	JMP wheel_topleft_three
wheel_topleft_one
	CMP #$08
	BCC wheel_topleft_two
	LDA #$90
	STA oam_page+1,X
	JMP wheel_topleft_three
wheel_topleft_two
	LDA #$81
	STA oam_page+1,X
wheel_topleft_three

	; set bottom-left corner
	INX
	INX
	INX
	INX
	LDA #$48 ; y-value
	STA oam_page+0,X
	LDA #$E4 ; x-value
	STA oam_page+3,X
	LDA #$C0
	STA oam_page+2,X
	LDA map_timer ; counter
	CMP #$68
	BCC wheel_btmleft_one
	LDA #$80	
	STA oam_page+1,X
	JMP wheel_btmleft_three
wheel_btmleft_one
	CMP #$48
	BCC wheel_btmleft_two
	LDA #$91
	STA oam_page+1,X
	JMP wheel_btmleft_three
wheel_btmleft_two
	LDA #$81
	STA oam_page+1,X
wheel_btmleft_three

	; set bottom-right corner
	INX
	INX
	INX
	INX
	LDA #$48 ; y-value
	STA oam_page+0,X
	LDA #$EC ; x-value
	STA oam_page+3,X
	LDA #$80
	STA oam_page+2,X
	LDA map_timer ; counter
	CMP #$A8
	BCC wheel_btmright_one
	LDA #$80	
	STA oam_page+1,X
	JMP wheel_btmright_three
wheel_btmright_one
	CMP #$88
	BCC wheel_btmright_two
	LDA #$90
	STA oam_page+1,X
	JMP wheel_btmright_three
wheel_btmright_two
	LDA #$81
	STA oam_page+1,X
wheel_btmright_three

	; set top-right corner
	INX
	INX
	INX
	INX
	LDA #$40 ; y-value
	STA oam_page+0,X
	LDA #$EC ; x-value
	STA oam_page+3,X
	LDA #$00
	STA oam_page+2,X
	LDA map_timer ; counter
	CMP #$E8
	BCC wheel_topright_one
	LDA #$80	
	STA oam_page+1,X
	JMP wheel_topright_three
wheel_topright_one
	CMP #$C8
	BCC wheel_topright_two
	LDA #$91
	STA oam_page+1,X
	JMP wheel_topright_three
wheel_topright_two
	LDA #$81
	STA oam_page+1,X
wheel_topright_three

	PLA
	TAX
	RTS


	
; draws horizontal bar
bar
	TXA
	PHA

	; set top-left corner
	LDX #$B0
	LDA #$A8 ; y-value
	STA oam_page+0,X
	LDA #$E4 ; x-value
	STA oam_page+3,X
	LDA #$00
	STA oam_page+2,X
	LDA char_fly_cnt ; counter
	CMP #$DC
	BCC bar_topleft_one
	LDA #$82
	STA oam_page+1,X
	JMP bar_topleft_four
bar_topleft_one	
	CMP #$B8
	BCC bar_topleft_two
	LDA #$83
	STA oam_page+1,X
	JMP bar_topleft_four
bar_topleft_two
	CMP #$94
	BCC bar_topleft_three
	LDA #$92
	STA oam_page+1,X
	JMP bar_topleft_four
bar_topleft_three
	LDA #$93
	STA oam_page+1,X
bar_topleft_four

	; set bottom-left corner
	INX
	INX
	INX
	INX
	LDA #$B0 ; y-value
	STA oam_page+0,X
	LDA #$E4 ; x-value
	STA oam_page+3,X
	LDA #$80
	STA oam_page+2,X
	LDA char_fly_cnt ; counter
	CMP #$DC
	BCC bar_btmleft_one
	LDA #$82
	STA oam_page+1,X
	JMP bar_btmleft_four
bar_btmleft_one	
	CMP #$B8
	BCC bar_btmleft_two
	LDA #$83
	STA oam_page+1,X
	JMP bar_btmleft_four
bar_btmleft_two
	CMP #$94
	BCC bar_btmleft_three
	LDA #$92
	STA oam_page+1,X
	JMP bar_btmleft_four
bar_btmleft_three
	LDA #$93
	STA oam_page+1,X
bar_btmleft_four

	; set bottom-right corner
	INX
	INX
	INX
	INX
	LDA #$B0 ; y-value
	STA oam_page+0,X
	LDA #$EC ; x-value
	STA oam_page+3,X
	LDA #$80
	STA oam_page+2,X
	LDA char_fly_cnt ; counter
	CMP #$6C
	BCC bar_btmright_one
	LDA #$82
	STA oam_page+1,X
	JMP bar_btmright_four
bar_btmright_one	
	CMP #$38
	BCC bar_btmright_two
	LDA #$83
	STA oam_page+1,X
	JMP bar_btmright_four
bar_btmright_two
	CMP #$14
	BCC bar_btmright_three
	LDA #$92
	STA oam_page+1,X
	JMP bar_btmright_four
bar_btmright_three
	LDA #$93
	STA oam_page+1,X
bar_btmright_four

	; set top-right corner
	INX
	INX
	INX
	INX
	LDA #$A8 ; y-value
	STA oam_page+0,X
	LDA #$EC ; x-value
	STA oam_page+3,X
	LDA #$00
	STA oam_page+2,X
	LDA char_fly_cnt ; counter
	CMP #$6C
	BCC bar_topright_one
	LDA #$82
	STA oam_page+1,X
	JMP bar_topright_four
bar_topright_one	
	CMP #$38
	BCC bar_topright_two
	LDA #$83
	STA oam_page+1,X
	JMP bar_topright_four
bar_topright_two
	CMP #$14
	BCC bar_topright_three
	LDA #$92
	STA oam_page+1,X
	JMP bar_topright_four
bar_topright_three
	LDA #$93
	STA oam_page+1,X
bar_topright_four

	PLA
	TAX
	RTS
	

; draw animated cloud
cloud
	TXA
	PHA
	; decrement cloud timer
	LDA cloud_val
	SEC
	SBC #$10 ; cloud speed
	STA cloud_val
	BCS cloud_skip
	LDA #$00
	STA cloud_val

	; remove cloud sprites
	LDX #$C0
	LDA #$EF
	STA oam_page+0,X
	STA oam_page+4,X
	STA oam_page+8,X
	STA oam_page+12,X

	PLA
	TAX
	RTS

cloud_skip
	; draw cloud sprites
	LDX #$C0

	LDA cloud_y
	SEC
	SBC #$08
	STA oam_page+0,X
	LDA cloud_val
	LSR A
	LSR A
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC #$84
	STA oam_page+1,X
	LDA #$03
	STA oam_page+2,X
	LDA cloud_x
	STA oam_page+3,X
	
	LDA cloud_y
	STA oam_page+4,X
	LDA cloud_val
	LSR A
	LSR A
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC #$94
	STA oam_page+5,X
	LDA #$03
	STA oam_page+6,X
	LDA cloud_x
	STA oam_page+7,X
	
	LDA cloud_y
	SEC
	SBC #$08
	STA oam_page+8,X
	LDA cloud_val
	LSR A
	LSR A
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC #$84
	STA oam_page+9,X
	LDA #$03
	ORA #$40
	STA oam_page+10,X
	LDA cloud_x
	CLC
	ADC #$08
	STA oam_page+11,X
	
	LDA cloud_y
	STA oam_page+12,X
	LDA cloud_val
	LSR A
	LSR A
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC #$94	
	STA oam_page+13,X
	LDA #$03
	ORA #$40
	STA oam_page+14,X
	LDA cloud_x
	CLC
	ADC #$08
	STA oam_page+15,X
	
	PLA
	TAX
	RTS


; level data (64 bytes each)
level_data
	; first level

	; background palettes
	.BYTE $0F,$1C,$2C,$3C ; inside
	.BYTE $0F,$09,$19,$29 ; outside
	.BYTE $0F,$19,$19,$19 ; status bar 
	.BYTE $0F,$0F,$0F,$0F ; unused

	; sprite palettes
	.BYTE $0C,$0F,$15,$30 ; character (and background)
	.BYTE $0F,$0F,$13,$33 ; enemy type one
	.BYTE $0F,$0F,$16,$36 ; enemy type two
	.BYTE $0F,$00,$10,$20 ; cloud

	; enemy dice and palettes (first half)
	.BYTE $10,$10,$10,$10
	.BYTE $10,$10,$21,$21

	; enemy dice and palettes (second half)
	.BYTE $10,$10,$10,$10
	.BYTE $24,$24,$21,$21

	; background in tile
	.BYTE $00

	; background out tile
	.BYTE $04

	; length of map, must be power of 2
	.BYTE $02

	; frequency of clocks
	.BYTE $01

	; unused
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00

	; second level

	; background palettes
	.BYTE $0F,$0A,$1A,$2A ; inside
	.BYTE $0F,$07,$17,$27 ; outside
	.BYTE $0F,$17,$17,$17 ; status bar 
	.BYTE $0F,$0F,$0F,$0F ; unused

	; sprite palettes
	.BYTE $0A,$0F,$15,$30 ; character (and background)
	.BYTE $0F,$0F,$13,$33 ; enemy type one
	.BYTE $0F,$0F,$16,$36 ; enemy type two
	.BYTE $0F,$00,$10,$20 ; cloud

	; enemy dice and palettes (first half)
	.BYTE $10,$10,$10,$10
	.BYTE $10,$10,$21,$21

	; enemy dice and palettes (second half)
	.BYTE $10,$10,$10,$10
	.BYTE $24,$24,$21,$21

	; background in tile
	.BYTE $08

	; background out tile
	.BYTE $0C

	; length of map, must be power of 2
	.BYTE $04

	; frequency of clocks
	.BYTE $01

	; unused
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00

	; third level

	; background palettes
	.BYTE $0F,$11,$21,$31 ; inside
	.BYTE $0F,$12,$22,$32 ; outside
	.BYTE $0F,$22,$22,$22 ; status bar 
	.BYTE $0F,$0F,$0F,$0F ; unused

	; sprite palettes
	.BYTE $01,$0F,$15,$30 ; character (and background)
	.BYTE $0F,$0F,$14,$34 ; enemy type one
	.BYTE $0F,$0F,$17,$37 ; enemy type two
	.BYTE $0F,$00,$10,$20 ; cloud

	; enemy dice and palettes (first half)
	.BYTE $10,$10,$21,$21
	.BYTE $12,$12,$23,$23

	; enemy dice and palettes (second half)
	.BYTE $24,$24,$15,$15
	.BYTE $12,$12,$23,$23

	; background in tile
	.BYTE $40

	; background out tile
	.BYTE $44

	; length of map, must be power of 2
	.BYTE $08

	; frequency of clocks
	.BYTE $02

	; unused
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00

	; fourth

	; background palettes
	.BYTE $0F,$02,$02,$22 ; inside
	.BYTE $0F,$11,$21,$31 ; outside
	.BYTE $0F,$21,$21,$21 ; status bar 
	.BYTE $0F,$0F,$0F,$0F ; unused

	; sprite palettes
	.BYTE $02,$0F,$15,$30 ; character (and background)
	.BYTE $0F,$0F,$13,$33 ; enemy type one
	.BYTE $0F,$0F,$17,$37 ; enemy type two
	.BYTE $0F,$00,$10,$20 ; cloud

	; enemy dice and palettes (first half)
	.BYTE $10,$10,$21,$21
	.BYTE $12,$12,$23,$23

	; enemy dice and palettes (second half)
	.BYTE $24,$24,$15,$15
	.BYTE $12,$12,$23,$23

	; background in tile
	.BYTE $48

	; background out tile
	.BYTE $4C

	; length of map, must be power of 2
	.BYTE $10

	; frequency of clocks
	.BYTE $02

	; unused
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00
	.BYTE $00,$00,$00,$00


; opening title screen and menu
menu
	; disable rendering
	LDA #$00
	STA ppu_mask

	; set title screen background and set sprites
	JSR title
	
	; enable rendering
	LDA #$1E
	STA ppu_mask

	; set animation to zero
	LDA #$01
	STA anim_cnt
	STA anim_val

	LDA #$04
	STA bob_y
	LDA #$FF
	STA bob_dir

	; clear v-blank flag
	LDA #$00
	STA vblank_ready

menu_loop
	; wait for v-blank flag
	LDA vblank_ready
	BEQ menu_loop

	; clear v-blank flag
	LDA #$00
	STA vblank_ready

	; change palette for sparkles
	INC spkl_cnt
	LDA spkl_cnt
	AND #$03
	BNE menu_sparkle_two
	INC spkl_val
	LDA spkl_val
	AND #$07
	BNE menu_sparkle_zero
	LDA spkl_dir
	EOR #$FF
	CLC
	ADC #$01
	STA spkl_dir
menu_sparkle_zero
	LDA ppu_status
	LDA #$3F
	STA ppu_addr
	LDA #$14
	STA ppu_addr
	LDA spkl_val
	AND #$01
	BNE menu_sparkle_one
	LDA #$0F
	STA ppu_data
	LDA #$11 ; background color
	STA ppu_data
	LDA #$18
	STA ppu_data
	LDA #$28
	STA ppu_data
	BNE menu_sparkle_two
menu_sparkle_one
	LDA #$0F
	STA ppu_data
	LDA #$18
	STA ppu_data
	LDA #$28
	STA ppu_data
	LDA #$38
	STA ppu_data
menu_sparkle_two

	; change palette for title
	LDA spkl_cnt
	AND #$0F
	BNE menu_sparkle_four
	LDA ppu_status
	LDA #$3F
	STA ppu_addr
	LDA #$08
	STA ppu_addr
	LDA #$0F
	STA ppu_data
	LDA #$0F
	STA ppu_data
	LDA spkl_dir
	CMP #$01
	BNE menu_sparkle_three
	LDA spkl_val
	AND #$1C
	LSR A
	LSR A
	CLC
	ADC #$12
	STA ppu_data
	CLC
	ADC #$20
	STA ppu_data
	BNE menu_sparkle_four
menu_sparkle_three
	LDA spkl_val
	AND #$1C
	LSR A
	LSR A
	STA math_slot0
	LDA #$1A
	SEC
	SBC math_slot0
	STA ppu_data
	CLC
	ADC #$20
	STA ppu_data

menu_sparkle_four
	; update high scores
	LDA anim_cnt
	AND #$03
	ASL A
	ASL A
	ASL A
	ASL A
	STA math_slot0
	LDA menu_pos
	ASL A
	ASL A
	ASL A
	ASL A
	ASL A
	ASL A
	CLC
	ADC math_slot0
	TAX
	LDY #$00
menu_score_one
	LDA score_page,X
	STA str_array,Y
	INX
	INY
	CPY #$10
	BNE menu_score_one
	LDA #$10
	STA str_x
	LDA anim_cnt
	AND #$03
	ASL A
	CLC
	ADC #$10
	STA str_y
	JSR string
	
	; reset ppu scroll
	LDA ppu_status
	LDA #$90
	STA ppu_ctrl
	LDA #$00
	STA ppu_scroll
	LDA #$00
	STA ppu_scroll

	; trigger oam dma
	LDA #$02
	STA oam_dma

	; check for kitty has been captured
	LDA ext_y
	CMP #$FF
	BEQ menu_bobble_one
	JMP menu_move_four

menu_bobble_one
	; animate character
	DEC anim_cnt
	BEQ menu_bobble_two
	JMP menu_move_two
menu_bobble_two
	LDA #$07
	STA anim_cnt
	INC anim_val
	LDA anim_val
	AND #$01
	STA anim_val

	; animate kitty
	LDA bob_y
	CLC
	ADC bob_dir
	STA bob_y
	BEQ menu_bobble_three
	CMP #$08
	BEQ menu_bobble_four
	BNE menu_bobble_five
menu_bobble_three
	LDA #$01
	STA bob_dir
	BNE menu_bobble_five
menu_bobble_four
	LDA #$FF
	STA bob_dir
menu_bobble_five

	; move character sprites
	LDA anim_val
	ASL A
	STA math_slot0
	LDX #$10
menu_move_one
	LDA menu_pos
	ASL A
	ASL A
	ASL A
	ASL A
	CLC
	ADC #$7C
	STA math_slot1
	TXA
	AND #$08
	ADC math_slot1
	STA oam_page+0,X
	LDA oam_page+1,X
	AND #$1F
	CLC
	ADC char_skin
	AND #$FD
	CLC
	ADC math_slot0
	STA oam_page+1,X
	INX
	INX
	INX
	INX
	CPX #$20
	BNE menu_move_one

menu_move_two
	; move kitty sprites
	LDX #$40
	LDA #$00
	STA math_slot0
menu_move_three
	LDA math_slot0
	AND #$F8
	CLC
	ADC bob_y
	CLC
	ADC #$18
	STA oam_page+0,X
	LDA oam_page+3,X
	SEC
	SBC #$01
	STA oam_page+3,X
	LDA math_slot0
	CLC
	ADC #$04
	STA math_slot0
	INX
	INX
	INX
	INX
	CPX #$50
	BNE menu_move_three
	JMP menu_move_six

menu_move_four
	; keep animation count going
	DEC anim_cnt

	; remove floating kitty
	LDX #$40
	LDA #$EF
	STA oam_page+0,X
	STA oam_page+4,X
	STA oam_page+8,X
	STA oam_page+12,X

	; draw character holding kitty
	LDX #$10
	LDA char_skin
	CLC
	ADC #$0C
	STA oam_page+1,X
	CLC
	ADC #$01
	STA oam_page+5,X
	CLC
	ADC #$0F
	STA oam_page+9,X
	CLC
	ADC #$01
	STA oam_page+13,X
	LDA char_skin
	CLC
	ADC #$0E
	STA oam_page+17,X
	CLC
	ADC #$01
	STA oam_page+21,X
	CLC
	ADC #$0F
	STA oam_page+25,X
	CLC
	ADC #$01
	STA oam_page+29,X
menu_move_five
	LDA menu_pos
	ASL A
	ASL A
	ASL A
	ASL A
	STA math_slot0
	TXA
	SEC
	SBC #$10
	AND #$18
	CLC
	ADC #$76
	CLC
	ADC math_slot0
	STA math_slot0
	LDA anim_cnt
	AND #$10
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC math_slot0
	STA oam_page+0,X
	LDA #$00
	STA oam_page+2,X
	TXA
	AND #$04
	ASL A
	CLC
	ADC #$18
	STA oam_page+3,X
	INX
	INX
	INX
	INX
	CPX #$30
	BNE menu_move_five
	
menu_move_six
	; read button state
	JSR buttons

	; check for select button
	LDA button_value
	AND #$20 ; select
	BEQ menu_move_eight
	LDA char_skin
	CLC
	ADC #$20
	AND #$20
	STA char_skin
menu_move_seven
	; wait until not pressing buttons
	JSR buttons
	LDA button_value
	BNE menu_move_seven

menu_move_eight
	; check start button
	LDA button_value
	AND #$10 ; start
	BEQ menu_press_one
	JMP story

menu_press_one
	; check up button
	LDA button_value
	AND #$08 ; up
	BEQ menu_press_two
	LDA menu_wait
	BNE menu_press_two
	LDA #$01
	STA menu_wait
	LDA menu_pos
	SEC
	SBC #$01
	STA menu_pos
	BCS menu_press_two
	LDA #$00
	STA menu_pos

menu_press_two
	; check down button
	LDA button_value
	AND #$04 ; down
	BEQ menu_press_three
	LDA menu_wait
	BNE menu_press_three
	LDA menu_pos
	CMP menu_prog
	BCS menu_press_three
	LDA #$01
	STA menu_wait
	LDA menu_pos
	CLC
	ADC #$01
	STA menu_pos
	CMP #$03 ; max selections
	BCC menu_press_three
	LDA #$03
	STA menu_pos

menu_press_three
	; reset wait state when releasing all buttons
	LDA button_value
	BNE menu_press_four
	LDA #$00
	STA menu_wait

menu_press_four
	; start game on pressing A or B
	LDA button_value
	AND #$C0 ; A or B
	BNE menu_exit
	JMP menu_loop

menu_exit
	; exit
	LDA #$00
	STA button_value
	RTS


; sets title screen background and sprites
title
	; make all sprites not drawn
	LDX #$00
	LDA #$EF
title_sprites
	STA oam_page,X
	INX
	INX
	INX
	INX
	BNE title_sprites

	; background palettes
	LDA ppu_status
	LDA #$3F
	STA ppu_addr
	LDA #$00
	STA ppu_addr
	LDA #$0F
	STA ppu_data
	LDA #$00
	STA ppu_data
	LDA #$10
	STA ppu_data
	LDA #$20
	STA ppu_data
	LDA #$0F
	STA ppu_data
	LDA #$0F
	STA ppu_data
	LDA #$0F
	STA ppu_data
	LDA #$30
	STA ppu_data
	LDA #$0F
	STA ppu_data
	LDA #$0F
	STA ppu_data
	LDA #$1C
	STA ppu_data
	LDA #$3C
	STA ppu_data
	LDX #$04
title_palettes_one
	LDA #$0F
	STA ppu_data
	DEX
	BNE title_palettes_one

	; sprite palettes
	LDA ppu_status
	LDA #$3F
	STA ppu_addr
	LDA #$10
	STA ppu_addr
	LDA #$11 ; background color
	STA ppu_data
	LDA #$0F
	STA ppu_data
	LDA #$15
	STA ppu_data
	LDA #$30
	STA ppu_data
	LDA #$0F
	STA ppu_data
	LDA #$18
	STA ppu_data
	LDA #$28
	STA ppu_data
	LDA #$38
	STA ppu_data
	LDX #$08
title_palettes_two
	LDA #$0F
	STA ppu_data
	DEX
	BNE title_palettes_two
	

	; set name table (and attribute table)
	LDY #$00
title_background_one
	LDA ppu_status
	TYA
	CLC
	ADC #$20
	STA ppu_addr
	LDA #$00
	STA ppu_addr
	LDX #$00
title_background_two
	LDA #$F0 ; blank tile in chr-rom
	STA ppu_data
	INX
	BNE title_background_two
	INY
	CPY #$04
	BNE title_background_one

	; set attribute table, separately
	LDA ppu_status
	LDA #$23
	STA ppu_addr
	LDA #$C0
	STA ppu_addr
	LDX #$20
title_attribute_one
	LDA #$55 ; second palette
	STA ppu_data
	STA ppu_data
	STA ppu_data
	STA ppu_data
	LDA #$AA ; third palette
	STA ppu_data
	STA ppu_data
	STA ppu_data
	STA ppu_data
	TXA
	SEC
	SBC #$08
	TAX
	BNE title_attribute_one
	LDX #$20
title_attribute_two
	LDA #$00 ; first palette
	STA ppu_data
	DEX
	BNE title_attribute_two

	; display title data
	LDA #$00 ; T-char
	STA title_val
	LDA #$04
	STA title_x
	LDA #$01
	STA title_y
	JSR title_char

	LDA #$10 ; O-char
	STA title_val
	LDA #$07
	STA title_x
	LDA #$01
	STA title_y
	JSR title_char

	LDA #$20 ; B-char
	STA title_val
	LDA #$0A
	STA title_x
	LDA #$01
	STA title_y
	JSR title_char

	LDA #$30 ; U-char
	STA title_val
	LDA #$0D
	STA title_x
	LDA #$01
	STA title_y
	JSR title_char

	LDA #$40 ; N-char
	STA title_val
	LDA #$12
	STA title_x
	LDA #$01
	STA title_y
	JSR title_char

	LDA #$50 ; E-char
	STA title_val
	LDA #$16
	STA title_x
	LDA #$01
	STA title_y
	JSR title_char

	LDA #$60 ; S-char
	STA title_val
	LDA #$18
	STA title_x
	LDA #$01
	STA title_y
	JSR title_char

	; character flying sprites
	LDX #$10
	LDA #$7C
	STA oam_page+0,X
	STA oam_page+4,X
	CLC
	ADC #$08
	STA oam_page+8,X
	STA oam_page+12,X
	LDA char_skin
	CLC
	ADC #$04
	STA oam_page+1,X
	CLC
	ADC #$01
	STA oam_page+5,X
	CLC
	ADC #$0F
	STA oam_page+9,X
	CLC
	ADC #$01
	STA oam_page+13,X
	LDA #$00 ; palette one
	STA oam_page+2,X
	STA oam_page+6,X
	STA oam_page+10,X
	STA oam_page+14,X
	LDA #$18
	STA oam_page+3,X
	STA oam_page+11,X
	CLC
	ADC #$08
	STA oam_page+7,X
	STA oam_page+15,X

	; floating kitty sprites
	LDX #$40
	LDA #$20
	STA oam_page+0,X
	STA oam_page+4,X
	CLC
	ADC #$08
	STA oam_page+8,X
	STA oam_page+12,X
	LDA #$6F
	STA oam_page+1,X
	LDA #$6E
	STA oam_page+5,X
	LDA #$7F
	STA oam_page+9,X
	LDA #$7E
	STA oam_page+13,X
	LDA #$40 ; palette one
	STA oam_page+2,X
	STA oam_page+6,X
	STA oam_page+10,X
	STA oam_page+14,X
	LDA #$F0
	STA oam_page+3,X
	STA oam_page+11,X
	LDA #$F8
	STA oam_page+7,X
	STA oam_page+15,X

	; sparkle sprites
	LDX #$80
	LDA #$10
	STA oam_page+0,X
	LDA #$9A
	STA oam_page+1,X
	LDA #$01 ; palette two
	STA oam_page+2,X
	LDA #$40
	STA oam_page+3,X
	LDA #$0C
	STA oam_page+4,X
	LDA #$9B
	STA oam_page+5,X
	LDA #$41 ; palette two
	STA oam_page+6,X
	LDA #$A0
	STA oam_page+7,X
	LDA #$38
	STA oam_page+8,X
	LDA #$9A
	STA oam_page+9,X
	LDA #$41 ; palette two
	STA oam_page+10,X
	LDA #$E0
	STA oam_page+11,X
	LDA #$30
	STA oam_page+12,X
	LDA #$9B
	STA oam_page+13,X
	LDA #$41 ; palette_two
	STA oam_page+14,X
	LDA #$14
	STA oam_page+15,X
	LDA #$34
	STA oam_page+16,X
	LDA #$9B
	STA oam_page+17,X
	LDA #$01 ; palette_two
	STA oam_page+18,X
	LDA #$80
	STA oam_page+19,X

	; level select strings
	LDA #$06
	STA str_x
	LDA #$10
	STA str_y
	LDA #$00
	STA math_slot0
	LDX #$00
	LDY #$00
title_string_one
	LDA string_data,X
	STA str_array,Y
	INX
	INY
	CPX #$10
	BNE title_string_one
	JSR string
	LDY #$00
	LDA str_y
	CLC
	ADC #$02
	STA str_y
	INC math_slot0
	LDA math_slot0
	ASL A
	ASL A
	ASL A
	TAX
	LDA menu_prog
	CLC
	ADC #$01
	CMP math_slot0
	BNE title_string_one
	
	; reset ppu scroll
	LDA ppu_status
	LDA #$90
	STA ppu_ctrl
	LDA #$00
	STA ppu_scroll
	LDA #$00
	STA ppu_scroll

	; trigger oam dma
	LDA #$02
	STA oam_dma

	; set sparkle variables
	LDA #$08
	STA spkl_cnt
	LDA #$08
	STA spkl_val
	LDA #$01
	STA spkl_dir

	RTS

; displays one large character
title_char
	LDA title_x
	TAY
	LDX title_val
title_display_one
	LDA ppu_status
	LDA title_y
	CLC
	ADC #$20
	STA ppu_addr
	TYA
	STA ppu_addr
title_display_two
	LDA title_data,X
	CLC
	ADC #$B0 ; where it's located on chr-rom
	STA ppu_data
	INX
	TXA
	AND #$03
	BNE title_display_two
	TYA
	CLC
	ADC #$20
	TAY
	SEC
	SBC title_x
	CMP #$80
	BNE title_display_one
	RTS

title_data
	; T-char
	.BYTE $02,$0A,$02,$00
	.BYTE $00,$01,$00,$00
	.BYTE $00,$01,$00,$00
	.BYTE $00,$01,$00,$00

	; O-char
	.BYTE $00,$00,$00,$00
	.BYTE $04,$02,$03,$00
	.BYTE $01,$00,$01,$00
	.BYTE $05,$02,$06,$00

	; B-char
	.BYTE $01,$00,$00,$00
	.BYTE $07,$02,$03,$00
	.BYTE $01,$00,$01,$00
	.BYTE $05,$02,$06,$00

	; U-char
	.BYTE $00,$00,$00,$00
	.BYTE $01,$00,$01,$00
	.BYTE $01,$00,$01,$00
	.BYTE $05,$02,$06,$00

	; N-char
	.BYTE $00,$00,$00,$00
	.BYTE $04,$0B,$00,$01
	.BYTE $01,$0D,$0B,$01
	.BYTE $01,$00,$0D,$06

	; E-char
	.BYTE $00,$00,$00,$00
	.BYTE $04,$02,$00,$00
	.BYTE $07,$02,$00,$00
	.BYTE $05,$02,$00,$00

	; S-char
	.BYTE $00,$00,$00,$00
	.BYTE $04,$02,$02,$00
	.BYTE $05,$02,$03,$00
	.BYTE $02,$02,$06,$00

; draws string to background
string
	TXA
	PHA

	; set coordinates
	LDA ppu_status
	LDA str_y
	LSR A
	LSR A
	LSR A
	CLC
	ADC #$20
	STA ppu_addr
	LDA str_y
	ASL A
	ASL A
	ASL A
	ASL A
	ASL A
	CLC
	ADC str_x
	STA ppu_addr
	
	; print each letter in string
	LDX #$00
string_sub_one
	LDA str_array,X
	CMP #$40 ; anything above 64 exits
	BCS string_sub_two
	CLC
	ADC #$80 ; start of characters
	STA ppu_data
	INX
	CPX #$10
	BNE string_sub_one

string_sub_two
	; exit
	PLA
	TAX
	RTS

string_data
	; RIVER
	.BYTE $1B,$12,$1F,$0E
	.BYTE $1B,$80,$80,$80

	; FOREST
	.BYTE $0F,$18,$1B,$0E
	.BYTE $1C,$1D,$80,$80

	; SNOWY
	.BYTE $1C,$17,$18,$20
	.BYTE $22,$80,$80,$80

	; CLOUDS
	.BYTE $0C,$15,$18,$1E
	.BYTE $0D,$1C,$80,$80


; compute high scores
score
	TXA
	PHA

	; get location of score data
	LDA menu_pos
	ASL A
	ASL A
	ASL A
	ASL A
	ASL A
	ASL A
	PHA
	
	; transfer previous scores downward
	; needs to only happen if there is a better score
	AND #$C0
	STA math_slot0
	DEC math_slot0
	CLC
	ADC #$2F
	TAX
score_shift_one
	LDA score_page+0,X
	STA score_page+16,X
	DEX
	CPX math_slot0
	BNE score_shift_one

	; grade
	PLA
	TAX
	LDA #$27 ; this needs computation
	STA score_page+0,X

	; space
	LDA #$30
	STA score_page+1,X

	; find score percentage
	TXA
	PHA
	LDA #$00
	STA math_slot1
	LDA pts_hit
	STA math_slot0
	LDX #$63 ; hundred minus one
score_per_one
	CLC
	ADC math_slot0
	BCC score_per_two
	INC math_slot1
score_per_two
	DEX
	BNE score_per_one
	STA math_slot0
	INC math_slot1 ; makes math easier later
	LDA pts_miss
	PHA
	LDA pts_hit
	CLC
	ADC pts_miss
	STA pts_miss
	LDA math_slot0
	LDX #$00
score_per_three
	SEC
	SBC pts_miss
	BCS score_per_four
	DEC math_slot1
	BEQ score_per_five
score_per_four
	INX
	BNE score_per_three
score_per_five
	PLA
	STA pts_miss
	STX dec_val
	PLA
	TAX

	; display score
	JSR decimal
	LDA dec_array+1
	STA score_page+2,X
	LDA dec_array+2
	STA score_page+3,X
	LDA dec_array+3
	STA score_page+4,X

	; percentage
	LDA #$2B
	STA score_page+5,X

	; space
	LDA #$30
	STA score_page+6,X

	; seconds
	LDA time_high
	STA dec_val
	JSR decimal
	LDA dec_array+1
	STA score_page+7,X
	LDA dec_array+2
	STA score_page+8,X
	LDA dec_array+3
	STA score_page+9,X

	; colon
	LDA #$28
	STA score_page+10,X

	; milliseconds
	LDA time_low
	STA dec_val
	JSR decimal
	LDA dec_array+2
	STA score_page+11,X
	LDA dec_array+3
	STA score_page+12,X

	; spaces
	LDA #$30
	STA score_page+13,X
	STA score_page+14,X

	; end of string
	LDA #$80
	STA score_page+15,X
	
	PLA
	TAX
	RTS

; converts value into separate digits of base 10
decimal
	TXA
	PHA

	LDA #$00 ; always zero
	STA dec_array+0 ; thousands position

	LDA dec_val
	LDX #$00
decimal_sub_one
	SEC
	SBC #$64 ; hundred
	BCC decimal_sub_two
	INX
	BNE decimal_sub_one
decimal_sub_two
	CLC
	ADC #$64
	STX dec_array+1 ; hundreds position
	LDX #$00
decimal_sub_three
	SEC
	SBC #$0A ; ten
	BCC decimal_sub_four
	INX
	BNE decimal_sub_three
decimal_sub_four
	CLC
	ADC #$0A
	STX dec_array+2 ; tens position
	STA dec_array+3 ; ones position

	PLA
	TAX
	RTS


; story scene
scene
	; clear the screen
	JSR clear

	; setup background palette
	LDA ppu_status
	LDA #$3F
	STA ppu_addr
	LDA #$00
	STA ppu_addr
	LDA #$0F
	STA ppu_data
	STA ppu_data
	STA ppu_data
	LDA #$30
	STA ppu_data
	
	; setup sprite palette
	LDA ppu_status
	LDA #$3F
	STA ppu_addr
	LDA #$10
	STA ppu_addr
	LDA #$11 ; background color
	STA ppu_data
	LDA #$0F
	STA ppu_data
	LDA #$15
	STA ppu_data
	LDA #$30
	STA ppu_data

	; draw text
	LDA #$0A
	STA str_x
	LDA #$06
	STA str_y
	LDY #$00
	JSR scene_string
	
	LDA #$09
	STA str_x
	LDA #$08
	STA str_y
	LDY #$10
	JSR scene_string

	LDA #$0B
	STA str_x
	LDA #$0C
	STA str_y
	LDY #$20
	JSR scene_string

	LDA #$0A
	STA str_x
	LDA #$0E
	STA str_y
	LDY #$30
	JSR scene_string

scene_sprites
	; character sprites
	LDX #$10
	LDA #$B0
	STA oam_page+0,X
	STA oam_page+4,X
	CLC
	ADC #$08
	STA oam_page+8,X
	STA oam_page+12,X
	LDA char_skin
	CLC
	ADC #$0A
	STA oam_page+1,X
	CLC
	ADC #$01
	STA oam_page+5,X
	CLC
	ADC #$0F
	STA oam_page+9,X
	CLC
	ADC #$01
	STA oam_page+13,X
	LDA #$00
	STA oam_page+2,X
	STA oam_page+6,X
	STA oam_page+10,X
	STA oam_page+14,X
	LDA #$60
	STA oam_page+3,X
	STA oam_page+11,X
	CLC
	ADC #$08
	STA oam_page+7,X
	STA oam_page+15,X	

	; kitty sprites
	LDX #$40
	LDA anim_val
	AND #$02
	CLC
	ADC #$90
	STA oam_page+0,X
	STA oam_page+4,X
	CLC
	ADC #$08
	STA oam_page+8,X
	STA oam_page+12,X
	LDA #$6E
	STA oam_page+1,X
	CLC
	ADC #$01
	STA oam_page+5,X
	CLC
	ADC #$0F
	STA oam_page+9,X
	CLC
	ADC #$01
	STA oam_page+13,X
	LDA #$00
	STA oam_page+2,X
	STA oam_page+6,X
	STA oam_page+10,X
	STA oam_page+14,X
	LDA #$90
	STA oam_page+3,X
	STA oam_page+11,X
	CLC
	ADC #$08
	STA oam_page+7,X
	STA oam_page+15,X	

	; reset ppu scroll
	LDA ppu_status
	LDA #$90
	STA ppu_ctrl
	LDA #$00
	STA ppu_scroll
	LDA #$00
	STA ppu_scroll

	; trigger oam dma
	LDA #$02
	STA oam_dma

	; enable rendering
	LDA #$1E
	STA ppu_mask

	; clear v-blank flag
	LDA #$00
	STA vblank_ready

scene_loop
	; wait for v-blank flag
	LDA vblank_ready
	BEQ scene_loop

	; clear v-blank flag
	LDA #$00
	STA vblank_ready

	; increment animation counter
	INC anim_cnt
	LDA anim_cnt
	CMP #$07
	BCC scene_next
	LDA #$00
	STA anim_cnt
	INC anim_val
	JMP scene_sprites

scene_next
	; reset ppu scroll
	LDA ppu_status
	LDA #$90
	STA ppu_ctrl
	LDA #$00
	STA ppu_scroll
	LDA #$00
	STA ppu_scroll

	; trigger oam dma
	LDA #$02
	STA oam_dma
	
	; check for button press
	JSR buttons

	; check for select button
	LDA button_value
	AND #$20 ; select
	BEQ scene_button_two
	LDA char_skin
	CLC
	ADC #$20
	AND #$20
	STA char_skin

scene_button_one
	; wait until nothing is pressed
	JSR buttons
	LDA button_value
	BNE scene_button_one
	JMP scene_sprites

scene_button_two
	; check for A or B button
	LDA button_value
	AND #$C0 ; A or B button
	BEQ scene_loop

	; clear buttons
	LDA #$00
	STA button_value

	RTS

; small sub-routine
scene_string
	LDX #$00
scene_string_sub
	LDA scene_data,Y
	STA str_array,X
	INY
	INX
	CPX #$10
	BNE scene_string_sub
	JSR string
	TYA
	CLC
	ADC #$10
	RTS

scene_data
	; YOUR KITTY
	.BYTE $22,$18,$1E,$1B
	.BYTE $30,$14,$12,$1D
	.BYTE $1D,$22,$80,$80
	.BYTE $80,$80,$80,$80

	; FLOATED AWAY!
	.BYTE $0F,$15,$18,$0A
	.BYTE $1D,$0E,$0D,$30
	.BYTE $0A,$20,$0A,$22
	.BYTE $26,$80,$80,$80

	; GET YOUR
	.BYTE $10,$0E,$1D,$30
	.BYTE $22,$18,$1E,$1B
	.BYTE $80,$80,$80,$80
	.BYTE $80,$80,$80,$80

	; KITTY BACK!
	.BYTE $14,$12,$1D,$1D
	.BYTE $22,$30,$0B,$0A
	.BYTE $0C,$14,$26,$80
	.BYTE $80,$80,$80,$80

; wipe effect on whole screen
wipe
	; check wipe tile
	LDA wipe_tile
	CMP #$FF
	BEQ wipe_check_one	
	LDA #$0F
	STA wipe_pal+0
	LDA #$11
	STA wipe_pal+1
	LDA #$21
	STA wipe_pal+2
	LDA #$31
	STA wipe_pal+3
	LDA #$4C ; actual tile
	STA wipe_tile
	BNE wipe_check_two

wipe_check_one
	; set level variables
	LDA menu_pos
	ASL A
	ASL A
	ASL A
	ASL A
	ASL A
	ASL A
	TAX
	LDA level_data+4,X ; outside palette
	STA wipe_pal+0
	LDA level_data+5,X
	STA wipe_pal+1
	LDA level_data+6,X
	STA wipe_pal+2
	LDA level_data+7,X
	STA wipe_pal+3
	LDA level_data+49,X ; outside tiles
	STA wipe_tile

wipe_check_two
	; clear v-blank flag
	LDA #$00
	STA vblank_ready

wipe_wait
	; wait for v-blank flag
	LDA vblank_ready
	BEQ wipe_wait

	; set last palette
	LDA ppu_status
	LDA #$3F
	STA ppu_addr
	LDA #$0C
	STA ppu_addr
	LDA wipe_pal+0
	STA ppu_data
	LDA wipe_pal+1
	STA ppu_data
	LDA wipe_pal+2
	STA ppu_data
	LDA wipe_pal+3
	STA ppu_data

	; reset ppu scroll
	LDA ppu_status
	LDA #$90
	STA ppu_ctrl
	LDA #$00
	STA ppu_scroll
	LDA #$00
	STA ppu_scroll

	; trigger oam dma
	LDA #$02
	STA oam_dma

	LDX #$00
wipe_sprites
	LDA oam_page+0,X
	CMP math_slot0

	; set name table counters to zero
	LDA #$20
	STA wipe_high
	LDA #$00
	STA wipe_low

	; clear v-blank flag
	LDA #$00
	STA vblank_ready

wipe_loop
	; wait for v-blank flag
	LDA vblank_ready
	BEQ wipe_loop

	; clear v-blank flag
	LDA #$00
	STA vblank_ready
	
	; find y-coordinate
	LDA wipe_low
	LSR A
	LSR A
	STA math_slot0
	LDA wipe_high
	SEC
	SBC #$20
	ASL A
	ASL A
	ASL A
	ASL A
	ASL A
	ASL A
	CLC
	ADC math_slot0

	; push y-coordinate
	PHA
	
	; shift down
	SEC
	SBC #$08
	LSR A
	LSR A
	CLC
	ADC #$C0
	BCS wipe_skip
	CMP #$F8
	BCS wipe_skip
	TAX

	; start drawing on attribute table
	LDA ppu_status
	LDA #$23
	STA ppu_addr
	STX ppu_addr
	LDX #$08
wipe_black
	LDA #$FF ; last palette
	STA ppu_data
	DEX
	BNE wipe_black

wipe_skip
	; start drawing on name table
	LDA ppu_status
	LDA wipe_high
	STA ppu_addr
	LDA wipe_low
	STA ppu_addr

	; find specific block
	LDA wipe_low
	AND #$60
	LSR A
	CLC
	ADC wipe_tile ; block to use for wipe

	; push for later
	PHA
	TAY
	
	; draw 4 tiles
	LDX #$04
wipe_blank_one
	STY ppu_data
	INY
	DEX
	BNE wipe_blank_one

	; pull same value
	PLA
	TAY
	
	; draw another 4 tiles
	LDX #$04
wipe_blank_two
	STY ppu_data
	INY
	DEX
	BNE wipe_blank_two

	; reset ppu scroll
	LDA ppu_status
	LDA #$00
	STA ppu_scroll
	LDA #$00
	STA ppu_scroll

	; trigger oam dma
	LDA #$02
	STA oam_dma

	; pull y-coordinate
	PLA
	CLC
	ADC #$02
	STA math_slot0

	; remove sprites above y-coordinate
	LDX #$00
wipe_sprites_one
	LDA oam_page+0,X
	CMP math_slot0
	BCS wipe_sprites_two	
	LDA #$EF
	STA oam_page+0,X
wipe_sprites_two
	INX
	INX
	INX
	INX
	BNE wipe_sprites_one

	; check to see if done with name table
	LDA wipe_low
	CLC
	ADC #$08
	STA wipe_low
	BCS wipe_check
	CMP #$C0
	BNE wipe_jump
	LDA wipe_high
	CMP #$23
	BNE wipe_jump
	RTS ; exit
wipe_check
	INC wipe_high
wipe_jump
	JMP wipe_loop


; interrupts

nmi
	INC vblank_ready
	RTI
	
irq
	RTI

; vectors

	.ORG $FFFA
	.WORD nmi
	.WORD reset
	.WORD irq


