'$INCLUDE: 'DATA.SBX'
'$INCLUDE: 'DIRECTQB.BI'

DECLARE SUB OpenMap ()
DECLARE SUB LoadMap ()
DECLARE SUB Ende ()
DECLARE SUB LoadSprites ()
DECLARE SUB OnScreen ()
DECLARE SUB DrawScreen ()
DECLARE SUB DrawAnimation ()
DECLARE SUB DrawFigur ()
DECLARE SUB Speichern ()

COMMON SHARED startx%, starty%, zielx%, ziely%, mapx%, mapy%, pmx%, pmy%, standardfeld%, richtung%
COMMON SHARED sdf%, map$, dummy&

CONST ap% = 1

DEFINT A-Z
DIM SHARED pal AS STRING * 768
DIM SHARED invent$(9, 30), attrib(9, 10)

CLS
LOCATE 1, 1: INPUT "X-Gr”sse:", mapx%
LOCATE 1, 1: INPUT "Y-Gr”sse:", mapy%
LOCATE 1, 1: INPUT "Standardfeld:", standardfeld%

REDIM SHARED map%(mapx% + 1, mapy% + 1), mapinfo&(mapx% + 1, mapy% + 1), mapon%(mapx% + 1, mapy% + 1)

FOR n = 1 TO mapx%
FOR m = 1 TO mapy%
map%(n, m) = standardfeld%
NEXT m
NEXT n

pmx% = INT(mapx% / 2) + 1
pmy% = INT(mapy% / 2) + 1


CLS
dummy& = SETMEM(-66000)

IF DQBinit(10, 0, 0) THEN Ende
       
        IF DQBsetBaseLayer(B0) = 0 THEN Ende
        'DQBinitVGA
        SCREEN 13
        LoadSprites


DO
DQBprint B0, STR$(map%(pmx%, pmy%)) + "/" + STR$(mapinfo&(pmx%, pmy%)) + "/" + STR$(mapon%(pmx%, pmy%)), 0, 0, 31
DQBprint B0, STR$(pmx%) + "/" + STR$(pmy%), 150, 0, 31
kbd$ = INKEY$
                                           
IF kbd$ <> "" THEN
kbd$ = RIGHT$(kbd$, 1)

SELECT CASE kbd$

CASE CHR$(27): Ende

CASE CHR$(72)
        richtung% = 0: ziely% = pmy% - 1: zielx% = pmx%: OnScreen

CASE CHR$(80)
        richtung% = 1: ziely% = pmy% + 1: zielx% = pmx%: OnScreen
CASE CHR$(77)
        richtung% = 3: ziely% = pmy%: zielx% = pmx% + 1: OnScreen
CASE CHR$(75)
        richtung% = 2: ziely% = pmy%: zielx% = pmx% - 1: OnScreen

CASE CHR$(115)
        Speichern

CASE CHR$(108)
        OpenMap
        REDIM SHARED map%(mapx% + 1, mapy% + 1), mapinfo&(mapx% + 1, mapy% + 1), mapon%(mapx% + 1, mapy% + 1)
        LoadMap

CASE CHR$(101)
       LOCATE 1, 1: INPUT "Event:", mapinfo&(pmx%, pmy%)

CASE CHR$(9)
        map%(pmx%, pmy%) = 0
        mapinfo&(pmx%, pmy%) = 0
        mapon%(pmx%, pmy%) = 0

CASE CHR$(103)
        map%(pmx%, pmy%) = 1


CASE CHR$(118)
        LOCATE 1, 1: INPUT "Quickmap: ", quickmap%
        LOCATE 1, 1: INPUT "Quickevent: ", quickevent&
        LOCATE 1, 1: INPUT "Quickobjekt: ", quickobjekt%

CASE CHR$(113)
        map%(pmx%, pmy%) = quickmap%
        mapinfo&(pmx%, pmy%) = quickevent&
        mapon%(pmx%, pmy%) = quickobjekt%

CASE CHR$(107)
startx% = pmx%
starty% = pmy%
BEEP

CASE CHR$(98)
LOCATE 1, 1: INPUT "Grafik:", map%(pmx%, pmy%)
      
CASE CHR$(111)
INPUT "Objekt: ", mapon%(pmx%, pmy%)

CASE CHR$(49)
DQBcopyLayer 1, VIDEO
SLEEP
CASE CHR$(50)
DQBcopyLayer 2, VIDEO
SLEEP
CASE CHR$(51)
DQBcopyLayer 3, VIDEO
SLEEP
CASE CHR$(52)
DQBcopyLayer 4, VIDEO
SLEEP
CASE CHR$(53)
DQBcopyLayer 5, VIDEO
SLEEP
CASE CHR$(54)
DQBcopyLayer 6, VIDEO
SLEEP
CASE CHR$(55)
DQBcopyLayer 7, VIDEO
SLEEP
CASE CHR$(56)
DQBcopyLayer 8, VIDEO
SLEEP
CASE CHR$(57)
DQBcopyLayer 9, VIDEO
SLEEP
CASE CHR$(48)
DQBcopyLayer 10, VIDEO
SLEEP




END SELECT
END IF
richtung% = 4: OnScreen
LOOP

REM $DYNAMIC
SUB DrawFigur

DQBBox B0, 150, 90, 169, 109, 1
DQBBox B0, 151, 91, 168, 108, 14
DQBcopyLayer B0, VIDEO
DQBclearLayer B0
END SUB

SUB DrawScreen

FOR x = -7 TO 7
FOR y = -4 TO 4

IF pmx% + x < 1 OR pmy% + y < 1 OR pmx% + x > mapx% OR pmy% + y > mapy% THEN DQBLine B0, (x + 7) * 20 + 10, (y + 4) * 20 + 10, (x + 7) * 20 + 29, (y + 4) * 20 + 29, 1: GOTO 1

mp% = map%(pmx% + x, pmy% + y)
IF mp% < 0 THEN mp% = -mp%

Reihe = FIX((mp% MOD 160) / 10) * 20
Zeile = ((mp% MOD 160) MOD 10) * 20
DQBxPut 1 + FIX(mp% / 160), Reihe, Zeile, Reihe + 19, Zeile + 19, B0, (x + 7) * 20 + 10, (y + 4) * 20 + 10

IF mapon%(pmx% + x, pmy% + y) <> 0 THEN
        mpo% = mapon%(pmx% + x, pmy% + y)
        IF mpo% < 0 THEN mpo% = -mpo%
        Reihe = INT((mpo% MOD 160) / 10) * 20
        Zeile = ((mpo% MOD 160) MOD 10) * 20
        DQBxPut 1 + INT(mpo% / 160), Reihe, Zeile, Reihe + 19, Zeile + 19, B0, (x + 7) * 20 + 10, (y + 4) * 20 + 10
END IF

1
NEXT y
NEXT x

END SUB

SUB Ende
       
        DQBclose
        CLS
        dummy& = SETMEM(66000)
        PRINT DQBerror$
        PRINT
        PRINT "Please read the manual to get further information."
        END
END SUB

REM $STATIC
SUB LoadMap

        FOR y = 1 TO mapy%
        FOR x = 1 TO mapx%
                INPUT #1, map%(x, y), mapinfo&(x, y), mapon%(x, y)
        NEXT x
        NEXT y
      
        INPUT #1, startx%, starty%
        INPUT #1, sdf%
CLOSE #1

END SUB

REM $DYNAMIC
SUB LoadSprites
       
        IF DQBopenDataFile("data.sba", "") THEN Ende
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
        IF DQBunpackPal(PALET, pal) THEN Ende
        DQBsetPal (pal)


END SUB

REM $STATIC
SUB OnScreen
IF richtung% < 4 AND zielx% > 0 AND ziely% > 0 AND zielx% <= mapx% AND ziely% <= mapy% THEN pmx% = zielx%: pmy% = ziely%
DrawScreen
DrawFigur
END SUB

SUB OpenMap
        LOCATE 1, 1: INPUT "Name zum Laden:", map$
        map$ = "map\" + map$ + ".map"
        OPEN map$ FOR INPUT AS #1
        INPUT #1, mapx%, mapy%
        pmx% = INT(mapx% / 2) + 1
        pmy% = INT(mapy% / 2) + 1

END SUB

SUB Speichern

LOCATE 1, 1: INPUT "Name zum Speichern:", map$
map$ = "map\" + map$ + ".map"
OPEN map$ FOR OUTPUT AS #1

PRINT #1, mapx%, mapy%

FOR y = 1 TO mapy%
FOR x = 1 TO mapx%
PRINT #1, map%(x, y); mapinfo&(x, y); mapon%(x, y);
NEXT x
PRINT #1,
NEXT y
PRINT #1, startx%, starty%
PRINT #1, sdf%
CLOSE

END SUB

