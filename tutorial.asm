.include "constants.inc"
.include "header.inc"

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00    ; 
  STA OAMADDR ; Tell the PPU to prepare the transfer 
  LDA #$02    ; Load $02 into the accumulator
  STA OAMDMA  ; Tell the PPU to transfer 256 bytes from $0200 - $02FF (High byte is the the number loaded just before)
  LDA #$00
  STA $2005   ; Set X scroll to 0
  STA $2005   ; Set Y scroll to 0
  RTI 
.endproc

.import reset_handler

.export main
.proc main
  LDX PPUSTATUS   ; Read status, side effect : make next byte an high byte
  LDX #$3f        ; Load high byte
  STX PPUADDR     ; 
  LDX #$00        ; 
  STX PPUADDR     ; Store $3F00
  load_palettes:
    LDA palettes, X   ; Load palette value[x]
;   STA PPUADDR       ; Store it at PPUADDR (First color of the first palette)
    STA PPUDATA       ; Write it to PPUDATA (PPUDATA increase address by 1 for every write to it)
;   LDA #$0C          ; Load color $0C in accumulator
;   STA PPUDATA       ; Write it to PPUDATA (PPUDATA increase address by 1 for every write to it)
    INX               ; 
    CPX #$20          ; 
    BNE load_palettes ; Keep looping until we've wrote all the palette to PPUDATA
  ; Write sprite data
  LDX #$00        ; 
  load_sprites:
    LDA sprites, X   ; Load sprite_infos[x] into accumulator (sprites_infos = Y coord, Tile number, Attribute, X coord)
    STA $0200, X     ; Store it to RAM
    INX              ; 
    CPX #$20         ; Keep looping until we've wrote all sprite_infos
    BNE load_sprites ; 
  ; write nametables
  ; ---------------------BIG STARS--------------------------------
    LDA PPUSTATUS
    LDA #$00         ; Address high byte
    STA PPUADDR      
    LDA #$6B         ; Address low byte
    STA PPUADDR
    LDX $2F          ; Big star tile
    STX PPUDATA
  ; ---------------------BIG STARS END----------------------------

  ; ---------------------SMALL STARS------------------------------

  ; ---------------------SMALL STARS END--------------------------

  ; Attribute table
  LDA PPUSTATUS
  LDA #$03
  STA PPUADDR
  LDA #$C2
  STA PPUADDR
  LDA #%11000000 ; Bottom right, palette 3
  STA PPUDATA
vblankwait:
  BIT PPUSTATUS   ; ??
  BPL vblankwait

  LDA #%10010000  ; Turn on NMI, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; Turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.segment "VECTORS"
  .addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
  palettes:
    .byte $0f, $12, $23, $27
    .byte $0f, $2b, $3c, $39
    .byte $0f, $0c, $07, $13
    .byte $0f, $19, $09, $29

    .byte $0f, $2d, $10, $15
    .byte $0f, $19, $09, $29
    .byte $0f, $19, $09, $29
    .byte $0f, $19, $09, $29
  ; Y, tile number, attribute, x
  ; Attributes-------------
  ; Bit 7 : Vertical flip
  ; Bit 6 : Horizontal flip
  ; Bit 5 : Priority
  ; Bit 4-2 : Nothing
  ; Bit 1-0 : Palette
  sprites:                   ; 
    .byte $70, $05, $00, $80 ; 
    .byte $70, $06, $00, $88 ; 
    .byte $78, $07, $00, $80 ; 
    .byte $78, $08, $00, $88 ; 
.segment "CHR"
.incbin "graphics.chr"