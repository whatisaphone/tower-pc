%assign LOG_VERBOSE 1
%assign LOG_TRACE 2
%assign LOG_DEBUG 4
%assign LOG_INFO 6
%assign LOG_WARNING 8
%assign LOG_ERROR 10
%assign LOG_CRITICAL 12
%assign LOG_FATAL 15

%assign HLE_VECTOR 0xff
%macro hlint 1		; %1 = desired high-level vector
	push	bp
	mov		bp, %1
	int		HLE_VECTOR
	pop		bp
%endmacro

%macro outb 2		; %1 = byte port, %2 = byte data
	mov		al, %2
	out		%1, al
%endmacro