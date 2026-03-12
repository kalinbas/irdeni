DECLARE FUNCTION Encode$ (what$)

CLS
OPEN "event.dat" FOR INPUT AS #1
OPEN "event2.sbt" FOR OUTPUT AS #2

DO
INPUT #1, ant$
IF ant$ = "#end" THEN EXIT DO
IF LEFT$(ant$, 1) = "#" THEN ant$ = STR$(VAL(RIGHT$(ant$, LEN(ant$) - 1)) * 3 + 2): ant$ = "#" + RIGHT$(ant$, LEN(ant$) - 1): PRINT #2, ant$: INPUT #1, ant$

split = 0
space = 0
x = 0
y = 1


FOR m = 1 TO LEN(ant$)
       z$ = MID$(ant$, m, 1)
       IF (ASC(z$) > 47 AND ASC(z$) < 58) OR z$ = "-" OR z$ = " " THEN split = 1 ELSE split = 0: EXIT FOR
       IF z$ = " " THEN space = 1
NEXT m


IF split = 1 AND space = 1 THEN
        DO
        x = x + 1
        'IF MID$(ant$, x, 1) = " " THEN PRINT #2, Encode$(MID$(ant$, y, x - y)): y = x + 1
        IF MID$(ant$, x, 1) = " " THEN PRINT #2, MID$(ant$, y, x - y): y = x + 1
        LOOP UNTIL x = LEN(ant$)
        'PRINT #2, Encode$(MID$(ant$, y))
        PRINT #2, MID$(ant$, y)
ELSE
        'PRINT #2, Encode$(ant$)
        PRINT #2, ant$
END IF

LOOP
CLOSE #1
CLOSE #2

DEFINT A-Z
FUNCTION Encode$ (what$)
res$ = ""
IF what$ = "" THEN EXIT FUNCTION
FOR n = 1 TO LEN(what$)
t$ = CHR$(ASC(MID$(what$, n, 1)) + 20)
res$ = res$ + t$
NEXT n
Encode$ = res$
END FUNCTION

