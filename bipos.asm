;   _     _            __            
;  | |__ (_)_ __      / /   ___  ___ 
;  | '_ \| | '_ \    / /   / _ \/ __|
;  | |_) | | |_) |  / /   | (_) \__ \
;  |_.__/|_| .__/  /_/     \___/|___/
;          |_|                       
;  
;  
;  BIP's Operating System!
;  Copyright (C) 2013 Universidade do Vale do Itajai
;
;  Contributors:
;  Hendrig Wernner Maus Santana Gonçalves
;  Fabricio Bortoluzzi
;  Cesar Albenes Zeferino
;

.data
  # Constantes
  prx_tsk_id      : .word 0x000       # Proximo id de tarefa
  tsk_quantity    : .word 0x000       # Quantidade de tarefas
  next_tsk        : .word 0x000       # Próxima tarefa
  get_next_tsk    : .word 0x000       
  next_tsk_ind    : .word 0x000       # Índice da próxima tarefa
  current_tsk_ind : .word 0x000       # Tarefa atual
  lst_acc_value   : .word 0x000       # Endereço para armazenar o último valor do acumulador
  lst_indr_value  : .word 0x000       # Endereço para armazenar o último valor do Indr
  lst_status_value: .word 0x000       # Endereço para armazenar o último valor do Status
  lst_pc_value    : .word 0x000       # Endereço para armazenar o último valor do PC
.text
#===============================================================================
# Trecho de interrupção
# Este é o ponto para onde são desviadas as interrupções do sistema.
#===============================================================================
	
  # Carrega os valores dos registradores para salvamento de contexto
  STO $tmp0                # $tmp0 é um endereço específico
  STO $tmp0
  LD $indr                 #
  STO $tmp1                # $tmp1 é um endereço específico
  LD $status               #
  STO $tmp2                # $tmp2 é um endereço específico
	
  LD $int_status           # Carrega o registrador $int_status
  ANDI 0x0003              # Caso o valor seja 0, não ocorreu interrupção, então...
  BEQ MAIN                 # Pula para MAIN
  LD lst_acc_value         # Carrega o endereço onde será armazenado o último
  STO $indr                # valor do registrador ACC antes da interrupção
  LD $tmp0                 #
  STOV 0x0000              # O registrador $zero é o endereço 0x000
  
  LD lst_indr_value        # Carrega o endereço onde será armazenado o último
  STO $indr                # valor do registrador Indr antes da interrupção
  LD $tmp1                 #
  STOV 0x0000              #
  
  LD lst_status_value      # Carrega o endereço onde será armazenado o último
  STO $indr                # valor do registrador Status antes da interrupção
  LD $tmp0                 #
  STOV 0x0000              #
  
  POP                      # Se foi iniciada pelo relógio, desempilha o topo da pilha
  STO $tmp0                # E salva o valor do mesmo no endereço especificado
  LD lst_pc_value          # Carrega o endereço onde será armazenado o último
  STO $indr                # valor do registrador PC antes da interrupção
  LD $tmp0                 # 
  STOV 0x0000              #
  
  LD $int_status           # Verificar se a interrupção foi gerada por relógio ou externamente
  ANDI 0x002               #
  BNE _INTERRUPT_          # Se foi gerada externamente, vai para o trecho de interrupção

  JMP SCHEDULER            # Vai para o SCHEDULER
  
INTERRUPT_RETURN:          # Rotina de retorno de interrupção
  LD current_tsk_ind       # Carrega o índice da tarefa atual
  ANDI 0x0007              #
  STO $arg1                # Carrega o Id da tarefa atual
  JMP OS_TSK_RETURN        # Retorna a tarefa
	  
#===============================================================================
# Fim do trecho de interrupção
#===============================================================================
	
#===============================================================================
#   Utils
# Funções úteis para o sistema
#===============================================================================

#===============================================================================
# SET_STATUS
# Atualiza o estado do registrador STATUS 
# Argumentos:
# $arg0 = Valor do registrador status
#===============================================================================
SET_STATUS:
  LD $arg0               # Carrega o argumento 0, que contém o Status
  SUBI 0x6               #  
  BNE CN_NOT_SET         # Os flags C e N estão setados?
  LDI 0xFFE              # Força o set nos flags C e N
  SUBI 0xFFF             #
  RETURN                 # Retorna
CN_NOT_SET:              #
  LD $arg0               # 
  SUBI 0x5               # 
  BNE CZ_NOT_SET         # Os flags C e Z estão setados?
  LDI 0x1                #
  ADDI 0xFFF             # Força o set nos flags C e Z
  RETURN                 # Retorna
CZ_NOT_SET:              #
  LD $arg0               #
  SUBI 0x4               #
  BNE C_NOT_SET          # O flag C está setado ?
  LDI 0x2                #
  ADDI 0xFFF             # Força um set no flag C
  RETURN                 # Retorna
C_NOT_SET:               #
  LD $arg0               #
  SUBI 0x2               #
  BNE N_NOT_SET          # O Flag N está setado?
  LDI 0xFFA              #
  SUBI 0x2               # Força um set no Flag N
  RETURN                 # Retorna
N_NOT_SET:               #
  LD $arg0               #
  SUBI 0x1               # 
  BNE Z_NOT_SET          # O Flag Z está setado?
  LDI 0x1                # 
  ANDI 0x0               # Força um set no flag Z
  RETURN                 # Retorna
Z_NOT_SET:               #
  LDI 0x3                #
  SUBI 0x2               # Limpa os flags
  RETURN                 # Retorna
  
#===============================================================================
# BUBBLE_SORT
# Algoritmo bubble sort para ordenar a lista de tarefas
#===============================================================================
BUBBLE_SORT:

  LD tsk_quantity        # Carrega o tamanho do vetor
  SUBI 0x0000            #
  BNE NOT_EMPTY_LIST     # Verifica se existem itens na lista de tarefas
  RETURN                 #
NOT_EMPTY_LIST:          #
  LD tsk_quantity        #
  SUBI 0x1               # 
  STO $tmp0              # $tmp0 = tsk_quantity - 1 (tmp0 = k)
  LDI 0x0                #
  STO $tmp1              # $tmp1 = 0 (tmp1 = i)
FOR_CMD:                 #
  LD $tmp0               #
  SUB $tmp1              #
  BEQ END_FOR_CMD        # Comando for ($tmp2 = 1; $tmp2<=tsk_quantity; $tmp2++)
  LDI 0x0000             # 
  STO $tmp2              # $tmp2 = 0 (tmp2 = j)
WHILE_BS:                #
  LD $tmp2               #
  SUB $tmp0              #
  BGE END_WHILE_BS       # Desvia se $tmp2 > $tmp0
  LD $tmp2               #
  STO $indr              # 
  LDV 0x05B0             # TAB_PROCESSOS[$tmp2] 
  STO $tmp3              # $tmp3 = TAB_PROCESSOS[$tmp2] (v[j])
  LD $indr               #
  ADDI 0x001             #
  STO $indr              #
  LDV 0x05B0             # TAB_PROCESSOS[$tmp2 + 1]
  STO $tmp4              # $tmp4 = TAB_PROCESSOS[$tmp2 + 1] 
  LD $tmp3               #
  SUB $tmp4              #
  BLE END_IF_BS          # Desvia se $tmp3 <= $tmp4
  LD $tmp3               #
  STO $tmp5              # $tmp5 = $tmp3
  LD $tmp2               #
  ADDI 0x001             #
  STO $indr              #
  LDV 0x05B0             #
  STO $tmp3              # $tmp3 = TAB_PROCESSOS[$tmp2 + 1]
  LD $tmp2               #
  STO $indr              #
  LD $tmp3               #
  STOV 0x5B0             # TAB_PROCESSOS[$tmp2] = $tmp3
  LD $indr               #
  ADDI 0x01              #
  STO $indr              #
  LD $tmp5               #
  STOV 0x05B0            # TAB_PROCESSOS[$tmp2 + 1] = $tmp5
END_IF_BS:               #
  LDI 0x1                #
  ADD $tmp2              #
  STO $tmp2              # $tmp2 ++
  JMP WHILE_BS           #
END_WHILE_BS:            #
  LD $tmp1               #
  ADDI 0x01              #
  STO $tmp1              #
  JMP FOR_CMD            #
END_FOR_CMD:             #
  RETURN                 # 	

#===============================================================================
#    Funções de Escrita
#===============================================================================
OS_WRITE_PORT0:
  LDI 0xFFE                 # Gera um bloqueio para escrita
  AND $int_config           #
  STO $int_config           #
  
  LD $arg0                  # Escreve o argumento 0
  STO $port0_data           # Na porta 0, dedicada para escrita

  LDI 0x001                 #
  OR $int_config            # Remove o bloqueio
  STO $int_config           #

  RETURN                    #
 
OS_WRITE_PORT1:
  LDI 0xFFE                 # Gera um bloqueio para escrita
  AND $int_config           #
  STO $int_config           #
  
  LD $arg0                  # Escreve o argumento 0
  STO $port1_data           # Na porta 1, dedicada para escrita

  LDI 0x001                 #
  OR $int_config            # Remove o bloqueio
  STO $int_config           #

  RETURN                    #

#===============================================================================
# API
#===============================================================================

# O BIP/OS possui as seguintes funções em sua API
# 
# = Criação de tarefa       (OS_TSK_CREATE)
# = Inicialização de tarefa (OS_TSK_START)
# = Pausa de tarefa         (OS_TSK_PAUSE)
# = Retorno de tarefa       (OS_TSK_RETURN)
# = Encerramento de tarefa  (OS_TSK_END)
# = Remoção de tarefa       (OS_TSK_REMOVE)

#===============================================================================
# OS_TSK_CREATE
#
# Cria a tarefa na estrutura de dados mantida pelo sistema operacional
# Argumentos:
# $arg1 = Endereço inicial da tarefa
# $arg2 = Endereço final da tarefa
# $arg3 = Prioridade da tarefa
#===============================================================================
OS_TSK_CREATE:                  
  
  LD prx_tsk_id             # Carrega o próximo endereço 
  SLL 0x4                   # Desloca o valor logicamente para a esquerda 4 vezes
  ADDI 0x700                # Soma o resultado com o endereço 0x700, dando o endereço onde ficarão os
  STO $indr                 # argumentos da tarefa. Salva esse resultado em $indr
  
  LD $arg1                  # Carrega o primeiro argumento da tarefa, início da tarefa
  STOV 0x0000               # Armazena o valor em 0x7X0, onde X é o id da tarefa
  
  LD $indr                  # Carrega o valor da variável indr
  ADDI 1                    # Atualiza tmp0 para conter o próximo endereço de tarefa
  STO $indr                 #
  LD $arg2                  # Carrega o segundo argumento da tarefa, fim da tarefa
  STOV 0x0000               # Armazena o valor em 0x7X1, onde X é o id da tarefa
	
  LD $indr                  #
  ADDI 1                    # Atualiza tmp0 para conter o próximo endereço de tarefa
  STO $indr                 #
  LD $arg3                  # Carrega o terceiro argumento (prioridade da tarefa)
  STOV 0x0000	             # Salva na estrutura a prioridade da tarefa no endereço 0x7X2
	
  LD $indr                  #
  ADDI 0x0001               # Atualiza $indr para conter o próximo endereço de tarefa
  STO $indr                 #
  LD $arg1                  # Carrega o primeiro argumento (início da tarefa)
  STOV 0x0000               # Salva no endereço 0x7X3, que contém o pc da tarefa
  
  LD prx_tsk_id             #
  SLL 0x0004                #
  ADDI 0x070C               # Define $tmp0 como 0x7XC, último endereço na tabela
  STO $tmp0                 # de contexto da tarefa
  
LOOP_FILL_ZERO:             # Preenche com zero os demais endereços
  LD $indr                  # Carrega o registrador $indr
  ADDI 0x0001               # Adiciona mais 1
  STO $indr                 # $indr = $indr + 1
  LDI 0x0000                #
  STOV 0x0000               # MEM[0x7X$indr] = 0x0
  LD $indr                  #
  SUB $tmp0                 #
  BNE LOOP_FILL_ZERO        #

  LD tsk_quantity           #
  STO $indr                 # Define o valor como índice do vetor
  LD $arg3                  # Carrega a prioridade da tarefa
  SLL 0x0004                # Desloca 4 bits para a esquerda
  ADD prx_tsk_id            # Adiciona com o Id da tarefa 
  STO $tmp0                 # $tmp0 = 0x0PI, onde P é a prioridade e I é o Id
  LD $tmp0                  # Carrega o valor da prioridade
  STOV 0x5B0                # Salva o valor na tabela de processos
  LD tsk_quantity           # Carrega a quantidade de tarefas
  ADDI 0x1                  # Soma mais 1
  STO tsk_quantity          #
  
  LD prx_tsk_id             # Carrega o próximo Id
  ADDI 0x0001               # Soma mais 1
  STO prx_tsk_id            # Salva o valor

  CALL BUBBLE_SORT          # Ordena a tabela de processos do menor para o maior

  RETURN                    #
  
#===============================================================================
# OS_TSK_START (UNUSED)
#
# Inicia a tarefa
# Essa função não é chamada por uma instrução CALL, mas sim por uma instrução 
# JMP. Ou seja, ela não guarda valores na pilha
#
# Argumentos: 
# $arg1 = Id da tarefa a ser iniciada
#===============================================================================
OS_TSK_START:
    
  LD $arg1                 #
  SLL 0x4                  #
  ADDI 0x702               #
  STO $indr                # Endereço da prioridade da tarefa (0x7X2)
  LDV 0x0000               # Carrega a prioridade da tarefa
  
  SLL 0x4                  # Desloca 4 bits à esquerda
  ADD $arg1                # Soma com o Id da tarefa
  STO $tmp0                #
  
  LD $indr                 # Carrega o valor do registrador $indr
  STO $tmp1                # Armazena temporariamente
  
  LD $tmp1                 # Recarrega o valor antigo de $indr
  STO $indr                #
  
  ADDI 0x6                 # Carrega 0x6
  STO $indr                # Armazena em $indr o endereço do status da tarefa (0x7X6)
  LDI 2                    # Carrega o valor 2 (Status 2 = Em execução)
  STOV 0x0000              # Salva na estrutura ( MEM[0+0x7X6] = 2)
  
  LD $indr                 # Carrega o endereço do status da tarefa (0x7X6)
  SUBI 0x3                 # Subtrai para o endereço do PC da tarefa (0x7X3)
  STO $indr                # Armazena o valor no registrador $indr
  LDV 0x0000               # Carrega MEM[0+0x7X3]
  STO $tmp1              
    
  JR $tmp1                 # Desvia para o pc inical da tarefa
  
#===============================================================================
# OS_TSK_PAUSE
#
# Pausa a tarefa em execução, salvando o contexto da mesma
# 
# Argumentos: 
# $arg1 = Id da tarefa
#===============================================================================
OS_TSK_PAUSE:
  
  LD lst_pc_value          # Carrega o último pc em andamento
  STO $indr                # Carrega o endereço de armazenamento do valor do 
  LDV 0x0000               # pc da tarefa
  STO $tmp0                # $tmp0 = Último PC da tarefa
  LD $arg1                 # 
  SLL 0x4                  #
  ADDI 0x703               #
  STO $indr                # Endereço base dos argumentos da tarefa
  STO $tmp1                #
  LD $tmp0                 #
  STOV 0x0000              # Salva o PC no endereço 0x7X3, sendo X o Id da tarefa
  
  LD lst_status_value      # Carrega o último valor do registrador status
  STO $indr                # 
  LDV 0x0000               #
  STO $tmp0                # $tmp0 = last status value
  LD $tmp1                 #
  ADDI 0x0001              #
  STO $tmp1                #
  STO $indr                # Carrega o endereço de armazenamento do valor do registrador status
  LD $tmp0                 #
  STOV 0x0000              # Armazena o valor do acumulador no endereço 0x7X4
  
  LD $indr                 # 
  ADDI 0x1                 #
  STO $tmp1                #
  LD lst_acc_value         # Carrega o último valor do acumulador da tarefa
  STO $indr                # Carrega o endereço de armazenamento do valor do acumulador
  LDV 0x0000               #
  STO $tmp0                #
  LD $tmp1                 #
  STO $indr                #
  LD $tmp0                 #
  STOV 0x0000              # Armazena o valor do acumulador no endereço 0x7X5
  
  LD $indr                 #
  ADDI 0x1                 #
  STO $indr                # Carrega o endereço de armazenamento do valor do status da tarefa
  STO $tmp1                #
  LDI 0x1                  # Carrega o status da tarefa (1, em espera)
  STOV 0x0000              # Armazena o status da tarefa no endereço 0x7X6
  
  LD lst_indr_value        # Carrega o índice do vetor
  STO $indr                #
  LDV 0x0000               #
  STO $tmp0                #
  LD $tmp1                 #
  ADDI 0x0001              #
  STO $tmp1                #
  STO $indr                # Carrega o endereço de armazenamento do valor do índice do vetor
  LD $tmp0                 #
  STOV 0x0000              # Armazena o valor do índice do vetor no endereço 0x7X7

  LD $indr                 #
  ADDI 0x1                 #
  STO $indr                # Carrega o endereço de armazenamento do valor da direção
  LD $port0_dir            # do registrador port0_data
  STOV 0x0000              # Armazena o valor em 0x7X8

  LD $indr                 #
  ADDI 0x1                 #
  STO $indr                # Carrega o endereço de armazenamento do valor 
  LD $port0_data           # contido no registrador port0_data
  STOV 0x0000              # Armazena o valor em 0x7X9

  LD $indr                 #
  ADDI 0x1                 #
  STO $indr                # Carrega o endereço de armazenamento do valor da direção
  LD $port1_dir            # do registrador port1_data
  STOV 0x0000              # Armazena o valor em 0x7XA

  LD $indr                 #
  ADDI 0x1                 #
  STO $indr                # Carrega o endereço de armazenamento do valor 
  LD $port1_data           # contido no registrador port1_data
  STOV 0x0000              # Armazena o valor em 0x7XB
  
  POP                      # Retira o endereço da chamada a esta função
  STO $tmp2                #
  
  LD $indr                 #
  ADDI 0x1                 #
  STO $indr                # Carrega o endereço do registrador $stkptr
  LD $stkptr               # 
  STOV 0x0000              # Armazena o valor em 0x7XC

  LD $arg1                 # Carrega o id da tarefa
  SLL 0x3                  # Desloca o endereço para a esquerda
  ADDI 0x680               # Adiciona ao endereço base da STACK_CONTEXT_TABLE
  STO $tmp1                # $tmp1 = base da pilha
  
  LD $stkptr               # Ajusta o valor do registrador STKPTR
  SUBI 0x0001              # para que o mesmo utilize o mesmo índice que a 
  STO $tmp0                # tabela de contexto da pilha
  
  LD $arg1                 #
  SLL 0x0003               #
  ADDI 0x0680              #
  ADD $tmp0                # Carrega o endereço para o topo da pilha
  STO $tmp0                #
  STO $indr                #

STACK_CONTEXT_LOOP_POP:           #
  LD $indr                        #
  SUB $tmp1                       # Desvia se o índice for menor que o valor do 
  BLT END_STACK_CONTEXT_LOOP_POP  # registrador STKPTR da tarefa
  POP                             # Loop de salvamento da pilha
  STOV 0x0000                     # Salva o topo da pilha no endereço 0x6Xi
  LD $indr                        # Carrega o endereço 0x6Xi
  SUBI 0x1                        # Carrega o próximo endereço (0x6Xi-1)             
  STO $indr                       # Salva o mesmo
  JMP STACK_CONTEXT_LOOP_POP      # Volta para o loop e continua desempilhando   
END_STACK_CONTEXT_LOOP_POP:       #

  LD $tmp2                   # Carrega o endereço da função que chamou
  PUSH                       # Retorna para a pilha

  RETURN                     #
  
#===============================================================================
# OS_TSK_RETURN
#
# Retorna a tarefa em pausa, carregando o contexto da mesma
# 
# Argumentos: 
# $arg1 = Id da tarefa
#===============================================================================
OS_TSK_RETURN:
    
  LD $arg1                 #
  SLL 0x4                  #
  ADDI 0x70C               # Carrega o endereço onde foi armazenado o valor do
  STO $indr                # registrador $stkptr
  LDV 0x0000               #
  STO $tmp0                # Salva o mesmo em $tmp0

  LD $arg1                 #
  SLL 0x3                  #
  ADDI 0x680               # 
  STO $tmp1                # Carrega o endereço da base da pilha (0x6X0)

  LD $tmp0                         #
  SUBI 0x0000                      # Verifica se existiam itens na pilha
  BEQ END_STACK_CONTEXT_LOOP_PUSH  #
  
  LD $tmp0                         # Carrega o valor do Stack Pointer, que
  SUBI 0x0001                      # começa em 1, e 
  STO $tmp0                        # Ajusta para o índice, que começa em 0

  LD $tmp1                         #
  ADD $tmp0                        #
  STO $tmp0                        # Carrega o endereço do topo da pilha 
  
STACK_CONTEXT_LOOP_PUSH:           #
  LD $tmp0                         # Carrega o endereço topo
  SUB $tmp1                        # Carrega o endereço base
  BLT END_STACK_CONTEXT_LOOP_PUSH  #
  LD $tmp0                         # 
  STO $indr                        #
  LDV 0x0000                       # Carrega o valor contido no endereço 0x6Xi
  PUSH                             # Salva no topo da pilha
  LD $indr                         # Carrega o valor da variável tmp1 endereço 0x6Xi
  SUBI 0x1                         # Diminui 1 do valor do endereço
  STO $tmp0                        #
  JMP STACK_CONTEXT_LOOP_PUSH      #
END_STACK_CONTEXT_LOOP_PUSH:       #

  LD $arg1                 #
  SLL 0x4                  # 
  ADDI 0x70B               # Transforma o mesmo em 0x7XB (Endereço do registrador port1_data do contexto da tarefa)
  STO $indr                #  
  LDV 0x0000               # Carrega o valor do registrador port1_data do contexto da tarefa
  STO $port1_data          # Joga o valor no local
  
  LD $indr                 # 
  SUBI 0x1                 # Diminui em 1 o endereço (0x7XA = Endereço do registrador port1_dir)
  STO $indr                #
  LDV 0x0000               #
  STO $port1_dir           # Joga o valor no local
  
  LD $indr                 # 
  SUBI 0x1                 # Diminui em 1 o endereço (0x7X9 = Endereço do registrador port0_data)
  STO $indr                #
  LDV 0x0000               # Carrega o valor contido no endereço
  STO $port0_data          # Joga o valor no local
  
  LD $indr                 # 
  SUBI 0x1                 # Diminui em 1 o endereço (0x7X8 = Endereço do registrador port0_dir)
  STO $indr                #
  LDV 0x0000               # Carrega o valor contido no endereço
  STO $port0_dir           # Joga o valor no local
  
  LD $arg1                 # Carrega o argumento da tarefa
  SLL 0x0004               #
  ADDI 0x0706              # Carrega o endereço (0x7X6 = Endereço do status da tarefa)
  STO $indr                #
  LDI 0x2                  #
  STOV 0x000               # Salva o status da tarefa como sendo 2 (2 - Em execução)

  LD $indr                 #
  SUBI 0x0001              # Diminui em 1 o endereço (0x7X5 = Endereço do registrador acc)
  STO $indr                # 
  LDV 0x0000               # Carrega o valor contido no endereço
  STO $tmp1                # Salva numa variável temporária
  
  LD $indr                 # 
  SUBI 0x2                 # Diminui em 2 o endereço (0x7X3 = Endereço do registrador pc)
  STO $indr                #
  LDV 0x0000               #
  STO $tmp2                # Salva numa variável temporária
  
  LD $indr                 #
  ADDI 0x4                 # Aumenta o endereço em 4 (0x7X7 = Endereço do registrador indr)
  STO $indr                #
  LDV 0x0000               # Carrega o valor contido no endereço
  STO $tmp3                # Joga o valor no local

  LD $arg1                 # 
  SLL 0x4                  # Diminui em 1 o endereço (0x7X4 = Endereço do registrador status)
  ADDI 0x0704              #
  STO $indr                #
  LDV 0x0000               # Carrega o valor contido no endereço
  STO $arg0                # Salva o valor do registrador STATUS em $arg0
  
  POP                      # Desempilha para não prejudicar o contexto da tarefa
  STO $tmp0                # quando chamar a função SET_STATUS
  
  LDI 0x001                #
  OR $int_config           # Prepara para a remoção do bloqueio
  STO $tmp4                #
  
  CALL SET_STATUS          # Retorna o estado do registrador status
  
  LD $tmp0                 #
  PUSH                     # Retorna o topo da pilha
  
  LD $tmp3                 # Retorna o valor do índice
  STO $indr                #
  
  LD $tmp4                 # Carrega o valor antigo da configuração de 
  STO $int_config          # interrupção sem alterar o registrador status
  
  LD $tmp1                 # Carrega o valor do acumulador
  JR $tmp2                 # Pula para a última linha da tarefa
  
#===============================================================================
# OS_TSK_END
#
# Encerra uma tarefa
# 
# Argumentos: 
# $arg0 = Id da tarefa
#===============================================================================
OS_TSK_END:
  LDI 0xFFE                # Gera um bloqueio 
  AND $int_config          #
  STO $int_config          #
    
  LD current_tsk_ind       # Carrega o argumento da tarefa (id da tarefa)
  STO $indr                #
  LDV 0x05B0               #
  ANDI 0x0007              #
  SLL 0x4                  # Desloca em 4 posições o id da tarefa
  ADDI 0x706               # Adiciona 0x706, formando o endereço do status da tarefa (0x7X6)
  STO $indr
  
  LDI 0x3                  # Carrega o status 3 = Tarefa encerrada
  STOV 0x0000              # Salva o status na estrutura
  
  JMP OS_TSK_REMOVE        #
  
# =============================================================================
# OS_TSK_REMOVE
#
# Remove uma tarefa. Em TODAS as tarefas a última linha deve ser um 
# JMP para este endereço.
# 
# =============================================================================	
OS_TSK_REMOVE:
	
  LD current_tsk_ind        # Carrega o índice da tarefa
  STO $tmp1                 # Armazena em $tmp1
  
  LD tsk_quantity                # Verifica se o índice é igual a 0
  SUBI 0x0001                    #
  SUB $tmp1                      # Se o mesmo for, não precisa remover da lista
  BEQ END_REMOVE_TASK_FROM_LIST  #
  
   
  LDI 0x0                    # Carrega o valor 0
  STO $tmp2                  # Armazena em $tmp2
LOOP_REBUILD_TASK_LIST:      #
  LD $tmp2                   # Carrega o valor do índice
  SUB $tmp1                  # Verifica se o valor contido no índice 
  BEQ REMOVE_TASK_FROM_LIST  # é igual ao valo de $tmp1
  LD $tmp2                   # Se não for igual, carrega $tmp2
  ADDI 0x1                   # e faz $tmp2 = $tmp2 + 1
  STO $tmp2                  #
  JMP LOOP_REBUILD_TASK_LIST # E volta para o loop
REMOVE_TASK_FROM_LIST:       # Se for igual, 
  LD $tmp2                   # Carrega $tmp2
  STO $tmp3                  # Armazena o mesmo em $tmp3
  LD $tmp2                   # Carrega novamente $tmp2
  ADDI 0x1                   # faz $tmp2 = $tmp2 + 1
  STO $tmp2                  #
  STO $indr                  # $indr = $tmp2
  LDV 0x5B0                  # Carrega o valor no vetor
  STO $tmp4                  # Armazena em $tmp4
  LD $tmp3                   # Carrega $tmp3 (Antigo $tmp2)
  STO $indr                  #
  LDV 0x05B0                 # 
  STO $tmp5                  # 
  LD $tmp4                   #
  STOV 0x5B0                 # TSK_LIST[ $tmp3 ] = $tmp4
  LD $tmp2                   #
  STO $indr                  #
  LD $tmp5                   #
  STOV 0x05B0                #
  LD tsk_quantity               #     
  SUBI 0x0001                   #
  SUB $tmp2                     # Verifica se a quantidade de tarefas contidas na lista
  BLE END_REMOVE_TASK_FROM_LIST # Encerra a rotina se for igual
  JMP REMOVE_TASK_FROM_LIST     # Senão, volta para o loop
END_REMOVE_TASK_FROM_LIST:      #
  
  LD tsk_quantity           #
  SUBI 0x0001               # Diminui o número de tarefas no sistema
  STO tsk_quantity          # 
  
  CALL BUBBLE_SORT          # Ordena a lista de tarefas
  
  LDI 0x0001                #
  STO get_next_tsk          # Indica que a próxima tarefa pode ser chamada
  
  LD tsk_quantity           #
  SUBI 0x0001               #
  SUB current_tsk_ind       # Se o índice atual for igual à quantidade de tarefas
  BNE RESET_TSK_IND         # reseta o índice
  
  LDI 0x0000                #
  STO current_tsk_ind       # 
   
RESET_TSK_IND:              #
  LD tsk_quantity           # Verifica se ainda existem tarefas para executar
  SUBI 0x0000               #
  BEQ OS_END                # Se não existem mais, pula para o fim
  
  JMP SCHEDULER             # Senão, pula para o SCHEDULER


#===============================================================================
# SCHEDULER
# 
# Este scheduler é um simples round=robin, visto que a lista de 
# tarefas está sempre organizada.
#===============================================================================
SCHEDULER:
  LDI 0xFFE                 # Gera um bloqueio 
  AND $int_config           #
  STO $int_config           #
  
  LD current_tsk_ind           #
  STO $indr                    #
  LDV 0x05B0                   # Carrega o índice da tarefa atual
  ANDI 0x0007                  # 
  SLL 0x0004                   # 
  ADDI 0x0706                  # 
  STO $indr                    # Carrega o status da tarefa
  LDV 0x0000                   # 
  STO $tmp0                    # Armazena em $tmp0
  LD $tmp0                     #
  SUBI 0x000                   # Status da tarefa igual a "criada"
  BEQ GOTO_TASK                #

  LD get_next_tsk              #
  SUBI 0x0001                  # Status da tarefa igual a "encerrada"
  BEQ GOTO_TASK                #

  LD current_tsk_ind           #
  STO $indr                    #
  LDV 0x5B0                    # Carrega o valor dentro da tabela de tarefas
  ANDI 0xF                     # Extrai o Id da tarefa a ser pausada
  STO $arg1                    #
  CALL OS_TSK_PAUSE            # Pausa a tarefa

  LD current_tsk_ind           # Carrega o índice no qual está a tarefa corrente
  ADDI 0x0001                  # Adiciona mais 1
  SUB tsk_quantity             # 
  BEQ RESET_ROUND_ROBIN        # Se o indice da próxima tarefa for igual à quantidade de tarefas
                               # reseta o round=robin
  
  LD current_tsk_ind           # Carrega o índice da tarefa atual
  ADDI 0x1                     #
  STO current_tsk_ind          # Atualiza para o próximo
  
  JMP GOTO_TASK                # Senão, pula para a tarefa

RESET_ROUND_ROBIN:             #
  LDI 0x0000                   #
  STO current_tsk_ind          # current task index = 0

GOTO_TASK:
  LD tsk_quantity              # Carrega a quantidade de tarefas ativas
  SUBI 0x0000                  # Se a mesma for igual a zero
  BEQ OS_END                   # Encerra
  
  LDI 0x0000                   # Desliga flag para pegar a próxima tarefa
  STO get_next_tsk             #
  
  LD current_tsk_ind           # Carrega o índice da tarefa
  STO $indr                    #
  LDV 0x5B0                    #
  ANDI 0x000F                  # Carrega o id da tarefa
  STO $arg1                    #
    
  JMP OS_TSK_RETURN            # Retorna para a tarefa
  
#===============================================================================
# OS_END
# Encerra as operações do SO
#===============================================================================
OS_END:                        # Encerra o SO
  HLT                          #

#===============================================================================
# Rotina de Interrupção
#===============================================================================
_INTERRUPT_:
  LD current_tsk_ind        # Carrega o índice atual da tarefa
  ANDI 0x0007               #
  STO $arg1                 # Carrega o identificador da tarefa
  CALL OS_TSK_PAUSE         # Pausa a tarefa atual
  
  #
  # Interruption instructions here...
  #
  
  JMP INTERRUPT_RETURN      # Retorna para o ponto de interrupção
#===============================================================================
# MAIN
#===============================================================================
MAIN:
  LDI 0x05A3                # Endereço onde será armazenado o valor do último PC
  STO lst_pc_value          #
  LDI 0x05A2                # Endereço onde será armazenado o valor do último STATUS
  STO lst_status_value      #
  LDI 0x05A1                # Endereço onde será armazenado o valor do último ACC
  STO lst_acc_value         #
  LDI 0x05A0                # Endereço onde será armazenado o valor do último INDR
  STO lst_indr_value        # 
  LDI 0x0001                #
  STO $tmr0_config          # Configura o prescaller
  LDI 0x01FF                # 
  STO 0x0412                # Configura a fatia de tempo em 0x1FF (Para fins de teste)
  LDI 0x0000                # 
  STO $int_config           # Desativa interrupções
  
#===============================================================================
# Chamada aos Programas do Usuário
#===============================================================================
  LDI INIT_TSK_1            # Endereço do início da tarefa
  STO $arg1                 # registrador de argumento 1
  LDI END_TSK_1             # Endereço do fim da tarefa
  STO $arg2                 # registrador de argumento 2
  LDI 0x0001                # Prioridade da tarefa 1
  STO $arg3                 #
  CALL OS_TSK_CREATE        # Chama o criador de tarefas

  LDI INIT_TSK_2            #
  STO $arg1                 #
  LDI END_TSK_2             #
  STO $arg2                 #
  LDI 0x0001                #
  STO $arg3                 #
  CALL OS_TSK_CREATE        #
  
  LDI INIT_TSK_3            #
  STO $arg1                 #
  LDI END_TSK_3             #
  STO $arg2                 #
  LDI 0x0000                #
  STO $arg3                 #
  CALL OS_TSK_CREATE        #

  LDI 0x0007                #
  STO $int_config           #
  JMP SCHEDULER             #

#===============================================================================
#  Programas do usuário
# À partir deste ponto é que começa a mágica...
#===============================================================================

#===============================================================================
# Programa 1
#===============================================================================
F1_0:              # Função que subtrai 2 do valor contido em 0x111
  LD 0x111         #
  SUBI 0x0002      #
  STO 0x0111       #
  CALL F1_1        # E chama a função F1_1
  RETURN           #
  
F1_1:              # Função que adiciona 1 ao valor de 0x111
  LD 0x0111        #
  ADDI 0x0001      #
  STO 0x0111       #
  CALL F1_2        # E chama a função F1_2
  RETURN           #
 
F1_2:              # Função que subtrai 2 do valor contido em 0x111
  LD 0x0111        #
  SUBI 0x0002      #
  STO 0x0111       # E retorna
  RETURN           #

# ==============================================================================
INIT_TSK_1:        # Início da tarefa 1
  LDI 0x01FF       # Carrega 0x1FF
  STO 0x0111       # Armazena em 0x111
L1:                #
  LD 0x111         # Carrega 0x111
  SUBI 0x1         # Subtrai 1 do valor contido em 0x111
  STO 0x111        # Armazena o resultado em 111
  LDI 0x111
  STO $port0_data
  CALL F1_0        # Chama a função F1_0
  LD 0x111         # Carrega o valor contido em 0x111
  SUBI 0x0         # Verifica se o valor é igual a 0x0
  BNE L1           # Desvia se for diferente
  JMP OS_TSK_END   # Encerra a tarefa
END_TSK_1:         #

#===============================================================================
# Programa 2
#===============================================================================
INIT_TSK_2:        # Início da tarefa 2
  LDI 0x02FF       # Carrega o valor 0x2FF
  STO 0x222        # Armazena em 0x222
L2:                #
  LD 0x222         # Carrega o valor contido em 0x222
  SUBI 0x1         # Subtrai 1 do valor contido em 0x222
  STO 0x222        # Armazena o resultado em 0x222
  LDI 0x222
  STO $port0_data
  LD 0x222         # Carrega o valor contido em 0x222
  SUBI 0x0         # Verifica se o mesmo está igual a 0
  BNE L2           # Desvia se estiver diferente
  JMP OS_TSK_END   # Encerra a tarefa
END_TSK_2:         #

#===============================================================================
# Programa 3
#===============================================================================
INIT_TSK_3:        # Início da tarefa 3
  LDI 0x00FF       # Carrega o valor 0xFF
  STO 0x333        # Armazena o valor em 0x333
L3:                # 
  LD 0x333         # Carrega o valor contido em 0x333
  SUBI 0x1         # Subtrai 1 do valor contido em 0x333
  STO 0x333        # Armazena o resultado em 0x333
  LDI 0x333
  STO $port0_data
  LD 0x333         # Carrega o valor contido em 0x333
  SUBI 0x0         # Verifica se o mesmo é igual a 0x0
  BNE L3           # Desvia se for diferente
  JMP OS_TSK_END   # Encerra a tarefa
END_TSK_3:         #
  HLT
