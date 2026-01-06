.global snake_init
.global snake_loop

.lcomm pending_dir,1
.lcomm snake_dir,1
.lcomm tick_counter,1
.lcomm snake_len,1

.lcomm snake_x,32
.lcomm snake_y,32
.lcomm food_x,1
.lcomm food_y,1
.lcomm rng_seed,1
.lcomm game_over,1

.equ GRID_W,16
.equ GRID_H,12
.equ TICK_THRESHOLD, 3

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

    ldi r16,7
    sts rng_seed,r16

    rcall spawn_food

    clr r16
    sts tick_counter,r16
    sts game_over,r16
    ret

snake_loop:
    mov r16,r24
    rcall read_input
    rcall tick_logic
    ret

read_input:
    cpi r16,0
    breq ri_done
    
    lds r18,snake_dir

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
    cpi r18,2
    breq ri_done
    ldi r17,0
    sts pending_dir,r17
    ret

try_right:
    cpi r18,3
    breq ri_done
    ldi r17,1
    sts pending_dir,r17
    ret

try_down:
    cpi r18,0
    breq ri_done
    ldi r17,2
    sts pending_dir,r17
    ret

try_left:
    cpi r18,1
    breq ri_done
    ldi r17,3
    sts pending_dir,r17
    ret

ri_done:
    ret

tick_logic:
    lds r18,tick_counter
    inc r18
    sts tick_counter,r18

    cpi r18,TICK_THRESHOLD
    brlo tl_done
    rjmp do_tick

tl_done:
    ret

do_tick:
    lds r16,game_over
    cpi r16,1
    brne dt_continue
    rjmp send_state

dt_continue:
    clr r18
    sts tick_counter,r18

    lds r19,pending_dir
    sts snake_dir,r19

    rcall move_snake
    rcall wrap_head
    rcall self_collision_check
    rcall food_check
    rjmp send_state


move_snake:
    lds r20,snake_len
    cpi r20,1
    breq ms_move_head

    dec r20
    mov r21,r20

ms_shift_loop:
    cpi r21,0
    breq ms_move_head

    ldi XL,lo8(snake_x)
    ldi XH,hi8(snake_x)
    clr r1
    add XL,r21
    adc XH,r1
    mov r22,r21
    dec r22
    ldi YL,lo8(snake_x)
    ldi YH,hi8(snake_x)
    add YL,r22
    adc YH,r1
    ld r16,Y
    st X,r16

    ldi XL,lo8(snake_y)
    ldi XH,hi8(snake_y)
    clr r1
    add XL,r21
    adc XH,r1
    ldi YL,lo8(snake_y)
    ldi YH,hi8(snake_y)
    add YL,r22
    adc YH,r1
    ld r16,Y
    st X,r16

    dec r21
    rjmp ms_shift_loop

ms_move_head:
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

wrap_head:
    lds r16,snake_x
    cpi r16,0x80
    brsh wx_underflow
    cpi r16,GRID_W
    brlo wy_check
    clr r16
    sts snake_x,r16
    rjmp wy_check
    
wx_underflow:
    ldi r16,GRID_W-1
    sts snake_x,r16

wy_check:
    lds r16,snake_y
    cpi r16,0x80
    brsh wy_underflow
    cpi r16,GRID_H
    brlo wy_ok
    clr r16
    sts snake_y,r16
    ret
    
wy_underflow:
    ldi r16,GRID_H-1
    sts snake_y,r16
wy_ok:
    ret

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
    cpi r16,32
    breq fc_spawn

    dec r16
    ldi XL,lo8(snake_x)
    ldi XH,hi8(snake_x)
    clr r1
    add XL,r16
    adc XH,r1
    ld r17,X
    inc r16
    ldi XL,lo8(snake_x)
    ldi XH,hi8(snake_x)
    clr r1
    add XL,r16
    adc XH,r1
    st X,r17

    dec r16
    ldi XL,lo8(snake_y)
    ldi XH,hi8(snake_y)
    clr r1
    add XL,r16
    adc XH,r1
    ld r17,X
    inc r16
    ldi XL,lo8(snake_y)
    ldi XH,hi8(snake_y)
    clr r1
    add XL,r16
    adc XH,r1
    st X,r17

    sts snake_len,r16

fc_spawn:
    rcall spawn_food

fc_done:
    ret

spawn_food:
    lds r16,rng_seed
    ldi r17,5
    mul r16,r17
    mov r16,r0
    subi r16,-7
    sts rng_seed,r16

    mov r17,r16
    andi r17,0x0F
    sts food_x,r17

    ldi r17,3
    mul r16,r17
    mov r16,r0
    subi r16,-11
    sts rng_seed,r16

    ldi r17,GRID_H
sf_mod_loop:
    cpi r16,GRID_H
    brlo sf_done
    sub r16,r17
    rjmp sf_mod_loop

sf_done:
    sts food_y,r16
    ret

self_collision_check:
    lds r20,snake_len
    cpi r20,1
    breq scc_done

    ldi r21,1

scc_loop:
    cp r21,r20
    breq scc_done

    ldi XL,lo8(snake_x)
    ldi XH,hi8(snake_x)
    clr r1
    add XL,r21
    adc XH,r1
    ld r16,X
    lds r17,snake_x
    cp r16,r17
    brne scc_next

    ldi XL,lo8(snake_y)
    ldi XH,hi8(snake_y)
    clr r1
    add XL,r21
    adc XH,r1
    ld r16,X
    lds r17,snake_y
    cp r16,r17
    brne scc_next

    ldi r16,1
    sts game_over,r16
    ret

scc_next:
    inc r21
    rjmp scc_loop

scc_done:
    ret

send_state:
    lds r16,game_over
    cpi r16,1
    brne send_normal
    rjmp send_game_over

send_normal:
    ldi r23,'S'
    rcall tx
    ldi r23,':'
    rcall tx

    clr r21
    lds r20,snake_len

ss_loop:
    cp r21,r20
    brne ss_continue
    rjmp ss_food

ss_continue:
    ldi XL,lo8(snake_x)
    ldi XH,hi8(snake_x)
    clr r1
    add XL,r21
    adc XH,r1
    ld r16,X
    
    mov r23,r16
    rcall send_digit
    
    ldi r23,','
    rcall tx

    ldi XL,lo8(snake_y)
    ldi XH,hi8(snake_y)
    clr r1
    add XL,r21
    adc XH,r1
    ld r16,X
    
    mov r23,r16
    rcall send_digit

    ldi r23,';'
    rcall tx

    inc r21
    rjmp ss_loop

ss_food:
    ldi r23,'F'
    rcall tx
    ldi r23,':'
    rcall tx
    
    lds r23,food_x
    rcall send_digit
    
    ldi r23,','
    rcall tx
    
    lds r23,food_y
    rcall send_digit
    
    ldi r23,';'
    rcall tx

    ldi r23,10
    rcall tx
    ret

send_game_over:
    ldi r23,'G'
    rcall tx
    ldi r23,'O'
    rcall tx
    ldi r23,';'
    rcall tx
    ldi r23,10
    rcall tx
    ret

send_digit:
    cpi r23,10
    brlo sd_single
    
    mov r24,r23
    ldi r25,10
    clr r26
sd_div:
    cp r24,r25
    brlo sd_print_tens
    sub r24,r25
    inc r26
    rjmp sd_div
    
sd_print_tens:
    mov r23,r26
    subi r23,-48
    rcall tx
    mov r23,r24
    subi r23,-48
    rcall tx
    ret

sd_single:
    subi r23,-48
    rcall tx
    ret

tx:
tx_wait:
    lds r22,0x00C0
    sbrs r22,5
    rjmp tx_wait
    sts 0x00C6,r23
    ret
