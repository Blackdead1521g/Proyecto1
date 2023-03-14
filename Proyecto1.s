 /* Archivo: Postlab05.s
 * Dispositivo: PIC16F887
 * Autor: Kevin Alarcón
 * Compilador: pic-as (v2.30), MPLABX V6.05
 * 
 * 
 * Programa: Presionar RB6 o RB7 para incrementar o decrementar un contador y mostrarlo en tres displays multiplexados en unidades, decenas y centnas
 * Hardware: Push en RB6 y RB7, displays en puerto C
 * 
 * Creado: 20 de feb, 2023
 * Última modificación: 23 de feb, 2023
 */
    
    PROCESSOR 16F887
    #include <xc.inc>
    
    ;configuración wor 1
    CONFIG FOSC=INTRC_NOCLKOUT //Oscilador Interno sin salidas
    CONFIG WDTE=OFF //WDT disabled (reinicio repetitivo del pic)
    CONFIG PWRTE=OFF //PWRT enabled (espera de 72ms al iniciar)
    CONFIG MCLRE=OFF //El pin de MCLR se utiliza como I/0
    CONFIG CP =OFF //Sin protección de código
    CONFIG CPD=OFF //Sin protección de datos
    
    CONFIG BOREN=OFF //Sin reinicio cúando el voltaje de alimentación baja de 4V
    CONFIG IESO=OFF //Reinicio sin cambio de reloj de interno a externo
    CONFIG FCMEN=OFF //Cambio de reloj externo a interno en caso de fallo
    CONFIG LVP=OFF //Programación en bajo voltaje permitida
    
    ;configuración word 2
    CONFIG WRT=OFF //Protección de autoescritura por el programa desactivada
    CONFIG BOR4V=BOR40V //Programación abajo de 4V, (BOR21V=2 . 1V)
    
    UP1 EQU 4
    DOWN1 EQU 5
    UP EQU 6
    DOWN EQU 7
  
    ;--------------------------MACROS------------------------------
    restart_TMR0 macro 
	banksel TMR0 ;Nos ubicamos en el banco donde está TMR0
	movf NTMR0, W;Cargamos al acumulador el valor que se le pondrá al TMR0
	movwf TMR0 ;Cargamos el valor N calculado para un desborde de 10mS
	bcf T0IF ;Colocamos en cero la bandera del TMR0
    endm
    
    PSECT udata_bank0; common memory
	count: DS 2 ;2 byte
	count1: DS 2 ;2 byte
	banderas: DS 1 ;1 bytes
	display: DS 4 ;3 bytes
	unidades: DS 2 ;2 bytes
	decenas: DS 2 ;2 bytes
	centenas: DS 2 ;2 bytes
	millares: DS 2 ;2 bytes
	NTMR0: DS 1
	Fint: DS 1 ;Frecuencia de interrupción
	BanderaCuadrada: DS 1
	BanderaTriangular: DS 1
	dient: DS 1
	contador: DS 1
	selector_graf: DS 1
	Prescaler: DS 1
	BanderaPresc: DS 1
	BanderaGraf: DS 1
	BanderaFrec: DS 1
	
 
    PSECT udata_shr
 	W_TEMP: DS 1 ;1 byte
    	STATUS_TEMP: DS 1 ;1 byte
    
    ;--------------------------vector reset------------------------
    PSECT resVect, class=CODE, abs, delta=2
    ORG 00h ;posición 0000h para el reset
    resetVec:
	PAGESEL main
	goto main
    ;--------------------------Vector interrupción-------------------
    PSECT intVECT, class=CODE, abs, delta=2
    ORG 0004h
    push: 
	movwf W_TEMP ;Movemos lo que hay en el acumulador al registro
	swapf STATUS, W ;Intercambiamos los bits del registro STATUS y lo metemos al acumulador
	movwf STATUS_TEMP ;Movemos lo que hay en el acumulador al registro
    isr: 
        BANKSEL PORTB
	btfsc RBIF ;Verificamos si alguno de los puertos de B cambiaron de estado
	call int_iocb ;Si, sí cambió de estado, llamamos a nuestra función 
	btfsc T0IF ;Verificamos si la bandera del TMR0 está encendida
	call int_t0 ;Si, Sí está encendida la bandera del TMR0 llamamos a nuestra función
    pop:
	swapf STATUS_TEMP, W ;Intercambiamos los bits del registro STATUS_TEMP y lo metemos al acumulador
	movwf STATUS ;Movemos lo que hay en el acumulador al registro
	swapf W_TEMP, F ;Intercambiamos los bits del registro y lo metemos al mismo registro
	swapf W_TEMP, W ;Intercambiamos los bits del registro y lo metemos al acumulador
	retfie ;Carga el PC con el valor que se encuentra en la parte superior de la pila, asegurando así la vuelta de la interrupción
    
    PSECT code, delta=2, abs
    ORG 100h  ;posición para el código
    table:
	clrf PCLATH
	bsf PCLATH, 0 ;PCLATH en 01
	andlw 0X0F ;
	addwf PCL ;PC = PCLATH + PCL | Sumamos W al PCL para seleccionar una dato de la tabla
	retlw 00111111B ;0
	retlw 00000110B ;1
	retlw 01011011B ;2
	retlw 01001111B ;3
	retlw 01100110B ;4
	retlw 01101101B ;5
	retlw 01111101B ;6
	retlw 00000111B ;7
	retlw 01111111B ;8
	retlw 01101111B ;9
	retlw 01110111B ;A
	retlw 01111100B ;B
	retlw 00111001B ;C
	retlw 01011110B ;D
	retlw 01111001B ;E
	retlw 01110001B ;F
    
    table_NTMR0128:
	clrf PCLATH
	bsf PCLATH, 0 ;PCLATH en 01
	andlw 0XFF ;Preguntar al profe por el límite de tabla
	addwf PCL ;PC = PCLATH + PCL | Sumamos W al PCL para seleccionar una dato de la tabla
	;Prescaler 1:128
	retlw 00000000B ;0 Hz
	retlw 01100100B //100 ;100Hz
	retlw 10110010B //178 ;200Hz
	retlw 11001100B //204 ;300Hz
	retlw 11011001B //217 ;400Hz
	;Prescaler 1:16
	retlw 00000110B ;6 - 500 Hz
	retlw 00110000B ;48 - 600 Hz
	retlw 01001110B ;78 - 700 Hz
	retlw 01100100B ;100 - 800 Hz
	retlw 01110101B ;117 - 900 Hz
	;Prescaler 1:8
	retlw 00000110B ;6 - 1000Hz
	retlw 00011101B ;29 - 1100Hz
	retlw 00110000B ;48 - 1200Hz
	retlw 01000000B ;64 - 1300Hz
	retlw 01001110B ;78 - 1400Hz
	retlw 01011001B ;89 - 1500Hz
	retlw 01100100B ;100 - 1600Hz
	retlw 01101101B ;109 - 1700Hz
	retlw 01110101B ;117 - 1800Hz
	retlw 01111101B ;125 - 1900Hz
	;Prescaler 1:4
	retlw 00000110B ;6 - 2000Hz
	retlw 00010010B ;18 - 2100Hz
	retlw 00011101B ;29 - 2200Hz
	retlw 00100111B ;39 - 2300Hz
	retlw 00110000B ;48 - 2400Hz
	retlw 00111000B ;56 - 2500Hz
	retlw 01000000B ;64 - 2600Hz
	retlw 01000111B ;71 - 2700Hz
	retlw 01001110B ;78 - 2800Hz
	retlw 01010100B ;84 - 2900Hz
	retlw 01011001B ;89 - 3000Hz
	retlw 01011111B ;95 - 3100Hz
	retlw 01100100B ;100 - 3200Hz
	retlw 01101001B ;105 - 3300Hz
	retlw 01101101B ;109 - 3400Hz
	retlw 01110001B ;113 - 3500Hz
	retlw 01110101B ;117 - 3600Hz
	retlw 01111001B ;121 - 3700Hz
	retlw 01111100B ;124 - 3800Hz
	retlw 10000000B ;128 - 3900Hz
	;Prescaler 1:2
	retlw 00000110B ;6 - 4000Hz
	retlw 00001100B ;12 - 4100Hz
	retlw 00010010B ;18 - 4200Hz
	retlw 00010111B ;23 - 4300Hz
	retlw 00011101B ;29 - 4400Hz
	retlw 00100010B ;34 - 4500Hz
	retlw 00100111B ;39 - 4600Hz
	retlw 00101011B ;43 - 4700Hz
	retlw 00110000B ;48 - 4800Hz
	retlw 00110100B ;52 - 4900Hz
	retlw 00111000B ;56 - 5000Hz
	//retlw B ;0Hz

    ;---------------------configuración----------------
    main:
	call config_io ;Llamamos a nuestra subrutina config_io para configurar los pines antes de ejecutar el código
	call config_reloj ;Llamamos a nuestra subrutina config_reloj para configurar la frecuencia del reloj antes de ejecutar el código
	call config_TMR0 ;Llamamos a nuestra función para configurar el TMR0
	call config_iocb ;Llamamos a nuestra función que habilita las interrupciones en el puerto B
	call config_int_enable ;Llamamos a nuestra función que habilita las interrupciones en general
	banksel PORTA ;Se busca el banco en el que está PORTA
	
    
    ;-----------------------loop principal---------------
    loop:
	movf contador, W
	movwf count
	movf BanderaFrec, W
	movwf PORTE
	call preparar_display ;Llamamos a nuestra función que le asigna cada valor a su respectivo display
	
	;Limpiamos las variables que utilizaremos para guardar los valores del contador en cada loop
	clrf unidades 
	clrf decenas
	clrf centenas
	clrf millares
	
	//call conv_millares
	//call conv_centenas ;Llamamos a nuestra función que convierte el valor a centenas
	call conv_decenas ;Llamamos a nuestra función que convierte el valor a decenas
	call conv_unidades ;Llamamos a nuestra función que convierte el valor a unidades
	goto loop ; loop forever
	
    ;----------------------Sub rutinas------------------
    config_iocb: ;Función para habilitar las interrupciones en el puerto B
	banksel TRISB ;Nos ubicamos en el banco del TRISB
	bsf IOCB, UP ;Habilitamos la interrupción al cambiar el estado de RB6
	bsf IOCB, DOWN ;Habilitamos la interrupción al cambiar el estado de RB7
	bsf IOCB, UP1 ;Habilitamos la interrupción al cambiar el estado de RB6
	bsf IOCB, DOWN1 ;Habilitamos la interrupción al cambiar el estado de RB7
	bsf IOCB, 0 ;Habilitamos la interrupción al cambiar el estado de RB0
	
	banksel PORTB 
	movf PORTB, W ;al leer termina la condición de mismatch
	bcf RBIF ;Ponemos en cero el cambio de estado para que se reinicie la verificación
	return ;Retornamos de nuestra función
	
    config_io: ;Función para configurar los puertos de entrada/salida
	bsf STATUS, 5 ;banco 11
	bsf STATUS, 6 ;Nos dirigimos al banco 3 porque ahí se encuentran las instrucciones ANSEL y ANSELH
	clrf ANSEL ;pines digitales
	clrf ANSELH
    
	bsf STATUS, 5 ;banco 01
	bcf STATUS, 6 ;Nos dirigimos al banco 1 porque ahí se encuentran lo configuración de los puertos
	
	;Configuramos los bits que usaremos como entradas del PORTB
	bsf TRISB, UP
	bsf TRISB, DOWN
	bsf TRISB, UP1
	bsf TRISB, DOWN1
	bsf TRISB, 0
	
	;Configuramos las salidas
	//movlw 0b00000000
	clrf TRISA
	clrf TRISD
	clrf TRISC
	clrf TRISE
	
	bcf OPTION_REG, 7 ;Habilitamos Pull ups
	bsf WPUB, UP
	bsf WPUB, DOWN
	bsf WPUB, 0
	
	;Nos dirigimos al banco 0 en donde se encuentran los puertos y procedemos a limpiar cada puerto después de cada reinicio
	bcf STATUS, 5 ;banco00
	bcf STATUS, 6 
	clrf banderas
	clrf BanderaCuadrada
	clrf BanderaTriangular
	clrf BanderaGraf
	clrf BanderaPresc
	clrf BanderaFrec
	clrf dient
	clrf count
	clrf count1
	clrf display
	clrf NTMR0
	clrf PORTD
	clrf PORTC
	clrf PORTE
	clrf PORTA
	return ;Retorna a donde fue llamada esta función

    conv_millares: ;Esta función nos sirve para extraer las centenas de nuestro contador 
	movlw 1000 ;Movemos 100 al acumulador
	subwf count, F ;Le restamos a nuestra variable de contador los 100 del acumulador y lo guardamos en el registro
	incf millares ;Incrementamos centenas
	btfsc STATUS, 0 ;Revisamos si queda un acarreo después de la resta
	goto $-4 ;Si queda algún acarreo del bit mas significativo volvemos a repetir el procedimiento anterior
	decf millares ;Si no queda ningún acarreo, esto significa que pasamos a un valor negativo por lo tanto le decrementamos el valor
		      ; a que le habíamos incrementado a centenas inicialmente
	movlw 1000 ;Movemos 100 al acumulador 
	addwf count, F ;Le ingresamos dicho número a nuestra variable contador por si en dado caso queda negativa nuestra variable
	return

    conv_centenas: ;Esta función nos sirve para extraer las centenas de nuestro contador 
	movlw 100 ;Movemos 100 al acumulador
	subwf count, F ;Le restamos a nuestra variable de contador los 100 del acumulador y lo guardamos en el registro
	incf centenas ;Incrementamos centenas
	btfsc STATUS, 0 ;Revisamos si queda un acarreo después de la resta
	goto $-4 ;Si queda algún acarreo del bit mas significativo volvemos a repetir el procedimiento anterior
	decf centenas ;Si no queda ningún acarreo, esto significa que pasamos a un valor negativo por lo tanto le decrementamos el valor
		      ; a que le habíamos incrementado a centenas inicialmente
	movlw 100 ;Movemos 100 al acumulador 
	addwf count, F ;Le ingresamos dicho número a nuestra variable contador por si en dado caso queda negativa nuestra variable
	return

    conv_decenas: ;Esta función nos sirve para extraer las decenas de nuestro contador 
	movlw 10 ;Movemos 10 al acumulador
	subwf count, F ;Le restamos a nuestra variable de contador los 10 del acumulador y lo guardamos en el registro
	incf decenas ;Incrementamos decenas
	btfsc STATUS, 0 ;Revisamos si queda un acarreo después de la resta
	goto $-4 ;Si queda algún acarreo del bit mas significativo volvemos a repetir el procedimiento anterior
	decf decenas ;Si no queda ningún acarreo, esto significa que pasamos a un valor negativo por lo tanto le decrementamos el valor
		     ; a que le habíamos incrementado a decenas inicialmente
	movlw 10 ;Movemos 10 al acumulador
	addwf count, F  ;Le ingresamos dicho número a nuestra variable contador por si en dado caso queda negativa nuestra variable
	return
	
    conv_unidades: ;Esta función nos sirve para extraer las unidades de nuestro contador
	movlw 1 ;Movemos 1 al acumulador
	subwf count, F ;Le restamos a nuestra variable de contador el 1 del acumulador y lo guardamos en el registro
	incf unidades ;Incrementamos unidades
	btfsc STATUS, 0 ;Revisamos si queda un acarreo después de la resta
	goto $-4 ;Si queda algún acarreo del bit mas significativo volvemos a repetir el procedimiento anterior
	decf unidades ;Si no queda ningún acarreo, esto significa que pasamos a un valor negativo por lo tanto le decrementamos el valor
		      ; a que le habíamos incrementado a unidades inicialmente
	movlw 1 ;Movemos 1 al acumulador
	addwf count, F ;Le ingresamos dicho número a nuestra variable contador por si en dado caso queda negativa nuestra variable
	return
	
    preparar_display: ;Esta función configura cada valor en su respectivo display
	;Los primeros 2 displays se quedaran con 0
	//movf millares, W
	movlw 0
	call table
	movwf display+3
	
	//movf centenas, W ;Movemos decenas al acumulador
	movlw 0
	call table ;Mandamos a llamar a la tabla y extraemos un valor
	movwf display+2 ;Movemos el valor extraido a nuestra variable display
	
	;Este será el tercer display donde irán las millares del contador
	movf decenas, W ;Movemos centenas al acumulador
	call table ;Mandamos a llamar a la tabla y extraemos un valor
	movwf display+1 ;Movemos el valor extraido a nuestra variable display+1
	
	;Este será el cuarto display donde irán las centenas del contador
	movf unidades, W ;Movemos unidades al acumulador
	call table ;Mandamos a llamar a la tabla y extraemos un valor
	movwf display ;Movemos el valor extraido a nuestra variable display+2
	return 
	
	
    config_reloj:
	banksel OSCCON ;Nos posicionamos en el banco en donde esté el registro OSCCON para configurar el reloj
	;Esta configuración permitirá poner el oscilador a 8 MHz
	bsf IRCF2 ;OSCCON 6 configuramos el bit 2 del IRCF como 1
	bsf IRCF1 ;OSCCON 5 configuramos el bit 1 del IRCF como 1
	bsf IRCF0 ;OSCCON 4 configuramos el bit 0 del IRCF como 1
	bsf SCS ;reloj interno 
	return ;Retorna a donde fue llamada esta función
	
    config_TMR0:
	banksel OPTION_REG
	bcf OPTION_REG, 5 ;Seleccionamos TMR0 como temporizador
	bcf OPTION_REG, 3 ;Asignamos PRESCALER a TMR0
	bsf OPTION_REG, 2 
	bsf OPTION_REG, 1
	bcf OPTION_REG, 0 ;Prescaler de 256 con configuración 111
	restart_TMR0 ;Reiniciamos el TMR0 con nuestra función
	return ;Retorna a donde fue llamada esta función

    config_int_enable:
	bsf T0IE ;INTCON ;Habilitamos la interrupción del TMR0
	bcf T0IF ;INTCON ;Ponemos en cero la bandera del TMR0
	bsf GIE ;INTCON ;Habilitamos las interrupciones en general
	bsf RBIE ;INTCON ;Habilitamos la interrupción del cambio en el puerto B
	bcf RBIF ;INTCON ;Ponemos en cero la bandera del cambio de estado para que se reinicie la verificación
	return
	
    int_t0:
	restart_TMR0 ;Reiniciamos el TMR0
	/*incf count1 ;Incrementamos la variable de nuestro contador del TMR0
	movf count1, W ;Movemos nuestra variable al acumulador
	sublw 10 ;A 100 le restamos lo que hay en el acumulador y lo gradamos en el acumulador
	btfss ZERO ;STATUS, 2 ;verificamos si la bandera de Zero se activa
	return ;Sino se activa retornamos de la función porque queremos que se ejecute solo cuando hayan pasado 1000ms (1s)
	clrf count1*/
	//incf PORTA
	//btfsc BanderaGraf, 0
	//incf PORTA
	call Graf_Selection
	//call GrafCuadrada
	call display_selections ;Llamos a nuestra función de selección de display
	return
    
    Graf_Selection:
	btfsc BanderaGraf, 0
	call GrafTriangular
	btfss BanderaGraf, 0
	call GrafCuadrada
	return
    
    GrafCuadrada:
	incf count1 ;Incrementamos la variable de nuestro contador del TMR0
	movf count1, W ;Movemos nuestra variable al acumulador
	sublw 10 ;A 100 le restamos lo que hay en el acumulador y lo gradamos en el acumulador
	btfss ZERO ;STATUS, 2 ;verificamos si la bandera de Zero se activa
	return ;Sino se activa retornamos de la función porque queremos que se ejecute solo cuando hayan pasado 1000ms (1s)*/
	clrf count1
	btfsc BanderaCuadrada, 0
	goto caida
	goto subida
	
    subida:
	movlw 0b11111111
	movwf PORTA
	goto toggle_b0
	
    caida:
	clrf PORTA

    toggle_b0:
	movlw 0x01
	xorwf BanderaCuadrada, F
	return
	
    GrafTriangular:
	btfsc BanderaTriangular, 0
	goto $+8
	incf PORTA
	movf PORTA, W
	sublw 254
	btfss ZERO
	goto $+6
	bsf BanderaTriangular, 0
	goto $+2
	decfsz PORTA, 1
	goto $+2
	clrf BanderaTriangular
	return
	
    display_selections:
	;Limpiamos los bits utilizador el puerto E
	bcf PORTD, 0
	bcf PORTD, 1
	bcf PORTD, 2
	bcf PORTD, 3
	
	
	btfss banderas, 0
	goto display_0 ;Si no se activa saltamos a la función display_1
	btfsc banderas, 1 ;Verificamos si el bit 0 de banderas se activa
	goto display_1 ;Si se activa saltamos a la función display_0
	btfsc banderas, 2 ;Verificamos si el bit 1 de banderas se activa
	goto display_2 ;Si se activa saltamos a la función display_2
	btfsc banderas, 3
	goto display_3
	
    display_0:
	movf display+2, W ;Movemos nuestra variable display al acumulador
	movwf PORTC ;Movemos este valor al puerto C
	bsf PORTD, 0 ;Activamos el bit 1 que activará su respectivo display
	bsf banderas, 1 ;Ponemos en 1 el bit 1 de banderas
	bsf banderas, 0
	return
	
    display_1:
	movf display+3, W ;Movemos nuestra variable display+1 al acumulador
	movwf PORTC ;Movemos este valor al puerto C
	bsf PORTD, 1 ;Activamos el bit 0 que activará su respectivo display
	bcf banderas, 1 ;Ponemos en 1 el bit 0 de banderas
	bsf banderas, 2
	return
	
    display_2:
	movf display, W ;Movemos nuestra variable display+2 al acumulador
	movwf PORTC ;Movemos este valor al puerto C
	bsf PORTD, 2 ;Activamos el bit 2 que activará su respectivo display
	bcf banderas, 2 ;Ponemos en 0 el bit 1 de banderas
	bsf banderas, 3 ;Ponemos en 0 el bit 2 de banderas
	return
    
    display_3:
	movf display+1, W ;Movemos nuestra variable display+2 al acumulador
	movwf PORTC ;Movemos este valor al puerto C
	bsf PORTD, 3 ;Activamos el bit 2 que activará su respectivo display
	bcf banderas, 0 ;Ponemos en 0 el bit 0 de banderas
	bcf banderas, 3 ;Ponemos en 0 el bit 2 de banderas
	return
    
    int_iocb:
	banksel PORTB ;Nos ubicamos en el banco del purto B
	clrf BanderaPresc
	//bsf BanderaFrec, 0
	
	;Mode_Graf
	btfsc PORTB, 0
	goto $+4
	movlw 0x01
	xorwf BanderaGraf, F
	clrf PORTA
	
	;Mode_Frec
	btfsc PORTB, UP1 ;Hz revisamos si esta oprimido el botón de Hz
	goto $+3 ;Sino está oprimido nos saltamos a la siquieren comprobación
	movlw 1 ;Si está oprimido le ingresamos 1 a la bandera de frecuencia para que se encienda el bit 0
	movwf BanderaFrec
	btfsc PORTB, DOWN1 ;KHz revisamos si esta oprimido el botón de KHz
	goto $+3 ;Sino está oprimido nos saltamos a la siquieren comprobación
	movlw 2 ;Si está oprimido le ingresamos 2 a la bandera de frecuencia para que se encienda el bit 1
	movwf BanderaFrec
	
	;Mode_INC_DEC
	btfsc	PORTB, UP ;Al estar en pullup normalmente el boton está en 1, así que verificamos si está en 1 (desoprimido) o en 0 (oprimido
			;el bit 6 del puerto B
	goto $+8 ;Sino está oprimido nos saltamos a la siquieren comprobación
	btfsc BanderaFrec, 0 ;Revisamos el bit 0 de la bandera de frecuencia para ver si estamos en HZ
	incf contador ;Si está prendido, incrementamos el contador en 1 ya que queremos ir de 100 en 100Hz
	btfss BanderaFrec, 1 ;Revisamos el bit 1 de la bandera de frecuencia para ver si estamos en KHZ
	goto $+4 ;Sino está encendido nos saltamos a la siquieren comprobación
	incf contador ;Si está prendido incrementamos en 1 el contador y le sumamos 4 para que vaya incrementando de 500 en 500Hz
	movlw 4
	addwf contador, F
	
	btfsc	PORTB, DOWN ;Al estar en pullup normalmente el boton está en 1, así que verificamos si está en 1 (desoprimido) o en 0 (oprimido
			;el bit 6 del puerto B
	goto $+8 ;Sino está oprimido nos saltamos a la siquieren comprobación
	btfsc BanderaFrec, 0 ;Revisamos el bit 0 de la bandera de frecuencia para ver si estamos en HZ
	decf contador ;Si está prendido, decrementamos el contador en 1 ya que queremos ir de 100 en 100Hz
	btfss BanderaFrec, 1 ;Revisamos el bit 1 de la bandera de frecuencia para ver si estamos en KHZ
	goto $+4 ;Sino está encendido nos saltamos a la siquieren comprobación
	decf contador ;Si está prendido decrementamos en 1 el contador y le sumamos 4 para que vaya decrementando de 500 en 500Hz
	movlw 4
	subwf contador, F
	
	movf contador, W
	sublw 4
	btfsc STATUS, 0
	goto $+17
	movf contador, W
	sublw 9
	btfsc STATUS, 0
	goto $+15
	movf contador, W
	sublw 19
	btfsc STATUS, 0
	goto $+13
	movf contador, W
	sublw 39
	btfsc STATUS, 0
	goto $+11
	movf contador, W
	sublw 50
	btfsc STATUS, 0
	goto $+9

	
	bsf BanderaPresc, 0
	goto $+8
	bsf BanderaPresc, 1
	goto $+6
	bsf BanderaPresc, 2
	goto $+4
	bsf BanderaPresc, 3
	goto $+2
	bsf BanderaPresc, 4
	
	btfsc BanderaPresc, 0
	call Presc128
	btfsc BanderaPresc, 1
	call Presc16
	btfsc BanderaPresc, 2
	call Presc8
	btfsc BanderaPresc, 3
	call Presc4
	btfsc BanderaPresc, 4
	call Presc2
	bcf RBIF
	return ;Retornamos de nuestra función

    Presc128:
	movlw 00010110B
	banksel OPTION_REG
	movwf OPTION_REG
	banksel PORTB
	movf contador, W
	call table_NTMR0128
	movwf NTMR0
	return

    Presc16:
	movlw 00010011B
	banksel OPTION_REG
	movwf OPTION_REG
	banksel PORTB
	movf contador, W
	call table_NTMR0128
	movwf NTMR0
	return

    Presc8:
	movlw 00010010B
	banksel OPTION_REG
	movwf OPTION_REG
	banksel PORTB
	movf contador, W
	call table_NTMR0128
	movwf NTMR0
	return
	
    Presc4:
	movlw 00010001B
	banksel OPTION_REG
	movwf OPTION_REG
	banksel PORTB
	movf contador, W
	call table_NTMR0128
	movwf NTMR0
	return
	
    Presc2:
	movlw 00010000B
	banksel OPTION_REG
	movwf OPTION_REG
	banksel PORTB
	movf contador, W
	call table_NTMR0128
	movwf NTMR0
	return
    END