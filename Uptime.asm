; Uptime v1.0 : show time elapsed since last reboot
; by Kyzer/CSG
; $VER: Uptime.asm 1.0 (04.08.98)
;
	incdir	include:
	include	devices/timer.i
	include	dos/dos.i
	include	exec/execbase.i
	include	exec/io.i
	include	exec/memory.i
	include	lvo/dos_lib.i
	include	lvo/exec_lib.i
	include	lvo/timer_lib.i

stackf	MACRO	; stack_symbol, stackelement_symbol, [size=4]
	IFND	\1
\1	set	0
	ENDC
	IFGE	NARG-3
\1	set	\1-\3
	ELSE
\1	set	\1-4
	ENDC
\2	equ	\1
	ENDM

VAR_SIZE=64
	stackf	stk, hostname, VAR_SIZE	; name of machine
	stackf	stk, PAD, 16		; GetVar() demolishes 16 bytes behind!!

	stackf	stk, secs, 2		; ^ arguments for printf statement
	stackf	stk, mins, 2		; |
	stackf	stk, hours, 2		; |
	stackf	stk, days, 2		; |
	stackf	stk, machinename	; | 

	machine	68020

Uptime	link	a5,#stk
	move.l	4.w,a6
	move.l	a6,a3
	btst.b	#AFB_68020,AttnFlags+1(a6)
	beq.s	.exit			; require 68020

	moveq	#IOTV_SIZE,d0		; allocate timerequest
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	jsr	_LVOAllocVec(a6)
	move.l	d0,a4			; a4 = ioreq
	tst.l	d0
	beq.s	.exit

	lea	timername(pc),a0	; open timer.device
	moveq	#UNIT_ECLOCK,d0
	moveq	#0,d1
	move.l	a4,a1
	jsr	_LVOOpenDevice(a6)
	tst.l	d0
	bne.s	.notime

	lea	IOTV_TIME(a4),a0
	move.l	IO_DEVICE(a4),a6
	jsr	_LVOReadEClock(a6)	; returns tickspersecond

	move.l	IOTV_TIME+EV_HI(a4),d1
	move.l	IOTV_TIME+EV_LO(a4),d2
	divu.l	d0,d1:d2	; ticks(d1:d2) / tickspersec(d0) = secs(d2)
	lea	days(a5),a0
	divul.l	#60*60*24,d1:d2	; secs(d2) / secsperday = days(d2):secs(d1)
	move.w	d2,(a0)+	; store days
	divul.l	#60*60,d2:d1	; secs(d1) / secsperhour = hours(d1):secs(d2)
	move.w	d1,(a0)+	; store hours
	divul.l	#60,d1:d2	; secs(d2) / secspermin = mins(d2):secs(d1)
	move.w	d2,(a0)+	; store mins
	move.w	d1,(a0)+	; store secs

	move.l	a3,a6
	move.l	a4,a1
	jsr	_LVOCloseDevice(a6)
.notime	move.l	a4,d1
	jsr	_LVOFreeVec(a6)
	bra.s	.print
.exit	unlk	a5
	moveq	#0,d0
	rts

.print	move.l	a3,a6
	lea	dosname(pc),a1	; dos.library v37+
	moveq.l	#37,d0
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	beq.s	.exit
	move.l	d0,a6

	; find $HOSTNAME, return it (or default) in A2
	lea	hostvar(pc),a0	; name of var, "HOSTNAME"
	move.l	a0,d1
	lea	hostname(a5),a2	; point to space for var
	move.l	a2,d2
	moveq	#VAR_SIZE,d3	; size of space
	moveq	#0,d4		; no special options
	jsr	_LVOGetVar(a6)
	tst.l	d0
	bge.s	.gotvar
	lea	uptime(pc),a2	; set default
.gotvar
	lea	machinename(a5),a1
	move.l	a2,(a1)		; set machinename

	lea	format(pc),a0
	move.l	a0,d1		; d1 = fmtstring
	move.l	a1,d2		; d2 = args
	jsr	_LVOVPrintf(a6)

	move.l	a6,a1
	move.l	a3,a6
	jsr	_LVOCloseLibrary(a6)
	bra.s	.exit

dosname		DOSNAME
timername	TIMERNAME
hostvar	dc.b	'HOSTNAME',0
uptime	dc.b	'Uptime:',0
format	dc.b	'%s up %d day(s), %02d:%02d:%02d',10,0
	dc.b	'$VER: Uptime 1.0 (04.08.98)',0
