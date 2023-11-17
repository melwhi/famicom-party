.include "constants.inc"
.segment "CODE"
.import main
.export reset_handler
.proc reset_handler
    SEI
    CLD
    LDX #$00
    STX PPUCTRL
    STX PPUMASK
  vblankwait: ; Wait for a VBLANK
    BIT PPUSTATUS
    BPL vblankwait

    LDX #$00
    LDA #$FF ; Y outside screen
    clear_oam:
      STA $0200, X  ; Set each sprite y to be $FF (Ends up putting them outside the screen)
      INX           ; Skip to other sprite
      INX
      INX
      INX
      BNE clear_oam ; If we're not back at $0200, we loop

    vblankwait2:
      BIT PPUSTATUS    ; ?
      BPL vblankwait2

    JMP main
.endproc