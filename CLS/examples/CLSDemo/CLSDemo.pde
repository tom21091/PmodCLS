/************************************************************************/
/*                                                                      */
/*  LCDSDemoProject                                                     */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*  Author: Monica Bot                                                  */
/*  Copyright 2011, Digilent Inc.                                       */
/************************************************************************/
/*  Module Description:                                                 */
/*                                                                      */
/* This module implements a simple demo application that demonstrates   */
/* how to use LCDS functions.                                           */
/* It also uses buttons to control the display.                         */
/*                                                                      */
/*  Functionality:                                                      */
/*                                                                      */
/* The application uses the two on-board buttons to control the display.*/
/* It also implements, in a circular manner, a number of steps, each of */
/* them demonstrating the use of a library function.                    */
/* The buttons are used to trigger actions and move to the next step of */
/* the application                                                      */
/*  Required Hardware:                                                  */
/*      1. Cerebot MX4cK (Chipkit Pro MX4)                              */
/*      2. PmodCLS - SPI: JP2 jumper on MD0, J1 on top row of JB        */
/*                   UART:  JP2 jumpers on MD0 and MD2 (9600 baud rate) */
/*                Because of the way the pins are lined up,             */
/*                you'll need to connect the pmod separately            */
/*                with wires.                                           */
/*                J2 connector on the PmodCLS needs 3.3V and Gnd        */
/*                The next two pins on J2 are connected to UART2:       */
/*                        J2  RX -> RF5 (JH2)                           */
/*                        J2  TX -> RF4 (JH3)                           */
/*                    I2C: JP2 jumpers on MD0 and MD1 (address: 0x48)   */
/*                        J2 SC -> I2C #2 SCK pin                       */
/*                        J2 SD -> I2c #2 SDA pin                       */
/************************************************************************/
/*  Revision History:                                                   */
/*                                                                      */
/*  10/25/2011 (MonicaB): created                                       */
/*  6/26/2014  (TommyK): Updated library to support UART and I2C        */
/*                       Bug fixes                                      */
/*                                                                      */
/************************************************************************/

/* ------------------------------------------------------------ */
/*              Include File Definitions                        */
/* ------------------------------------------------------------ */
#include <LCDS.h>
#include <DSPI.h>
#include <Bounce.h>
#include <Wire.h>
/* ------------------------------------------------------------ */
/*              Local Type Definitions                          */
/* ------------------------------------------------------------ */
#define btnPin1           42
#define btnPin2           43
/* ------------------------------------------------------------ */
/*              Global Variables                                */
/* ------------------------------------------------------------ */
LCDS         MyLCDS;
char         szInfo1[0x27]; 
char         szInfo2[0x27];
//custom characters definition
byte         defChar[] = {0, 0x4, 0x2, 0x1F, 0x02, 0x4, 0, 0};
byte         defChar1[] = {14, 31, 21, 31, 23, 16, 31, 14};
byte         defChar2[] = {0x00, 0x1F, 0x11, 0x00, 0x00, 0x11, 0x1F, 0x00};
byte         defChar3[] = {0x00, 0x0A, 0x15, 0x11, 0x0A, 0x04, 0x00, 0x00};
//bytes array representing the position of the user defined characters in the memory
byte         charsToDisp[] = {1, 2, 3, 4, 0};
//definitions for display and cursor settings flags
boolean      fDisplay     = true;
boolean      fBackLight   = true;
boolean      fCursor      = false;
boolean      fBlink       = false;
//flags indicating whether a button has been pressed or not
boolean      fBtn1Process;
boolean      fBtn2Process;
//Bounce class objects instantiation
Bounce       debBtn2      = Bounce(btnPin2, 50);
Bounce       debBtn1      = Bounce(btnPin1, 50);
/* ------------------------------------------------------------ */
/*              Forward Declarations                            */
/* ------------------------------------------------------------ */
//function that detects if a button or both have been pressed
boolean WaitUntilBtnPressed(boolean *pfBtn1Process, boolean *pfBtn2Process);


void setup() {
  Serial.begin(9600);
    //select communication protocol
    //MyLCDS.Begin(PAR_ACCESS_DSPI0);//SPI
    //MyLCDS.Begin(PAR_ACCESS_UART2);//UART
    MyLCDS.Begin(PAR_ACCESS_I2C);//I2C
    //set the pin buttons as inputs
    pinMode(btnPin1, INPUT);
    pinMode(btnPin2, INPUT);
    //default settings for display
    MyLCDS.DisplaySet(true, true);
    MyLCDS.DisplayMode(0);
    
    // define custom characters for displaying on the LCD
    MyLCDS.DefineUserChar(defChar, 1);
    delay(5);
    MyLCDS.DefineUserChar(defChar1, 2);
    delay(5);
    MyLCDS.DefineUserChar(defChar2, 3);
    delay(5);
    MyLCDS.DefineUserChar(defChar3, 4);
    delay(5);
}

void loop() {
 
  // 1. Welcome message displayed
    MyLCDS.DisplayClear(); // clear display, return cursor home
    strcpy(szInfo1, "CLS Demo");
    strcpy(szInfo2, "Press any button");
    MyLCDS.WriteStringAtPos(0, 0, szInfo1);
    MyLCDS.WriteStringAtPos(1, 0, szInfo2);
    fBtn1Process = false;
    fBtn2Process = false;
    //wait until any button pressed
    while((fBtn1Process == false && fBtn2Process == false)) {
       WaitUntilBtnPressed(&fBtn1Process, &fBtn2Process);
    }
    MyLCDS.DisplayClear(); // clear display, return cursor home
   
   /*
    // 2. Toggle Backlight (not supported by pmodCLS)
    strcpy(szInfo1, "BTN2: Backlight");
    strcpy(szInfo2, "BTN1: Continue");
    MyLCDS.WriteStringAtPos(0, 0, szInfo1);
    MyLCDS.WriteStringAtPos(1, 0, szInfo2); 
    fBtn1Process = false;
    fBtn2Process = false;
    //wait for button 1 pressed to continue
    while(fBtn1Process == false) {
        WaitUntilBtnPressed(&fBtn1Process, &fBtn2Process);
	if(fBtn2Process == true) {
            // if only button 2 is pressed
	    fBackLight =  1 - fBackLight; // toggle fBackLight
	    MyLCDS.DisplaySet(fDisplay, fBackLight);
	}
    }
    */
    
    // 3. Display Scroll left/right
    //set the display mode to 40 characters in a line. 
    //we need to explicitly do this for a correct usage of the scroll functionality
    //otherwise the number of chars will be truncated to 16 by default
    MyLCDS.DisplayMode(0);
    //restore the display settings
    MyLCDS.DisplaySet(true, true);
    // clear display, return cursor home
    MyLCDS.DisplayClear(); 
    strcpy(szInfo1, "Btns - L/R scroll long text");
    strcpy(szInfo2, "BTN1&BTN2: continue");
    MyLCDS.WriteStringAtPos(0, 0, szInfo1);
    MyLCDS.WriteStringAtPos(1, 0, szInfo2); 
    while(fBtn1Process == false || fBtn2Process == false) {
	WaitUntilBtnPressed(&fBtn1Process, &fBtn2Process);
	if(fBtn1Process != fBtn2Process) {
            // if only one button is pressed
            //scroll one position to left or right
	    MyLCDS.DisplayScroll(fBtn1Process,1);
	 }
    }
    MyLCDS.DisplayClear(); // clear display, return cursor home

    // 4. Toggle cursor 
    strcpy(szInfo1, "BTN2: Cursor");
    strcpy(szInfo2, "BTN1: Continue");
    MyLCDS.WriteStringAtPos(0, 0, szInfo1);
    MyLCDS.WriteStringAtPos(1, 0, szInfo2); 
    fBtn1Process = false;
    fBtn2Process = false;
	//wait for button 1 pressed to continue
    while(fBtn1Process == false) {
	WaitUntilBtnPressed(&fBtn1Process, &fBtn2Process);
	if(fBtn2Process == true) {
	    // if only button 2 is pressed
	    fCursor =  1 - fCursor; // toggle fCursor
	    MyLCDS.CursorModeSet(fCursor, false);
	}
    }
  
    // 5. Toggle blink
    strcpy(szInfo1, "BTN2: Blink ");
    strcpy(szInfo2, "BTN1: Continue");
    MyLCDS.WriteStringAtPos(0, 0, szInfo1);
    MyLCDS.WriteStringAtPos(1, 0, szInfo2); 
    fBtn1Process = false;
    fBtn2Process = false;
	//wait for button 1 pressed to continue
    while(fBtn1Process == false){
	WaitUntilBtnPressed(&fBtn1Process, &fBtn2Process);
	if(fBtn2Process == true){
	    // if only button 2 is pressed
	    fBlink =  1 - fBlink; // toggle fBlink
            MyLCDS.CursorModeSet(true, fBlink);
        }
    }
    MyLCDS.CursorModeSet(true, false);
    
    // 6. Erase chars
    strcpy(szInfo1, "BTN2: Erase char");
    strcpy(szInfo2, "BTN1: Continue");
    MyLCDS.WriteStringAtPos(0, 0, szInfo1);
    MyLCDS.WriteStringAtPos(1, 0, szInfo2); 
    fBtn1Process = false;
    fBtn2Process = false;
    MyLCDS.SetPos(0, 10);
	//wait for button 1 pressed to continue
    while(fBtn1Process == false){
	WaitUntilBtnPressed(&fBtn1Process, &fBtn2Process);
	if(fBtn2Process == true){
	    // if only button 2 is pressed
            // erase 4 chars starting at the current position of the cursor
            MyLCDS.EraseChars(4);
        }
    }
    MyLCDS.DisplayClear(); // clear display, return cursor home
    
    // 7. Erase in line
    strcpy(szInfo1, "BTN2: Erase");
    strcpy(szInfo2, "BTN1: Continue");
    MyLCDS.WriteStringAtPos(0, 0, szInfo1);
    MyLCDS.WriteStringAtPos(1, 0, szInfo2); 
    fBtn1Process = false;
    fBtn2Process = false;
    MyLCDS.SetPos(0, 6);
	//wait for button 1 pressed to continue
    while(fBtn1Process == false) {
	WaitUntilBtnPressed(&fBtn1Process, &fBtn2Process);
	if(fBtn2Process == true) {
	    // if only button 2 is pressed
            // erase chars from the current position to the end of line
            MyLCDS.EraseInLine(0);
        }
    }
    
    // 8. User char.
    // define characters in RAM at positions 0, 1, 2, 3 
    MyLCDS.DisplayClear(); // clear display, return cursor home
    strcpy(szInfo1, "User char:");
    MyLCDS.WriteStringAtPos(0, 0, szInfo1);
    // write user defined character	
    MyLCDS.DispUserChar(charsToDisp, 4, 0, 10);
    strcpy(szInfo2, "Btn to continue");
    MyLCDS.WriteStringAtPos(1, 0, szInfo2);
    fBtn1Process = false;
    fBtn2Process = false;
    //move forward if any button pressed
    while(fBtn1Process == false && fBtn2Process == false) {
        WaitUntilBtnPressed(&fBtn1Process, &fBtn2Process);
    }
} 
/* ------------------------------------------------------------------- */
/** void  WaitUntilBtnPressed(boolean *pfBtn1Process, boolean *pfBtn2Process)
**
**	Parameters:
**		pfBtn1Process - true for button1 pressed
**		pfBtn2Process - true for button2 pressed
**
**	Return Value:
**		boolean
**
**	Errors:
**		none
**
**	Description:
**		This function returns the state of the two buttons, if they are pressed or not
**
-----------------------------------------------------------------------*/
boolean WaitUntilBtnPressed(boolean *pfBtn1Process, boolean *pfBtn2Process)
{
    *pfBtn1Process = false;
    *pfBtn2Process = false;
    while ((*pfBtn1Process == false) && (*pfBtn2Process == false)) {
	//check the state of the buttons
        debBtn1.update();
        debBtn2.update();
        //if either one of them is pressed while the other is released, set the flags for buttons pressed
	if ((debBtn2.read() && debBtn1.risingEdge())||
           (debBtn2.risingEdge() && debBtn1.read())) 
	    {
	    *pfBtn1Process = true;
	    *pfBtn2Process = true;
  	}
	else {
            //if only button 1 is pressed
	    if (debBtn1.read()&&debBtn1.risingEdge()) {
		*pfBtn1Process = true;
	    }
	    else {
                //if only button 2 is pressed
			if (debBtn2.read()&&debBtn2.risingEdge()) {
		    *pfBtn2Process = true;
		}
	    }	
	}
    }
}
