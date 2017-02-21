;
; BIP/OS
; Author: Hendrig Wernner M. S. Gon�alves
;

.text
	; Registradores tempor�rios
	tmp0                 : .word 0x5FF
	tmp1                 : .word 0x5FE
	tmp2                 : .word 0x5FD
	tmp3                 : .word 0x5FC
	tmp4                 : .word 0x5FB
	arg1                 : .word 0x5FA
	arg2                 : .word 0x5F9
	arg3                 : .word 0x5F8
	arg4                 : .word 0x5F7
	arg5                 : .word 0x5F6
	result1              : .word 0x5F5
	result2              : .word 0x5F4
	
	; Endere�os auxiliares
	lst_pc_value         : .word 0x5F3
	lst_status_value     : .word 0x5F2
	lst_acc_value        : .word 0x5F1
	lst_indr_value       : .word 0x5F0
	
	; Endere�os reservados da arquitetura do uBIP
	port0_dir_addr       : .word 0x400
	port0_data_addr      : .word 0x401
	port1_dir_addr       : .word 0x402
	port1_data_addr      : .word 0x403
	tmr0_config_addr     : .word 0x410
	tmr0_value_addr      : .word 0x411
	int_config_addr      : .word 0x420
	int_status_addr      : .word 0x421
	mcu_config_addr      : .word 0x430
	indr_addr            : .word 0x431
	status_addr          : .word 0x432
	
	; Endere�os iniciais para a estrutura
	tsk_indr_addr        : .word 0x500 ;o id ser� outra coisa...
	tsk_init_addr        : .word 0x501
	tsk_end_addr         : .word 0x502
	tsk_prd_addr         : .word 0x503
	tsk_pc_addr          : .word 0x504
	tsk_reg_status_addr  : .word 0x505
	tsk_acc_addr         : .word 0x506
	tsk_status_addr      : .word 0x507
	
	; Constantes
	prx_tsk_id      : .word 0x000
	
.data
;------------------------------------------------------
; Trecho de interrup��o
;------------------------------------------------------
	
	; Carrega os valores dos registradores para salvamento de contexto
	STO lst_acc_value
	LD indr_addr
	STO lst_indr_value
	LD status_addr
	STO lst_status_value
	
	; Verificar se a interrup��o foi gerada por rel�gio ou externamente
	LD int_status_addr
	ANDI 0x002
	; Se foi iniciada externamente, vai para o trecho de interrup��o
	BNE _INTERRUPT_
	
	; Se foi iniciada pelo rel�gio, desempilha o topo da pilha
	POP
	STO lst_pc_value
	JMP SCHEDULER
	
;------------------------------------------------------
; Fim do trecho de interrup��o
;------------------------------------------------------
	
;------------------------------------------------------
; MAIN
;------------------------------------------------------
	LD _INIT_TSK_1         ; Endere�o do in�cio da tarefa
	STO arg1               ; registrador de argumento 1
	LD _END_TSK_1          ; Endere�o do fim da tarefa
	STO arg2               ; registrador de argumento 2
	LDI TSK_1_PRIOR        ; Prioridade da tarefa 1
	STO arg3 
	CALL OS_TSK_CREATE     ; Chama o criador de tarefas
	
;------------------------------------------------------
;   Utils
;------------------------------------------------------

; Fun��o de Multiplica��o
MULT:
	LD arg4
	STO tmp
LOOP_MULT:
	LD arg5
	SUBI 0x001
	STO arg5
	LD arg4
	ADD tmp
	STO tmp
	LD arg5
	SUBI 0x001
	BNE LOOP_MULT	
	LD tmp
	STO result1
	RETURN

;------------------------------------------------------
; API
;------------------------------------------------------

; O BIP/OS possui as seguintes fun��es em sua API
; 
; - Cria��o de tarefa       (OS_TSK_CREATE)
; - Inicializa��o de tarefa (OS_TSK_START)
; - Pausa de tarefa         (OS_TSK_PAUSE)
; - Retorno de tarefa       (OS_TSK_RETURN)
; - Encerramento de tarefa  (OS_TSK_END)
; - Remo��o de tarefa       (OS_TSK_REMOVE)

; -----------------------------------------------------------------------------
; OS_TSK_CREATE
;
; Cria a tarefa na estrutura de dados mantida pelo sistema operacional
;
; -----------------------------------------------------------------------------
OS_TSK_CREATE:                 ; Criador de tarefas
	; A cria��o de tarefas � uma fun��o cr�tica, n�o podendo ser 
	; interrompida por uma interrup��o.
	LDI 0xFFE              ; Carrega o equivalente a 0b111111111110
	AND int_config
	STO int_config         ; Desabilita a chave geral de interrup��o (GIE)
	;------
	
	LD prx_tsk_id          ; Carrega o pr�ximo endere�o 
	SLL 0x4                ; Desloca o valor logicamente para a esquerda 4 vezes
	ADDI 0x700             ; Soma o resultado com o endere�o 0x700, dando o endere�o onde ficar�o os
	STO tmp0               ; argumentos da tarefa. Salva esse resultado em tmp
	
	LD arg1                ; Carrega o primeiro argumento da tarefa, in�cio da tarefa
	STO tmp0               ; Armazena o valor em 0x7X0, onde X � o id da tarefa
	
	LD tmp0
	ADDI 1                 ; Atualiza tmp0 para conter o pr�ximo endere�o de tarefa
	STO tmp0
	LD arg2                ; Carrega o segundo argumento da tarefa, fim da tarefa
	STO tmp0               ; Armazena o valor em 0x7X1, onde X � o id da tarefa
	
	LD tmp0
	ADDI 1                 ; Atualiza tmp0 para conter o pr�ximo endere�o de tarefa
	STO tmp0
	LD arg3                ; Carrega o terceiro argumento (prioridade da tarefa)
	STO tmp0	           ; Salva na estrutura a prioridade da tarefa no endere�o 0x7X2
	
	LD tmp0
	ADDI 1                 ; Atualiza tmp0 para conter o pr�ximo endere�o de tarefa
	STO tmp0
	LD arg1                ; Carrega o primeiro argumento (in�cio da tarefa)
	STO tmp0               ; Salva no endere�o 0x7X3, que cont�m o pc da tarefa
	
	;;
	;;  Adicionar rotina que preencha com 0 os pr�ximos campos.
	;;
	
	LDI 0x001              ; carrega 1
	ADD prx_tsk_id         ; e soma ao valor do registrador que cont�m o pr�ximo id
	STO prx_tsk_id         ; atualizando o pr�ximo id dispon�vel
	
	; Fim da se��o cr�tica.
	LDI 0x001              ; Carrega o equivalente a 0b000000000001
	OR int_config          
	STO int_config         ; Habilita interrup��es
	RETURN
	
; -----------------------------------------------------------------------------
; OS_TSK_START
;
; Inicia a tarefa
; Essa fun��o n�o � chamada por uma instru��o CALL, mas sim por uma instru��o 
; JMP. Ou seja, ela n�o guarda valores na pilha
;
; Argumentos: Id da tarefa a ser iniciada
; -----------------------------------------------------------------------------
OS_TASK_START:
	; In�cio da se��o cr�tica
	LDI 0xFFE              ; Carrega o equivalente a 0b111111111110
	AND int_config
	STO int_config         ; Desabilita a chave geral de interrup��o (GIE)
	
	LD arg1
	SLL 0x4
	ADDI 0x700
	STO tmp0               ; Endere�o base dos argumentos da tarefa
	
    ; Carregamento dos argumentos das tarefas
	ADDI 0x6
	STO tmp1               ; Procura o endere�o do status da tarefa
	LDI 2                  ; Carrega o valor 2
	STO tmp1               ; O status da tarefa torna-se igual a 2 (Em execu��o)
	
	LD tmp0
	ADDI 0x3               ; Carrega o endere�o no qual o pc da tarefa � armazenado
	STO tmp1
	
	; Fim da se��o cr�tica.
	LDI 0x001              ; Carrega o equivalente a 0b000000000001
	OR int_config          
	STO int_config         ; Habilita interrup��es
	
	JMP tmp1               ; Desvia para o pc inical da tarefa

; -----------------------------------------------------------------------------
; OS_TASK_PAUSE
;
; Pausa a tarefa em execu��o, salvando o contexto da mesma
; 
; Argumentos: Id da tarefa
; -----------------------------------------------------------------------------	
OS_TASK_PAUSE:
	; In�cio da se��o cr�tica
	LDI 0xFFE              ; Carrega o equivalente a 0b111111111110
	AND int_config
	STO int_config         ; Desabilita a chave geral de interrup��o (GIE)
	
	LD arg1
	SLL 0x4
	ADDI 0x700
	STO tmp0               ; Endere�o base dos argumentos da tarefa
	
	LD tmp0
	ADDI 0x3
	STO tmp0               ; Carrega o endere�o de armazenamento do valor do pc da tarefa
	LD lst_pc_value        ; Carrega o �ltimo pc em andamento
	STO tmp0               ; Salva no endere�o 0x7X3, onde X � o id da tarefa
	
	LD tmp0
	ADDI 1
	STO tmp0               ; Carrega o endere�o de armazenamento do valor do registrador status
	LD lst_status_value    ; Carrega o �ltimo valor do registrador status
	STO tmp0               ; Armazena o valor do acumulador no endere�o 0x7X4
	
	LD tmp0
	ADDI 1
	STO tmp0               ; Carrega o endere�o de armazenamento do valor do acumulador
	LD lst_acc_value       ; Carrega o �ltimo valor do acumulador da tarefa
	STO tmp0               ; Armazena o valor do acumulador no endere�o 0x7X5
	
	LD tmp0
	ADDI 1
	STO tmp0               ; Carrega o endere�o de armazenamento do valor do status da tarefa
	LDI 1                  ; Carrega o status da tarefa (1, em espera)
	STO tmp0               ; Armazena o status da tarefa no endere�o 0x7X6
	
	LD tmp0
	ADDI 1
	STO tmp0               ; Carrega o endere�o de armazenamento do valor do �ndice do vetor
	LD lst_indr_value      ; Carrega o �ndice do vetor
	STO tmp0               ; Armazena o valor do �ndice do vetor no endere�o 0x7X7
	
	; Fim da se��o cr�tica
	LDI 0x001              ; Carrega o equivalente a 0b000000000001
	OR int_config          
	STO int_config         ; Habilita interrup��es

OS_TASK_RETURN:
	LDI 0xFFE              ; Carrega o equivalente a 0b111111111110
	AND int_config
	STO int_config         ; Desabilita a chave geral de interrup��o (GIE)
	; 
	; TODO Here
	;
	LDI 0x001              ; Carrega o equivalente a 0b000000000001
	OR int_config          
	STO int_config         ; Habilita interrup��es

	
OS_TASK_END:
	LDI 0xFFE              ; Carrega o equivalente a 0b111111111110
	AND int_config
	STO int_config         ; Desabilita a chave geral de interrup��o (GIE)
	; 
	; TODO Here
	;
	LDI 0x001              ; Carrega o equivalente a 0b000000000001
	OR int_config          
	STO int_config         ; Habilita interrup��es

	
OS_TASK_REMOVE:
	LDI 0xFFE              ; Carrega o equivalente a 0b111111111110
	AND int_config
	STO int_config         ; Desabilita a chave geral de interrup��o (GIE)
	; 
	; TODO Here
	;
	LDI 0x001              ; Carrega o equivalente a 0b000000000001
	OR int_config          
	STO int_config         ; Habilita interrup��es

	
;----------------------------------------------
;    SCHEDULER
;----------------------------------------------
SCHEDULER:

;----------------------------------------------
;    PROCESS MANAGER
;----------------------------------------------
PROCESS_MANAGER:

_INTERRUPT_: