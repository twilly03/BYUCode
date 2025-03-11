// Uncomment for debug prints
//#define DEBUG
 
#if defined(DEBUG)
#include <stdio.h>
#include "xil_printf.h"
#define DPRINTF(...) printf(__VA_ARGS__)
#define DPCHAR(ch) outbyte(ch)
#else
#define DPRINTF(...)
#define DPCHAR(ch)
#endif

#include <stdint.h>
#include <stdio.h>
#include "mio.h"
#include "buttons.h"
#include "trigger.h"
#include "transmitter.h"

#define TRIGGER_GUN_TRIGGER_MIO_PIN 10 //mio pin mapped
#define TRIGGER_DEBOUNCE_WAIT 0.05 * 100000 //wait 50ms (50ms * 100kHz)
#define GUN_TRIGGER_PRESSED 1 //value rewpresenting a press
#define INIT_DBG "init\n" //Init debug state message
#define WAIT_DBG "wait press\n" //wait debug state message
#define DEBOUNCE_PRESS_DBG "debounce press\n" //debounce press debug state message
#define WAIT_DEPRESS_DBG "wait depress\n" //wait depress debug state message
#define DEBOUNCE_DEPRESS_DBG "debounce depress\n" //debounce depress debug state message
#define SHOOT_DBG "SHOOOOOT\n" //shoot debug state message
#define BLANK_MSG " " //for some reason needed for code to work
#define D_MSG "D\n" //indicates when the button has been pressed
#define U_MSG "U\n" //indicates when the it has been shot



static bool ignoreGunInput; //bool to determine if input needs to be ignored
static bool enableTrigger; //bool enabling trigger
static uint16_t shotsLeft; //variable to store how many shots are left
static uint16_t debounceCount; //variable to count the debounced

//the states for the trigger state machine
enum trigger_states_t {INIT, WAIT_PRESS, WAIT_DEPRESS, DEBOUNCE_PRESS, DEBOUNCE_DEPRESS, SHOOT} currentTriggerState;

// Trigger can be activated by either btn0 or the external gun that is attached to TRIGGER_GUN_TRIGGER_MIO_PIN
// Gun input is ignored if the gun-input is high when the init() function is invoked.
bool triggerPressed() {
	return ((!ignoreGunInput & (mio_readPin(TRIGGER_GUN_TRIGGER_MIO_PIN) == GUN_TRIGGER_PRESSED)) || 
                (buttons_read() & BUTTONS_BTN0_MASK));
}

// Init trigger data-structures.
// Initializes the mio subsystem.
// Determines whether the trigger switch of the gun is connected
// (see discussion in lab web pages).
void trigger_init() {
    mio_init(false); 
    mio_setPinAsInput(TRIGGER_GUN_TRIGGER_MIO_PIN);

    currentTriggerState = INIT;
    ignoreGunInput = 0;
    shotsLeft = 0;
    enableTrigger = false;
    
    // If the trigger is pressed when trigger_init() is called, assume that the gun is not connected and ignore it.
    if (triggerPressed()) {
        ignoreGunInput = true;
    }
}

// This is a debug state print routine. It will print the names of the states each
// time tick() is called. It only prints states if they are different than the
// previous state.
void debugStatePrint() {
  static enum trigger_states_t previousState;
  static bool firstPass = true;
  // Only print the message if:
  // 1. This the first pass and the value for previousState is unknown.
  // 2. previousState != currentState - this prevents reprinting the same state name over and over.
  if (previousState != currentTriggerState || firstPass) {
    firstPass = false;                // previousState will be defined, firstPass is false.
    previousState = currentTriggerState;     // keep track of the last state that you were in.
    switch(currentTriggerState) {            // This prints messages based upon the state that you were in.
      case INIT:
        printf(INIT_DBG);
        break;
      case WAIT_PRESS:
        printf(WAIT_DBG);
        break;
      case DEBOUNCE_PRESS:
        printf(DEBOUNCE_PRESS_DBG);
        break;
      case WAIT_DEPRESS:
        printf(WAIT_DEPRESS_DBG);
        break;
      case DEBOUNCE_DEPRESS:
        printf(DEBOUNCE_DEPRESS_DBG);
        break;
      case SHOOT:
        printf(SHOOT_DBG);
        break;
     }
  }
}
//debug state machine to print current states
void passoffPrint() {
  static enum trigger_states_t previousState;
  static bool firstPass = true;
  // Only print the message if:
  // 1. This the first pass and the value for previousState is unknown.
  // 2. previousState != currentState - this prevents reprinting the same state name over and over.
  if (previousState != currentTriggerState || firstPass) {
    firstPass = false;                // previousState will be defined, firstPass is false.
    previousState = currentTriggerState;     // keep track of the last state that you were in.
    switch(currentTriggerState) {            // This prints messages based upon the state that you were in.
      case INIT:
        printf(BLANK_MSG);
        break;
      case WAIT_PRESS:
        printf(BLANK_MSG);
        break;
      case DEBOUNCE_PRESS:
        printf(BLANK_MSG);
        break;
      case WAIT_DEPRESS:
        printf(D_MSG);
        break;
      case DEBOUNCE_DEPRESS:
        printf(BLANK_MSG);
        break;
      case SHOOT:
        printf(U_MSG);
        break;
     }
  }
}

// Standard tick function.
void trigger_tick() {
    //debugStatePrint();
    
    //mealy
    switch(currentTriggerState) {
        case INIT:
            if(enableTrigger) {
                currentTriggerState = WAIT_PRESS;
            }
            break;
        case WAIT_PRESS:
            if(triggerPressed()) {
                debounceCount = 0;
                currentTriggerState = DEBOUNCE_PRESS;
            }
            break;
        case DEBOUNCE_PRESS:
            if(debounceCount >= TRIGGER_DEBOUNCE_WAIT) {
                currentTriggerState = WAIT_DEPRESS;
            }
            else if(!triggerPressed()) {
                currentTriggerState = WAIT_PRESS;
            }
            break;
        case WAIT_DEPRESS:
            if(!triggerPressed()) {
                currentTriggerState = DEBOUNCE_DEPRESS;
                debounceCount = 0;
            }
            break;
        case DEBOUNCE_DEPRESS:
            if(debounceCount >= TRIGGER_DEBOUNCE_WAIT) {
                currentTriggerState = SHOOT;
            }
            else if(triggerPressed()) {
                currentTriggerState = WAIT_DEPRESS;
            }
            break;
        case SHOOT:
            transmitter_run();
            currentTriggerState = INIT;
            break;
    }

    //mooooooooooooooooore
    switch(currentTriggerState) {
        case INIT:
            break;
        case WAIT_PRESS:
            break;
        case DEBOUNCE_PRESS:
            debounceCount++;
            break;
        case WAIT_DEPRESS:
            break;
        case DEBOUNCE_DEPRESS:
            debounceCount++;
            break;
        case SHOOT:
            break;
    }

}

// Enable the trigger state machine. The trigger state-machine is inactive until
// this function is called. This allows you to ignore the trigger when helpful
// (mostly useful for testing).
void trigger_enable() {
    enableTrigger = true;
}

// Disable the trigger state machine so that trigger presses are ignored.
void trigger_disable() {
    enableTrigger = false;
}

// Returns the number of remaining shots.
trigger_shotsRemaining_t trigger_getRemainingShotCount() {
    return shotsLeft;
}

// Sets the number of remaining shots.
void trigger_setRemainingShotCount(trigger_shotsRemaining_t count) {
    shotsLeft = count;
}

// Runs the test continuously until BTN3 is pressed.
// The test just prints out a 'D' when the trigger or BTN0
// is pressed, and a 'U' when the trigger or BTN0 is released.
// Depends on the interrupt handler to call tick function.
void trigger_runTest() {
    trigger_enable();
    
    #if defined(DEBUG)
    while(GUN_TRIGGER_PRESSED) {
       passoffPrint();
    }
    #endif
}