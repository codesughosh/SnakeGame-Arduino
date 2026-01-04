.global snake_init
.global snake_loop


; =====================
; SRAM
; =====================
.lcomm pending_dir,1
.lcomm snake_dir,1
.lcomm tick_counter,1
.lcomm snake_len,1

.lcomm snake_x,32
.lcomm snake_y,32
.lcomm food_x,1
.lcomm food_y,1

.equ GRID_W,16
.equ GRID_H,12
.equ TICK_THRESHOLD, 12

; =====================
; INIT / RESET
; =====================
snake_init:
    ldi r16,1
    sts pending_dir,r16
    sts snake_dir,r16

    ldi r16,3
    sts snake_len,r16

    ldi r16,8
    sts snake_x,r16
    ldi r16,6
    sts snake_y,r16

    ldi r16,7
    sts snake_x+1,r16
    ldi r16,6
    sts snake_y+1,r16

    ldi r16,6
    sts snake_x+2,r16
    ldi r16,6
    sts snake_y+2,r16

    ldi r16,3
    sts food_x,r16
    ldi r16,3
    sts food_y,r16

    clr r16
    sts tick_counter,r16
    ret

; =====================
; MAIN LOOP
; =====================
snake_loop:
    mov r16,r24
    rcall read_input
    rcall tick_logic
    ret

; =====================
; INPUT
; =====================

read_input:
    ; r16 = input char
    lds r18, snake_dir   ; current direction

    cpi r16,'W'
    breq try_up
    cpi r16,'D'
    breq try_right
    cpi r16,'S'
    breq try_down
    cpi r16,'A'
    breq try_left
    ret

try_up:
    cpi r18,2            ; DOWN?
    breq ri_done         ; ignore reverse
    ldi r17,0
    sts pending_dir,r17
    ret

try_right:
    cpi r18,3            ; LEFT?
    breq ri_done
    ldi r17,1
    sts pending_dir,r17
    ret

try_down:
    cpi r18,0            ; UP?
    breq ri_done
    ldi r17,2
    sts pending_dir,r17
    ret

try_left:
    cpi r18,1            ; RIGHT?
    breq ri_done
    ldi r17,3
    sts pending_dir,r17
    ret

ri_done:
    ret

; =====================
; TICK
; =====================
tick_logic:
    lds r18, tick_counter
    inc r18
    sts tick_counter, r18

    cpi r18, TICK_THRESHOLD
    brsh do_tick
    rjmp send_state

do_tick:
    clr r18
    sts tick_counter, r18

    lds r19, pending_dir
    sts snake_dir, r19

    rcall move_head
    rcall wrap_head
    rcall food_check
    rcall self_collision
    rjmp send_state


; =====================
; MOVE HEAD
; =====================
move_head:
    lds r16,snake_dir
    cpi r16,0
    breq mu
    cpi r16,1
    breq mr
    cpi r16,2
    breq md
    cpi r16,3
    breq ml
    ret

mu:
    lds r17,snake_y
    dec r17
    sts snake_y,r17
    ret

mr:
    lds r17,snake_x
    inc r17
    sts snake_x,r17
    ret

md:
    lds r17,snake_y
    inc r17
    sts snake_y,r17
    ret

ml:
    lds r17,snake_x
    dec r17
    sts snake_x,r17
    ret

; =====================
; WRAP
; =====================
wrap_head:
    lds r16,snake_x
    cpi r16,GRID_W
    brlo wx_ok
    clr r16
    sts snake_x,r16
wx_ok:
    lds r16,snake_y
    cpi r16,GRID_H
    brlo wy_ok
    clr r16
    sts snake_y,r16
wy_ok:
    ret

; =====================
; FOOD CHECK (GROW ONLY)
; =====================
food_check:
    lds r16,snake_x
    lds r17,food_x
    cp r16,r17
    brne fc_done

    lds r16,snake_y
    lds r17,food_y
    cp r16,r17
    brne fc_done

    lds r16,snake_len
    inc r16
    sts snake_len,r16

fc_done:
    ret

; =====================
; SELF COLLISION (RESET)
; =====================
self_collision:
    lds r20,snake_len
    ldi r21,1
sc_loop:
    cp r21,r20
    breq sc_done

    ldi XL,lo8(snake_x)
    ldi XH,hi8(snake_x)
    add XL,r21
    ld r16,X
    lds r17,snake_x
    cp r16,r17
    brne sc_next

    ldi XL,lo8(snake_y)
    ldi XH,hi8(snake_y)
    add XL,r21
    ld r16,X
    lds r17,snake_y
    cp r16,r17
    breq sc_reset
    sc_reset:
    rjmp snake_init



sc_next:
    inc r21
    rjmp sc_loop

sc_done:
    ret

; =====================
; SERIAL OUTPUT (S: and F:)
; =====================
send_state:
    ldi r23,'S'
    rcall tx
    ldi r23,':'
    rcall tx

    lds r23,snake_x
    subi r23,-48
    rcall tx
    ldi r23,','
    rcall tx
    lds r23,snake_y
    subi r23,-48
    rcall tx
    ldi r23,';'
    rcall tx

    ldi r23,'F'
    rcall tx
    ldi r23,':'
    rcall tx
    lds r23,food_x
    subi r23,-48
    rcall tx
    ldi r23,','
    rcall tx
    lds r23,food_y
    subi r23,-48
    rcall tx
    ldi r23,';'
    rcall tx
    ret

tx:
tx_wait:
    lds r22,0x00C0
    sbrs r22,5
    rjmp tx_wait
    sts 0x00C6,r23
    ret
