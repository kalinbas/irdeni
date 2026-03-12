'$INCLUDE: 'SPRITES.BI'
'$INCLUDE: 'DIRECTQB.BI'

DECLARE SUB Shade ()
DECLARE SUB Credits ()
DECLARE SUB MainMenu ()
DECLARE FUNCTION LoadGame ()
DECLARE SUB LoadStat ()
DECLARE SUB DrawRahmen ()
DECLARE FUNCTION TextEingabe$ ()
DECLARE FUNCTION Decode$ (what$)
DECLARE FUNCTION Encode$ (what$)
DECLARE SUB NewGame ()
DECLARE SUB LevelUp ()
DECLARE FUNCTION DiceNumber (what$)
DECLARE SUB Fight (en%)
DECLARE SUB SaveStat ()
DECLARE SUB BattleField ()
DECLARE SUB ChangeInventar (what$, how$, amount$)
DECLARE SUB Event (eventcode&)
DECLARE SUB WriteText (Text$, x1%)
DECLARE SUB InputText (x1%, x2%, y2%)
DECLARE SUB Action ()
DECLARE SUB OpenMap ()
DECLARE SUB LoadMap ()
DECLARE SUB Ende ()
DECLARE SUB LoadSprites ()
DECLARE SUB OnScreen ()
DECLARE SUB DrawScreen ()
DECLARE SUB DrawAnimation ()
DECLARE SUB Inventar ()
DECLARE SUB DrawFigur ()

COMMON SHARED ter%, ausloes&, evemist%, negeve%, hwm%, xpmx%, xpmy%, id$, n$, npat%, ani%, zielx%, ziely%, mapx%, mapy%, pmx%, pmy%, richtung%
COMMON SHARED ozx%, ozy%, sdf%, map$, oldmap$, dummy&, at!, bt!, newmap%, noa%, ans%, pmodus%, what, what$

CONST toolvalue% = 25
CONST ap% = 1
CONST walkspeed& = 30000, fightspeed% = 20, textspeed% = 5

DEFINT A-Z
DIM SHARED palett AS STRING * 768
DIM SHARED ifont AS STRING * 2305
DIM SHARED att(10), eneatt(20)
DIM SHARED mor%(4), answer$(20), anseve&(20), inv$(28, 6), item$(6), enetex$(6), ene%(99, 3)
         
CLS
dummy& = SETMEM(-66000)

IF DQBinit(13, 0, 0) THEN Ende
        DQBinstallKeyboard
        IF DQBsetBaseLayer(B0) = 0 THEN Ende
        DQBinitVGA
        LoadSprites
        MainMenu
       
DO
    bt! = TIMER
    IF newmap% > 0 THEN GOSUB newmap:
    IF newmap% > 1 THEN BattleField
   
    IF bt! - at! > .1 THEN GOSUB els:
   
    IF att(3) >= 500 * att(4) THEN LevelUp
    IF DQBkey(KEYUP) THEN richtung% = 0: ziely% = pmy% - 1: zielx% = pmx%: OnScreen
    IF DQBkey(KEYDOWN) THEN richtung% = 1: ziely% = pmy% + 1: zielx% = pmx%: OnScreen
    IF DQBkey(KEYLEFT) THEN richtung% = 2: zielx% = pmx% - 1: ziely% = pmy%: OnScreen
    IF DQBkey(KEYRIGHT) THEN richtung% = 3: zielx% = pmx% + 1: ziely% = pmy%: OnScreen
    IF DQBkey(KEYESC) THEN MainMenu
    IF DQBkey(23) THEN Inventar
    IF DQBkey(KEYENTER) THEN Action
    IF DQBkey(38) THEN x = LoadGame
    IF DQBkey(31) THEN SaveStat: WriteText "Spielstand gespeichert.", 150
    IF DQBkey(29) AND DQBkey(45) THEN ChangeInventar TextEingabe$, "0", "1"
LOOP

els:
ani% = 1
OnScreen
ani% = 0
at! = TIMER
RETURN

newmap:
OpenMap
REDIM SHARED map%(mapx% + 1, mapy% + 1), mapinfo&(mapx% + 1, mapy% + 1), mapon%(mapx% + 1, mapy% + 1)
LoadMap
IF xpmx% > 0 THEN pmx% = xpmx%: xpmx% = 0
IF xpmy% > 0 THEN pmy% = xpmy%: xpmy% = 0
IF newmap% = 1 THEN ani% = 1: OnScreen: ani% = 0: Event ausloes&: newmap% = 0: ausloes& = 0
DQBwait 10
RETURN

REM $DYNAMIC
SUB Action

SELECT CASE richtung%
CASE 0: ziely% = pmy% - 1: zielx% = pmx%
CASE 1: ziely% = pmy% + 1: zielx% = pmx%
CASE 2: zielx% = pmx% - 1: ziely% = pmy%
CASE 3: zielx% = pmx% + 1: ziely% = pmy%
END SELECT

IF mapinfo&(zielx%, ziely%) > 0 THEN Event (mapinfo&(zielx%, ziely%)) ':DQBwait 20

END SUB

REM $STATIC
SUB BattleField
RANDOMIZE TIMER

SELECT CASE richtung%
CASE 0: pmx% = FIX(mapx% / 2): pmy% = mapy% - 1
CASE 1: pmx% = FIX(mapx% / 2): pmy% = 2
CASE 2: pmx% = mapx% - 1: pmy% = FIX(mapy% / 2)
CASE 3: pmx% = 2: pmy% = FIX(mapy% / 2)
END SELECT

IF (negeve% = 1 OR ter% = 1) THEN pmx% = FIX(mapx% / 2): pmy% = FIX(mapy% / 2)

FOR n = 1 TO eneatt(6)
ene%(n, 3) = DiceNumber(enetex$(3))
2
x% = INT(RND * mapx% + 1)
y% = INT(RND * mapy% + 1)
IF map%(x%, y%) > 0 AND mapon%(x%, y%) = 0 AND (pmx% <> x% OR pmy% <> y%) THEN mapon%(x%, y%) = -eneatt(7) ELSE GOTO 2
ene%(n, 1) = x%
ene%(n, 2) = y%
NEXT n


ani% = 2
richtung% = 1
OnScreen
ani% = 0
at! = TIMER

DO
    bt! = TIMER
    IF bt! - at! > .1 THEN GOSUB els2:
   
    IF DQBkey(23) THEN Inventar
    IF DQBkey(KEYUP) THEN richtung% = 0: ziely% = pmy% - 1: zielx% = pmx%: OnScreen: t = t + 1
    IF DQBkey(KEYDOWN) THEN richtung% = 1: ziely% = pmy% + 1: zielx% = pmx%: OnScreen: t = t + 1
    IF DQBkey(KEYLEFT) THEN richtung% = 2: zielx% = pmx% - 1: ziely% = pmy%: OnScreen: t = t + 1
    IF DQBkey(KEYRIGHT) THEN richtung% = 3: zielx% = pmx% + 1: ziely% = pmy%: OnScreen: t = t + 1
   
    IF pmx% = 1 THEN IF mor%(3) = 1 THEN pmodus% = 3: GOSUB eb ELSE DQBwait 10
    IF pmy% = 1 THEN IF mor%(1) = 1 THEN pmodus% = 1: GOSUB eb ELSE DQBwait 10
    IF pmx% = mapx% THEN IF mor%(4) = 1 THEN pmodus% = 4: GOSUB eb ELSE DQBwait 10
    IF pmy% = mapy% THEN IF mor%(2) = 1 THEN pmodus% = 2: GOSUB eb ELSE DQBwait 10
   

    FOR n% = 1 TO eneatt(6)
    IF pmx% = ene%(n%, 1) AND pmy% = ene%(n%, 2) THEN Fight n%: GOSUB enemyturn:
    NEXT n%
   
    IF t >= eneatt(8) THEN GOSUB enemyturn

LOOP

enemyturn:
IF eneatt(6) = 0 THEN pmodus% = 5: Event 1000: GOSUB eb
FOR n% = 1 TO eneatt(6)
        x% = ene%(n%, 1)
        y% = ene%(n%, 2)

        IF pmx% > x% AND pmy% > y% THEN
                IF pmx% - x% >= pmy% - y% THEN IF map%(x% + 1, y%) > 0 AND mapon%(x% + 1, y%) = 0 THEN mapon%(x%, y%) = 0: mapon%(x% + 1, y%) = -eneatt(7): ene%(n%, 1) = ene%(n%, 1) + 1
                IF pmx% - x% < pmy% - y% THEN IF map%(x%, y% + 1) > 0 AND mapon%(x%, y% + 1) = 0 THEN mapon%(x%, y%) = 0: mapon%(x%, y% + 1) = -eneatt(7): ene%(n%, 2) = ene%(n%, 2) + 1
        END IF
        IF pmx% < x% AND pmy% < y% THEN
                IF x% - pmx% >= y% - pmy% THEN IF map%(x% - 1, y%) > 0 AND mapon%(x% - 1, y%) = 0 THEN mapon%(x%, y%) = 0: mapon%(x% - 1, y%) = -eneatt(7): ene%(n%, 1) = ene%(n%, 1) - 1
                IF x% - pmx% < y% - pmy% THEN IF map%(x%, y% - 1) > 0 AND mapon%(x%, y% - 1) = 0 THEN mapon%(x%, y%) = 0: mapon%(x%, y% - 1) = -eneatt(7): ene%(n%, 2) = ene%(n%, 2) - 1
        END IF
        IF pmx% < x% AND pmy% > y% THEN
                IF x% - pmx% >= pmy% - y% THEN IF map%(x% - 1, y%) > 0 AND mapon%(x% - 1, y%) = 0 THEN mapon%(x%, y%) = 0: mapon%(x% - 1, y%) = -eneatt(7): ene%(n%, 1) = ene%(n%, 1) - 1
                IF x% - pmx% < pmy% - y% THEN IF map%(x%, y% + 1) > 0 AND mapon%(x%, y% + 1) = 0 THEN mapon%(x%, y%) = 0: mapon%(x%, y% + 1) = -eneatt(7): ene%(n%, 2) = ene%(n%, 2) + 1
        END IF
        IF pmx% > x% AND pmy% < y% THEN
                IF pmx% - x% >= y% - pmy% THEN IF map%(x% + 1, y%) > 0 AND mapon%(x% + 1, y%) = 0 THEN mapon%(x%, y%) = 0: mapon%(x% + 1, y%) = -eneatt(7): ene%(n%, 1) = ene%(n%, 1) + 1
                IF pmx% - x% < y% - pmy% THEN IF map%(x%, y% - 1) > 0 AND mapon%(x%, y% - 1) = 0 THEN mapon%(x%, y%) = 0: mapon%(x%, y% - 1) = -eneatt(7): ene%(n%, 2) = ene%(n%, 2) - 1
        END IF
        IF pmx% = x% AND pmy% < y% THEN
                IF map%(x%, y% - 1) > 0 AND mapon%(x%, y% - 1) = 0 THEN mapon%(x%, y%) = 0: mapon%(x%, y% - 1) = -eneatt(7): ene%(n%, 2) = ene%(n%, 2) - 1
        END IF
        IF pmx% > x% AND pmy% = y% THEN
                IF map%(x% + 1, y%) > 0 AND mapon%(x% + 1, y%) = 0 THEN mapon%(x%, y%) = 0: mapon%(x% + 1, y%) = -eneatt(7): ene%(n%, 1) = ene%(n%, 1) + 1
        END IF
        IF pmx% = x% AND pmy% > y% THEN
                IF map%(x%, y% + 1) > 0 AND mapon%(x%, y% + 1) = 0 THEN mapon%(x%, y%) = 0: mapon%(x%, y% + 1) = -eneatt(7): ene%(n%, 2) = ene%(n%, 2) + 1
        END IF
        IF pmx% < x% AND pmy% = y% THEN
                IF map%(x% - 1, y%) > 0 AND mapon%(x% - 1, y%) = 0 THEN mapon%(x%, y%) = 0: mapon%(x% - 1, y%) = -eneatt(7): ene%(n%, 1) = ene%(n%, 1) - 1
        END IF

        ani% = 2: OnScreen: ani% = 0
        IF pmx% = ene%(n%, 1) AND pmy% = ene%(n%, 2) THEN Fight n: GOTO enemyturn
NEXT n
t = -1
RETURN

els2:
ani% = 1
OnScreen
ani% = 0
at! = TIMER
RETURN

eb:
newmap% = 1
map$ = oldmap$
EXIT SUB


END SUB

SUB ChangeInventar (what$, how$, amount$)

IF what$ = "" THEN EXIT SUB

id = VAL(how$)

SELECT CASE id
CASE 0  'HinzufÅgen

FOR n = 1 TO LEN(what$)
IF MID$(what$, n, 1) = "=" THEN EXIT FOR
NEXT n

item$(1) = MID$(what$, 1, n - 1)
item$(2) = MID$(what$, n + 1, 1)
item$(3) = MID$(what$, n + 2, 3)
item$(4) = MID$(what$, n + 6, 3)
item$(5) = MID$(what$, n + 10)

FOR n = 1 TO 20
IF inv$(n, 1) = item$(1) THEN inv$(n, 6) = STR$(VAL(inv$(n, 6)) + VAL(amount$)): EXIT SUB
IF inv$(n, 1) = "" THEN inv$(n, 1) = item$(1): inv$(n, 2) = item$(2): inv$(n, 3) = item$(3): inv$(n, 4) = item$(4): inv$(n, 5) = item$(5): inv$(n, 6) = amount$: EXIT SUB
NEXT n

FOR n = 1 TO 20
IF inv$(n, 2) = "0" AND inv$(n, 6) = "1" THEN WriteText "Ihr habt " + inv$(n, 1) + " weggeworfen, da der Rucksack voll war.", 150: inv$(n, 1) = item$(1): inv$(n, 2) = item$(2): inv$(n, 3) = item$(3): inv$(n, 4) = item$(4): inv$(n, 5) = item$(5): _
                                                                                                                         inv$(n, 6) = amount$: EXIT SUB
NEXT n

CASE 1 'Benutzen
nr = VAL(what$)

SELECT CASE inv$(VAL(what$), 2)
CASE "W"
at = 5: inv = 22: GOSUB change
CASE "S"
at = 6: inv = 24: GOSUB change
CASE "A"
at = 6: inv = 23: GOSUB change
CASE "H"
at = 10: inv = 21: GOSUB change
CASE "B"
at = 10: inv = 25: GOSUB change
CASE "E", "U"
zielx% = pmx%: ziely% = pmy%: Event VAL(inv$(nr, 3))
CASE "C"
att(1) = att(1) + VAL(inv$(nr, 3)): ChangeInventar STR$(nr), "2", "1"
IF att(1) > att(2) THEN att(1) = att(2)
END SELECT

EXIT SUB

change:
att(at) = att(at) + VAL(inv$(nr, 3)): att(at) = att(at) - VAL(inv$(inv, 3))
FOR n = 1 TO 6: item$(n) = inv$(inv, n): inv$(inv, n) = inv$(nr, n): inv$(nr, n) = item$(n): NEXT n
EXIT SUB

CASE 2 'Lîschen
nr = VAL(what$)
menge = VAL(amount$)

IF VAL(inv$(nr, 6)) - menge < 1 THEN
        FOR n = nr TO 19
                FOR m = 1 TO 6
                        inv$(n, m) = inv$(n + 1, m)
                NEXT m
        NEXT n
        FOR m = 1 TO 6: inv$(20, m) = "": NEXT m
        EXIT SUB
ELSE
        inv$(nr, 6) = STR$(VAL(inv$(nr, 6)) - menge)
        
END IF

CASE 3 'Suchen
FOR what = 1 TO 20
IF inv$(what, 1) = what$ THEN hwm% = VAL(inv$(what, 6)): EXIT SUB
NEXT what
what = 0

END SELECT

END SUB

SUB Credits
DQBclearLayer B0
DQBclearLayer VIDEO

answer$(1) = "base programming"
answer$(2) = "graphical design"
answer$(3) = "level design"
answer$(4) = "story"
answer$(5) = "event programming"
answer$(6) = "production"
answer$(7) = "graphics"
answer$(8) = "game test"
answer$(9) = "beta test"

answer$(11) = "BASTIAN KéLIN"
answer$(12) = "BASTIAN KéLIN & SIMON JUNKER"
answer$(13) = "SIMON JUNKER"
answer$(14) = "BASTIAN KéLIN & SIMON JUNKER"
answer$(15) = "BASTIAN KéLIN & SIMON JUNKER"
answer$(16) = "SIMBA ENTERTAINMENT PRODUCTIONS"
answer$(17) = "SIMON JUNKER"
answer$(18) = "BASTIAN KéLIN & SIMON JUNKER"
answer$(19) = "XXX"




x = 0
DO
x = x + 1
FOR n = 1 TO 9
DQBprint B0, answer$(n), 30, x - (n - 1) * 40, 31
DQBprint B0, answer$(n + 10), 30, x - (n - 1) * 40 + 20, 31
NEXT n
DrawRahmen


DQBcopyLayer B0, VIDEO
DQBclearLayer B0
DQBwait 5
LOOP UNTIL x > 600


END SUB

FUNCTION Decode$ (what$)
res$ = ""
FOR n = 1 TO LEN(what$)
res$ = res$ + CHR$(ASC(MID$(what$, n, 1)) - 20)
NEXT n
Decode$ = res$
END FUNCTION

FUNCTION DiceNumber (what$)

IF what$ = "" THEN EXIT FUNCTION
what = 0
FOR n = 1 TO LEN(what$)
        IF MID$(what$, n, 1) = "X" THEN EXIT FOR
NEXT n

a = VAL(LEFT$(what$, n - 1))
b = VAL(RIGHT$(what$, LEN(what$) - n))

DiceNumber = a + INT(RND * 2 * b) - b

END FUNCTION

REM $DYNAMIC
SUB DrawAnimation

opmx% = pmx%: opmy% = pmy%
pmx% = zielx%: pmy% = ziely%
DrawScreen
pmx% = opmx%: pmy% = opmy%
DQBcopyLayer B0, 11
DQBclearLayer B0
DrawScreen

FOR n = 0 TO 3
FOR m = 0 TO 4
SELECT CASE richtung%

CASE 0
        DQBscroll B0, 0, 1
        DQBxPut 11, 10, 29 - n * 5 - m, 309, 29 - n * 5 - m, B0, 10, 10
        DQBboxf B0, 0, 190, 319, 199, 0
    
CASE 1
        DQBscroll B0, 0, -1
        DQBxPut 11, 10, 170 + n * 5 + m, 309, 170 + n * 5 + m, B0, 10, 189
        DQBboxf B0, 0, 0, 319, 9, 0

CASE 2
        DQBscroll B0, 1, 0
        DQBxPut 11, 29 - n * 5 - m, 10, 29 - n * 5 - m, 49, B0, 10, 10
        DQBxPut 11, 29 - n * 5 - m, 50, 29 - n * 5 - m, 99, B0, 10, 50
        DQBxPut 11, 29 - n * 5 - m, 100, 29 - n * 5 - m, 149, B0, 10, 100
        DQBxPut 11, 29 - n * 5 - m, 150, 29 - n * 5 - m, 189, B0, 10, 150
        DQBboxf B0, 310, 0, 319, 199, 0

CASE 3
        DQBscroll B0, -1, 0
        DQBxPut 11, 290 + n * 5 + m, 10, 290 + n * 5 + m, 49, B0, 309, 10
        DQBxPut 11, 290 + n * 5 + m, 50, 290 + n * 5 + m, 99, B0, 309, 50
        DQBxPut 11, 290 + n * 5 + m, 100, 290 + n * 5 + m, 149, B0, 309, 100
        DQBxPut 11, 290 + n * 5 + m, 150, 290 + n * 5 + m, 189, B0, 309, 150
        DQBboxf B0, 0, 0, 9, 199, 0

END SELECT

DQBcopyLayer B0, 12
DQBxPut 10, richtung% * 80 + (n) * 20, (ap% - 1) * 20, richtung% * 80 + 19 + (n) * 20, 19 + (ap% - 1) * 20, B0, 150, 90

REM DQBwait 1
FOR i& = 1 TO walkspeed&: NEXT i&

DrawRahmen
DQBcopyLayer B0, VIDEO
DQBclearLayer B0
DQBcopyLayer 12, B0
NEXT m
NEXT n

pmx% = zielx%
pmy% = ziely%

DQBcopyLayer 11, B0
DrawFigur

REM FOR i& = 1 TO walkspeed&: NEXT i&

DrawRahmen
DQBcopyLayer B0, VIDEO
DQBclearLayer B0
DQBclearLayer 11
DQBclearLayer 12

END SUB

REM $STATIC
SUB DrawFigur
DQBxPut 10, richtung% * 80, (ap% - 1) * 20, richtung% * 80 + 19, 19 + (ap% - 1) * 20, B0, 150, 90

END SUB

SUB DrawRahmen
DQBxPut 13, 0, 0, 319, 19, B0, 0, 0

DQBxPut 13, 0, 180, 319, 199, B0, 0, 180

DQBxPut 13, 0, 20, 19, 59, B0, 0, 20
DQBxPut 13, 0, 60, 19, 99, B0, 0, 60
DQBxPut 13, 0, 100, 19, 139, B0, 0, 100
DQBxPut 13, 0, 140, 19, 179, B0, 0, 140

DQBxPut 13, 300, 20, 319, 59, B0, 300, 20
DQBxPut 13, 300, 60, 319, 99, B0, 300, 60
DQBxPut 13, 300, 100, 319, 139, B0, 300, 100
DQBxPut 13, 300, 140, 319, 179, B0, 300, 140

DQBprint B0, STR$(pmx%) + STR$(pmy%), 10, 10, 31

END SUB

REM $DYNAMIC
SUB DrawScreen

FOR x = -7 TO 7
FOR y = -4 TO 4

'Wenn ausserhalb der Karte
IF (pmx% + x < 1 OR pmy% + y < 1 OR pmx% + x > mapx% OR pmy% + y > mapy%) THEN

a = sdf%
IF ani% = 1 AND a > 1279 THEN a = INT(RND * 4 + a)

Reihe = FIX((a MOD 160) / 10) * 20
Zeile = ((a MOD 160) MOD 10) * 20
DQBxPut 1 + FIX(a / 160), Reihe, Zeile, Reihe + 19, Zeile + 19, B0, (x + 7) * 20 + 10, (y + 4) * 20 + 10
GOTO 1
END IF


'Wenn Map animiert
IF ani% = 1 AND map%(pmx% + x, pmy% + y) > 1279 THEN
        a = map%(pmx% + x, pmy% + y) MOD 4
        IF a = 3 THEN map%(pmx% + x, pmy% + y) = map%(pmx% + x, pmy% + y) - 3 ELSE map%(pmx% + x, pmy% + y) = map%(pmx% + x, pmy% + y) + 1
END IF

IF ani% = 1 AND map%(pmx% + x, pmy% + y) < -1279 THEN
        a = -(map%(pmx% + x, pmy% + y) MOD 4)
        IF a = 3 THEN map%(pmx% + x, pmy% + y) = map%(pmx% + x, pmy% + y) + 3 ELSE map%(pmx% + x, pmy% + y) = map%(pmx% + x, pmy% + y) - 1
END IF


'Map zeichnen
mp% = map%(pmx% + x, pmy% + y)
IF mp% < 0 THEN mp% = -mp%
Reihe = FIX((mp% MOD 160) / 10) * 20
Zeile = ((mp% MOD 160) MOD 10) * 20
DQBxPut 1 + FIX(mp% / 160), Reihe, Zeile, Reihe + 19, Zeile + 19, B0, (x + 7) * 20 + 10, (y + 4) * 20 + 10


'Wenn Objekt existiert
IF mapon%(pmx% + x, pmy% + y) <> 0 THEN
    
        'Wenn Objekt animiert
        IF ani% = 1 AND mapon%(pmx% + x, pmy% + y) > 1279 THEN
                a = mapon%(pmx% + x, pmy% + y) MOD 4
                IF a = 3 THEN mapon%(pmx% + x, pmy% + y) = mapon%(pmx% + x, pmy% + y) - 3 ELSE mapon%(pmx% + x, pmy% + y) = mapon%(pmx% + x, pmy% + y) + 1
             
                IF x = -7 THEN posi% = mapon%(pmx% + x - 1, pmy% + y): IF posi% > 1279 THEN a = posi% MOD 4: IF a = 3 THEN mapon%(pmx% + x - 1, pmy% + y) = posi% - 3 ELSE mapon%(pmx% + x - 1, pmy% + y) = posi% + 1
                IF x = 7 THEN posi% = mapon%(pmx% + x + 1, pmy% + y): IF posi% > 1279 THEN a = posi% MOD 4: IF a = 3 THEN mapon%(pmx% + x + 1, pmy% + y) = posi% - 3 ELSE mapon%(pmx% + x + 1, pmy% + y) = posi% + 1
                IF y = -4 THEN posi% = mapon%(pmx% + x, pmy% + y - 1): IF posi% > 1279 THEN a = posi% MOD 4: IF a = 3 THEN mapon%(pmx% + x, pmy% + y - 1) = posi% - 3 ELSE mapon%(pmx% + x, pmy% + y - 1) = posi% + 1
                IF y = 4 THEN posi% = mapon%(pmx% + x, pmy% + y + 1): IF posi% > 1279 THEN a = posi% MOD 4: IF a = 3 THEN mapon%(pmx% + x, pmy% + y + 1) = posi% - 3 ELSE mapon%(pmx% + x, pmy% + y + 1) = posi% + 1
                IF x = -7 AND y = -4 THEN posi% = mapon%(pmx% + x - 1, pmy% + y - 1): IF posi% > 1279 THEN a = posi% MOD 4: IF a = 3 THEN mapon%(pmx% + x - 1, pmy% + y - 1) = posi% - 3 ELSE mapon%(pmx% + x - 1, pmy% + y - 1) = posi% + 1
                IF x = 7 AND y = -4 THEN posi% = mapon%(pmx% + x + 1, pmy% + y - 1): IF posi% > 1279 THEN a = posi% MOD 4: IF a = 3 THEN mapon%(pmx% + x + 1, pmy% + y - 1) = posi% - 3 ELSE mapon%(pmx% + x + 1, pmy% + y - 1) = posi% + 1
                IF x = -7 AND y = 4 THEN posi% = mapon%(pmx% + x - 1, pmy% + y + 1): IF posi% > 1279 THEN a = posi% MOD 4: IF a = 3 THEN mapon%(pmx% + x - 1, pmy% + y + 1) = posi% - 3 ELSE mapon%(pmx% + x - 1, pmy% + y + 1) = posi% + 1
                IF x = 7 AND y = 4 THEN posi% = mapon%(pmx% + x + 1, pmy% + y + 1): IF posi% > 1279 THEN a = posi% MOD 4: IF a = 3 THEN mapon%(pmx% + x + 1, pmy% + y + 1) = posi% - 3 ELSE mapon%(pmx% + x + 1, pmy% + y + 1) = posi% + 1
        END IF
       
        IF ani% = 1 AND mapon%(pmx% + x, pmy% + y) < -1279 THEN
                a = -(mapon%(pmx% + x, pmy% + y) MOD 4)
                IF a = 3 THEN mapon%(pmx% + x, pmy% + y) = mapon%(pmx% + x, pmy% + y) + 3 ELSE mapon%(pmx% + x, pmy% + y) = mapon%(pmx% + x, pmy% + y) - 1
        END IF
       
        'Objekt zeichnen
        mpo% = mapon%(pmx% + x, pmy% + y)
        IF mpo% < 0 THEN mpo% = -mpo%
        Reihe = FIX((mpo% MOD 160) / 10) * 20
        Zeile = ((mpo% MOD 160) MOD 10) * 20
        DQBxPut 1 + FIX(mpo% / 160), Reihe, Zeile, Reihe + 19, Zeile + 19, B0, (x + 7) * 20 + 10, (y + 4) * 20 + 10
END IF

1
NEXT y
NEXT x

END SUB

REM $STATIC
FUNCTION Encode$ (what$)
res$ = ""
IF what$ = "" THEN EXIT FUNCTION
FOR n = 1 TO LEN(what$)
res$ = res$ + CHR$(ASC(MID$(what$, n, 1)) + 20)
NEXT n
Encode$ = res$
END FUNCTION

REM $DYNAMIC
SUB Ende
       
        DQBclose
        CLS
        dummy& = SETMEM(66000)
        dummy2& = SETMEM(17000)
        PRINT DQBerror$
        PRINT
        PRINT "Please read the manual to get further information."
        END
END SUB

REM $STATIC
SUB Event (eventcode&)
RANDOMIZE TIMER

nextevent:
IF eventcode& = 0 THEN EXIT SUB
IF eventcode& > 10000 THEN eneatt(6) = eventcode& MOD 100: eventcode& = FIX(eventcode& / 100)

OPEN "event.dat" FOR INPUT AS #3

DO
INPUT #3, nonsense$
LOOP UNTIL nonsense$ = "#" + RIGHT$(STR$(eventcode&), LEN(STR$(eventcode&)) - 1)

INPUT #3, ade

SELECT CASE ade

        CASE 1 'Simple Textmeldung
        GOSUB textout
        GOSUB innew
        DQBwait 10

        CASE 2 'Objekt erhalten
        GOSUB textout
        INPUT #3, what$
        INPUT #3, amount$
        ChangeInventar what$, "0", amount$
        GOSUB innew

        CASE 3 'Objekt verlieren
        GOSUB textout
        INPUT #3, what$
        INPUT #3, amount$
        ChangeInventar what$, "3", "1"
        ChangeInventar STR$(what), "2", amount$
        GOSUB innew

        CASE 4 'Attributsteigerung
        GOSUB textout
        INPUT #3, atc%
        INPUT #3, what$
        att(atc%) = att(atc%) + DiceNumber(what$)
        IF att(1) > att(2) THEN att(1) = att(2)
        IF att(8) > att(9) THEN att(8) = att(9)
        GOSUB innew

        CASE 5 'Attributsenkung
        GOSUB textout
        INPUT #3, atc%
        INPUT #3, what$
        att(atc%) = att(atc%) - DiceNumber(what$)
        IF att(atc%) < 0 THEN att(atc%) = 0
        IF att(1) > att(2) THEN att(1) = att(2)
        GOSUB innew

        CASE 8 'Objekt erhalten - Geld weg
        INPUT #3, Text$
        INPUT #3, what$
        INPUT #3, amount$
        INPUT #3, what
        IF att(7) - what >= 0 THEN ChangeInventar what$, "0", amount$: att(7) = att(7) - what: WriteText Text$, 150 ELSE WriteText "Ihr habt nicht genug Geld!", 150
        GOSUB innew

        CASE 9 'Zufallsevent (Weiterleitung)
        GOSUB textout
        zufall% = INT(RND * 10000 + 1)
        zahl% = 0
        INPUT #3, noa%
        FOR n = 1 TO noa%
                INPUT #3, anseve&(n)
                IF zahl% = 0 AND anseve&(n) >= zufall% THEN zahl% = n
        NEXT n
        FOR n = 1 TO noa%
                INPUT #3, anseve&(n)
        NEXT n
        CLOSE #3
        eventcode& = anseve&(zahl%)
        GOSUB nextevent
       
        CASE 10 'Frage
        npat% = 1
        GOSUB textout
        npat% = 0
        INPUT #3, breite%
        INPUT #3, noa%
        FOR n = 1 TO noa%
        INPUT #3, answer$(n)
        NEXT n
        FOR n = 1 TO noa%
        INPUT #3, anseve&(n)
        NEXT n
        CLOSE
        InputText 0, breite%, 130
        DrawScreen
        DrawFigur
        DrawRahmen
        DQBcopyLayer B0, VIDEO
        DQBclearLayer B0
        eventcode& = anseve&(ans%)
        GOSUB nextevent

        CASE 11 'öberprÅfung ob Attribut genug hoch
        GOSUB textout
        INPUT #3, atc%
        INPUT #3, zahl%
        GOSUB intw
        CLOSE #3
        IF att(atc%) >= zahl% THEN eventcode& = eventtrue% ELSE eventcode& = eventfalse%
        GOSUB nextevent

        CASE 12 'öberprÅfung Besitz eines Objektes
        GOSUB textout
        INPUT #3, what$
        INPUT #3, amount$
        GOSUB intw
        CLOSE #3
        ChangeInventar what$, "3", ""
        IF what > 0 AND hwm% >= VAL(amount$) THEN eventcode& = eventtrue% ELSE eventcode& = eventfalse%
        GOSUB nextevent
       
        CASE 13 'öberprÅfung Besitz eines Objektes und lîschen - Event weiter
        GOSUB textout
        INPUT #3, what$
        INPUT #3, amount$
        GOSUB intw
        CLOSE #3
        ChangeInventar what$, "3", ""
        IF what > 0 AND hwm% >= VAL(amount$) THEN
                eventcode& = eventtrue%
                ChangeInventar STR$(what), "2", amount$
        ELSE
                eventcode& = eventfalse%
        END IF
        GOSUB nextevent
       
        CASE 14 'Texteingabe
        Shade
        npat% = 1
        GOSUB textout
        npat% = 0
        INPUT #3, noa%
        FOR n = 1 TO noa%
        INPUT #3, answer$(n)
        NEXT n
        FOR n = 1 TO noa%
        INPUT #3, anseve&(n)
        NEXT n
        INPUT #3, evemist%
        CLOSE #3
        txt$ = TextEingabe$
        FOR n = 1 TO noa%
        IF answer$(n) = UCASE$(txt$) THEN eventcode& = anseve&(n): GOSUB nextevent
        NEXT n
        eventcode& = evemist%: GOSUB nextevent
       
       
        CASE 15 'Verkaufsevent
        DQBcopyLayer VIDEO, B0
        Shade
        GOSUB textout
        FOR n = 1 TO 5
        INPUT #3, answer$(n)
        NEXT n
       
        INPUT #3, mpp%
        CLOSE #3
        c = 0
       
        DO
        FOR n = 1 TO 3
        x1 = n * 30 + 90
        y1 = 120
        x2 = n * 30 + 111
        y2 = 141
        DQBboxf B0, x1, y1, x2, y2, 0
        DQBbox B0, x1, y1, x2, y2, 2
        IF n = 2 THEN DQBbox B0, x1 - 1, y1 - 1, x2 + 1, y2 + 1, 3
       
        IF n + c > 0 AND n + c < 21 THEN img = VAL(inv$(n + c, 4))
        IF n + c = 0 THEN img = VAL(inv$(20, 4))
        IF n + c = 21 THEN img = VAL(inv$(1, 4))

        Reihe = FIX((img MOD 160) / 10) * 20
        Zeile = ((img MOD 160) MOD 10) * 20
        DQBxPut 1 + FIX(img / 160), Reihe, Zeile, Reihe + 19, Zeile + 19, B0, x1 + 1, y1 + 1
        NEXT n
       
        DQBboxf B0, 60, 80, 260, 113, 0: DQBbox B0, 60, 80, 260, 113, 2: DQBboxf B0, 61, 81, 259, 112, 3: DQBboxf B0, 62, 82, 258, 111, 2
        DQBboxf B0, 120, 60, 200, 80, 0: DQBbox B0, 120, 60, 200, 80, 2:  DQBbox B0, 121, 61, 199, 79, 3:  DQBbox B0, 122, 62, 198, 78, 2
        DQBprint B0, STR$(att(7)), 120, 68, 31

        IF inv$(c + 2, 1) <> "" THEN
                DQBprint B0, STR$(VAL(inv$(c + 2, 6))) + " " + inv$(c + 2, 1), 60, 88, 31
                IF (inv$(c + 2, 2) = answer$(1) OR inv$(c + 2, 2) = answer$(2) OR inv$(c + 2, 2) = answer$(3) OR inv$(c + 2, 2) = answer$(4) OR inv$(c + 2, 2) = answer$(5)) THEN
                        IF inv$(c + 2, 2) = "E" THEN
                                DQBprint B0, STR$(toolvalue% * VAL(inv$(c + 2, 6)) * mpp%) + " Gold", 60, 100, 31
                        ELSE
                                DQBprint B0, STR$(VAL(inv$(c + 2, 3)) * VAL(inv$(c + 2, 6)) * mpp%) + " Gold", 60, 100, 31
                        END IF
                ELSE
                        DQBprint B0, " UnverkÑuflich", 60, 100, 31
                END IF
        END IF

        DQBcopyLayer B0, VIDEO
       
        IF DQBkey(KEYESC) THEN DQBclearLayer B0: DO: LOOP WHILE DQBkey(KEYESC): EXIT SUB
        IF DQBkey(KEYRIGHT) THEN c = c + 1: IF c > 18 THEN c = -1
        IF DQBkey(KEYLEFT) THEN c = c - 1: IF c < -1 THEN c = 18
        IF DQBkey(KEYENTER) THEN
                IF (inv$(c + 2, 2) = answer$(1) OR inv$(c + 2, 2) = answer$(2) OR inv$(c + 2, 2) = answer$(3) OR inv$(c + 2, 2) = answer$(4) OR inv$(c + 2, 2) = answer$(5)) THEN
                        IF inv$(c + 2, 2) <> "E" THEN att(7) = att(7) + VAL(inv$(c + 2, 3)) * VAL(inv$(c + 2, 6)) * mpp% ELSE att(7) = att(7) + VAL(inv$(c + 2, 6)) * mpp% * toolvalue%
                        x$ = inv$(c + 2, 6)
                        ChangeInventar STR$(c + 2), "2", x$
                END IF
        END IF
        DQBwait 8
        LOOP

       
        CASE 16 'Einkaufsevent
        DQBcopyLayer VIDEO, B0
        Shade
        npat% = 1: GOSUB textout: npat% = 0
       
        INPUT #3, noa%
        FOR n = 1 TO noa%
        INPUT #3, answer$(n)
        NEXT n
        FOR n = 1 TO noa%
        INPUT #3, eneatt(n)
        NEXT n
        CLOSE #3
        c = 0
             
        'Zuordnen der Bilder
        FOR m = 1 TO noa%
        FOR n = 1 TO LEN(answer$(m))
        IF MID$(answer$(m), n, 1) = "=" THEN EXIT FOR
        NEXT n
        anseve&(m) = VAL(MID$(answer$(m), n + 6, 3))
        NEXT m
       
        DO
        FOR n = 1 TO 3
        x1 = n * 30 + 90
        y1 = 120
        x2 = n * 30 + 111
        y2 = 141
        DQBboxf B0, x1, y1, x2, y2, 0
        DQBbox B0, x1, y1, x2, y2, 2
        IF n = 2 THEN DQBbox B0, x1 - 1, y1 - 1, x2 + 1, y2 + 1, 3
       
        IF n + c > 0 AND n + c < noa% + 1 THEN img = anseve&(n + c)
        IF n + c = 0 THEN img = anseve&(noa%)
        IF n + c = noa% + 1 THEN img = anseve&(1)
       
        Reihe = FIX((img MOD 160) / 10) * 20
        Zeile = ((img MOD 160) MOD 10) * 20
        DQBxPut 1 + FIX(img / 160), Reihe, Zeile, Reihe + 19, Zeile + 19, B0, x1 + 1, y1 + 1
        NEXT n
      
        DQBboxf B0, 60, 80, 260, 113, 0: DQBbox B0, 60, 80, 260, 113, 2: DQBbox B0, 61, 81, 259, 112, 3: DQBboxf B0, 62, 82, 258, 111, 2
        DQBboxf B0, 120, 60, 200, 80, 0: DQBbox B0, 120, 60, 200, 80, 2:  DQBbox B0, 121, 61, 199, 79, 3:  DQBbox B0, 122, 62, 198, 78, 2
        DQBprint B0, STR$(att(7)), 120, 68, 31

        FOR n = 1 TO LEN(answer$(c + 2))
        IF MID$(answer$(c + 2), n, 1) = "=" THEN EXIT FOR
        NEXT n
        nom$ = MID$(answer$(c + 2), 1, n - 1)

        DQBprint B0, nom$, 68, 88, 31
        DQBprint B0, STR$(eneatt(c + 2)) + " Gold", 60, 100, 31
      
        IF DQBkey(KEYESC) THEN DQBclearLayer B0: DO: LOOP WHILE DQBkey(KEYESC): EXIT SUB
        IF DQBkey(KEYRIGHT) THEN c = c + 1: IF c > noa% - 2 THEN c = -1
        IF DQBkey(KEYLEFT) THEN c = c - 1: IF c < -1 THEN c = noa% - 2
        IF DQBkey(KEYENTER) THEN IF att(7) - eneatt(c + 2) >= 0 THEN att(7) = att(7) - eneatt(c + 2): ChangeInventar answer$(c + 2), "0", "1": WriteText "Ihr habt " + nom$ + " gekauft!", 150 ELSE WriteText "Ihr habt nicht genug Gold.", 150
        DO: LOOP UNTIL NOT DQBkey(KEYENTER)
        DQBwait 8
        DQBcopyLayer B0, VIDEO
        LOOP
       
        CASE 20 'Kampf
        ozx% = zielx%: ozy% = ziely%
        IF map%(ozx%, ozy% - 1) > 0 AND mapon%(ozx%, ozy% - 1) <= 0 THEN mor%(1) = 1 ELSE mor%(1) = 0
        IF map%(ozx%, ozy% + 1) > 0 AND mapon%(ozx%, ozy% + 1) <= 0 THEN mor%(2) = 1 ELSE mor%(2) = 0
        IF map%(ozx% - 1, ozy%) > 0 AND mapon%(ozx% - 1, ozy%) <= 0 THEN mor%(3) = 1 ELSE mor%(3) = 0
        IF map%(ozx% + 1, ozy%) > 0 AND mapon%(ozx% + 1, ozy%) <= 0 THEN mor%(4) = 1 ELSE mor%(4) = 0
       
        GOSUB textout
        INPUT #3, eneatt(1)
        INPUT #3, eneatt(2)
        INPUT #3, eneatt(3)
        INPUT #3, zahl$
        enetex$(5) = zahl$
        INPUT #3, zahl$
        enetex$(6) = zahl$
        INPUT #3, eneatt(7)
        INPUT #3, eneatt(8)
        INPUT #3, enetex$(1)
        INPUT #3, enetex$(2)
        INPUT #3, enetex$(3)
        INPUT #3, enetex$(4)
        SaveStat
        oldmap$ = map$
        INPUT #3, map$
        INPUT #3, ter%
        INPUT #3, ausloes&
        newmap% = 2
        CLOSE #3
        EXIT SUB
       
        CASE 21 'VerÑndern der Zielkoordinate (direkt)
        GOSUB textout
        INPUT #3, map%(zielx%, ziely%): INPUT #3, mapinfo&(zielx%, ziely%): INPUT #3, mapon%(zielx%, ziely%)
        CLOSE #3
        EXIT SUB
       
        CASE 22 'öberprÅfen von Spielerkoordinate
        GOSUB textout
        INPUT #3, px%
        INPUT #3, py%
        INPUT #3, eventtrue%
        INPUT #3, eventfalse%
        CLOSE #3
        IF pmx% = px% AND pmy% = py% THEN eventcode& = eventtrue% ELSE eventcode& = eventfalse%
        GOSUB nextevent
       
        CASE 23 'VerÑndern der Spielerposition
        GOSUB textout
        INPUT #3, px%
        INPUT #3, py%
        pmx% = px%: pmy% = py%
        GOSUB innew

        CASE 24 'öberprÅfen von Terrain(Map/Mapon)
        GOSUB textout
        INPUT #3, ma%
        INPUT #3, mo%
        GOSUB intw
        CLOSE #3
        IF map%(pmx%, pmy%) = ma% AND mapon%(pmx%, pmy%) = mo% THEN eventcode& = eventtrue% ELSE eventcode& = eventfalse%
        GOSUB nextevent
       
        CASE 25 'VerÑndern von beliebigem Terrain an einer Koordinate
        GOSUB textout
        INPUT #3, x%
        INPUT #3, y%
        INPUT #3, map%(x%, y%): INPUT #3, mapinfo&(x%, y%): INPUT #3, mapon%(x%, y%)
        GOSUB innew

        CASE 26 'öberprÅfen von Terrain(Mapon) irgendwo
        GOSUB textout
        INPUT #3, xt%
        INPUT #3, yt%
        INPUT #3, wp%
        INPUT #3, op%
        GOSUB intw
        CLOSE #3
        IF mapon%(xt%, yt%) = op% AND map%(xt%, yt%) = wp% THEN eventcode& = eventtrue% ELSE eventcode& = eventfalse%
        GOSUB nextevent
       
        CASE 27 'öberprÅfen von Karte
        GOSUB textout
        INPUT #3, wmap$
        GOSUB intw
        CLOSE #3
        IF map$ = wmap$ THEN eventcode& = eventtrue% ELSE eventcode& = eventfalse%
        GOSUB nextevent
        
        CASE 28 'Timerevent
        GOSUB textout
        INPUT #3, time
        DQBwait time
        INPUT #3, eventcode&
        CLOSE #3
        ani% = 1: OnScreen: ani% = 0
        GOSUB nextevent
       
        CASE 30
        GOSUB textout
        INPUT #3, obje
        INPUT #3, time
        INPUT #3, stax, stay
        INPUT #3, ans%
       
        mapon%(pmx% + stax, pmy% + stay) = obje
        ani% = 1: OnScreen: ani% = 0: DQBwait time
        INPUT #3, bef$
        GOSUB innew
        CLOSE #3

        FOR n = 1 TO ans%
                mapon%(pmx% + stax, pmy% + stay) = oldon%
                SELECT CASE MID$(bef$, n, 1)
                        CASE "X": stax = stax + 1
                        CASE "x": stax = stax - 1
                        CASE "Y": stay = stay + 1
                        CASE "y": stay = stay - 1
                END SELECT
                oldon% = mapon%(pmx% + stax, pmy% + stay)
                mapon%(pmx% + stax, pmy% + stay) = obje
                ani% = 1: OnScreen: ani% = 0: DQBwait time
        NEXT n
        mapon%(pmx% + stax, pmy% + stay) = oldon%
       
        CASE 40 'Neue Karte
        GOSUB textout
        SaveStat
        oldmap$ = map$
        INPUT #3, map$
        INPUT #3, xpmx%, xpmy%
        INPUT #3, ausloes&
        newmap% = 1
        CLOSE #3
        EXIT SUB

        CASE 45 'Fade out
        GOSUB textout
        INPUT #3, time
        INPUT #3, eventcode&
        CLOSE #3
        DQBwait time
        DQBfadeTo 0, 0, 0
        DQBclearLayer VIDEO
        GOSUB nextevent
       
        CASE 46 'Fade in
        ani% = 1: OnScreen: ani% = 0
        GOSUB textout
        INPUT #3, time
        INPUT #3, eventcode&
        CLOSE #3
        DQBfadeIn palett
        DQBwait time
        GOSUB nextevent

END SELECT

CLOSE #3

IF att(1) <= 0 THEN Ende

IF infoafter& < -1 THEN eventcode& = -infoafter&: GOSUB nextevent ELSE IF infoafter& > -1 THEN mapinfo&(zielx%, ziely%) = infoafter&
IF mapafter% <> 0 THEN map%(zielx%, ziely%) = mapafter%
IF onafter% <> -1 THEN mapon%(zielx%, ziely%) = onafter%
EXIT SUB

textout:
INPUT #3, Text$
WriteText Text$, 150
RETURN

innew:
INPUT #3, mapafter%: INPUT #3, infoafter&: INPUT #3, onafter%
INPUT #3, what$: what = DiceNumber(what$): att(3) = att(3) + what
IF what > 0 THEN WriteText "+" + STR$(what) + " EP", 50
RETURN

intw:
INPUT #3, eventtrue%
INPUT #3, eventfalse%
RETURN

END SUB

SUB Fight (en%)

flyflag% = 0
fulene% = ene%(en%, 3)
GOSUB PrepareFight
GOSUB Graph

DO
        a = INT(RND * 100 + 1)
        IF a < prohityou THEN
                GOSUB Angriff
                GOSUB Defense
        ELSE
                GOSUB Defense
                GOSUB Angriff
        END IF
        
LOOP

Pause:
        FOR n = 1 TO fightspeed%
                IF DQBkey(23) THEN Inventar: GOSUB PrepareFight: EXIT FOR
                DQBwait 1
        NEXT n
RETURN

PrepareFight:
        FOR n = 1 TO 4: answer$(n) = "": NEXT n
        DrawScreen
        DrawFigur
        DrawRahmen
        
        DQBboxf B0, 10, 100, 309, 149, 0: DQBbox B0, 10, 100, 309, 149, 2: DQBbox B0, 11, 101, 308, 148, 3: DQBbox B0, 12, 102, 307, 147, 2
        DQBprint B0, enetex$(1) + ":", 18, 108, 31
        DQBprint B0, MID$(enetex$(2), 1, 36), 18, 120, 31
        DQBprint B0, MID$(enetex$(2), 37, 36), 18, 132, 31
        DQBboxf B0, 20, 20, 299, 79, 0: DQBbox B0, 20, 20, 299, 79, 2: DQBbox B0, 21, 21, 298, 78, 3: DQBbox B0, 22, 22, 297, 77, 2
        DQBbox B0, 227, 27, 252, 52, 0: DQBbox B0, 227, 27, 252, 52, 2: DQBbox B0, 228, 28, 251, 51, 3: DQBbox B0, 229, 29, 250, 50, 2
        DQBbox B0, 67, 27, 92, 52, 0: DQBbox B0, 67, 27, 92, 52, 2: DQBbox B0, 68, 28, 91, 51, 3: DQBbox B0, 69, 29, 90, 50, 2
        img = eneatt(7): Reihe = FIX((img MOD 160) / 10) * 20: Zeile = ((img MOD 160) MOD 10) * 20
        DQBxPut 1 + FIX(img / 160), Reihe, Zeile, Reihe + 19, Zeile + 19, B0, 230, 30
        DQBxPut 10, 1 * 80, (ap% - 1) * 20, 1 * 80 + 19, 19 + (ap% - 1) * 20, B0, 70, 30
        prohit = 100 / (att(10) + eneatt(3))
        prohitene = prohit * eneatt(3)
        prohityou = prohit * att(10)
RETURN

Graph:
        DQBboxf B0, 30, 60, 130, 69, 97
        DQBboxf B0, 185, 60, 285, 69, 97
        IF att(1) > 0 THEN DQBboxf B0, 30, 60, 30 + 100 * (att(1) / att(2)), 69, 96
        IF ene%(en%, 3) > 0 THEN DQBboxf B0, 185, 60, 185 + 100 * (ene%(en%, 3) / fulene%), 69, 96
        DQBcopyLayer B0, VIDEO
RETURN

Angriff:
        IF answer$(3) <> "" THEN DQBboxf B0, 255, 50, 290, 60, 0: DQBprint B0, answer$(3), 255, 50, 32
       
        IF INT(RND * 100 + 1) < prohityou THEN
                damabsene = (100 * eneatt(2)) / (att(5) + eneatt(2))
                dam = FIX(att(5) - att(5) * (damabsene / 100) + INT(RND * att(5) / 4 + 1) - att(5) / 8)
                ene%(en%, 3) = ene%(en%, 3) - dam
                answer$(1) = "-" + RIGHT$(STR$(dam), LEN(STR$(dam)) - 1)
        ELSE
                answer$(1) = "-0"
        END IF
       
        DQBboxf B0, 255, 35, 290, 45, 0
        DQBprint B0, answer$(1), 255, 35, 31
        answer$(3) = answer$(1)
        GOSUB Graph
        GOSUB Pause
        IF ene%(en%, 3) <= 0 THEN GOTO Ende2
RETURN

Defense:
        IF answer$(4) <> "" THEN DQBboxf B0, 95, 50, 160, 60, 0: DQBprint B0, answer$(4), 95, 50, 32
        IF INT(RND * 100 + 1) < prohitene THEN
                damabsyou = (100 * att(6)) / (att(6) + eneatt(1))
                dam = FIX(eneatt(1) - eneatt(1) * (damabsyou / 100) + INT(RND * eneatt(1) / 4 + 1) - eneatt(1) / 8)
                att(1) = att(1) - dam
                answer$(2) = "-" + RIGHT$(STR$(dam), LEN(STR$(dam)) - 1)
        ELSE
                answer$(2) = "-0"
        END IF
        DQBboxf B0, 95, 35, 160, 45, 0
        DQBprint B0, answer$(2), 95, 35, 31
        answer$(4) = answer$(2)
        GOSUB Graph
        GOSUB Pause
        IF att(1) <= 0 THEN Ende
RETURN

Ende2:
        att(3) = att(3) + DiceNumber(enetex$(6))
        att(7) = att(7) + DiceNumber(enetex$(5))
        ChangeInventar enetex$(4), "0", "1"
        mapon%(pmx%, pmy%) = 0
        FOR m = 1 TO 3
                ene%(en%, m) = ene%(eneatt(6), m)
        NEXT m
        eneatt(6) = eneatt(6) - 1
        DQBwait 10
        DQBclearLayer B0
EXIT SUB

Ende4:
        WriteText "Flucht gelungen.", 150
        mapon%(ene%(en%, 1), ene%(en%, 2)) = 0
3
        x% = INT(RND * mapx% + 1)
        y% = INT(RND * mapy% + 1)
        IF map%(x%, y%) > 0 AND mapon%(x%, y%) <= 0 AND (pmx% <> x% OR pmy% <> y%) THEN mapon%(x%, y%) = -eneatt(7) ELSE GOTO 3
        ene%(en%, 1) = x%
        ene%(en%, 2) = y%
        DQBclearLayer B0
END SUB

DEFSNG A-Z
SUB InputText (x1%, x2%, y2%)

DQBcopyLayer VIDEO, B0
Shade
DQBboxf B0, x1%, y2% - 9 - noa% * 10, x2%, y2%, 0: DQBbox B0, x1%, y2% - 9 - noa% * 10, x2%, y2%, 2: DQBbox B0, x1% + 1, y2% - 8 - noa% * 10, x2% - 1, y2% - 1, 3: DQBbox B0, x1% + 2, y2% - 7 - noa% * 10, x2% - 2, y2% - 2, 2

FOR n = 1 TO noa%
DQBprint B0, answer$(n), x1% + 10, y2% - 12 + 10 * (n - noa%), 31
NEXT n

ans% = 1

DO
DQBbox B0, x1% + 8, y2% - 14 + 10 * (ans% - noa%), x2% - 7, y2% - 4 + 10 * (ans% - noa%), 3
IF DQBkey(KEYENTER) THEN DQBclearLayer B0: DQBwait 10: EXIT SUB
IF DQBkey(KEYUP) THEN DQBbox B0, x1% + 8, y2% - 14 + 10 * (ans% - noa%), x2% - 7, y2% - 4 + 10 * (ans% - noa%), 0: DQBwait 10: IF ans% > 1 THEN ans% = ans% - 1 ELSE ans% = noa%
IF DQBkey(KEYDOWN) THEN DQBbox B0, x1% + 8, y2% - 14 + 10 * (ans% - noa%), x2% - 7, y2% - 4 + 10 * (ans% - noa%), 0: DQBwait 10: IF ans% < noa% THEN ans% = ans% + 1 ELSE ans% = 1
DQBcopyLayer B0, VIDEO
LOOP

DQBclearLayer B0

END SUB

DEFINT A-Z
SUB Inventar

ans% = 1
DQBclearLayer VIDEO
neuzeichnen:
DQBclearLayer B0

DQBbox B0, 0, 0, 319, 199, 2
DQBbox B0, 1, 1, 318, 198, 3
DQBbox B0, 2, 2, 317, 197, 2


FOR n = 1 TO 20
x1 = n * 30 - 17 - INT(n / 11) * 300
y1 = 139 + INT(n / 11) * 30
x2 = n * 30 - INT(n / 11) * 300 + 4
y2 = 160 + INT(n / 11) * 30
DQBbox B0, x1 + 1, y1 + 1, x2 - 1, y2 - 1, 2
img = VAL(inv$(n, 4))
Reihe = FIX((img MOD 160) / 10) * 20
Zeile = ((img MOD 160) MOD 10) * 20
DQBxPut 1 + FIX(img / 160), Reihe, Zeile, Reihe + 19, Zeile + 19, B0, x1 + 1, y1 + 1
IF inv$(n, 1) <> "" THEN IF VAL(inv$(n, 6)) > 1 THEN DQBprint B0, inv$(n, 6), x1 + 1, y1 + 1, 31
NEXT n

DQBprint B0, "Kraft:    " + STR$(att(5)), 10, 10, 31
DQBprint B0, "Abwehr:   " + STR$(att(6)), 10, 20, 31
DQBprint B0, "Geschick: " + STR$(att(10)), 10, 30, 31
DQBprint B0, "LP:       " + STR$(att(1)) + "/" + RIGHT$(STR$(att(2)), LEN(STR$(att(2))) - 1), 10, 40, 31
DQBprint B0, "Gold:     " + STR$(att(7)), 10, 60, 31
DQBprint B0, "Exp:      " + STR$(att(3)), 10, 70, 31
DQBprint B0, n$ + " in " + id$, 10, 85, 31

answer$(1) = "Helm:"
answer$(2) = "Waffe:"
answer$(3) = "RÅstung:"
answer$(4) = "Schild:"
answer$(5) = "Stiefel:"

FOR n = 0 TO 4
x1 = 280
y1 = 22 * n + 3
x2 = 299
y2 = 22 * n + 22
DQBbox B0, x1 + 1, y1 + 1, x2, y2, 2
DQBprint B0, answer$(n + 1), 200, y1 + 5, 31
img = VAL(inv$(n + 21, 4))
Reihe = FIX((img MOD 160) / 10) * 20
Zeile = ((img MOD 160) MOD 10) * 20
DQBxPut 1 + FIX(img / 160), Reihe, Zeile, Reihe + 19, Zeile + 19, B0, x1 + 1, y1 + 1
NEXT n

DO

x1 = ans% * 30 - 17 - INT(ans% / 11) * 300
y1 = 139 + INT(ans% / 11) * 30
x2 = ans% * 30 - INT(ans% / 11) * 300 + 4
y2 = 160 + INT(ans% / 11) * 30
DQBbox B0, x1, y1, x2, y2, 3

IF DQBkey(KEYESC) THEN DO: LOOP UNTIL NOT DQBkey(KEYESC): GOSUB Ende:
IF DQBkey(KEYUP) AND ans% > 10 THEN DQBbox B0, x1, y1, x2, y2, 0: ans% = ans% - 10
IF DQBkey(KEYDOWN) AND ans% <= 10 THEN DQBbox B0, x1, y1, x2, y2, 0: ans% = ans% + 10
IF DQBkey(KEYRIGHT) THEN
        DQBbox B0, x1, y1, x2, y2, 0
        IF ans% <> 10 AND ans% <> 20 THEN ans% = ans% + 1 ELSE ans% = ans% - 9
        DO: LOOP UNTIL NOT DQBkey(KEYRIGHT)
END IF

IF DQBkey(KEYLEFT) THEN
        DQBbox B0, x1, y1, x2, y2, 0
        IF ans% <> 1 AND ans% <> 11 THEN ans% = ans% - 1 ELSE ans% = ans% + 9
        DO: LOOP UNTIL NOT DQBkey(KEYLEFT)
END IF

IF DQBkey(32) THEN WriteText inv$(ans%, 5), 150
IF DQBkey(48) THEN ChangeInventar STR$(ans%), "1", "": DQBwait 10: GOSUB neuzeichnen
IF DQBkey(38) THEN
        oans% = ans%: npat% = 1: WriteText "Wollt ihr " + inv$(ans%, 1) + " wirklich lîschen?", 150: npat% = 0: noa% = 2: answer$(1) = "Ja": answer$(2) = "Nein": InputText 150, 200, 150
        IF ans% = 1 THEN x$ = inv$(oans%, 6): ChangeInventar STR$(oans%), "2", x$
        DQBwait 10
        ans% = oans%
        GOSUB neuzeichnen
END IF

DQBboxf B0, 10, 112, 310, 130, 0
DQBbox B0, 10, 112, 310, 130, 2
DQBbox B0, 11, 113, 309, 129, 3
DQBboxf B0, 12, 114, 308, 128, 2
DQBprint B0, inv$(ans%, 1), 20, 118, 31

DQBcopyLayer B0, VIDEO
LOOP

Ende:
DQBclearLayer VIDEO
DQBclearLayer B0

END SUB

SUB LevelUp

att(5) = att(5) + 2
att(6) = att(6) + 2
att(10) = att(10) + 1
att(2) = att(2) + 10
att(1) = att(2)
att(3) = att(3) - 500 * att(4)
att(4) = att(4) + 1

WriteText "Ihr seid auf Level" + STR$(att(4)) + " aufgestiegen.", 150

END SUB

FUNCTION LoadGame
File$ = DQBdir$("save\*.*", ATTRIB.D): File$ = DQBdir$("", 0)
noa% = 0
DO
        answer$(noa% + 1) = DQBdir$("", 0)
        IF answer$(noa% + 1) = "" THEN EXIT DO
        noa% = noa% + 1
        place$ = "save\" + answer$(noa%) + "\" + "me.dat"

        OPEN place$ FOR INPUT AS #1
        INPUT #1, x$
        answer$(noa%) = Decode$(x$)
        FOR n = 1 TO 5: INPUT #1, x$: NEXT n
        answer$(noa%) = answer$(noa%) + " - Lvl" + Decode(x$)
        CLOSE #1
LOOP

noa% = noa% + 1
answer$(noa%) = "zurÅck"

InputText 50, 270, 150

IF ans% = noa% THEN LoadGame = -1: EXIT FUNCTION

id$ = "save" + RIGHT$(STR$(ans%), 1)
LoadStat
LoadGame = 1
END FUNCTION

SUB LoadMap

        FOR y = 1 TO mapy%
        FOR x = 1 TO mapx%
                INPUT #1, map%(x, y), mapinfo&(x, y), mapon%(x, y)
        NEXT x
        NEXT y

        INPUT #1, pmx%, pmy%
        INPUT #1, sdf%
       
        CLOSE #1

IF pmodus% > 0 THEN

SELECT CASE pmodus%
CASE 1: pmx% = ozx%: pmy% = ozy% - 1
CASE 2: pmx% = ozx%: pmy% = ozy% + 1
CASE 3: pmx% = ozx% - 1: pmy% = ozy%
CASE 4: pmx% = ozx% + 1: pmy% = ozy%
CASE 5: pmx% = ozx%: pmy% = ozy%: IF ter% = 0 THEN mapinfo&(ozx%, ozy%) = 0: mapon%(ozx%, ozy%) = 0: zielx% = pmx%: ziely% = pmy%: pmodus% = 0: EXIT SUB
END SELECT

IF ter% = 0 THEN nr& = FIX(mapinfo&(ozx%, ozy%) / 100)
IF ter% = 0 THEN IF negeve% = 0 THEN mapinfo&(ozx%, ozy%) = 100 * nr& + eneatt(6) ELSE mapinfo&(ozx%, ozy%) = 100 * nr& - eneatt(6)
pmodus% = 0
negeve% = 0
ter% = 0

END IF

zielx% = pmx%
ziely% = pmy%

END SUB

REM $DYNAMIC
SUB LoadSprites
       
        IF DQBopenDataFile("sprites.bin", "") THEN Ende
        IF DQBunpackImage(SPRITES1, 1, 0, 0) THEN Ende
        IF DQBunpackImage(SPRITES2, 2, 0, 0) THEN Ende
        IF DQBunpackImage(SPRITES3, 3, 0, 0) THEN Ende
        IF DQBunpackImage(SPRITES4, 4, 0, 0) THEN Ende
        IF DQBunpackImage(SPRITES5, 5, 0, 0) THEN Ende
        IF DQBunpackImage(SPRITES6, 6, 0, 0) THEN Ende
        IF DQBunpackImage(SPRITES7, 7, 0, 0) THEN Ende
        IF DQBunpackImage(SPRITES8, 8, 0, 0) THEN Ende
        IF DQBunpackImage(SPRITES9, 9, 0, 0) THEN Ende
        IF DQBunpackImage(ANIM, 10, 0, 0) THEN Ende
        IF DQBunpackImage(RAHMEN, 13, 0, 0) THEN Ende
        IF DQBunpackPal(PALET, palett) THEN Ende
        IF DQBunpackFont(IRDENI, ifont) THEN Ende
        DQBsetFont ifont
        'DQBpalOff
        'IF DQBunpackImage(LOGO, VIDEO, 0, 0) THEN Ende
        'DQBcloseDataFile
        'DQBwait 100
        'DQBfadeIn palett
        'DQBwait 160
        'DQBfadeTo 0, 0, 0
        'DQBclearLayer VIDEO
       
        DQBsetPal (palett)
        'DQBwait 100
END SUB

REM $STATIC
SUB LoadStat

place$ = "save\" + id$ + "\" + "me.dat"

OPEN place$ FOR INPUT AS #1
INPUT #1, n$
n$ = Decode(n$)
INPUT #1, map$
map$ = Decode(map$)

FOR n = 1 TO 10
INPUT #1, att$
att(n) = VAL(Decode(att$))
NEXT n

FOR n = 1 TO 28
FOR m = 1 TO 6
INPUT #1, inv$(n, m)
IF inv$(n, m) = "-" THEN inv$(n, m) = "" ELSE inv$(n, m) = Decode(inv$(n, m))
NEXT m
NEXT n
CLOSE #1

newmap% = 1
END SUB

SUB MainMenu
7
DQBclearLayer VIDEO

answer$(1) = "Neues Spiel"
IF n$ <> "" THEN noa% = 5: answer$(1) = "ZurÅck zum Spiel": answer$(5) = "Neues Spiel" ELSE noa% = 4
answer$(2) = "Spiel laden"
answer$(3) = "Credits"
answer$(4) = "Beenden"

InputText 80, 240, 150

SELECT CASE ans%
CASE 1: IF n$ = "" THEN NewGame
        IF n$ = "" THEN GOTO 7 ELSE EXIT SUB
CASE 2: IF LoadGame = -1 THEN GOTO 7
CASE 3: Credits: GOTO 7
CASE 4: Ende
CASE 5: NewGame: GOTO 7
END SELECT

END SUB

SUB NewGame
      
File$ = DQBdir$("save\*.*", ATTRIB.D): File$ = DQBdir$("", 0)
noa% = 0

DO
        answer$(noa% + 1) = DQBdir$("", 0)
        IF answer$(noa% + 1) = "" THEN EXIT DO
        noa% = noa% + 1
        place$ = "save\" + answer$(noa%) + "\" + "me.dat"

        OPEN place$ FOR INPUT AS #1
        INPUT #1, x$
        answer$(noa%) = Decode$(x$)
        FOR n = 1 TO 5: INPUT #1, x$: NEXT n
        answer$(noa%) = answer$(noa%) + " - Lvl" + Decode(x$)
        CLOSE #1
LOOP


IF noa% < 6 THEN noa% = noa% + 1: answer$(noa%) = "leer"
noa% = noa% + 1: answer$(noa%) = "zurÅck"
InputText 50, 270, 150
IF ans% = noa% THEN EXIT SUB

n$ = "SimBa"
DQBclearLayer VIDEO
id$ = "save" + RIGHT$(STR$(ans%), 1)

SHELL "md save\" + id$
SHELL "del save\" + id$ + " *.*"
SHELL "copy *.map save\" + id$
SHELL "exit"
DQBclearLayer VIDEO

att(1) = 20
att(2) = 20
att(4) = 1
att(5) = 10
att(6) = 10
att(7) = 0
att(10) = 5
SaveStat

Event 1
at! = TIMER
richtung% = 1
END SUB

SUB OnScreen
IF ani% = 0 AND map%(zielx%, ziely%) > 0 AND mapon%(zielx%, ziely%) <= 0 AND zielx% > 0 AND ziely% > 0 AND zielx% <= mapx% AND ziely% <= mapy% THEN
        DrawAnimation
        IF mapinfo&(zielx%, ziely%) <= -10000 THEN negeve% = 1
        IF mapinfo&(zielx%, ziely%) < 0 THEN Event -mapinfo&(zielx%, ziely%)
END IF
IF ani% <> 0 THEN
        IF newmap% = 2 AND (map%(zielx%, ziely%) <= 0 OR mapon%(zielx%, ziely%) > 0) THEN DQBwait 10
        DrawScreen
        DrawFigur
        DrawRahmen
        DQBcopyLayer B0, VIDEO
        DQBclearLayer B0
END IF


END SUB

SUB OpenMap
        IF map$ = "" THEN map$ = "heimap.map"
        OPEN "save\" + id$ + "\" + map$ FOR INPUT AS #1
        INPUT #1, mapx%, mapy%

END SUB

SUB SaveStat
IF map$ = "" THEN GOSUB charsave
place$ = "save\" + id$ + "\" + map$
OPEN place$ FOR OUTPUT AS #1

PRINT #1, mapx%, mapy%

FOR y = 1 TO mapy%
FOR x = 1 TO mapx%
PRINT #1, map%(x, y); mapinfo&(x, y); mapon%(x, y);
NEXT x
PRINT #1,
NEXT y
PRINT #1, pmx%, pmy%
PRINT #1, sdf%
CLOSE #1

charsave:
place$ = "save\" + id$ + "\" + "me.dat"
OPEN place$ FOR OUTPUT AS #1
PRINT #1, Encode$(n$)
PRINT #1, Encode$(map$)

FOR n = 1 TO 10
IF att(n) > 0 THEN PRINT #1, Encode$(STR$(att(n))) ELSE PRINT #1, "0"
NEXT n

FOR n = 1 TO 28
FOR m = 1 TO 6
IF inv$(n, m) <> "" THEN PRINT #1, Encode$(inv$(n, m)) ELSE PRINT #1, "-"
NEXT m
NEXT n
CLOSE #1

END SUB

SUB Shade

FOR x = 0 TO 320 STEP 2
        FOR y = 0 TO 200 STEP 2
                DQBline B0, x, y, x, y, 0
        NEXT y
NEXT x

END SUB

FUNCTION TextEingabe$

        DQBcopyLayer VIDEO, B0
        DQBboxf B0, 0, 0, 319, 25, 0: DQBbox B0, 0, 0, 319, 25, 2: DQBbox B0, 1, 1, 318, 24, 3: DQBbox B0, 2, 2, 317, 23, 2
        DQBprint B0, "->", 10, 10, 31
        DQBcopyLayer B0, VIDEO
    
        DO
        DQBboxf B0, 0, 0, 319, 25, 0: DQBbox B0, 0, 0, 319, 25, 2: DQBbox B0, 1, 1, 318, 24, 3: DQBbox B0, 2, 2, 317, 23, 2
        DO: a$ = DQBinkey$: LOOP UNTIL a$ <> ""
        a$ = UCASE$(a$)
        IF ASC(a$) = 13 THEN TextEingabe$ = txt$: DQBclearLayer B0: EXIT FUNCTION
        IF ASC(a$) = 8 THEN IF LEN(txt$) > 0 THEN txt$ = LEFT$(txt$, LEN(txt$) - 1): GOTO 5 ELSE GOTO 5
        IF ASC(a$) = 27 THEN 5
        IF a$ = "Y" THEN a$ = "Z": GOTO 4
        IF a$ = "Z" THEN a$ = "Y"
4
        txt$ = txt$ + a$
5
        DQBprint B0, "->" + txt$, 10, 10, 31
        DQBcopyLayer B0, VIDEO
        LOOP
END FUNCTION

DEFSNG A-Z
SUB WriteText (Text$, y1%)
 
IF Text$ = "" THEN EXIT SUB

DQBboxf VIDEO, 0, y1%, 319, y1% + 49, 0: DQBbox VIDEO, 1, y1%, 319, y1% + 49, 2: DQBbox VIDEO, 2, y1% + 1, 318, y1% + 48, 3: DQBbox VIDEO, 3, y1% + 2, 317, y1% + 47, 2
c = 0
Speed = textspeed%
FOR n = 1 TO LEN(Text$)
IF (n + c) MOD 36 > 24 THEN IF MID$(Text$, n, 1) = " " THEN c = c + (36 - (n + c) MOD 36)

DQBprint VIDEO, MID$(Text$, n, 1), (((n + c) - 1) MOD 36) * 8 + 10, (INT(((n + c) - 1) / 36) + 1) * 10 + y1% - (INT(((n + c) - 1) / (36 * 3))) * 30, 31
               
DQBwait Speed
IF (n + c) MOD (36 * 3) = 0 THEN DQBtri VIDEO, 300, y1% + 40, 305, y1% + 45, 310, y1% + 40, 3: DO: LOOP UNTIL DQBkey(KEYSPACE): DQBboxf VIDEO, 4, y1% + 3, 316, y1% + 46, 0: Speed = textspeed%: DQBwait 10
IF DQBkey(KEYSPACE) THEN Speed = 1
IF DQBkey(KEYESC) THEN EXIT SUB
NEXT n

IF npat% = 0 THEN DO: LOOP UNTIL DQBkey(KEYSPACE)

END SUB

