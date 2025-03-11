/*
This software is provided for student assignment use in the Department of
Electrical and Computer Engineering, Brigham Young University, Utah, USA.
Users agree to not re-host, or redistribute the software, in source or binary
form, to other persons or other institutions. Users may modify and use the
source code for personal or educational use.
For questions, contact Brad Hutchings or Jeff Goeders, https://ece.byu.edu/
*/

#include <stdbool.h>
#include "mio.h"
#include "leds.h"
#include "hitLedTimer.h"
#include "utils.h"
#include <stdio.h>

// The hitLedTimer is active for 1/2 second once it is started.
// While active, it turns on the LED connected to MIO pin 11
// and also LED LD0 on the ZYBO board.

#define HIT_LED_TIMER_EXPIRE_VALUE 50000  //Defined in terms of 100 kHz ticks.
#define HIT_LED_TIMER_OUTPUT_PIN 11      //JF-3
#define TRANSMITTER_HIGH_VALUE 1        //high value to turn LED on
#define TRANSMITTER_LOW_VALUE 0        //low value to to run LED off
#define LED_1_HIGH_VALUE 1         //High value for Led1
#define LED_1_LOW_VALUE 0         //Low value for Led1
#define LED_TIMER_TIME .5           //Half a second time on and off for LED
#define DELAY_UTILS 300 //a 300ms delay needed for passoff


//states for the hit LED timer state machine
enum hitLedTimer_st_t{
    TIMER_WAIT,
    TIMER_RUNNING,
    TIMER_FINISH
}; 

//current state variable for state machine
volatile static uint32_t currentState;
//count variable to track timer
volatile static uint32_t cnt = 0;
//enable bool needed to run LED
volatile static bool enable;
//start bool needed to run LED
volatile static bool start;

// Need to init things.
void hitLedTimer_init(){
    mio_init(false); //need to do this but maybe dont do it here??
    mio_setPinAsOutput(HIT_LED_TIMER_OUTPUT_PIN);
    leds_init(false);
    currentState = TIMER_WAIT;
    cnt = 0;
    hitLedTimer_enable();
}

// Standard tick function.
// Standard tick function.
void hitLedTimer_tick(){
    // State transition state machine
    switch(currentState){
        case TIMER_WAIT:
            if(start && enable){
                currentState = TIMER_RUNNING;
                hitLedTimer_turnLedOn();
                cnt = 0;
                start = 0;
            }
            break;

        case TIMER_RUNNING:
            if(cnt >= HIT_LED_TIMER_EXPIRE_VALUE){
                currentState = TIMER_WAIT;
                hitLedTimer_turnLedOff(); // Turn off LED when time expires
                cnt = 0; // Reset count for next cycle
            }
            break;

        case TIMER_FINISH:
            if(cnt >= HIT_LED_TIMER_EXPIRE_VALUE){
                currentState = TIMER_WAIT; // Go back to waiting state after the same duration
            }
            break;
    }

    // Action state machine
    switch(currentState){
        case TIMER_WAIT:
            break;
        case TIMER_RUNNING:
            cnt++;
            break;
        case TIMER_FINISH:
            cnt++;
            break;
    }
}

// Calling this starts the timer.
void hitLedTimer_start(){
    start = 1;
}

// Returns true if the timer is currently running.
bool hitLedTimer_running(){
    return ((currentState!=TIMER_WAIT)||start);
}

// Turns the gun's hit-LED on.
void hitLedTimer_turnLedOn(){
    leds_write(LED_1_HIGH_VALUE);
    mio_writePin(HIT_LED_TIMER_OUTPUT_PIN, TRANSMITTER_HIGH_VALUE); // Write a '1' to JF-3.
}

// Turns the gun's hit-LED off.
void hitLedTimer_turnLedOff(){
    leds_write(LED_1_LOW_VALUE);
    mio_writePin(HIT_LED_TIMER_OUTPUT_PIN, TRANSMITTER_LOW_VALUE); // Write a '1' to JF-3.
}

// Disables the hitLedTimer.
void hitLedTimer_disable(){
    enable = 0;
}

// Enables the hitLedTimer.
void hitLedTimer_enable(){
    enable = 1;
}

// Runs a visual test of the hit LED until BTN3 is pressed.
// The test continuously blinks the hit-led on and off.
// Depends on the interrupt handler to call tick function.
void hitLedTimer_runTest(){
    while(LED_1_HIGH_VALUE) {
        // Step 1: invoke hitLedTimer_start().
        hitLedTimer_start();
        
        // Step 2: wait until hitLedTimer_running() is false
        while(!hitLedTimer_running()) {
            // Step 3: Delay for 300 ms using utils_msDelay().
            utils_msDelay(DELAY_UTILS);
        }
    }
}
