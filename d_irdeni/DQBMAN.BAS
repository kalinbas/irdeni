' ---------------------------------------------------------------------------
'
'                       The DirectQB Library Manager
'                               version  1.2
'
'                *** Builds DirectQB 1.61 library files ***
'
'                by Angelo Mottola - Enhanced Creations 1999
'
' This program allows you to create and customize your own copy of the
' DirectQB library. The BC, LINK and LIB programs are called to accomplish
' this task, and each time you compile the library, the file DIRECTQB.LOG is
' created, and holds the actual shell commands used.
' The utility also creates the DIRECTQB.BI and CALLS.BAS files depending on
' which modules you include in the library; see the help window for more info
' on each module. For a detailed explanation on how to use DirectQB and its
' functions, read carefully the DIRECTQB.DOC file.
'
' Hint: it is recommended that you compile this program and always run the
' EXE version, as by running this within the QB IDE could cause some out of
' memory problems when calling the BC, LIB and LINK program to create the
' library. In addition, once compiled you can easily maintain DirectQB, and
' you can also use the /Q switch from the command line to quickly rebuild the
' library once, assuming no changes (that's mainly for debug purposes)
'
' What's new in version 1.2: The QB45 directory search bug has been fixed;
'   now it first asks for the correct QB45 path, and scans disk for it only
'   if you hit enter without entering it. Also updated the library manager
'   to build DirectQB 1.61 library files.
'
' Contact informations:
'
' Angelo Mottola                        angelillo@bigfoot.com
' Enhanced Creations Homepage           http://ec.quickbasic.com
'
' Thanks for using DirectQB!
'
' ---------------------------------------------------------------------------
DEFINT A-Z

TYPE RegType
  ax AS INTEGER
  bx AS INTEGER
  cx AS INTEGER
  dx AS INTEGER
  bp AS INTEGER
  si AS INTEGER
  di AS INTEGER
  flags AS INTEGER
  ds AS INTEGER
  es AS INTEGER
END TYPE

DECLARE SUB Init ()
DECLARE SUB Main ()
DECLARE SUB ReadHelp (HelpCode, MaxLines)
DECLARE SUB SwitchFocus (focus)
DECLARE SUB MakeDQB ()
DECLARE SUB BuildBI ()
DECLARE SUB BuildCALLS ()
DECLARE SUB BuildLibrary ()
DECLARE SUB WriteTemp (num, l$)
DECLARE SUB Center (y, t$)
DECLARE SUB DrawWindow (x1, y1, x2, y2, title$, c)
DECLARE SUB DrawSelBar (sel)
DECLARE SUB ClearSelBar (sel)
DECLARE SUB interruptx (IntNum, inreg AS RegType, OutReg AS RegType)
DECLARE FUNCTION FindPath ()
DECLARE FUNCTION QBdir$ (filespec$, attr)
DECLARE FUNCTION path$ ()

CONST mMAIN = 1, mDRAW = 2, mIMAGE = 3, mSPRITE = 4, mBIT = 5, mPALETTE = 6
CONST mFONT = 7, mDISK = 8, mBLENDING = 9, mKEYBOARD = 10, mJOYSTICK = 11
CONST mMOUSE = 12, mSOUND = 13, m3D = 14, mDATAFILE = 15
CONST MAXDIRS = 30, MAXFILES = 300
CONST VERSION$ = "1.2", HelpFile$ = "DQBMAN.MHL", LIBVERSION$ = "1.61"
CONST DataFile$ = "INSTALL.DAT", LogFile$ = "INSTALL.LOG"
CONST Bar$ = "----------------------------------------------------------------------------"
DIM SHARED Module(16) AS STRING, Install(16) AS INTEGER, Old(16) AS INTEGER
DIM SHARED QBpath AS STRING, HelpLine(300) AS STRING, ErrDir AS INTEGER
DIM SHARED temps AS INTEGER, done AS INTEGER, QuickMode AS INTEGER
DIM SHARED DTA AS STRING * 44

ON ERROR GOTO ErrorHandler

QuickMode = -1
IF COMMAND$ <> "" THEN
  PRINT
  PRINT "DirectQB Library Manager version " + VERSION$
  PRINT "by Angelo Mottola - Enhanced Creations 1998-99"
  PRINT
  IF UCASE$(COMMAND$) = "/Q" THEN
    FOR i = 1 TO 15
      READ Module(i)
      OPEN Module(i) FOR BINARY AS #1: l& = LOF(1): CLOSE #1
      IF l& = 0 THEN KILL Module(i): ERROR 77
    NEXT i
    OPEN DataFile$ FOR BINARY AS #1: l& = LOF(1): CLOSE #1
    IF l& = 0 THEN KILL DataFile$: ERROR 79
    OPEN DataFile$ FOR INPUT AS #1
    FOR i = 1 TO 15
      INPUT #1, Old(i): Install(i) = Old(i)
    NEXT i
    INPUT #1, QBpath
    CLOSE #1
    PRINT "Building DirectQB.";
    BuildBI
    BuildCALLS
    BuildLibrary
    PRINT "done!"
    PRINT
  ELSE
    PRINT "Unknown option " + CHR$(34) + COMMAND$ + CHR$(34)
    PRINT
    PRINT "Usage:"
    PRINT "  DQBMAN     Starts the DirectQB Library Manager"
    PRINT "  DQBMAN /Q  Rebuilds the library without changes (quickmode)"
    PRINT
  END IF
  END
END IF

QuickMode = 0
Init
Main
SCREEN 1: SCREEN 0: WIDTH 80
PRINT "Thanks for using the DirectQB Library Manager"
OPEN DataFile$ FOR OUTPUT AS #1
FOR i = 1 TO 15: PRINT #1, Old(i): NEXT i
PRINT #1, QBpath: CLOSE #1
END

DATA "MAIN.OBJ"
DATA "DRAW.OBJ"
DATA "IMAGE.OBJ"
DATA "SPRITE.OBJ"
DATA "BIT.OBJ"
DATA "PALETTE.OBJ"
DATA "FONT.OBJ"
DATA "DISK.OBJ"
DATA "BLENDING.OBJ"
DATA "KEYBOARD.OBJ"
DATA "JOYSTICK.OBJ"
DATA "MOUSE.OBJ"
DATA "SOUND.OBJ"
DATA "3D.OBJ"
DATA "DATAFILE.OBJ"

ErrorHandler:
SCREEN 1: SCREEN 0: WIDTH 80: COLOR 7, 0: CLS
SELECT CASE ERR
CASE 77
  PRINT "Cannot locate DQB module file(s); you must run this program from your DirectQB"
  PRINT "main directory!"
CASE 78
  PRINT "Cannot locate " + HelpFile$ + ". Please run DQBMAN from your main DQB directory!"
CASE 79
  PRINT "Cannot use quick mode: library has never been created before!"
CASE ELSE
  PRINT "Unexpected program error (code" + STR$(ERR) + "), program aborted."
END SELECT
PRINT : END

DirCheck:
IF ERR = 76 THEN ErrDir = 1 ELSE ErrDir = 2
RESUME NEXT

SUB BuildBI
'
OPEN "DIRECTQB.BI" FOR OUTPUT AS #1
PRINT #1, "'" + Bar$
PRINT #1, "' DIRECTQB.BI"
PRINT #1, "'   Include file for the DirectQB library version " + LIBVERSION$
PRINT #1, "'   by Angelo Mottola - Enhanced Creations 1998-99"
PRINT #1, "'"
PRINT #1, "' This file contains constants and function declarations used by the library"
PRINT #1, "' Always include this file into your own programs!"
PRINT #1, "'"
PRINT #1, "' Include file created on " + DATE$ + " by the DirectQB Library Manager v" + VERSION$
PRINT #1, "' Run DQBMAN again to modify your DirectQB module settings"
PRINT #1, "'"
PRINT #1, "' þ Read DIRECTQB.DOC for detailed informations on how to use the library"
PRINT #1, "'" + Bar$
PRINT #1, ""
PRINT #1, "'$DYNAMIC"
PRINT #1, "DEFINT A-Z"
PRINT #1, ""
PRINT #1, "' Procedures from MAIN.OBJ:"
PRINT #1, "DECLARE FUNCTION DQBinit% (BYVAL NumLayers%, BYVAL NumSounds%, BYVAL MemSize%)"
PRINT #1, "DECLARE FUNCTION DQBver% ()"
PRINT #1, "DECLARE FUNCTION DQBid$ ()"
PRINT #1, "DECLARE FUNCTION DQBmapLayer% (BYVAL Layer%)"
PRINT #1, "DECLARE SUB DQBclose ()"
PRINT #1, "DECLARE SUB DQBpeek (BYVAL DataSeg%, BYVAL DataOff%, BYVAL Offset&, BYVAL Length%)"
PRINT #1, "DECLARE SUB DQBpoke (BYVAL DataSeg%, BYVAL DataOff%, BYVAL Offset&, BYVAL Length%)"
PRINT #1, "DECLARE SUB DQBsort (BYVAL ArraySeg%, BYVAL ArrayOff%, BYVAL NumRecords%, BYVAL RecordLen%, BYVAL IndexOff%)"
PRINT #1, "DECLARE FUNCTION DQBangle% (BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%)"
PRINT #1, "DECLARE SUB DQBinitVGA ()"
PRINT #1, "DECLARE SUB DQBinitText ()"
PRINT #1, "DECLARE FUNCTION DQBsetBaseLayer% (BYVAL Layer%)"
PRINT #1, "DECLARE SUB DQBcopyLayer (BYVAL SourceLayer%, BYVAL DestLayer%)"
PRINT #1, "DECLARE SUB DQBclearLayer (BYVAL Layer%)"
PRINT #1, "DECLARE SUB DQBwait (BYVAL Times%)"
PRINT #1, "DECLARE SUB DQBsetFrameRate (BYVAL FPS%)"
PRINT #1, "DECLARE FUNCTION DQBframeReady% ()"
PRINT #1, "DECLARE FUNCTION DQBerror$ ()"
IF Install(mDRAW) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from DRAW.OBJ:"
  PRINT #1, "DECLARE SUB DQBcopyTransLayer (BYVAL SourceLayer%, BYVAL DestLayer%)"
  PRINT #1, "DECLARE SUB DQBcopyHitLayer (BYVAL SourceLayer%, BYVAL DestLayer%, BYVAL Col%)"
  PRINT #1, "DECLARE SUB DQBpset (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL Col%)"
  PRINT #1, "DECLARE FUNCTION DQBpoint% (BYVAL Layer%, BYVAL x%, BYVAL y%)"
  PRINT #1, "DECLARE SUB DQBline (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL Col%)"
  PRINT #1, "DECLARE SUB DQBgline (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL Col1%, BYVAL Col2%)"
  PRINT #1, "DECLARE SUB DQBellipse (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL rx%, BYVAL ry%, BYVAL Col%)"
  PRINT #1, "DECLARE SUB DQBbox (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL Col%)"
  PRINT #1, "DECLARE SUB DQBboxf (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL Col%)"
  PRINT #1, "DECLARE SUB DQBpaint (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL Col%)"
  PRINT #1, "DECLARE SUB DQBscroll (BYVAL Layer%, BYVAL dx%, BYVAL dy%)"
  PRINT #1, "DECLARE SUB DQBscrollArea (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL Direction%)"
  PRINT #1, "DECLARE SUB DQBsetTransPut ()"
  PRINT #1, "DECLARE SUB DQBsetSolidPut ()"
  PRINT #1, "DECLARE SUB DQBget (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL BufSeg%, BYVAL BufOff%)"
  PRINT #1, "DECLARE SUB DQBput (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL BufSeg%, BYVAL BufOff%)"
END IF
IF Install(mIMAGE) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from IMAGE.OBJ:"
  PRINT #1, "DECLARE FUNCTION DQBloadImage% (Layer%, x%, y%, FileName$, Pal$, imgWidth%, imgHeight%)"
  PRINT #1, "DECLARE FUNCTION DQBsaveImage% (Layer%, x1%, y1%, x2%, y2%, FileName$, Pal$, Format%)"
  PRINT #1, "DECLARE FUNCTION DQBplayFLI% (FileName$, BufLayer%, KeyStop%, LoopFlag%)"
  PRINT #1, "DECLARE FUNCTION DQBopenFLI% (FileName$, Frames%, Speed%)"
  PRINT #1, "DECLARE SUB DQBplayFLIstep (BYVAL Layer%)"
  PRINT #1, "DECLARE SUB DQBcloseFLI ()"
END IF
IF Install(mSPRITE) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from SPRITE.OBJ:"
  PRINT #1, "DECLARE FUNCTION DQBsize% (BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%)"
  PRINT #1, "DECLARE SUB DQBsetClipBox (BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%)"
  PRINT #1, "DECLARE SUB DQBfPut (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL BufSeg%, BYVAL BufOff%)"
  PRINT #1, "DECLARE SUB DQBsPut (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL BufSeg%, BYVAL BufOff%, BYVAL NewWidth%, BYVAL NewHeight%)"
  PRINT #1, "DECLARE SUB DQBrPut (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL BufSeg%, BYVAL BufOff%, BYVAL Angle%, BYVAL Zoom%)"
  PRINT #1, "DECLARE SUB DQBxPut (BYVAL SourceLayer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL DestLayer%, BYVAL x%, BYVAL y%)"
  PRINT #1, "DECLARE SUB DQBmPut (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL BufSeg%, BYVAL BufOff%, BYVAL Flip%)"
  PRINT #1, "DECLARE SUB DQBhPut (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL BufSeg%, BYVAL BufOff%, BYVAL Col%)"
  PRINT #1, "DECLARE SUB DQBtPut (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL BufSeg%, BYVAL BufOff%, BYVAL BitMode%)"
  PRINT #1, "DECLARE SUB DQBpPut (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL BufSeg%, BYVAL BufOff%, BYVAL Pattern%)"
  PRINT #1, "DECLARE SUB DQBputOver (BYVAL BackSeg%, BYVAL BackOff%, BYVAL x%, BYVAL y%, BYVAL BufSeg%, BYVAL BufOff%)"
  PRINT #1, "DECLARE SUB DQBsetCollideMethod (BYVAL Method%)"
  PRINT #1, "DECLARE FUNCTION DQBcollide% (BYVAL x1%, BYVAL y1%, BYVAL Seg1%, BYVAL Off1%, BYVAL x2%, BYVAL y2%, BYVAL Seg2%, BYVAL Off2%)"
  PRINT #1, "DECLARE FUNCTION DQBcollideOnLayer% (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL SpriteSeg%, BYVAL SpriteOff%)"
END IF
IF Install(mBIT) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from BIT.OBJ:"
  PRINT #1, "DECLARE FUNCTION DQBsetBit% (BYVAL Value%, BYVAL Bit%)"
  PRINT #1, "DECLARE FUNCTION DQBresetBit% (BYVAL Value%, BYVAL Bit%)"
  PRINT #1, "DECLARE FUNCTION DQBreadBit% (BYVAL Value%, BYVAL Bit%)"
  PRINT #1, "DECLARE FUNCTION DQBtoggleBit% (BYVAL Value%, BYVAL Bit%)"
  PRINT #1, "DECLARE FUNCTION DQBshiftLeft% (BYVAL Value%, BYVAL nBits%)"
  PRINT #1, "DECLARE FUNCTION DQBshiftRight% (BYVAL Value%, BYVAL nBits%)"
END IF
IF Install(mPALETTE) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from PALETTE.OBJ:"
  PRINT #1, "DECLARE SUB DQBsetCol (BYVAL ColorIndex%, BYVAL Red%, BYVAL Green%, BYVAL Blue%)"
  PRINT #1, "DECLARE SUB DQBgetCol (BYVAL ColorIndex%, Red%, Green%, Blue%)"
  PRINT #1, "DECLARE FUNCTION DQBfindCol% (BYVAL Red%, BYVAL Green%, BYVAL Blue%)"
  PRINT #1, "DECLARE FUNCTION DQBfindPalCol% (Pal$, Red%, Green%, Blue%)"
  PRINT #1, "DECLARE SUB DQBsetPal (Pal$)"
  PRINT #1, "DECLARE SUB DQBgetPal (Pal$)"
  PRINT #1, "DECLARE SUB DQBfadeIn (Pal$)"
  PRINT #1, "DECLARE SUB DQBfadeStepIn (Pal$)"
  PRINT #1, "DECLARE SUB DQBfadeTo (BYVAL Red%, BYVAL Green%, BYVAL Blue%)"
  PRINT #1, "DECLARE SUB DQBfadeStepTo (BYVAL Red%, BYVAL Green%, BYVAL Blue%)"
  PRINT #1, "DECLARE SUB DQBpalOff ()"
  PRINT #1, "DECLARE SUB DQBpalRotate (BYVAL FirstCol%, BYVAL LastCol%, BYVAL RotDir%)"
END IF
IF Install(mFONT) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from FONT.OBJ:"
  PRINT #1, "DECLARE SUB DQBprint (Layer%, Text$, x%, y%, Col%)"
  PRINT #1, "DECLARE SUB DQBprints (Layer%, Text$, x%, y%, Col%, Style%)"
  PRINT #1, "DECLARE FUNCTION DQBlen% (Text$)"
  PRINT #1, "DECLARE SUB DQBsetBIOSfont ()"
  PRINT #1, "DECLARE FUNCTION DQBloadFont% (FileName$)"
  PRINT #1, "DECLARE SUB DQBsetFont (Font$)"
  PRINT #1, "DECLARE SUB DQBsetTextStyle (BYVAL Style%)"
  PRINT #1, "DECLARE SUB DQBsetTextBackCol (BYVAL Col%)"
  PRINT #1, "DECLARE SUB DQBsetTextSpacing (BYVAL Spacing%)"
  PRINT #1, "DECLARE SUB DQBsetTextBMap (BYVAL BMap%)"
  PRINT #1, "DECLARE SUB DQBsetFontTexture (BYVAL TextSeg%, BYVAL TextOff%)"
END IF
IF Install(mDISK) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from DISK.OBJ:"
  PRINT #1, "DECLARE FUNCTION DQBdir$ (Mask$, Attributes%)"
  PRINT #1, "DECLARE FUNCTION DQBdrive$ ()"
  PRINT #1, "DECLARE FUNCTION DQBpath$ ()"
  PRINT #1, "DECLARE FUNCTION DQBnumDrives% ()"
  PRINT #1, "DECLARE SUB DQBsetDrive (NewDrive$)"
  PRINT #1, "DECLARE FUNCTION DQBchDir (NewDir$)"
END IF
IF Install(mBLENDING) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from BLENDING.OBJ:"
  PRINT #1, "DECLARE SUB DQBfilterBox (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL Col%, BYVAL BMap%)"
  PRINT #1, "DECLARE SUB DQBbPut (BYVAL Layer%, BYVAL x%, BYVAL y%, BYVAL BufSeg%, BYVAL BufOff%, BYVAL BMap%)"
  PRINT #1, "DECLARE SUB DQBcopyBlendLayer (BYVAL SourceLayer%, BYVAL DestLayer%, BYVAL BMap%)"
  PRINT #1, "DECLARE FUNCTION DQBcreateBMap% (BYVAL BMap%, BYVAL FirstCol%, BYVAL LastCol%)"
  PRINT #1, "DECLARE FUNCTION DQBloadBMap% (BMap%, FileName$)"
  PRINT #1, "DECLARE FUNCTION DQBsaveBMap% (BMap%, FileName$)"
  PRINT #1, "DECLARE SUB DQBsetBMap (BYVAL BMap%, BYVAL ForeCol%, BYVAL BackCol%, BYVAL NewCol%)"
  PRINT #1, "DECLARE FUNCTION DQBgetBMap% (BYVAL BMap%, BYVAL ForeCol%, BYVAL BackCol%)"
END IF
IF Install(mKEYBOARD) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from KEYBOARD.OBJ:"
  PRINT #1, "DECLARE SUB DQBinstallKeyboard ()"
  PRINT #1, "DECLARE SUB DQBremoveKeyboard ()"
  PRINT #1, "DECLARE FUNCTION DQBkey% (BYVAL ScanCode%)"
  PRINT #1, "DECLARE FUNCTION DQBreadKey% ()"
  PRINT #1, "DECLARE SUB DQBwaitKey (BYVAL ScanCode%)"
  PRINT #1, "DECLARE FUNCTION DQBasc% (BYVAL ScanCode%, BYVAL ShiftFlag%)"
  PRINT #1, "DECLARE FUNCTION DQBinkey$ ()"
END IF
IF Install(mJOYSTICK) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from JOYSTICK.OBJ:"
  PRINT #1, "DECLARE FUNCTION DQBjoyDetected% (BYVAL JoyNum%)"
  PRINT #1, "DECLARE FUNCTION DQBjoyX% (BYVAL JoyNum%)"
  PRINT #1, "DECLARE FUNCTION DQBjoyY% (BYVAL JoyNum%)"
  PRINT #1, "DECLARE FUNCTION DQBjoyMove% (BYVAL JoyNum%, BYVAL Direction%)"
  PRINT #1, "DECLARE FUNCTION DQBjoyFire% (BYVAL JoyNum%, BYVAL Button%)"
  PRINT #1, "DECLARE SUB DQBpollJoy (BYVAL JoyNum%)"
  PRINT #1, "DECLARE SUB DQBresetJoy ()"
  PRINT #1, "DECLARE SUB DQBsetJoySens (BYVAL Sens%)"
END IF
IF Install(mMOUSE) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from MOUSE.OBJ:"
  PRINT #1, "DECLARE FUNCTION DQBmouseDetected% ()"
  PRINT #1, "DECLARE FUNCTION DQBmouseX% ()"
  PRINT #1, "DECLARE FUNCTION DQBmouseY% ()"
  PRINT #1, "DECLARE FUNCTION DQBmouseLB% ()"
  PRINT #1, "DECLARE FUNCTION DQBmouseRB% ()"
  PRINT #1, "DECLARE SUB DQBsetMousePos (BYVAL x%, BYVAL y%)"
  PRINT #1, "DECLARE SUB DQBmouseShow ()"
  PRINT #1, "DECLARE SUB DQBmouseHide ()"
  PRINT #1, "DECLARE SUB DQBsetMouseRange (BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%)"
  PRINT #1, "DECLARE SUB DQBsetMouseShape (hotX%, hotY%, Shape$)"
  PRINT #1, "DECLARE SUB DQBsetMouseSpeed (BYVAL HorSpeed%, BYVAL VerSpeed%)"
  PRINT #1, "DECLARE SUB DQBresetMouse ()"
END IF
IF Install(mSOUND) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from SOUND.OBJ:"
  PRINT #1, "DECLARE FUNCTION DQBinstallSB% (BYVAL VolActive%, BYVAL Channels%, BYVAL Freq%, BYVAL BaseAddr%, BYVAL IRQ%, BYVAL DMA%)"
  PRINT #1, "DECLARE FUNCTION DQBloadSound% (Slot%, FileName$)"
  PRINT #1, "DECLARE FUNCTION DQBloadRawSound% (Slot%, FileName$, Offset&, Length&)"
  PRINT #1, "DECLARE FUNCTION DQBinUse% (BYVAL Voice%)"
  PRINT #1, "DECLARE SUB DQBplaySound (BYVAL SoundNum%, BYVAL Voice%, BYVAL Freq%, BYVAL LoopFlag%)"
  PRINT #1, "DECLARE SUB DQBsetVoiceVol (BYVAL Voice%, BYVAL NewVol%)"
  PRINT #1, "DECLARE SUB DQBpauseSound ()"
  PRINT #1, "DECLARE SUB DQBresumeSound ()"
  PRINT #1, "DECLARE SUB DQBstopVoice (BYVAL Voice%)"
  PRINT #1, "DECLARE SUB DQBremoveSB ()"
  PRINT #1, "DECLARE SUB DQBsetVolume (BYVAL Volume%)"
END IF
IF Install(m3D) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from 3D.OBJ:"
  PRINT #1, "DECLARE SUB DQBtri (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL x3%, BYVAL y3%, BYVAL Col%)"
  PRINT #1, "DECLARE SUB DQBbtri (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL x3%, BYVAL y3%, BYVAL Col%, BYVAL BMap%)"
  PRINT #1, "DECLARE SUB DQBgtri (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL c1%, BYVAL x2%, BYVAL y2%, BYVAL c2%, BYVAL x3%, BYVAL y3%, BYVAL c3%)"
  PRINT #1, "DECLARE SUB DQBbgtri (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL c1%, BYVAL x2%, BYVAL y2%, BYVAL c2%, BYVAL x3%, BYVAL y3%, BYVAL c3%, BYVAL BMap%)"
  PRINT #1, "DECLARE SUB DQBttri (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL x3%, BYVAL y3%, BYVAL u1%, BYVAL v1%, BYVAL u2%, BYVAL v2%, BYVAL u3%, BYVAL v3%, BYVAL TextureSeg%, BYVAL TextureOff%)"
  PRINT #1, "DECLARE SUB DQBbttri (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL x3%, BYVAL y3%, BYVAL u1%, BYVAL v1%, BYVAL u2%, BYVAL v2%, BYVAL u3%, BYVAL v3%, BYVAL TextureSeg%, BYVAL TextureOff%, BYVAL BMap%)"
  PRINT #1, "DECLARE SUB DQBfttri (BYVAL Layer%, BYVAL x1%, BYVAL y1%, BYVAL x2%, BYVAL y2%, BYVAL x3%, BYVAL y3%, BYVAL u1%, BYVAL v1%, BYVAL u2%, BYVAL v2%, BYVAL u3%, BYVAL v3%, BYVAL TextureSeg%, BYVAL TextureOff%)"
  PRINT #1, "DECLARE SUB DQBsetTextureSize (BYVAL Size%)"
END IF
IF Install(mDATAFILE) THEN
  PRINT #1, ""
  PRINT #1, "' Procedures from DATAFILE.OBJ:"
  PRINT #1, "DECLARE FUNCTION DQBopenDataFile (FileName$, Password$)"
  PRINT #1, "DECLARE FUNCTION DQBunpackFont (PacketID%, Font$)"
  PRINT #1, "DECLARE FUNCTION DQBunpackImage (BYVAL PacketID%, BYVAL Layer%, BYVAL x%, BYVAL y%)"
  PRINT #1, "DECLARE FUNCTION DQBunpackSprite (BYVAL PacketID%, BYVAL SpriteSeg%, BYVAL SpriteOff%)"
  PRINT #1, "DECLARE FUNCTION DQBunpackSound (BYVAL PacketID%, BYVAL Slot%)"
  PRINT #1, "DECLARE FUNCTION DQBunpackPal (PacketID%, Pal$)"
  PRINT #1, "DECLARE FUNCTION DQBunpackBMap (BYVAL PacketID%, BYVAL BMap%)"
  PRINT #1, "DECLARE FUNCTION DQBunpackCursor (PacketID%, Cursor$)"
  PRINT #1, "DECLARE FUNCTION DQBunpackUser (BYVAL PacketID%, BYVAL DataSeg%, BYVAL DataOff%)"
  PRINT #1, "DECLARE SUB DQBcloseDataFile ()"
END IF
PRINT #1, ""
PRINT #1, "' Library constants:"
PRINT #1, "CONST FALSE = 0, TRUE = NOT FALSE, VIDEO = 0"
PRINT #1, "CONST B0 = &H8000, B1 = &H8001, B2 = &H8002, B3 = &H8003, B4 = &H8004"
PRINT #1, "CONST B5 = &H8005, B6 = &H8006, B7 = &H8007, B8 = &H8008, B9 = &H8009"
IF Install(mIMAGE) THEN
  PRINT #1, "CONST BSV = 0, BMP = 1, PCX = 2"
END IF
IF Install(mSPRITE) THEN
  PRINT #1, "CONST HOR = 1, VER = 2, BOX = 0, PIXEL = 1, BIT.AND = 1, BIT.OR = 2, BIT.XOR = 3"
END IF
IF Install(mPALETTE) THEN
  PRINT #1, "CONST FORWARD = 0, BACKWARD = 1"
END IF
IF Install(mFONT) THEN
  PRINT #1, "CONST CENTERED = &H8000, NONE = 0, SOLID = &H1, BOLD = &H2, ITALIC = &H4"
  PRINT #1, "CONST UNDERLINED = &H8, BLENDED = &H10, TEXTURED = &H20"
END IF
IF Install(mDISK) THEN
  PRINT #1, "CONST ATTRIB.R = &H1, ATTRIB.H = &H2, ATTRIB.S = &H4"
  PRINT #1, "CONST ATTRIB.L = &H8, ATTRIB.D = &H10, ATTRIB.A = &H20"
END IF
IF Install(mKEYBOARD) THEN
  PRINT #1, "CONST KEYANY = -1, KEYESC = 1, KEYENTER = 28, KEYSPACE = 57"
  PRINT #1, "CONST KEYUP = 72, KEYDOWN = 80, KEYLEFT = 75, KEYRIGHT = 77"
END IF
IF Install(mJOYSTICK) OR Install(mDRAW) THEN
  PRINT #1, "CONST UP = 0, DOWN = 1, LEFT = 2, RIGHT = 3"
END IF
IF Install(mJOYSTICK) THEN
  PRINT #1, "CONST JOY1 = 0, JOY2 = 1, GAMEPAD = 2"
  PRINT #1, "CONST BUTA = 0, BUTB = 1, BUTC = 2, BUTD = 3"
END IF
IF Install(mSOUND) OR Install(mIMAGE) THEN
  PRINT #1, "CONST AUTO = -1, ONCE = 0, LOOPED = 1"
END IF
CLOSE #1
IF NOT QuickMode THEN LOCATE 14, 30 + done: PRINT CHR$(178): done = done + 1 ELSE PRINT ".";
END SUB

SUB BuildCALLS
'
OPEN "CALLS.BAS" FOR OUTPUT AS #1
PRINT #1, "' This file contains function overrides for the DirectQB Library version " + LIBVERSION$
PRINT #1, "' Created by the DirectQB Library Manager v" + VERSION$ + " on " + DATE$
PRINT #1, "' If you've successfully built the library, you can now delete this file..."
PRINT #1, "DEFINT A-Z"
PRINT #1, "DECLARE SUB xDQBerror (BYVAL MsgSeg, BYVAL MsgOff)"
PRINT #1, "DECLARE FUNCTION DQBerror$ ()"
PRINT #1, "DECLARE FUNCTION DQBid$ ()"
IF Install(mIMAGE) THEN
  PRINT #1, "DECLARE FUNCTION xDQBloadImage (BYVAL Layer, BYVAL x, BYVAL y, BYVAL FileSeg, BYVAL FileOff, BYVAL PalSeg, BYVAL PalOff, imgWidth AS INTEGER, imgHeight AS INTEGER)"
  PRINT #1, "DECLARE FUNCTION DQBloadImage (Layer AS INTEGER, x AS INTEGER, y AS INTEGER, FileName AS STRING, Pal AS STRING, imgWidth AS INTEGER, imgHeight AS INTEGER)"
  PRINT #1, "DECLARE FUNCTION xDQBsaveImage (BYVAL Layer, BYVAL x1, BYVAL y1, BYVAL x2, BYVAL y2, BYVAL FileSeg, BYVAL FileOff, BYVAL PalSeg, BYVAL PalOff, BYVAL Format)"
  PRINT #1, "DECLARE FUNCTION DQBsaveImage (Layer AS INTEGER, x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER, FileName AS STRING, Pal AS STRING, Format AS INTEGER)"
  PRINT #1, "DECLARE FUNCTION xDQBplayFLI (BYVAL FileSeg, BYVAL FileOff, BYVAL BufSeg, BYVAL KeyStop, BYVAL LoopFlag)"
  PRINT #1, "DECLARE FUNCTION DQBplayFLI (FileName AS STRING, BufLayer AS INTEGER, KeyStop AS INTEGER, LoopFlag AS INTEGER)"
  PRINT #1, "DECLARE FUNCTION xDQBopenFLI (BYVAL FileSeg, BYVAL FileOff, Frames AS INTEGER, Speed AS INTEGER)"
  PRINT #1, "DECLARE FUNCTION DQBopenFLI (FileName AS STRING, Frames AS INTEGER, Speed AS INTEGER)"
END IF
IF Install(mPALETTE) THEN
  PRINT #1, "DECLARE FUNCTION xDQBfindPalCol (BYVAL PalSeg, BYVAL PalOff, BYVAL Red, BYVAL Green, BYVAL Blue)"
  PRINT #1, "DECLARE FUNCTION DQBfindPalCol (Pal AS STRING, Red AS INTEGER, Green AS INTEGER, Blue AS INTEGER)"
  PRINT #1, "DECLARE SUB xDQBsetPal (BYVAL PalSeg, BYVAL PalOff)"
  PRINT #1, "DECLARE SUB DQBsetPal (Pal AS STRING)"
  PRINT #1, "DECLARE SUB xDQBgetPal (BYVAL PalSeg, BYVAL PalOff)"
  PRINT #1, "DECLARE SUB DQBgetPal (Pal AS STRING)"
  PRINT #1, "DECLARE SUB xDQBfadeIn (BYVAL PalSeg, BYVAL PalOff)"
  PRINT #1, "DECLARE SUB DQBfadeIn (Pal AS STRING)"
  PRINT #1, "DECLARE SUB xDQBfadeStepIn (BYVAL PalSeg, BYVAL PalOff)"
  PRINT #1, "DECLARE SUB DQBfadeStepIn (Pal AS STRING)"
END IF
IF Install(mFONT) THEN
  PRINT #1, "DECLARE FUNCTION xDQBlen (BYVAL TextSeg, BYVAL TextOff)"
  PRINT #1, "DECLARE FUNCTION DQBlen (Text AS STRING)"
  PRINT #1, "DECLARE FUNCTION xDQBloadFont (BYVAL FileSeg, BYVAL FileOff)"
  PRINT #1, "DECLARE FUNCTION DQBloadFont (FileName AS STRING)"
  PRINT #1, "DECLARE SUB xDQBprint (BYVAL Layer, BYVAL TextSeg, BYVAL TextOff, BYVAL x, BYVAL y, BYVAL Col, BYVAL Style)"
  PRINT #1, "DECLARE SUB DQBprint (Layer AS INTEGER, Text AS STRING, x AS INTEGER, y AS INTEGER, Col AS INTEGER)"
  PRINT #1, "DECLARE SUB DQBprints (Layer AS INTEGER, Text AS STRING, x AS INTEGER, y AS INTEGER, Col AS INTEGER, Style AS INTEGER)"
  PRINT #1, "DECLARE SUB xDQBsetFont (BYVAL FontSeg, BYVAL FontOff)"
  PRINT #1, "DECLARE SUB DQBsetFont (Font AS STRING)"
END IF
IF Install(mBLENDING) THEN
  PRINT #1, "DECLARE FUNCTION xDQBloadBMap (BYVAL BMap, BYVAL FileSeg, BYVAL FileOff)"
  PRINT #1, "DECLARE FUNCTION DQBloadBMap (BMap AS INTEGER, FileName AS STRING)"
  PRINT #1, "DECLARE FUNCTION xDQBsaveBMap (BYVAL BMap, BYVAL FileSeg, BYVAL FileOff)"
  PRINT #1, "DECLARE FUNCTION DQBsaveBMap (BMap AS INTEGER, FileName AS STRING)"
END IF
IF Install(mDISK) THEN
  PRINT #1, "DECLARE FUNCTION xDQBdrive ()"
  PRINT #1, "DECLARE FUNCTION DQBdrive$ ()"
  PRINT #1, "DECLARE SUB xDQBpath (BYVAL PathSeg, BYVAL PathOff)"
  PRINT #1, "DECLARE FUNCTION DQBpath$ ()"
  PRINT #1, "DECLARE SUB xDQBdir (BYVAL MaskSeg, BYVAL MaskOff, BYVAL Attrib, BYVAL FileSeg, BYVAL FileOff)"
  PRINT #1, "DECLARE FUNCTION DQBdir$ (Mask AS STRING, Attrib AS INTEGER)"
  PRINT #1, "DECLARE SUB xDQBsetDrive (BYVAL Drive)"
  PRINT #1, "DECLARE SUB DQBsetDrive (Drive AS STRING)"
  PRINT #1, "DECLARE FUNCTION xDQBchDir (BYVAL DirSeg, BYVAL DirOff)"
  PRINT #1, "DECLARE FUNCTION DQBchDir (Dir AS STRING)"
END IF
IF Install(mKEYBOARD) THEN
  PRINT #1, "DECLARE FUNCTION xDQBinkey ()"
  PRINT #1, "DECLARE FUNCTION DQBinkey$ ()"
END IF
IF Install(mMOUSE) THEN
  PRINT #1, "DECLARE SUB xDQBsetMouseShape (BYVAL hotX, BYVAL hotY, BYVAL ShapeSeg, BYVAL ShapeOff)"
  PRINT #1, "DECLARE SUB DQBsetMouseShape (hotX AS INTEGER, hotY AS INTEGER, Shape AS STRING)"
END IF
IF Install(mSOUND) THEN
  PRINT #1, "DECLARE FUNCTION xDQBloadSound (BYVAL Slot, BYVAL FileSeg, BYVAL FileOff)"
  PRINT #1, "DECLARE FUNCTION DQBloadSound (Slot AS INTEGER, FileName AS STRING)"
  PRINT #1, "DECLARE FUNCTION xDQBloadRawSound (BYVAL Slot, BYVAL FileSeg, BYVAL FileOff, BYVAL Offset AS LONG, BYVAL Length)"
  PRINT #1, "DECLARE FUNCTION DQBloadRawSound (Slot AS INTEGER, FileName AS STRING, Offset AS LONG, Length AS INTEGER)"
END IF
IF Install(mDATAFILE) THEN
  PRINT #1, "DECLARE FUNCTION xDQBopenDataFile (BYVAL FileSeg, BYVAL FileOff, BYVAL PassSeg, BYVAL PassOff)"
  PRINT #1, "DECLARE FUNCTION DQBopenDataFile (FileName AS STRING, Password AS STRING)"
  PRINT #1, "DECLARE FUNCTION xDQBunpackFont (BYVAL PackID, BYVAL FontSeg, BYVAL FontOff)"
  PRINT #1, "DECLARE FUNCTION DQBunpackFont (PacketID AS INTEGER, Font AS STRING)"
  PRINT #1, "DECLARE FUNCTION xDQBunpackPal (BYVAL PackID, BYVAL PalSeg, BYVAL PalOff)"
  PRINT #1, "DECLARE FUNCTION DQBunpackPal (PacketID AS INTEGER, Pal AS STRING)"
  PRINT #1, "DECLARE FUNCTION xDQBunpackCursor (BYVAL PackID, BYVAL CursorSeg, BYVAL CursorOff)"
  PRINT #1, "DECLARE FUNCTION DQBunpackCursor (PacketID AS INTEGER, Cursor AS STRING)"
END IF
PRINT #1, "FUNCTION DQBerror$"
PRINT #1, "DIM ErrorMsg AS STRING * 32"
PRINT #1, "xDQBerror VARSEG(ErrorMsg), VARPTR(ErrorMsg)"
PRINT #1, "DQBerror$ = RTRIM$(ErrorMsg)"
PRINT #1, "END FUNCTION"
PRINT #1, "FUNCTION DQBid$"
PRINT #1, "DQBid$ = " + CHR$(34) + "DirectQB v" + LIBVERSION$ + " by Angelo Mottola - Enhanced Creations 1998-99" + CHR$(34)
PRINT #1, "END FUNCTION"
IF Install(mIMAGE) THEN
  PRINT #1, "FUNCTION DQBloadImage (Layer, x, y, FileName AS STRING, Pal AS STRING, imgWidth AS INTEGER, imgHeight AS INTEGER)"
  PRINT #1, "DIM NewName AS STRING"
  PRINT #1, "NewName = FileName + CHR$(0)"
  PRINT #1, "DQBloadImage = xDQBloadImage(Layer, x, y, VARSEG(NewName), SADD(NewName), VARSEG(Pal), SADD(Pal), imgWidth, imgHeight)"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBsaveImage (Layer AS INTEGER, x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER, FileName AS STRING, Pal AS STRING, Format AS INTEGER)"
  PRINT #1, "DIM NewName AS STRING"
  PRINT #1, "NewName = FileName + CHR$(0)"
  PRINT #1, "DQBsaveImage = xDQBsaveImage(Layer, x1, y1, x2, y2, VARSEG(NewName), SADD(NewName), VARSEG(Pal), SADD(Pal), Format)"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBplayFLI (FileName AS STRING, BufLayer AS INTEGER, KeyStop AS INTEGER, LoopFlag AS INTEGER)"
  PRINT #1, "DIM NewName AS STRING"
  PRINT #1, "NewName = FileName + CHR$(0)"
  PRINT #1, "DQBplayFLI = xDQBplayFLI(VARSEG(NewName), SADD(NewName), BufLayer, KeyStop, LoopFlag)"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBopenFLI (FileName AS STRING, Frames AS INTEGER, Speed AS INTEGER)"
  PRINT #1, "DIM NewName AS STRING"
  PRINT #1, "NewName = FileName + CHR$(0)"
  PRINT #1, "DQBopenFLI = xDQBopenFLI(VARSEG(NewName), SADD(NewName), Frames, Speed)"
  PRINT #1, "END FUNCTION"
END IF
IF Install(mPALETTE) THEN
  PRINT #1, "FUNCTION DQBfindPalCol (Pal AS STRING, Red AS INTEGER, Green AS INTEGER, Blue AS INTEGER)"
  PRINT #1, "DQBfindPalCol = xDQBfindPalCol(VARSEG(Pal), SADD(Pal), Red, Green, Blue)"
  PRINT #1, "END FUNCTION"
  PRINT #1, "SUB DQBsetPal (Pal AS STRING)"
  PRINT #1, "xDQBsetPal VARSEG(Pal), SADD(Pal)"
  PRINT #1, "END SUB"
  PRINT #1, "SUB DQBgetPal (Pal AS STRING)"
  PRINT #1, "xDQBgetPal VARSEG(Pal), SADD(Pal)"
  PRINT #1, "END SUB"
  PRINT #1, "SUB DQBfadeIn (Pal AS STRING)"
  PRINT #1, "xDQBfadeIn VARSEG(Pal), SADD(Pal)"
  PRINT #1, "END SUB"
  PRINT #1, "SUB DQBfadeStepIn (Pal AS STRING)"
  PRINT #1, "xDQBfadeStepIn VARSEG(Pal), SADD(Pal)"
  PRINT #1, "END SUB"
END IF
IF Install(mFONT) THEN
  PRINT #1, "FUNCTION DQBlen (Text AS STRING)"
  PRINT #1, "DIM NewText AS STRING"
  PRINT #1, "NewText = Text + CHR$(0)"
  PRINT #1, "DQBlen = xDQBlen(VARSEG(NewText), SADD(NewText))"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBloadFont (FileName AS STRING)"
  PRINT #1, "DIM NewName AS STRING"
  PRINT #1, "NewName = FileName + CHR$(0)"
  PRINT #1, "DQBloadFont = xDQBloadFont(VARSEG(NewName), SADD(NewName))"
  PRINT #1, "END FUNCTION"
  PRINT #1, "SUB DQBprint (Layer AS INTEGER, Text AS STRING, x AS INTEGER, y AS INTEGER, Col AS INTEGER)"
  PRINT #1, "DIM NewText AS STRING"
  PRINT #1, "NewText = Text + CHR$(0)"
  PRINT #1, "xDQBprint Layer, VARSEG(NewText), SADD(NewText), x, y, Col, &HFF"
  PRINT #1, "END SUB"
  PRINT #1, "SUB DQBprints (Layer AS INTEGER, Text AS STRING, x AS INTEGER, y AS INTEGER, Col AS INTEGER, Style AS INTEGER)"
  PRINT #1, "DIM NewText AS STRING"
  PRINT #1, "NewText = Text + CHR$(0)"
  PRINT #1, "xDQBprint Layer, VARSEG(NewText), SADD(NewText), x, y, Col, Style"
  PRINT #1, "END SUB"
  PRINT #1, "SUB DQBsetFont (Font AS STRING)"
  PRINT #1, "xDQBsetFont VARSEG(Font), SADD(Font)"
  PRINT #1, "END SUB"
END IF
IF Install(mBLENDING) THEN
  PRINT #1, "FUNCTION DQBloadBMap (BMap AS INTEGER, FileName AS STRING)"
  PRINT #1, "DIM NewName AS STRING"
  PRINT #1, "NewName = FileName + CHR$(0)"
  PRINT #1, "DQBloadBMap = xDQBloadBMap(BMap, VARSEG(NewName), SADD(NewName))"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBsaveBMap (BMap AS INTEGER, FileName AS STRING)"
  PRINT #1, "DIM NewName AS STRING"
  PRINT #1, "NewName = FileName + CHR$(0)"
  PRINT #1, "DQBsaveBMap = xDQBsaveBMap(BMap, VARSEG(NewName), SADD(NewName))"
  PRINT #1, "END FUNCTION"
END IF
IF Install(mDISK) THEN
  PRINT #1, "FUNCTION DQBdir$ (Mask AS STRING, Attrib AS INTEGER)"
  PRINT #1, "DIM NewMask AS STRING, File AS STRING"
  PRINT #1, "NewMask = Mask + CHR$(0)"
  PRINT #1, "File = SPACE$(260)"
  PRINT #1, "xDQBdir VARSEG(NewMask), SADD(NewMask), Attrib, VARSEG(File), SADD(File)"
  PRINT #1, "IF INSTR(File, CHR$(0)) = 1 THEN"
  PRINT #1, "DQBdir$ = " + CHR$(34) + CHR$(34)
  PRINT #1, "ELSE"
  PRINT #1, "DQBdir$ = LEFT$(File, INSTR(File, CHR$(0)) - 1)"
  PRINT #1, "END IF"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBdrive$"
  PRINT #1, "DQBdrive$ = CHR$(xDQBdrive)"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBpath$"
  PRINT #1, "DIM Path AS STRING * 260"
  PRINT #1, "xDQBpath VARSEG(Path), VARPTR(Path)"
  PRINT #1, "DQBpath$ = LEFT$(Path, INSTR(Path, CHR$(0)) - 1)"
  PRINT #1, "END FUNCTION"
  PRINT #1, "SUB DQBsetDrive (Drive AS STRING)"
  PRINT #1, "xDQBsetDrive ASC(UCASE$(Drive)) - 65"
  PRINT #1, "END SUB"
  PRINT #1, "FUNCTION DQBchDir (Dir AS STRING)"
  PRINT #1, "DIM NewDir AS STRING"
  PRINT #1, "NewDir = Dir + CHR$(0)"
  PRINT #1, "DQBchDir = xDQBchDir(VARSEG(NewDir), SADD(NewDir))"
  PRINT #1, "END FUNCTION"
END IF
IF Install(mKEYBOARD) THEN
  PRINT #1, "FUNCTION DQBinkey$"
  PRINT #1, "DIM Char AS STRING * 1"
  PRINT #1, "Char = CHR$(xDQBinkey)"
  PRINT #1, "IF Char = CHR$(0) THEN DQBinkey$ = " + CHR$(34) + CHR$(34) + " ELSE DQBinkey$ = Char"
  PRINT #1, "END FUNCTION"
END IF
IF Install(mMOUSE) THEN
  PRINT #1, "SUB DQBsetMouseShape (hotX AS INTEGER, hotY AS INTEGER, Shape AS STRING)"
  PRINT #1, "xDQBsetMouseShape hotX, hotY, VARSEG(Shape), SADD(Shape)"
  PRINT #1, "END SUB"
END IF
IF Install(mSOUND) THEN
  PRINT #1, "FUNCTION DQBloadRawSound (Slot AS INTEGER, FileName AS STRING, Offset AS LONG, Length AS INTEGER)"
  PRINT #1, "DIM NewName AS STRING"
  PRINT #1, "NewName = FileName + CHR$(0)"
  PRINT #1, "DQBloadRawSound = xDQBloadRawSound(Slot, VARSEG(NewName), SADD(NewName), Offset, Length)"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBloadSound (Slot AS INTEGER, FileName AS STRING)"
  PRINT #1, "DIM NewName AS STRING"
  PRINT #1, "NewName = FileName + CHR$(0)"
  PRINT #1, "DQBloadSound = xDQBloadSound(Slot, VARSEG(NewName), SADD(NewName))"
  PRINT #1, "END FUNCTION"
END IF
IF Install(mDATAFILE) THEN
  PRINT #1, "FUNCTION DQBopenDataFile (FileName AS STRING, Password AS STRING)"
  PRINT #1, "DIM NewName AS STRING, NewPass AS STRING"
  PRINT #1, "NewName = FileName + CHR$(0)"
  PRINT #1, "NewPass = UCASE$(Password) + CHR$(0)"
  PRINT #1, "DQBopenDataFile = xDQBopenDataFile(VARSEG(NewName), SADD(NewName), VARSEG(NewPass), SADD(NewPass))"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBunpackFont (PacketID AS INTEGER, Font AS STRING)"
  PRINT #1, "DQBunpackFont = xDQBunpackFont(PacketID, VARSEG(Font), SADD(Font))"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBunpackPal (PacketID AS INTEGER, Pal AS STRING)"
  PRINT #1, "DQBunpackPal = xDQBunpackPal(PacketID, VARSEG(Pal), SADD(Pal))"
  PRINT #1, "END FUNCTION"
  PRINT #1, "FUNCTION DQBunpackCursor (PacketID AS INTEGER, Cursor AS STRING)"
  PRINT #1, "DQBunpackCursor = xDQBunpackCursor(PacketID, VARSEG(Cursor), SADD(Cursor))"
  PRINT #1, "END FUNCTION"
END IF
CLOSE #1
IF NOT QuickMode THEN LOCATE 14, 30 + done: PRINT CHR$(178): done = done + 1 ELSE PRINT ".";
END SUB

SUB BuildLibrary
'
DIM regs AS RegType
OPEN "DQB.LIB" FOR BINARY AS #1: CLOSE #1
KILL "DQB.LIB"
cmd$ = QBpath + "BC CALLS.BAS,,NUL /O /S"
WriteTemp 0, cmd$
SHELL cmd$ + " >dqbtmp0"
IF NOT QuickMode THEN LOCATE 14, 30 + done: PRINT CHR$(178): done = done + 1 ELSE PRINT ".";
cmd$ = QBpath + "LIB DQB.LIB " + QBpath + "QB.LIB;"
WriteTemp 1, cmd$
SHELL cmd$ + " >dqbtmp1"
IF NOT QuickMode THEN LOCATE 14, 30 + done: PRINT CHR$(178): done = done + 1 ELSE PRINT ".";
cmd$ = QBpath + "LIB DQB.LIB +MAIN.OBJ;"
WriteTemp 2, cmd$
SHELL cmd$ + " >dqbtmp2"
IF NOT QuickMode THEN LOCATE 14, 30 + done: PRINT CHR$(178): done = done + 1 ELSE PRINT ".";
temps = 2
FOR i = 2 TO 15
  IF Install(i) THEN
    temps = temps + 1
    cmd$ = QBpath + "LIB DQB.LIB +" + Module(i) + ";"
    WriteTemp temps, cmd$
    SHELL cmd$ + " >dqbtmp" + LTRIM$(STR$(temps))
    IF NOT QuickMode THEN LOCATE 14, 30 + done: PRINT CHR$(178): done = done + 1 ELSE PRINT ".";
  END IF
NEXT i
temps = temps + 1
cmd$ = QBpath + "LIB DQB.LIB +CALLS;"
WriteTemp temps, cmd$
SHELL cmd$ + " >dqbtmp" + LTRIM$(STR$(temps))
temps = temps + 1
cmd$ = QBpath + "LINK /Q DQB.LIB,DQB.QLB,NUL," + QBpath + "BQLB45.LIB"
WriteTemp temps, cmd$
SHELL cmd$ + " >dqbtmp" + LTRIM$(STR$(temps))
IF NOT QuickMode THEN LOCATE 14, 30: PRINT STRING$(20, 178)
OPEN LogFile$ FOR BINARY AS #1: CLOSE #1: KILL LogFile$
OPEN LogFile$ FOR OUTPUT AS #1
PRINT #1, "DIRECTQB.BI and CALLS.BAS successfully created"
FOR i = 0 TO temps
  OPEN "DQBTMH" + LTRIM$(STR$(i)) FOR INPUT AS #2
  LINE INPUT #2, l$: CLOSE #2
  PRINT #1, Bar$
  PRINT #1, "Shell command:"
  PRINT #1, l$
  OPEN "DQBTMP" + LTRIM$(STR$(i)) FOR INPUT AS #2
  WHILE NOT EOF(2)
    LINE INPUT #2, l$
    PRINT #1, l$
  WEND
  CLOSE #2
  PRINT #1, ""
NEXT i
PRINT #1, Bar$
PRINT #1, "Temporary files deleted"
PRINT #1, "Operation complete"
CLOSE #1
SHELL "DEL DQBTMP*.* >NUL"
SHELL "DEL DQBTMH*.* >NUL"
IF QuickMode THEN EXIT SUB
PCOPY 1, 0
DrawWindow 1, 3, 80, 22, "Viewing compiling log (" + LogFile$ + ")", 2
LOCATE 25, 1: COLOR 15, 6: PRINT SPACE$(80);
Center 25, " <F1> help, <" + CHR$(24) + "/" + CHR$(25) + "> move, <SPACE> select, <TAB> window, <ENTER> build, <ESC> quit"
FOR i = 0 TO 300: HelpLine(i) = "": NEXT i
logMax = -1
OPEN LogFile$ FOR INPUT AS #1
WHILE NOT EOF(1)
  logMax = logMax + 1
  LINE INPUT #1, HelpLine(logMax)
WEND
CLOSE #1
COLOR 13, 2
FOR i = 1 TO 19: LOCATE 3 + i, 1: PRINT HelpLine(i - 1): NEXT i
IF logMax > 19 THEN
  COLOR 3, 2: FOR i = 4 TO 22: LOCATE i, 80: PRINT CHR$(178); : NEXT i
  COLOR 11, 3: LOCATE 4, 80: PRINT CHR$(24): LOCATE 22, 80: PRINT CHR$(25);
  LOCATE 5, 80: PRINT CHR$(177)
END IF
logPos = 0
DO
  k$ = INKEY$: WHILE k$ = "": k$ = INKEY$: WEND
  IF k$ = CHR$(0) + "H" AND logPos > 0 THEN
    regs.ax = &H701
    regs.bx = 0
    regs.cx = &H300
    regs.dx = &H154D
    CALL interruptx(&H10, regs, regs)
    hP = 5 + INT((logPos / (logMax - 19)) * 16)
    logPos = logPos - 1
    COLOR 3, 2: LOCATE hP, 80: PRINT CHR$(178)
    hP = 5 + INT((logPos / (logMax - 19)) * 16)
    COLOR 11, 2: LOCATE hP, 80: PRINT CHR$(177)
    COLOR 13, 2
    l$ = LEFT$(HelpLine(logPos), 78)
    IF LEN(HelpLine(logPos)) > 78 THEN MID$(l$, 75, 4) = "[..]"
    LOCATE 4, 1: PRINT SPACE$(78);
    LOCATE 4, 1: PRINT l$;
  END IF
  IF k$ = CHR$(0) + "P" AND logPos < logMax - 19 THEN
    regs.ax = &H601
    regs.bx = 0
    regs.cx = &H300
    regs.dx = &H154D
    CALL interruptx(&H10, regs, regs)
    hP = 5 + INT((logPos / (logMax - 19)) * 16)
    logPos = logPos + 1
    COLOR 3, 2: LOCATE hP, 80: PRINT CHR$(178)
    hP = 5 + INT((logPos / (logMax - 19)) * 16)
    COLOR 11, 2: LOCATE hP, 80: PRINT CHR$(177)
    COLOR 13, 2
    l$ = LEFT$(HelpLine(logPos + 18), 78)
    IF LEN(HelpLine(logPos + 18)) > 78 THEN MID$(l$, 75, 4) = "[..]"
    LOCATE 22, 1: PRINT SPACE$(78);
    LOCATE 22, 1: PRINT l$;
  END IF
  IF k$ = CHR$(27) THEN EXIT DO
  IF k$ = CHR$(13) THEN
    SCREEN 1: SCREEN 0: WIDTH 80
    Errors = 0
    FOR i = 0 TO logMax
      IF LEN(HelpLine(i)) > 0 THEN
        FOR ii = 1 TO LEN(HelpLine(i))
          IF MID$(HelpLine(i), ii, 1) = CHR$(7) THEN Errors = -1
        NEXT ii
      END IF
    NEXT i
    IF Errors THEN
      PRINT "There were errors while creating the DirectQB library; this may depend on low"
      PRINT "memory to run the BC, LIB or LINK programs from inside the library manager,"
      PRINT "so it is strongly suggested that you check the INSTALL.LOG file for any error"
      PRINT "message that may appear into it. If you can't solve the problem, try to compile"
      PRINT "and run DQBMAN again, or try to type the lines under the " + CHR$(34) + "command:" + CHR$(34) + " statements"
      PRINT "into INSTALL.LOG from the DOS prompt."
      OPEN DataFile$ FOR OUTPUT AS #1
      FOR i = 1 TO 15: PRINT #1, Old(i): NEXT i
      PRINT #1, QBpath: CLOSE #1
    ELSE
      PRINT "The files DQB.LIB and DQB.QLB have been successfully created into the current"
      PRINT "directory! Type now " + CHR$(34) + "QB / LDQB" + CHR$(34) + " to start!"
      OPEN DataFile$ FOR OUTPUT AS #1
      FOR i = 1 TO 15: PRINT #1, Install(i): NEXT i
      PRINT #1, QBpath: CLOSE #1
    END IF
    PRINT
    END
  END IF
LOOP

END SUB

SUB Center (y, t$)
'
LOCATE y, (((79 - LEN(t$)) \ 2) + 1): PRINT t$;
END SUB

SUB ClearSelBar (sel)
'
DEF SEG = &HB800
Offset = ((sel + 5) * 160) + 1
FOR i = 3 TO 36
  POKE Offset + (i * 2), &H10 + 10 - (Install(sel + 1) * 5)
NEXT i
POKE Offset + 40, &H12

END SUB

SUB DrawSelBar (sel)
'
DEF SEG = &HB800
Offset = ((sel + 5) * 160) + 1
FOR i = 3 TO 36
  POKE Offset + (i * 2), &H50 + 10 - (Install(sel + 1) * 5)
NEXT i
POKE Offset + 40, &H52

END SUB

SUB DrawWindow (x1, y1, x2, y2, title$, c)
'
COLOR , c
FOR i = y1 TO y2
  LOCATE i, x1: PRINT SPACE$(x2 - x1 + 1);
NEXT i
COLOR 2, 1
IF x2 + 1 <= 80 THEN
  FOR i = y1 + 1 TO y2 + 1
    LOCATE i, x2 + 1: PRINT CHR$(SCREEN(i, x2 + 1));
  NEXT i
END IF
FOR i = x1 + 1 TO x2
  LOCATE y2 + 1, i: PRINT CHR$(SCREEN(y2 + 1, i));
NEXT i
IF title$ <> "" THEN
  LOCATE y1, x1: COLOR 15, c + 3: PRINT SPACE$(x2 - x1 + 1);
  LOCATE y1, x1 + (((x2 - x1 + 1) - LEN(title$)) \ 2): PRINT title$;
END IF
END SUB

FUNCTION FindPath
'$DYNAMIC
'
DIM File(MAXFILES) AS STRING * 12
DIM Dir(MAXDIRS) AS STRING * 12
p$ = path$: IF LEN(p$) > 50 THEN MID$(p$, 49) = "..."
LOCATE 13, 5: PRINT SPACE$(70)
Center 13, "Scanning \" + p$
d = 0: f = 0
Dir(0) = QBdir$("*.", &H10)
Dir(0) = QBdir$("", &H10)
Dir(0) = QBdir$("", &H10)
WHILE RTRIM$(Dir(d)) <> "" AND d < MAXDIRS
  d = d + 1
  Dir(d) = QBdir$("", &H10)
WEND
File(0) = QBdir$("*.*", &H20)
WHILE RTRIM$(File(f)) <> "" AND f < MAXFILES
  f = f + 1
  File(f) = QBdir$("", &H20)
WEND

IF f > 0 THEN
  QB = 0
  FOR i = 0 TO f - 1
    IF RTRIM$(File(i)) = "BQLB45.LIB" THEN QB = QB OR &H1
    IF RTRIM$(File(i)) = "BC.EXE" THEN QB = QB OR &H2
    IF RTRIM$(File(i)) = "LINK.EXE" THEN QB = QB OR &H4
    IF RTRIM$(File(i)) = "LIB.EXE" THEN QB = QB OR &H8
    IF RTRIM$(File(i)) = "QB.LIB" THEN QB = QB OR &H10
  NEXT i
  IF QB = &H1F THEN FindPath = 1: EXIT FUNCTION
END IF
ON ERROR GOTO DirCheck
IF d > 0 THEN
  FOR i = 0 TO d - 1
    ErrDir = 0: CHDIR RTRIM$(Dir(i))
    IF ErrDir = 0 THEN
      IF FindPath THEN FindPath = 1: EXIT FUNCTION
      CHDIR ".."
    ELSEIF ErrDir = 2 THEN
      ON ERROR GOTO ErrorHandler
      ERROR 80
    END IF
  NEXT i
END IF
FindPath = 0
ON ERROR GOTO ErrorHandler

END FUNCTION

REM $STATIC
SUB Init
'
FOR i = 1 TO 15
  READ Module(i)
  OPEN Module(i) FOR BINARY AS #1: l& = LOF(1): CLOSE #1
  IF l& = 0 THEN KILL Module(i): ERROR 77
NEXT i

OPEN HelpFile FOR BINARY AS #1: l& = LOF(1): CLOSE #1
IF l& = 0 THEN KILL HelpFile: ERROR 78
SCREEN 0: WIDTH 80: CLS

FOR i = 1 TO 8
  OUT &H3C8, (i - 1)
  OUT &H3C9, 0
  OUT &H3C9, 0
  OUT &H3C9, (i * 8) - 1
  OUT &H3C8, (8 + i) - 1
  OUT &H3C9, (i * 8) - 1
  OUT &H3C9, (i * 8) - 1
  OUT &H3C9, 63
NEXT i
FOR i = 0 TO 15: PALETTE i, i: NEXT i

COLOR 4, 2
FOR i = 1 TO 25: LOCATE i, 1: PRINT STRING$(80, 177); : NEXT i
LOCATE 1, 1: COLOR 15, 5: PRINT SPACE$(80);
Center 1, "DirectQB Library Manager Utility version " + VERSION$ + " - Enhanced Creations 1998-99"
LOCATE 25, 1: COLOR 15, 6: PRINT SPACE$(80);
Center 25, " <F1> help, <" + CHR$(24) + "/" + CHR$(25) + "> move, <SPACE> select, <TAB> window, <ENTER> build, <ESC> quit"
DrawWindow 3, 3, 38, 22, "Modules selection", 1
COLOR 15, 2: LOCATE 4, 3: PRINT SPACE$(36)
LOCATE 4, 3: PRINT "  Module             Status"
COLOR 2, 1
FOR i = 5 TO 22: LOCATE i, 21: PRINT CHR$(179); : NEXT i
DrawWindow 42, 3, 77, 22, "Module description", 1
COLOR 3, 2: FOR i = 4 TO 22: LOCATE i, 77: PRINT CHR$(178); : NEXT i
COLOR 11, 3: LOCATE 4, 77: PRINT CHR$(24): LOCATE 22, 77: PRINT CHR$(25);
PCOPY 0, 1
DrawWindow 15, 10, 64, 16, "", 4
COLOR 15, 4
Center 11, "The DirectQB Library Manager Utility"
Center 13, "version " + VERSION$
Center 14, "by Angelo Mottola - Enhanced Creations 1998-99"
COLOR 10, 5: LOCATE 16, 15: PRINT SPACE$(50)
Center 16, "- press any key to continue -"
WHILE INKEY$ = "": WEND
PCOPY 1, 0

OPEN DataFile$ FOR BINARY AS #1
l& = LOF(1): CLOSE #1
IF l& = 0 THEN
  KILL DataFile$
  PCOPY 0, 1
  DrawWindow 9, 5, 71, 20, "Welcome!", 3
  COLOR 14, 3
  Center 7, "It seems this is the first time you're building the DirectQB"
  Center 8, "library. This program will help you in this operation, by"
  Center 9, "allowing you to select what modules to include in your"
  Center 10, "custom copy of the library. This way you'll create the"
  Center 11, "actual quicklibrary files needed to use DirectQB, with only"
  Center 12, "the functions you require, saving disk space and runtime"
  Center 13, "memory usage. Please refer to the DIRECTQB.DOC file for"
  Center 14, "details on each library function. Once you're done with"
  Center 15, "selecting your modules, press <ENTER> to build the library;"
  Center 16, "this will generate the DQB.LIB, DQB.QLB and DIRECTQB.BI"
  Center 17, "library files, plus " + LogFile$ + " (installation log) and"
  Center 18, DataFile$ + " (installation data) in the current directory."
  COLOR 10, 4: LOCATE 20, 9: PRINT SPACE$(63)
  Center 20, "- press any key to continue -"
  WHILE INKEY$ = "": WEND
  PCOPY 1, 0: COLOR 10, 1
  FOR i = 2 TO 15: Install(i) = 0: Old(i) = 0: NEXT i
  Install(1) = -1: Old(1) = -1: QBpath = "?"
ELSE
  COLOR 10, 1
  OPEN DataFile$ FOR INPUT AS #1
  FOR i = 1 TO 15
    INPUT #1, Old(i): Install(i) = Old(i)
  NEXT i
  INPUT #1, QBpath
  CLOSE #1
END IF
FOR i = 1 TO 15
  IF Install(i) THEN
    COLOR 15, 1
    LOCATE 5 + i, 5: PRINT Module(i)
    LOCATE 5 + i, 24: PRINT "Installed"
  ELSE
    COLOR 10, 1
    LOCATE 5 + i, 5: PRINT Module(i)
    LOCATE 5 + i, 24: PRINT "Not installed"
  END IF
NEXT i
END SUB

SUB Main
'
DIM regs AS RegType
focus = 1
sel = 0: hPos = 0: hMax = 0
DrawSelBar sel
SwitchFocus focus
ReadHelp 1, hMax

DO
  k$ = INKEY$: WHILE k$ = "": k$ = INKEY$: WEND
  IF k$ = CHR$(9) THEN SwitchFocus focus
  IF focus = 0 THEN
    IF k$ = CHR$(0) + ";" THEN
      SwitchFocus focus
      ReadHelp 0, hMax
    END IF
    IF k$ = CHR$(0) + "H" THEN
      ClearSelBar sel
      IF sel = 0 THEN sel = 14 ELSE sel = sel - 1
      DrawSelBar sel
      ReadHelp sel + 1, hMax
      hPos = 0
    END IF
    IF k$ = CHR$(0) + "P" THEN
      ClearSelBar sel
      IF sel = 14 THEN sel = 0 ELSE sel = sel + 1
      DrawSelBar sel
      ReadHelp sel + 1, hMax
      hPos = 0
    END IF
    IF k$ = CHR$(32) AND sel <> 0 THEN Install(sel + 1) = NOT Install(sel + 1): DrawSelBar sel
    IF k$ = CHR$(27) THEN EXIT DO
    IF k$ = CHR$(13) THEN MakeDQB
  ELSE
    IF k$ = CHR$(0) + ";" THEN ReadHelp 0, hMax
    IF k$ = CHR$(0) + "H" AND hPos > 0 THEN
      regs.ax = &H701
      regs.bx = 0
      regs.cx = &H32A
      regs.dx = &H154A
      CALL interruptx(&H10, regs, regs)
      hP = 5 + INT((hPos / (hMax - 19)) * 16)
      COLOR 3, 2: LOCATE hP, 77: PRINT CHR$(178)
      hPos = hPos - 1: hP = 5 + INT((hPos / (hMax - 19)) * 16)
      COLOR 11, 2: LOCATE hP, 77: PRINT CHR$(177)
      COLOR 13, 1
      LOCATE 4, 43: PRINT SPACE$(34)
      LOCATE 4, 43: PRINT HelpLine(hPos)
    END IF
    IF k$ = CHR$(0) + "P" AND hPos + 19 < hMax THEN
      regs.ax = &H601
      regs.bx = 0
      regs.cx = &H32A
      regs.dx = &H154A
      CALL interruptx(&H10, regs, regs)
      hP = 5 + INT((hPos / (hMax - 19)) * 16)
      COLOR 3, 2: LOCATE hP, 77: PRINT CHR$(178)
      hPos = hPos + 1: hP = 5 + INT((hPos / (hMax - 19)) * 16)
      COLOR 11, 2: LOCATE hP, 77: PRINT CHR$(177)
      COLOR 13, 1
      LOCATE 22, 43: PRINT SPACE$(34)
      LOCATE 22, 43: PRINT HelpLine(hPos + 18)
    END IF
    IF k$ = CHR$(27) THEN EXIT DO
    IF k$ = CHR$(13) THEN MakeDQB
  END IF
LOOP
END SUB

SUB MakeDQB
'
PCOPY 0, 1
IF QBpath = "?" THEN
  DrawWindow 5, 9, 74, 14, "Searching for QuickBasic 4.5", 4
  COLOR 10, 4: Center 10, "Please enter the full path of your working copy of QuickBasic 4.5"
  Center 11, "(Hit <enter> to search for it automatically)"
  COLOR 15, 1: LOCATE 13, 7: PRINT SPACE$(66)
  QBpath = ""
  DO
    LOCATE 13, 7: COLOR 15, 1: PRINT QBpath$; : COLOR 31, 1: PRINT "_"
    k$ = UCASE$(INKEY$)
    IF k$ = CHR$(13) AND QBpath = "" THEN QBpath = "?": PCOPY 1, 0: EXIT DO
    IF k$ = CHR$(27) THEN QBpath = "?": PCOPY 1, 0: EXIT SUB
    SELECT CASE k$
    CASE "A" TO "Z", "\", "_", "~", ".", "0" TO "9", "$", "!", "-", "+", ":"
      IF LEN(QBpath) < 64 THEN
        QBpath = QBpath + k$
      END IF
    CASE CHR$(8)
      IF LEN(QBpath) > 0 THEN
        COLOR 15, 1: LOCATE 13, 7 + LEN(QBpath): PRINT CHR$(32)
        QBpath = LEFT$(QBpath, LEN(QBpath) - 1)
      END IF
    CASE CHR$(13)
      IF RIGHT$(QBpath, 1) <> "\" THEN QBpath = QBpath + "\"
      ON ERROR GOTO DirCheck
      ValidDir = 1: OPEN QBpath + "BC.EXE" FOR INPUT AS #1: CLOSE #1
      IF ValidDir = 1 THEN
        OPEN QBpath + "LIB.EXE" FOR INPUT AS #1: CLOSE #1
        IF ValidDir = 1 THEN
          OPEN QBpath + "LINK.EXE" FOR INPUT AS #1: CLOSE #1
          IF ValidDir = 1 THEN
            OPEN QBpath + "BQLB45.LIB" FOR INPUT AS #1: CLOSE #1
            IF ValidDir = 1 THEN
              OPEN QBpath + "QB.LIB" FOR INPUT AS #1: CLOSE #1
              ON ERROR GOTO ErrorHandler
              EXIT DO
            END IF
          END IF
        END IF
      END IF
      PCOPY 0, 2
      DrawWindow 10, 10, 69, 14, "Error!", 2
      COLOR 15, 2
      Center 12, "Invalid directory, or QB not found in such directory"
      COLOR 10, 3: LOCATE 14, 10: PRINT SPACE$(60)
      Center 14, "- press any key to continue -"
      WHILE INKEY$ = "": WEND
      PCOPY 2, 0
      ON ERROR GOTO ErrorHandler
    END SELECT
  LOOP
END IF
PCOPY 1, 0
IF QBpath = "?" THEN
  DrawWindow 5, 11, 74, 15, "Searching QuickBasic 4.5...", 3
  COLOR 10, 4: LOCATE 15, 5: PRINT SPACE$(70)
  Center 15, "- please wait -"
  oldPath$ = "\" + path$
  CHDIR "\": COLOR 13, 3
  IF FindPath THEN
    QBpath = "\" + path$
    IF RIGHT$(QBpath, 1) <> "\" THEN QBpath = QBpath + "\"
    Center 13, SPACE$(70)
    Center 13, "Found into " + QBpath$
    COLOR 10, 4: LOCATE 15, 5: PRINT SPACE$(70)
    Center 15, "- press any key to continue -"
    WHILE INKEY$ = "": WEND
  ELSE
    QBpath = "?"
  END IF
  CHDIR oldPath$
END IF
PCOPY 1, 0
DrawWindow 23, 2, 56, 23, "Summary of operations", 3
COLOR 10, 4: LOCATE 23, 23: PRINT SPACE$(34);
Center 23, "<ENTER> continue | <ESC> abort"
COLOR 12, 3
adding = 0: removing = 0
FOR i = 1 TO 15
  IF Install(i) <> Old(i) THEN
    IF Install(i) THEN adding = adding + 1 ELSE removing = removing + 1
  END IF
NEXT i
IF adding = 0 AND removing = 0 THEN
  LOCATE 4, 25: PRINT "Rebuilding DirectQB with no"
  LOCATE 5, 25: PRINT "changes"
ELSE
  LOCATE 4
  IF adding = 0 THEN
    LOCATE , 25: PRINT "Adding no new modules"
  ELSE
    LOCATE , 25: PRINT "Adding module(s):"
    FOR i = 1 TO 15
      IF Install(i) AND NOT Old(i) THEN LOCATE , 28: PRINT Module(i)
    NEXT i
  END IF
  IF removing = 0 THEN
    LOCATE , 25: PRINT "Removing no old modules"
  ELSE
    LOCATE , 25: PRINT "Removing module(s):"
    FOR i = 1 TO 15
      IF NOT Install(i) AND Old(i) THEN LOCATE , 28: PRINT Module(i)
    NEXT i
  END IF
END IF
DO
  k$ = UCASE$(INKEY$)
LOOP WHILE k$ <> CHR$(13) AND k$ <> CHR$(27)
PCOPY 1, 0
IF k$ = CHR$(13) THEN
  DrawWindow 20, 11, 59, 15, "Building DirectQB", 4
  COLOR 15, 4: Center 13, "Please wait..."
  LOCATE 14, 27: PRINT "0%": LOCATE 14, 51: PRINT "100%"
  COLOR 4, 2: LOCATE 14, 30: PRINT STRING$(20, 177)
  COLOR 9, 6: done = 0
  BuildBI
  BuildCALLS
  BuildLibrary
  PCOPY 1, 0
END IF

END SUB

FUNCTION path$
DIM regs AS RegType
DIM PathSize AS STRING * 64
regs.ax = &H1900
CALL interruptx(&H21, regs, regs)
regs.dx = (regs.ax + 1) MOD 256
regs.ax = &H4700
regs.ds = VARSEG(PathSize)
regs.si = VARPTR(PathSize)
CALL interruptx(&H21, regs, regs)
path$ = LEFT$(PathSize, INSTR(PathSize, CHR$(0)) - 1)

END FUNCTION

FUNCTION QBdir$ (filespec$, attr)
DIM regs AS RegType

regs.ax = &H1A00
regs.dx = VARPTR(DTA)
regs.ds = VARSEG(DTA)
CALL interruptx(&H21, regs, regs)

IF LEN(filespec$) THEN
  FileSpecZ$ = filespec$ + CHR$(0)
  regs.ax = &H4E00
  regs.cx = attr
  regs.dx = SADD(FileSpecZ$)
  regs.ds = VARSEG(FileSpecZ$)
ELSE
  regs.ax = &H4F00
END IF
CALL interruptx(&H21, regs, regs)

IF regs.flags AND 1 THEN
  QBdir$ = ""
ELSE
  Null = INSTR(31, DTA, CHR$(0))
  QBdir$ = MID$(DTA, 31, Null - 31)
END IF

END FUNCTION

SUB ReadHelp (HelpCode, MaxLines)
'
COLOR 13, 1
FOR i = 4 TO 22: LOCATE i, 43: PRINT SPACE$(35): NEXT i
OPEN HelpFile FOR INPUT AS #1
S$ = "(" + LTRIM$(STR$(HelpCode)) + ")"
DO
  LINE INPUT #1, l$
  IF l$ = S$ THEN EXIT DO
LOOP WHILE NOT EOF(1)
IF l$ <> S$ THEN CLOSE #1: LOCATE 12, 51: PRINT "Help unavailable!": EXIT SUB

FOR i = 0 TO 300: HelpLine(i) = "": NEXT i
hLine = 0
DO
  LINE INPUT #1, l$
  IF l$ = "~" THEN EXIT DO
  IF l$ = "" THEN
    hLine = hLine + 1
  ELSE
    WHILE LEN(l$) <> 0
      IF LEFT$(l$, 1) = "õ" THEN
        hLine = hLine + 1: l$ = RIGHT$(l$, LEN(l$) - 1)
      END IF
      S = INSTR(l$, " ")
      IF S <> 0 THEN
        IF LEN(HelpLine(hLine)) + S > 34 THEN hLine = hLine + 1
        HelpLine(hLine) = HelpLine(hLine) + LEFT$(l$, S)
        l$ = RIGHT$(l$, LEN(l$) - S)
      ELSE
        IF LEN(HelpLine(hLine)) + LEN(l$) >= 34 THEN hLine = hLine + 1
        HelpLine(hLine) = HelpLine(hLine) + l$: l$ = ""
      END IF
    WEND
    IF LEN(HelpLine(hLine)) >= 34 THEN hLine = hLine + 1 ELSE HelpLine(hLine) = HelpLine(hLine) + " "
  END IF
LOOP
CLOSE #1
MaxLines = hLine + 1
FOR i = 4 TO 22: LOCATE i, 43: PRINT HelpLine(i - 4): NEXT i
IF MaxLines > 19 THEN
  COLOR 3, 2: FOR i = 4 TO 22: LOCATE i, 77: PRINT CHR$(178); : NEXT i
  COLOR 11, 3: LOCATE 4, 77: PRINT CHR$(24): LOCATE 22, 77: PRINT CHR$(25);
  LOCATE 5, 77: PRINT CHR$(177)
END IF

END SUB

SUB SwitchFocus (focus)
'
DEF SEG = &HB800
IF focus = 0 THEN
  FOR i = 2 TO 37: POKE 321 + (i * 2), &H4F: NEXT i
  FOR i = 41 TO 76: POKE 321 + (i * 2), &H7F: NEXT i
  focus = 1
ELSE
  FOR i = 2 TO 37: POKE 321 + (i * 2), &H7F: NEXT i
  FOR i = 41 TO 76: POKE 321 + (i * 2), &H4F: NEXT i
  focus = 0
END IF
END SUB

SUB WriteTemp (num, l$)
'
OPEN "DQBTMH" + LTRIM$(STR$(num)) FOR OUTPUT AS #2
PRINT #2, l$: CLOSE #2
END SUB

