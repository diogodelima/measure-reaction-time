    .equ	STACK_SIZE, 64                

	.equ	INPORT_ADDRESS, 0xFF80       

	.equ	OUTPORT_ADDRESS, 0xFFC0              

	.equ	PTC_ADDRESS,  0xFF00         

	.equ	PTC_TCR, 0                   
	.equ	PTC_TMR, 2                    
	.equ	PTC_TC,  4                    
	.equ	PTC_TIR, 6                    

	.equ	PTC_CMD_START, 0              
	.equ	PTC_CMD_STOP, 1               

	.equ	SYSCLK_FREQ, 0x0A             
             

	.section startup
	b	_start
	ldr	pc, isr_addr
_start:
	ldr	sp, tos_addr
	ldr	pc, main_addr

tos_addr:
	.word	tos
main_addr:
	.word	main
isr_addr:
	.word	isr

	.text

main:
	ldr r0, t_fim_addr_main
	mov r1, #0
	str r1, [r0, #0]
	mov r0, #0xFF
	bl outport_write ;coloca na saída o resultado e o STIMULUS a 1
	bl inport_read ;lê a entrada
	lsl r0, r0, #15
	lsr r0, r0, #15 ;coloca em R0 o valor da entrada USER
	mov r1, #1 
	cmp r0, r1
	bne main ;se a entrada USER for 0, volta ao início
	mov r0, #1
	bl outport_write ;coloca a saída STIMULUS a 1 e o resultado 0
	mov	r0, #SYSCLK_FREQ
	bl	ptc_init ;inicia o timer
	mrs r0, cpsr
	mov r1, #0x10
	orr r0, r0, r1
	msr cpsr, r0 ;liga as interrupções
empty:
	bl inport_read ;lê a entrada
	lsl r0, r0, #15
	lsr r0, r0, #15 ;coloca em R0 o valor da entrada USER
	mov r1, #1
	cmp r0, r1
	bne main
	bl inport_read ;lê a entrada
	lsl r0, r0, #8
	lsr r0, r0, #12 ;pega o valor da entrada do bit 4 ao 7
	ldr r2, t_fim_addr_main
	ldr r1, [r2, #0]
	cmp r0, r1
	bne empty ;verifica se o tempo chegou ao fim, se não chegar volta ao estado anterior
	ldr r0, count_addr_main
	mov r1, #0
	str r1, [r0, #0] ;inicializa a variável COUNT com o valor 0, para apresentar no fim como resultado
stimulus:
	mov r0, #0
	bl outport_write
	bl inport_read ;lê a entrada
	lsl r0, r0, #15
	lsr r0, r0, #15 ;coloca em R0 o valor da entrada USER
	mov r1, #0
	cmp r0, r1
	bne stimulus ;se a entrada USER estiver com 1, volta ao estado anterior
	ldr r1, count_addr_main
	ldr r0, [r1, #0]
	lsl r0, r0, #1 ;desloca o resultado 1 bit para a esquerda, por causa do bit STIMULUS
	bl outport_write
	b .

t_fim_addr_main:
	.word t_fim
	
count_addr_main:
	.word count

isr:
	push r0
	push r1
	ldr r0, PTC_ADDR
	mov r1, #0
	strb r1, [r0, #PTC_TIR]
	ldr r0, t_fim_addr
	ldr r1, [r0, #0]
	add r1, r1, #1
	str r1, [r0, #0]
	ldr r0, count_addr
	ldr r1, [r0, #0]
	add r1, r1, #1
	str r1, [r0, #0]
	pop r1
	pop r0
	movs pc, lr

t_fim_addr:
	.word t_fim

count_addr:
	.word count

inport_read:
	ldr	r1, inport_addr
	ldrb	r0, [r1, #0]
	mov	pc, lr

inport_addr:
	.word	INPORT_ADDRESS

outport_write:
	ldr	r1, outport_addr
	strb	r0, [r1, #0]
	mov	pc, lr

outport_addr:
	.word	OUTPORT_ADDRESS

ptc_start:
	ldr	r0, PTC_ADDR
	mov	r1, #PTC_CMD_START
	strb	r1, [r0, #PTC_TCR]
	mov	pc, lr

ptc_stop:
	ldr	r0, PTC_ADDR
	mov	r1, #PTC_CMD_STOP
	strb	r1, [r0, #PTC_TCR]
	mov	pc, lr

ptc_get_value:
	ldr	r1, PTC_ADDR
	ldrb	r0, [r1, #PTC_TC]
	mov	pc, lr

ptc_init:
	push lr
	push r0
	bl ptc_stop
	pop r0
	ldr r1, PTC_ADDR
	strb r0, [r1, #PTC_TMR]
	bl ptc_start
	pop pc

PTC_ADDR:
	.word	PTC_ADDRESS

; Seccao:    data
; Descricao: Guarda as variáveis globais com um valor inicial definido
;
	.data

; Seccao:    bss
; Descricao: Guarda as variáveis globais sem valor inicial definido
;
	.bss

t_fim:
	.space 2

count:
	.space 2


; Seccao:    stack
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
	.stack
	.space	STACK_SIZE
tos:
