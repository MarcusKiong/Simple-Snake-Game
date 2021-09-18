INCLUDE Irvine32.inc

encryption PROTO C, val: BYTE, key: WORD 
validatePosition PROTO C,  xPosarr: BYTE,yPosarr: BYTE, xFoodPos: BYTE, yFoodPos: BYTE
getSpeed PROTO C
gameOverValidation	PROTO C

.data
encryptionkey WORD 3
username BYTE "admin",0
password BYTE "^pjfp`lli",0			; encrypted password for "asmiscool"
pwLength DWORD 9

myUserInput BYTE 10 dup(?)
myPasswordInput BYTE 30 dup(?)
encryptedPWinput BYTE 30 dup(?)

promptUser BYTE "Enter your Username: ",0
promptPassword BYTE "Enter your password: ",0

invalid BYTE "Incorrect Username/Password. Proceed To Enter Again In 3 Seconds",0
valid BYTE "Correct Username and Password. Entering Game In 3 Seconds...",0
loginflag BYTE 0


xWall BYTE 52 DUP("#"),0

strScore BYTE "Your score is: ",0
score BYTE 0
highScore BYTE 0

strTryAgain BYTE "Try Again?  1=yes, 0=no",0
invalidInput BYTE "invalid input",0
strGameOver BYTE "Game Over ",0
strCurrentScore BYTE "Your Score: ",0
strHighScore BYTE "High Score: ",0
blank BYTE "                                     ",0

snake BYTE "X", 104 DUP("x")

xPos BYTE 45,44,43,42,41, 100 DUP(?)
yPos BYTE 15,15,15,15,15, 100 DUP(?)

xPosWall BYTE 34,34,85,85			;position of upperLeft, lowerLeft, upperRight, lowerRight wall 
yPosWall BYTE 5,24,5,24

xFoodPos BYTE ?
yFoodPos BYTE ?

inputChar BYTE "+"					; + denotes the start of the game
lastInputChar BYTE "+"				

strSpeed BYTE "Speed (1-fast, 2-medium, 3-slow): ",0
speed	DWORD 0

.code
mainAsm PROC C

	cmp loginflag, 1
	je StartLoopGame
	jne inputUsername

inputUsername:
	mov edx, OFFSET promptUser	
	Call WriteString							;Output the Prompt

	mov ecx, 10									;maximum amount of chracter to be stored (and display if needed)
	mov edx, OFFSET myUserInput	
	Call ReadString								;Read Input Of Username

	INVOKE Str_compare,							;Compare Both Username Strings
		ADDR username,
		ADDR myUserInput

		je correctUser							;Jump If Strings Are Equal
		jne incorrectUser						;Jump If Strings Are Not Equal


	correctUser:
		mov edx, OFFSET promptPassword	
		Call WriteString						;Output Password Prompt

		mov ecx, 30								;maximum amount of chracter to be stored (or display if needed)
		mov edx, OFFSET myPasswordInput
		Call ReadString							;Read Input Of Password

		cmp eax, pwLength						; compare length of input and the length of the correct password
		jne incorrectPass						; password length not same (incorrect password)

		mov esi, 0								; loop input starting from index 0
		encryptInput:  
		INVOKE encryption,myPasswordInput[esi], encryptionkey 						; encrypt it	
		mov encryptedPWinput[esi], al		; move the encrypted input into variable encryptedPWinput
		cmp  al, password[esi]				; compare the encrypted input with the correct password
		jne incorrectPass					; password not the same as input (incorrect password)
		inc esi								; increment esi to check for the next index at the next iteration
		cmp esi, pwLength					; reloop if esi is not the index of the last character
		jb encryptInput

		jmp correctPass						; password is correct
	ret

	incorrectUser:
		mov edx, OFFSET promptPassword	
		Call WriteString						;Output Password Prompt

		mov ecx, 10								;maximum amount of chracter to be stored (or display if needed)
		mov edx, OFFSET myPasswordInput
		Call ReadString							;Read Input Of Password
		
		Call InvalidUserPass						;UserName Already Wrong, Straight Away Invalid
	ret							
		
	correctPass:
		Call Crlf
		mov edx, OFFSET valid
		Call WriteString						;Output Valid Username and Password
		mov eax, 2000							;Delay For 2 Seconds
		Call Delay	
		Call Clrscr
		mov loginflag, 1						;Sucesfull Login, do not display login again
		CALL StartLoopGame							;Proceed To Call Game Functions
	ret

	incorrectPass:
		Call InvalidUserPass		
	
	InvalidUserPass:
		Call Crlf
		mov edx, OFFSET invalid
		Call WriteString						;Output Invalid Username/Password

		mov eax, 2000							;Delay For 2 Seconds
		call Delay	
		Call Clrscr								;Clear Screen After 2 Seconds
		jmp inputUsername						;Input Again
		ret

StartLoopGame::
	call DrawWall			;draw walls
	call DrawScoreboard		;draw scoreboard
	call ChooseSpeed		;let snake to choose Speed

	mov esi,0
	mov ecx,5
drawInitialSnake:
	call DrawSnake			;draw snake(start with 5 units)
	inc esi
loop drawInitialSnake

	call Randomize
	call CreateRandomFood
	call DrawFood			;set up finish

	gameLoop::
		mov dl,106						;move cursor to coordinates
		mov dh,1
		call Gotoxy

		; get user key input
		call ReadKey
        jz checkInput						;jump if no key is entered
		processInput:
		mov bl, inputChar
		mov lastInputChar, bl
		mov inputChar,al				;assign variables

		checkInput:
		cmp inputChar,"x"	
		je exitgame						;exit game if user input x
		cmp inputChar,"w"
		je checkTop
		cmp inputChar,"s"
		je checkBottom
		cmp inputChar,"a"
		je checkLeft
		cmp inputChar,"d"
		je checkRight
		jmp dontChgDirection					; reloop if no meaningful key was entered


		; check whether can continue moving
		checkBottom:	
		cmp lastInputChar, "w"
		je dontChgDirection		;cant go down immediately after going up
		mov cl, yPosWall[1]
		dec cl					;one unit ubove the y-coordinate of the lower bound
		cmp yPos[0],cl
		jb moveDown
		je died					;die if crash into the wall

		checkLeft:		
		cmp lastInputChar, "+"	;check whether its the start of the game
		je dontChgDirection
		cmp lastInputChar, "d"
		je dontChgDirection
		mov cl, xPosWall[0]
		inc cl
		cmp xPos[0],cl
		ja moveLeft
		je died					; check for left	

		checkRight:		
		cmp lastInputChar, "a"
		je dontChgDirection
		mov cl, xPosWall[2]
		dec cl
		cmp xPos[0],cl
		jb moveRight
		je died					; check for right	

		checkTop:		
		cmp lastInputChar, "s"
		je dontChgDirection
		mov cl, yPosWall[0]
		inc cl
		cmp yPos[0],cl
		ja moveUp
		je died				; check for up	
		

		moveUp:		
		mov eax, speed		;slow down the moving
		add eax, speed
		call delay
		mov esi, 0			;index 0(snake head)
		call UpdateSnake	
		mov ah, yPos[esi]	
		mov al, xPos[esi]	;alah stores the pos of the snake's next unit 
		dec yPos[esi]		;move the head up
		jmp displaySnake

		
		moveDown:			;move down
		mov eax, speed
		add eax, speed
		call delay
		mov esi, 0
		call UpdateSnake
		mov ah, yPos[esi]
		mov al, xPos[esi]
		inc yPos[esi]
		jmp displaySnake


		moveLeft:			;move left
		mov eax, speed
		call delay
		mov esi, 0
		call UpdateSnake
		mov ah, yPos[esi]
		mov al, xPos[esi]
		dec xPos[esi]
		jmp displaySnake


		moveRight:			;move right
		mov eax, speed
		call delay
		mov esi, 0
		call UpdateSnake
		mov ah, yPos[esi]
		mov al, xPos[esi]
		inc xPos[esi]
		jmp displaySnake

		displaySnake:
		call DrawSnake				; call procedure to draw the snake's head
		call DrawBody				; call procedure to draw the snake's body
		call CheckSnake				; call procedure to check if the snake's collides with itself

	; getting points
		checkFood::
		INVOKE validatePosition, xPos[0], yPos[0], xFoodPos, yFoodPos 
		cmp eax,'0'
		jne gameloop				;reloop if snake is not intersecting with food
		call EatingFood			;call to update score, append snake and generate new food	
		jmp gameLoop			;reiterate the gameloop


	dontChgDirection:		;dont allow user to change direction
	movzx ebx, lastInputChar
	mov inputChar, bl		;set current inputChar as previous
	jmp gameLoop				;jump gameloop to continue it's previous movement

	died::
	movzx ecx, score
	cmp highScore, cl		; check whether current score is a new high score
	jb newHighScore			
	call GameOver

	newHighScore:		
	mov highScore, cl		; set current score as new high score
	call GameOver
	 
	playagn::			
	call ReinitializeGame			;reinitialise everything
	
	exitgame::
	exit
ret
mainAsm ENDP 



DrawWall PROC 				;procedure to draw wall
	mov dl,xPosWall[0]
	mov dh,yPosWall[0]
	call Gotoxy	
	mov edx,OFFSET xWall
	call WriteString			;draw upper wall

	mov dl,xPosWall[1]
	mov dh,yPosWall[1]
	call Gotoxy	
	mov edx,OFFSET xWall		
	call WriteString			;draw lower wall

	mov dl, xPosWall[2]
	mov dh, yPosWall[2]
	mov eax,"#"	
	L11: 
	call Gotoxy	
	call WriteChar	
	cmp dh, yPosWall[3]			;draw right wall
	inc dh
	jb L11

	mov dl, xPosWall[0]
	mov dh, yPosWall[0]
	mov eax,"#"	
	L12: 
	call Gotoxy	
	call WriteChar	
	inc dh
	cmp dh, yPosWall[3]			;draw left wall
	jb L12
	ret
DrawWall ENDP

DrawScoreboard PROC				;procedure to draw scoreboard
	mov dl,2
	mov dh,1
	call Gotoxy
	mov edx,OFFSET strScore		;print string that indicates score
	call WriteString
	mov eax,"0"
	call WriteChar				;scoreboard starts with 0
	ret
DrawScoreboard ENDP

ChooseSpeed PROC			;procedure for snake to choose speed
	mov edx,0
	mov dl,71				
	mov dh,1
	call Gotoxy	
	mov edx,OFFSET strSpeed	; prompt to enter integers (1,2,3)
	call WriteString
	mov esi, 80				; milisecond difference per speed level
	mov eax,0
	INVOKE getSpeed
	cmp eax, 99
	je invalidspeed
	mul esi	
	add eax, 40
	mov speed, eax			;assign speed variable in miliseconds
	ret

	invalidspeed:			;jump here if user entered an invalid number
	mov dl,105				
	mov dh,1
	call Gotoxy	
	mov edx, OFFSET invalidInput		;print error message		
	call WriteString
	mov ax, 1500
	call delay							; delay for 1500 miliseconds
	mov dl,105				
	mov dh,1
	call Gotoxy	
	mov edx, OFFSET blank				;erase error message after 1.5 secs of delay
	call writeString
	call ChooseSpeed					;call procedure for user to choose again
	ret
ChooseSpeed ENDP

DrawSnake PROC			; draw snake at (xPos,yPos)
	mov dl,xPos[esi]
	mov dh,yPos[esi]
	call Gotoxy
	mov dl, al			;temporarily save al in dl
	mov al, snake[esi]		
	call WriteChar		; print snake unit
	mov al, dl			; move the value in dl back into al
	ret
DrawSnake ENDP

UpdateSnake PROC		; erase snake at (xPos,yPos)
	mov dl, xPos[esi]
	mov dh,yPos[esi]
	call Gotoxy
	mov dl, al			;temporarily save al in dl
	mov al, " "
	call WriteChar
	mov al, dl
	ret
UpdateSnake ENDP

DrawFood PROC						;procedure to draw food
	mov eax,yellow (yellow * 16)
	call SetTextColor				;set color to yellow for food
	mov dl,xFoodPos
	mov dh,yFoodPos
	call Gotoxy
	mov eax,0
	mov al,"H"
	call WriteChar
	mov eax,white (black * 16)		;reset color to black and white
	call SetTextColor
	ret
DrawFood ENDP

CreateRandomFood PROC				;procedure to create a random food
	mov eax,47
	call RandomRange	;0-47
	add eax, 36			;36-83
	mov xFoodPos,al

	mov eax,15
	call RandomRange	;0-15
	add eax, 7			;7-22
	mov yFoodPos,al

	movzx ebx, score
	add bl, 4				;loop until last index of snake unit
	mov esi,0
	validateFood:
	mov eax, 0
	INVOKE validatePosition, xPos[esi], yPos[esi], xFoodPos, yFoodPos				; invoke function to check whether the food is generated on the snake 
	inc esi
	cmp eax,'0'
	je generateFoodAgain															; jump to generate food again
	cmp esi, ebx
	jne validateFood																; jump to validate food for another index		
	ret
	
	generateFoodAgain:
	call CreateRandomFood		; food generated on snake/ in front of snake, calling function again to create another set of coordinates
CreateRandomFood ENDP

CheckSnake PROC				;check whether the snake head collides w its body 
	mov esi,4				; start checking from index 4(5th unit)
	mov ecx,5
	add cl,score			; total units of snake
	checkCollision:
	INVOKE validatePosition, xPos[esi], yPos[esi], xPos[0], yPos[0] 
	cmp eax,'0'
	je died					; jump to kill snake if the body is intersecting with head
	inc esi
	cmp esi, ecx
	jb checkCollision
	ret
CheckSnake ENDP

DrawBody PROC				;procedure to print body of the snake
	mov ecx, 4
	add cl, score		;number of iterations to print the snake body n tail	
	printbodyloop:	
	inc esi				;loop to print remaining units of snake
	call UpdateSnake
	mov dl, xPos[esi]
	mov dh, yPos[esi]	;dldh temporarily stores the current pos of the unit 
	mov yPos[esi], ah
	mov xPos[esi], al	;assign new position to the unit
	mov al, dl
	mov ah,dh			;move the current position back into alah
	call DrawSnake
	cmp esi, ecx
	jb printbodyloop
	ret
DrawBody ENDP

EatingFood PROC
	; snake is eating food
	inc score
	movzx esi,score
	add esi, 4				;get total units of the current snake  
	mov ebx, 2
	movzx eax, xPos[esi-1]		; move the x position of old tail into eax
	mul bl						; multiply it with 2
	sub al, xPos[esi-2]			; subtract the x position of the unit before the old tail
	mov xPos[esi],al			; the al obtained is the x position for the new tail

	movzx eax, yPos[esi-1]		; move the y position of old tail into eax
	mul bl						; multiply it with 2
	sub al, yPos[esi-2]			; subtract the y position of the unit before the old tail
	mov yPos[esi], al			; the al obtained is the y position for the new tail
				
	;update new food
	call CreateRandomFood		; call function to create new food
	call DrawFood				; call function to draw new food

	mov dl,17				
	mov dh,1
	call Gotoxy
	mov al,score				; write updated score at the scoreboard
	call WriteInt
	ret
EatingFood ENDP


GameOver PROC
	mov eax, 1000
	call delay
	Call ClrScr					;clear screen
	mov dl,	57
	mov dh, 11
	call Gotoxy
	mov edx, OFFSET strGameOver			;"game over"
	call WriteString

	mov dl,	54
	mov dh, 13
	call Gotoxy
	mov edx, OFFSET strCurrentScore			;display score
	call WriteString
	movzx eax, score
	call WriteInt


	mov dl,	54
	mov dh, 14
	call Gotoxy
	mov edx, OFFSET strHighScore		;display Highscore
	call WriteString
	movzx eax, highScore
	call WriteInt

	mov dl,	50
	mov dh, 17
	call Gotoxy
	mov edx, OFFSET strTryAgain
	call WriteString				;"try again?"

	retry:
	mov dh, 18
	mov dl,	56
	call Gotoxy
	INVOKE gameOverValidation			;get user input
	cmp al, 1
	je playagn				;playagn
	cmp al, 0
	je exitgame				;exitgame

	mov dh,	16
	mov dl,	56
	call Gotoxy
	mov edx, OFFSET invalidInput	;"Invalid input"
	call WriteString		
	mov dl,	56
	mov dh, 18
	call Gotoxy
	mov edx, OFFSET blank			;erase previous input
	call WriteString
	jmp retry						;let user input again
GameOver ENDP


ReinitializeGame PROC		;procedure to reinitialize everything
	mov bl, 40
	mov ecx, 5
resetSnakePos:				;reinitialize snake position
	inc bl
	mov xPos[ecx-1], bl
	mov yPos[ecx-1], 15
loop resetSnakePos	
	mov score,0				;reinitialize score
	mov	inputChar, "+"		;reinitialize inputChar 
	mov lastInputChar, "+"
	Call ClrScr
	jmp StartLoopGame				;start over the game
ReinitializeGame ENDP
END 