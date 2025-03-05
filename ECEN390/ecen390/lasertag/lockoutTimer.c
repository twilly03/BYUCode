/*
This software is provided for student assignment use in the Department of
Electrical and Computer Engineering, Brigham Young University, Utah, USA.
Users agree to not re-host, or redistribute the software, in source or binary
form, to other persons or other institutions. Users may modify and use the
source code for personal or educational use.
For questions, contact Brad Hutchings or Jeff Goeders, https://ece.byu.edu/
*/

#include "intervalTimer.h"
#include "lockoutTimer.h"
#include "stdio.h"

#define LOCKOUT_TICKS 50000 //half second * freq of board
#define WAIT_DB "WAIT\n" //Wait Debug state print
#define RUN_DB "RUN\n" //Run Debug state print
#define FINISHED_DB "FINISHED\n" //Finished Debug state print
#define HALF_SECOND .5 //Half second timer
#define TIMER_TWO 2 //Two used for timer purposes

//bool to determine if the timer should run
volatile bool runTimer;
//bool if timer is currently running
volatile bool timerRunning;
//variable to track the timer ticks
volatile uint32_t timerCount;

// The lockoutTimer is active for 1/2 second once it is started.
// It is used to lock-out the detector once a hit has been detected.
// This ensures that only one hit is detected per 1/2-second interval.

//States for the lockout Timer state machine
enum lockout_timer_states_t {WAIT, TIMER_RUN, TIMER_FINISHED} currentTimerState;

// Perform any necessary inits for the lockout timer.
void lockoutTimer_init() {
    currentTimerState = WAIT;
    timerRunning = false;
    runTimer = false;
    timerCount = 0;
}

//debug state machine
void debugTimerStatePrint() {
  static enum lockout_timer_states_t previousState;
  static bool firstPass = true;
  // Only print the message if:
  // 1. This the first pass and the value for previousState is unknown.
  // 2. previousState != currentState - this prevents reprinting the same state name over and over.
  if (previousState != currentTimerState || firstPass) {
    firstPass = false;                // previousState will be defined, firstPass is false.
    previousState = currentTimerState;     // keep track of the last state that you were in.
    switch(currentTimerState) {            // This prints messages based upon the state that you were in.
      case WAIT:
        printf(WAIT_DB);
        break;
      case TIMER_RUN:
        printf(RUN_DB);
        break;
      case TIMER_FINISHED:
        printf(FINISHED_DB);
        break;
     }
  }
}

// Standard tick function.
void lockoutTimer_tick() {
    //debugTimerStatePrint();
    //mealy
    switch(currentTimerState) {
        case WAIT:
            if(runTimer) {
                timerCount = 0;
                currentTimerState = TIMER_RUN;
                runTimer = 0;
            }
            break;
        case TIMER_RUN:
            if (timerCount >= LOCKOUT_TICKS) {
                currentTimerState = WAIT;
            }
            break;
        case TIMER_FINISHED:
            runTimer = false;
            timerRunning = false;
            currentTimerState = WAIT;
            break;
        default:
            break;
    }

    //moore
    switch(currentTimerState) {
        case WAIT:
            break;
        case TIMER_RUN:
            timerCount++;
            break;
        case TIMER_FINISHED:
            break;
        default:
            break;
    }

}

// Calling this starts the timer.
void lockoutTimer_start() {
    runTimer = true;
}

// Returns true if the timer is running.
bool lockoutTimer_running() {
   return((currentTimerState != WAIT) || runTimer);
}

// Test function assumes interrupts have been completely enabled and
// lockoutTimer_tick() function is invoked by isr_function().
// Prints out pass/fail status and other info to console.
// Returns true if passes, false otherwise.
// This test uses the interval timer to determine correct delay for
// the interval timer.
bool lockoutTimer_runTest() {
    lockoutTimer_init();
    lockoutTimer_start();
    intervalTimer_init(TIMER_TWO);
    intervalTimer_start(TIMER_TWO);
    while (lockoutTimer_running()) {
        
    }
    intervalTimer_stop(TIMER_TWO);
    
    printf("%f\n", intervalTimer_getTotalDurationInSeconds(TIMER_TWO));
    
    if(intervalTimer_getTotalDurationInSeconds(TIMER_TWO) >= HALF_SECOND) {
        return true;
    }

    return false;
}
