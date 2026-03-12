DEFINT A-Z

'$INCLUDE: 'DIRECTQB.BI'
IF DQBinit(2, 0, 0) THEN DQBclose: PRINT DQBerror$: END

FOR i = 0 TO 14
  DQBbox 2, (i * 16), 0, (i * 16) + 15, 15, 4
  DQBline 2, (i * 16) + (15 - i), 15, (i * 16) + i, 0, 40
  DQBline 2, (i * 16) + 15, i, (i * 16), (15 - i), 40
NEXT i

DQBinitVGA

  DQBcopyLayer 2, VIDEO
SLEEP


DQBclose

