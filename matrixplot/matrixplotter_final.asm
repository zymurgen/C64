;Plotter routine to plot pixels on a 16x16 char matrix
;this one uses sin/cos datatables to plot an animated curve



*=$4000
screen_offset   = $040a
icharhigh       = 16                     ;
icharwidth      = 16                     ;
scrwidth        = 40
chars           = $2000


tmpY            = $fd ;temp storage for y register used in plot routine


first_run       =$c6 ;on the first run, no need to clear any pixels
chrset_lo       =$c0 ;low pointer to current charset 
chrset_hi       =$c1 ;high pointer to current charset
ctr             =$c2 ;loop pointer for sinus data

prev_frame      =$c5

plotpixel_x     = $d0 ;pointer to x coordinate used by plotter subroutine
plotpixel_y     = $d1 ;pointer to y coordinate

data_ptrX       = $e0 ;high byte indirect addressed base address for sinus data
data_ptrY       = $e2 ;low byte

init_irq 
                sei
                lda #0
                sta ctr      ;set counter to zero
                sta first_run
                sta $d021
    
                lda #<chars
                sta chrset_lo
                lda #>chars
                sta chrset_hi
                jsr clear_data                         
                jsr clear_screen
                jsr ichar     ;draw char matrix
                lda #$7f      ;setup raster interupt
                sta $dc0d
                sta $dd0d
                lda #$01
                sta $d01a
                lda #$1b
                ldx #$08
                ldy #$14
                sta $d011
                stx $d016; 
 


                sty $d018
                lda #<irq
                ldx #>irq
                ldy #$f0
                sta $0314
                stx $0315
                sty $d012
                lda $dc0d
                lda $dd0d
                asl $d019
                cli
et_loop         jmp et_loop                                        

;macro for plotting pixel
defm    plot 
                lda ctr    ;load data pointer/counter
                clc     
                adc #/1    ;add with which ever pixel nr
                tay        ;transfer to y reg, to get right pos from table
                lda (data_ptrX),y;
                sta plotpixel_x
                tya
                clc
                adc ctr
                tay
                lda (data_ptrY),y;
                lsr              ;decrease y amplitude by half
                sta plotpixel_y
                jsr plotpixel
        
        endm
;macro for "deplotting" pixel same as above
defm dplot 
                lda prev_frame
                clc
                adc #/1
                tay
                lda (data_ptrX),y;
                sta plotpixel_x
                tya
                clc
                adc prev_frame
                tay
                lda (data_ptrY),y;
                lsr
                sta plotpixel_y
                jsr clearpixel
endm


irq             lda #$18      ; screen default at $0400, chars at $2000
                sta $d018     
                        
                inc $d020
                lda #<plotdtaX   ;low byte of sinus data
                sta data_ptrX    ;store in zp for indirect addressing
                lda #>plotdtaX   ;high byte of sinus
                sta data_ptrX+1
                lda #<plotdtaY   ;low byte of cosinus data
                sta data_ptrY
                lda #>plotdtaY
                sta data_ptrY+1  
                                  ;perhaps cos table is not needed
                                  ;use offset of sin table instead?
#region deplott
                dplot 0           ;clear previous frames pixels 
                dplot 7
                dplot 14
                dplot 21
                dplot 28
                dplot 35
                dplot 42
                dplot 49
                dplot 56
                dplot 63
                dplot 70
                dplot 77
                dplot 84
                dplot 91
                dplot 98
                dplot 105
                dplot 112
                dplot 119
                dplot 126
                dplot 133
                dplot 140
                dplot 147
                dplot 154
                dplot 161
                dplot 168
                dplot 175
                dplot 182
                dplot 189
                dplot 196
                dplot 203
                dplot 210
                dplot 217
                dplot 224
                dplot 231
                dplot 238
                dplot 245

#endregion



#region plotter                 ;plot pixels using macro for unrolling the loop
                plot 0
                plot 7
                plot 14
                plot 21
                plot 28
                plot 35
                plot 42
                plot 49
                plot 56
                plot 63
                plot 70
                plot 77
                plot 84
                plot 91
                plot 98
                plot 105
                plot 112
                plot 119
                plot 126
                plot 133
                plot 140
                plot 147
                plot 154
                plot 161
                plot 168
                plot 175
                plot 182
                plot 189
                plot 196
                plot 203
                plot 210
                plot 217
                plot 224
                plot 231
                plot 238
                plot 245
               
#endregion
                lda ctr         
                sta prev_frame  ;store previous frame count (for deleting)
                clc
                adc #1          
                sta ctr
  
return          dec $d020
                asl $d019
                jmp $ea81 ; return from interupt
                rts

ichar                           ;build char matrix - code from codebase64.org
                ldx            #0
initic
                txa
                ldy            #0
i2
                sta            screen_offset,y
                clc
                adc            #icharhigh
                iny
                cpy            #icharwidth
                bne            i2
                lda            i2+1
                clc
                adc            #scrwidth
                sta            i2+1
                bcc            *+5
                inc            i2+2
                inx
                cpx            #icharhigh
                bne            initic
                rts

clear_data                         ;set all chardata to 0 (clear canvas)
                                   ;only for init, too time consuming to do per frame    
                ldx            #$00
@loop           lda            #$00
                sta            $2000,x
                sta            $2100,x
                sta            $2200,x
                sta            $2300,x
                sta            $2400,x
                sta            $2500,x
                sta            $2600,x
                sta            $2700,x
                dex
                bne            @loop
                rts


clear_screen                         
                ldx            #$00
@loop           lda            #$ff
                sta            $0400,x
                sta            $0500,x
                sta            $0600,x
                sta            $0700,x
                dex
                bne            @loop
                rts

plotpixel       lda chrset_lo ;calculate which byte of the charset to plot in
                sta $fb
                                   ; ptr = (x / 8) * 128
                lda plotpixel_x ;txa
                lsr                      ; x / 8
                lsr
                lsr
                lsr                      ; * 128 (16-bit)
                ror $fb
                adc chrset_hi;adc            #>chars
                sta $fc
                                   ; mask = 2 ^ (x & 3)
                lda plotpixel_x;txa
                and #%00000111
                tax
                sty tmpY
                ldy plotpixel_y
                lda ($fb),y
                ora bitmask,x
                sta ($fb),y
                ldy tmpY
                rts

clearpixel      lda chrset_lo ;
                sta $fb
                                   ; ptr = (x / 8) * 128
                lda plotpixel_x ;txa
                lsr                      ; x / 8
                lsr
                lsr
                lsr                      ; * 128 (16-bit)
                ror $fb
                adc chrset_hi;adc            #>chars
                sta $fc
                                   ; mask = 2 ^ (x & 3)
                lda plotpixel_x;txa
                and #%00000111
                tax
                sty tmpY
                ldy plotpixel_y
                lda ($fb),y
                eor bitmask,x
                sta ($fb),y
                ldy tmpY
                rts


                ;pixel 1   2  3   4   5   6   7   8
bitmask         byte $80,$40,$20,$10,$08,$04,$02,$01



;plotdtaX byte 96
;        byte 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 94, 94, 94, 94, 93, 93
;        byte 93, 92, 92, 92, 91, 91, 90, 90, 90, 89, 89, 88, 88, 87, 87, 86
;        byte 85, 85, 84, 84, 83, 82, 82, 81, 81, 80, 79, 78, 78, 77, 76, 76
;        byte 75, 74, 73, 73, 72, 71, 70, 70, 69, 68, 67, 66, 66, 65, 64, 63
;        byte 63, 62, 61, 60, 59, 59, 58, 57, 56, 56, 55, 54, 53, 52, 52, 51
;        byte 50, 50, 49, 48, 48, 47, 46, 45, 45, 44, 44, 43, 42, 42, 41, 41
;        byte 40, 40, 39, 39, 38, 38, 37, 37, 36, 36, 35, 35, 35, 34, 34, 34
;        byte 34, 33, 33, 33, 33, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
;        byte 32, 32, 32, 32, 32, 32, 32, 32, 32, 33, 33, 33, 33, 34, 34, 34
;        byte 34, 35, 35, 35, 36, 36, 37, 37, 38, 38, 39, 39, 40, 40, 41, 41
;        byte 42, 42, 43, 44, 44, 45, 45, 46, 47, 47, 48, 49, 50, 50, 51, 52
;        byte 52, 53, 54, 55, 56, 56, 57, 58, 59, 59, 60, 61, 62, 63, 63, 64
;        byte 65, 66, 66, 67, 68, 69, 70, 70, 71, 72, 73, 73, 74, 75, 76, 76
;        byte 77, 78, 78, 79, 80, 81, 81, 82, 82, 83, 84, 84, 85, 85, 86, 87
;        byte 87, 88, 88, 89, 89, 90, 90, 90, 91, 91, 92, 92, 92, 93, 93, 93
;        byte 94, 94, 94, 94, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 96


plotdtaX byte 128
        byte 127, 127, 127, 127, 127, 127, 127, 126, 126, 126, 125, 125, 124, 124, 123, 123
        byte 122, 121, 121, 120, 119, 118, 117, 117, 116, 115, 114, 113, 112, 111, 110, 109
        byte 107, 106, 105, 104, 103, 101, 100, 99, 98, 96, 95, 93, 92, 91, 89, 88
        byte 86, 85, 83, 82, 80, 79, 77, 76, 74, 73, 71, 69, 68, 66, 65, 63
        byte 62, 60, 58, 57, 55, 54, 52, 51, 49, 48, 46, 44, 43, 41, 40, 39
        byte 37, 36, 34, 33, 32, 30, 29, 27, 26, 25, 24, 22, 21, 20, 19, 18
        byte 17, 16, 15, 14, 13, 12, 11, 10, 09, 08, 07, 07, 06, 05, 05, 04
        byte 04, 03, 03, 02, 02, 01, 01, 01, 00, 00, 00, 00, 00, 00, 00, 00
        byte 00, 00, 00, 00, 00, 00, 01, 01, 01, 02, 02, 03, 03, 04, 04, 05
        byte 05, 06, 07, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19
        byte 20, 21, 22, 24, 25, 26, 27, 29, 30, 31, 33, 34, 36, 37, 39, 40
        byte 41, 43, 44, 46, 48, 49, 51, 52, 54, 55, 57, 58, 60, 62, 63, 65
        byte 66, 68, 69, 71, 73, 74, 76, 77, 79, 80, 82, 83, 85, 86, 88, 89
        byte 91, 92, 93, 95, 96, 98, 99, 100, 101, 103, 104, 105, 106, 107, 109, 110
        byte 111, 112, 113, 114, 115, 116, 117, 117, 118, 119, 120, 121, 121, 122, 123, 123
        byte 124, 124, 125, 125, 126, 126, 126, 127, 127, 127, 127, 127, 127, 127, 128


plotdtaY byte 64, 66, 68, 71, 73, 75, 77, 79, 81, 83, 85, 87, 88, 90, 91, 92, 93
        byte 94, 95, 95, 95, 95, 95, 95, 95, 94, 94, 93, 92, 90, 89, 88, 86
        byte 84, 82, 80, 78, 76, 74, 72, 69, 67, 65, 62, 60, 58, 55, 53, 51
        byte 49, 47, 45, 43, 41, 39, 38, 37, 35, 34, 33, 33, 32, 32, 32, 32
        byte 32, 32, 32, 33, 34, 35, 36, 37, 39, 40, 42, 44, 46, 48, 50, 52
        byte 54, 56, 59, 61, 63, 66, 68, 71, 73, 75, 77, 79, 81, 83, 85, 87
        byte 88, 90, 91, 92, 93, 94, 95, 95, 95, 95, 95, 95, 95, 94, 94, 93
        byte 92, 90, 89, 88, 86, 84, 82, 80, 78, 76, 74, 72, 69, 67, 65, 62
        byte 60, 58, 55, 53, 51, 49, 47, 45, 43, 41, 39, 38, 37, 35, 34, 33
        byte 33, 32, 32, 32, 32, 32, 32, 32, 33, 34, 35, 36, 37, 39, 40, 42
        byte 44, 46, 48, 50, 52, 54, 56, 59, 61, 63, 66, 68, 71, 73, 75, 77
        byte 79, 81, 83, 85, 87, 88, 90, 91, 92, 93, 94, 95, 95, 95, 95, 95
        byte 95, 95, 94, 94, 93, 92, 90, 89, 88, 86, 84, 82, 80, 78, 76, 74
        byte 72, 69, 67, 65, 62, 60, 58, 55, 53, 51, 49, 47, 45, 43, 41, 39
        byte 38, 37, 35, 34, 33, 33, 32, 32, 32, 32, 32, 32, 32, 33, 34, 35
        byte 36, 37, 39, 40, 42, 44, 46, 48, 50, 52, 54, 56, 59, 61, 63
;plotdtaY  byte 64, 65, 67, 68, 70, 71, 73, 74, 76, 78, 79, 81, 82, 84, 85, 87, 88
;        byte 90, 91, 92, 94, 95, 97, 98, 99, 100, 102, 103, 104, 105, 107, 108, 109
;        byte 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 119, 120, 121, 121, 122, 123
;        byte 123, 124, 124, 125, 125, 126, 126, 126, 127, 127, 127, 127, 127, 127, 127, 127
;        byte 127, 127, 127, 127, 127, 127, 126, 126, 126, 125, 125, 125, 124, 124, 123, 122
;        byte 122, 121, 120, 120, 119, 118, 117, 116, 116, 115, 114, 113, 112, 111, 109, 108
;        byte 107, 106, 105, 104, 102, 101, 100, 99, 97, 96, 94, 93, 92, 90, 89, 87
;        byte 86, 84, 83, 81, 80, 78, 77, 75, 74, 72, 71, 69, 67, 66, 64, 63
;        byte 61, 60, 58, 56, 55, 53, 52, 50, 49, 47, 46, 44, 43, 41, 40, 38
;        byte 37, 35, 34, 33, 31, 30, 28, 27, 26, 25, 23, 22, 21, 20, 19, 18
;        byte 16, 15, 14, 13, 12, 11, 11, 10, 09, 08, 07, 07, 06, 05, 05, 04
;        byte 03, 03, 02, 02, 02, 01, 01, 01, 00, 00, 00, 00, 00, 00, 00, 00
;        byte 00, 00, 00, 00, 00, 00, 01, 01, 01, 02, 02, 03, 03, 04, 04, 05
;        byte 06, 06, 07, 08, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19
;        byte 20, 22, 23, 24, 25, 27, 28, 29, 30, 32, 33, 35, 36, 37, 39, 40
;        byte 42, 43, 45, 46, 48, 49, 51, 53, 54, 56, 57, 59, 60, 62, 63