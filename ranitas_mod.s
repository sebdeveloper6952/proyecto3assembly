/*********************** Juego de Ranitas ************************
/************************** Registros ****************************
r0-r3 utilizados por funciones de c
r4 guarda el turno: 1 = jugador 1, 2 = jugador 2 
*****************************************************************/

.global main
.func main

main:
  bl imprimir_titulo
  bl imprimir_logo
  mov r4, #0x1                           @ turno de jugador 1
  game_loop:
    bl imprimir_tablero
    bl pedir_posiciones
    bl validar_posiciones
    
    /* Preparar parametros para mover ranita. */
    ldr r0, =pos0
    ldr r0, [r0]
    ldr r1, =pos1
    ldr r1, [r1]
    /* Obtener posiciones de caracteres a intercambiar. */
    bl transformar_posiciones
    
    /* Intercambiar caracteres para simular el moviemiento de las ranitas. */
    bl mover_ranita
    
    /* Se revisa si algun jugador gano, el resultado de esta subrutina esta en r0. */
    bl revisar_tablero
    
    /* Se revisa r0 para ver si algun jugador gano, de lo contrario inicia un nuevo turno. */
    cmp r0, #0x1
    beq gano_jugador_1
    cmp r0, #0x2
    beq gano_jugador_2
    bal fin_turno

/************************* Subrutinas ****************************/

/* Imprime el tablero, mostrando el estado actual
   del juego. */
imprimir_tablero:
  push {lr}                              @ guardar registro link
  ldr r0, =tablero_titulo
  bl puts
  ldr r0, =tablero0
  bl puts
  ldr r0, =tablero1
  bl puts
  pop {pc}                               @ pc <- lr para continuar programa

pedir_posiciones:
  push {lr}
  ldr r0, =msg_turno_jugador             @ "Turno de jugador x"
  mov r1, r4
  bl printf
  ldr r0, =msg_ing_pos1                  @ "Seleccione su ranita: "
  bl puts
  ldr r0, =fmt_entero                    @ jugador selecciona su ranita
  ldr r1, =pos0
  bl scanf
  cmp r0, #0x0
  beq validar_numero_entero              @ si se ingreso algo que no es numero entero, es invalido
  ldr r0, =msg_ing_pos2                  @ "Ingrese destino de su ranita"
  bl puts
  ldr r0, =fmt_entero                    @ jugador ingresa destino de ranita
  ldr r1, =pos1
  bl scanf
  cmp r0, #0x0
  beq validar_numero_entero              @ si se ingreso algo que no es numero entero, es  invalido
  ldr r0, =pos0                          @ cargar posiciones en registros para ser validadas
  ldr r0, [r0]
  ldr r1, =pos1
  ldr r1, [r1]
  pop {pc} 

/* En caso de que se ingrese algo que no es numero entero, se vacia el input buffer para quitar los
   caracteres invalidos del mismo, para que no sean leidos, y luego se le informa al jugador que
   ingreso algo invalido, y se le piden los datos de nuevo. */
validar_numero_entero:
  loop_flush_input_buffer:           @ limpia el input buffer hasta encontrar \n
    bl getchar                       @ sirve para cuando el usuario ingresa letras
    cmp r0, #0xA                     @ #0xA = '\n'
    bne loop_flush_input_buffer
  bal posiciones_invalidas

/* Valida que las posiciones esten en el rango adecuado (1 a 11). Si las posiciones
   son validas, se procede a verificar de que jugador es el turno, y se pasa al
   proceso adecuado. */
validar_posiciones:
  push {lr}                  @ pushear lr para poder regresar luego
  ldr r0, =pos0              @ cargar posiciones ingresadas por el jugador
  ldr r0, [r0]
  cmp r0, #0xB               @ 0 < r0 <= 11 asegurarse que posiciones esten en rango valido
  bgt posiciones_invalidas
  cmp r0, #0x0
  ble posiciones_invalidas
  ldr r1, =pos1
  ldr r1, [r1]
  cmp r1, #0xB
  bgt posiciones_invalidas
  cmp r1, #0x0
  ble posiciones_invalidas
  bl transformar_posiciones  @ computar posiciones de caracteres validas
  cmp r4, #0x1               @ saltar a validacion correspondiente dependiendo de que jugador tiene el turno
  beq validar_j1             @ turno de jugador 1
  bal validar_j2             @ turno de jugador 2

/* Validaciones para el jugador 1. Se verifica que en la posicion de origen haya una ranita que pertenezca al
   jugador 1. Luego se verifica que tipo de movimiento desea hacer el jugador (movimiento normal o salto) */
validar_j1:
  ldr r2, =tablero0
  ldrb r3, [r2, r0]          @ cargar caracter origen
  cmp r3, #0x61              @ jugador 1 solo puede mover ranitas 'a'
  bne posiciones_invalidas 
  sub r2, r1, r0             @ calcular diferencia entre destino y origen
  cmp r2, #0x4               @ corresponde a saltar otra ranita
  bgt posiciones_invalidas
  beq validar_salto_j1
  cmp r2, #0x2               @ corresponde a mover ranita
  beq validar_mov_j1
  bne posiciones_invalidas   @ jugador ingreso algo invalido

/* Validaciones para el jugador 2. Se verifica que en la posicion de origen haya una ranita que pertenezca al
   jugador 2. Luego se verifica que tipo de movimiento desea hacer el jugador (movimiento normal o salto) */
validar_j2:
  ldr r2, =tablero0
  ldrb r3, [r2,r0]
  cmp r3, #0x62              @ jugador 2 solo puede mover 'b'
  bne posiciones_invalidas
  sub r2, r0, r1             @ calcular diferencia entre origen y destino
  cmp r2, #0x4               @ corresponde a saltar otra ranita
  bgt posiciones_invalidas
  beq validar_salto_j2
  cmp r2, #0x2               @ corresponde a mover ranita
  beq validar_mov_j2
  bne posiciones_invalidas   @ jugador ingreso algo invalido

/* Validacion de salto de ranita para jugador 1. Para verificar si el salto es valido, se
   revisa que una posicion antes del destino haya una rana de otra especie y que en la
   posicion del destino haya un espacio libre. En caso de que se cumplan estas condiciones,
   se pasa mover las ranitas. */
validar_salto_j1:
  ldr r2, =tablero0
  sub r1, r1, #0x2
  ldrb r3, [r2, r1]
  cmp r3, #0x62              @ una posicion antes del destino debe haber ranita 'b'
  bne posiciones_invalidas
  add r1, r1, #0x2
  ldrb r3, [r2, r1]
  cmp r3, #0x20              @ en el destino debe haber un espacio
  bne posiciones_invalidas
  bal fin_validacion

/* Validacion de movimiento de un espacio de ranita para jugador 1. Unicamente se puede
   mover la ranita si en el destino hay un espacio libre o una ranita de otra especie. */
validar_mov_j1:
  ldr  r2, =tablero0
  ldrb r3, [r2, r1]
  cmp r3, #0x61
  beq posiciones_invalidas
  bal fin_validacion

/* Validacion de salto de ranita para jugador 2. Para verificar si el salto es valido, se
   revisa que una posicion antes del destino haya una rana de otra especie y que en la
   posicion del destino haya un espacio libre. En caso de que se cumplan estas condiciones,
   se pasa mover las ranitas. */
validar_salto_j2:
  ldr r2, =tablero0                    @ direccion inicial de tablero
  add r1, r1, #0x2                     @ direccion de posicion antes del destino
  ldrb r3, [r2,r1]                     @ se carga caracter antes del destino, debe ser una ranita del jugador 1
  cmp r3, #0x61
  bne posiciones_invalidas
  sub r1, r1, #0x2                     @ se regresa a la direccion del destino
  ldrb r3, [r2, r1]                    @ se carga caracter en destino, debe ser un espacio libre
  cmp r3, #0x20
  bne posiciones_invalidas
  bal fin_validacion

/* Validacion de movimiento de un espacio de ranita para jugador 2. Unicamente se puede
   mover la ranita si en el destino hay un espacio libre o una ranita de otra especie. */
validar_mov_j2:
  ldr r2, =tablero0
  ldrb r3, [r2, r1]
  cmp r3, #0x62
  beq posiciones_invalidas
  bal fin_validacion

/* Todas las sub-validaciones terminan aqui, para regresar el control del programa a quien
   llamo a la subrutina validar_posiciones */
fin_validacion:
  pop {pc}

/* Subrutina que muestra un mensaje de error y regresa a game loop (inicio del turno), 
   sin avanzar el turno, para que el jugador pueda seleccionar posiciones validas. */
posiciones_invalidas:
  ldr r0, =msg_pos_invalidas
  bl puts
  pop {lr}                           @ el lr que se pusheo al inicio de validar_posiciones se libera aqui
  bal game_loop

/* Mueve la ranita, se asume que las posiciones han sido validadas anteriormente. 
   Este metodo intercambia los caracteres que estan en las posiciones almacenadas
   en r0 y r1. Basicamente esta subrutina intercambia caracteres. */
mover_ranita:
  push {r4, lr}                 @ guardar valor en r4
  ldr r2, =tablero0
  ldrb r3, [r2, r0]         @ caracter origen
  ldrb r4, [r2, r1]         @ caracter destino
  strb r3, [r2, r1]         @ intercambiar caracteres
  strb r4, [r2, r0]
  pop {r4, pc}

/* Recorre el tablero para verificar si algun jugador gano. Si el jugador 1 acaba de mover una
   ranita, se revisa que en la parte derecha del tablero hayan 5 ranas de su especie, y vice-versa
   para el jugador 2.
   output:
     r0 <- 0 si nadie gano, 1 si gano jugador 1, 2 si gano jugador 2.*/
revisar_tablero:
  push {lr}
  mov r5, #0x5             @ contador para loop
  cmp r4, #0x1
  beq revisar_tablero_j1
  bne revisar_tablero_j2
  revisar_tablero_j1:
    ldr r0, =tablero0
    add r0, r0, #0xD
    loop_j1:
      ldrb r1, [r0], #0x2  @ cargar caracter y avanzar en el tablero
      cmp r1, #0x61        @ comparar con ranita de jugador 1
      bne sin_ganador      @ si la ranita no es del jugador 1, no ha ganado
      subs r5, r5, #0x1    @ restar el contador y continuar el loop
      bgt loop_j1
      mov r0, #0x1         @ en r0 se retorna un 1 para indicar que gano el jugador 1
      bal fin_revisar
  revisar_tablero_j2:
    ldr r0, =tablero0
    add r0, r0, #0x1
    loop_j2:
      ldrb r1, [r0], #0x2
      cmp r1, #0x62
      bne sin_ganador
      subs r5, r5, #0x1
      bgt loop_j2
      mov r0, #0x2
      bal fin_revisar      @ en r0 se retorna 2 para indicar que gano el jugador 2
  sin_ganador:
    mov r0, #0x0           @ si nadie gano se devuelve un 0 en r0
  fin_revisar:
    pop {pc}               @ regresar control de programa

/* Transforma las posiciones ingresadas por el jugador a posiciones validas, ya que
   se debe tomar en cuenta los caracteres separadores del tablero. Por ejemplo si el
   jugador quiere mover la ranita en la posicion 5, el caracter correspondiente a esta
   ranita esta a 9 caracteres del primer caracter del arreglo del tablero.
   input:
     r0 :pos0
     r1 :pos1
   output:
     r0 <- pos0 transformada
     r1 <- pos1 transformada */
transformar_posiciones:
  push {lr}
  mov r2, #0x2
  mul r0, r0, r2
  mul r1, r1, r2
  sub r0, r0, #0x1
  sub r1, r1, #0x1
  pop {pc}

/* Metodo de ayuda que unicamente cambia el valor de r4 para representar el turno
   del nuevo jugador, y vuelve a entrar el loop principal del juego. */
fin_turno:
  cmp r4, #0x1
  addeq r4, r4, #0x1
  subne r4, r4, #0x1
  bal game_loop

gano_jugador_1:
  bl imprimir_felicitacion
  bal fin_juego

gano_jugador_2:
  bl imprimir_felicitacion
  bal fin_juego

imprimir_titulo:
  push {lr}
  ldr r0, =titulo
  bl printf
  pop {pc}

imprimir_logo:
  push {lr}
  ldr r0, =logo_ranitas
  bl printf
  pop {pc}

imprimir_felicitacion:
  push {lr}
  mov r1, r0
  ldr r0, =felicitacion
  bl printf
  pop {pc}

fin_juego:
  mov r7, #1
  svc 0

.data
  tablero_titulo: .asciz "******** Tablero ********"
  tablero0: .asciz "|a|a|a|a|a| |b|b|b|b|b|"
  tablero1: .asciz "|1|2|3|4|5|6|7|8|9|10|11|"
  msg_turno_jugador: .asciz "Turno de jugador %d\n"
  msg_ing_pos1: .asciz "Seleccione su ranita: "
  msg_ing_pos2: .asciz "Ingrese destino de ranita: "
  msg_pos_invalidas: .asciz "Posiciones invalidas, ingrese de nuevo..."
  fmt_entero: .asciz "%d"
  pos0: .word 0
  pos1: .word 0
  logo_ranitas: .asciz "                           :. .do/\n                         `oh`  `:ho/.\n                       `:yho/:ydyssydh-\n                      +mhsssydyhhyyyosm/\n                     .Myyyyyyyo-----/smy\n               .-::.``my:-..-+.......-om``-:-.\n             /hhyyyhhdh....-:/:+.......ddhyyyhh/\n            /Noooossssh-...:s+/y......:hyyysooom+\n            +Noooossdoos+///+ss+::-:/+soshooooohh\n            `myooooosyssssssooosssssssssysoooosm:\n             -hhsoooooooosssssssssssoooo+oooshh:\n              `/yhyso+oooooooooooooo+o++osymm/`\n         `....`  ./omhyssssoooooosssyyhhys+ydh:\n        shhsssyys/./moosshdmNNNNNNNNNmyoooooo+do   `....``\n       .Mos:::+sysdNsoosooosyhhhhhysooosoosoo//mo+syssshyys-\n       -Moooooooooodooohoooooo++ooooooosyoohooshdyo//+oooohm\n        my+oooooooshoohyooo/::---::/oooodoosysysoooooooooohd\n        :m+ooossooshoodso+:---------:/ooyhoodoooooooooo+oym-\n         :myooooyyodo+yh/-------------:osdoodoosyyooos/+hy.\n          -hdsooosdshood:--------------/hhoyyohhsooosyho-\n    `./osyyyNNdsoooyydysh/-------------/mosmdhsosyhmNms+-`\n  `/hNNNmdyooosyyssooshdhhs::-------::shohdyosssyssyhdmNNh-\n /so/omNdhdhsooooosshdhhsosyyo/:::+ohhsoosyhysoooydddhdNd.\n`` -ss+/:mNhhdhyso+NNdMddNmdy+osyso/hdhmymmdNdsyhdhdN+-:+o`\n        syo:.      s`omo:Mh.        -Mm:hM-`/o   `:+yd\n                     `  .o           /`  /\n"
  titulo: .asciz " ____ ____ ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ ____ \n||R |||a |||n |||i |||t |||a |||s |||       |||L |||o |||c |||a |||s ||\n||__|||__|||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__|||__||\n|/__\\|/__\\|/__\\|/__\\|/__\\|/__\\|/__\\|/_______\\|/__\\|/__\\|/__\\|/__\\|/__\\|\n"
  felicitacion: .asciz "___ _ ____ ____ ____ ____ ____ ____ _________ ____ _________ ____ ____ ____ ____ ____ ____ ____ ____ \n||J |||u |||g |||a |||d |||o |||r |||       |||%d |||       |||g |||a |||n |||a |||s |||t |||e |||! ||\n||__|||__|||__|||__|||__|||__|||__|||_______|||__|||_______|||__|||__|||__|||__|||__|||__|||__|||__||\n|/__\\|/__\\|/__\\|/__\\|/__\\|/__\\|/__\\|/_______\\|/__\\|/_______\\|/__\\|/__\\|/__\\|/__\\|/__\\|/__\\|/__\\|/__\\|\n"
