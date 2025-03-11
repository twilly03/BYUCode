/*
This software is provided for student assignment use in the Department of
Electrical and Computer Engineering, Brigham Young University, Utah, USA.
Users agree to not re-host, or redistribute the software, in source or binary
form, to other persons or other institutions. Users may modify and use the
source code for personal or educational use.
For questions, contact Brad Hutchings or Jeff Goeders, https://ece.byu.edu/
*/

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include "filter.h"
#include "mio.h"
#include "utils.h"
#include "buttons.h"
#include "switches.h"

#define TRANSMITTER_OUTPUT_PIN 13     // JF1 (pg. 25 of ZYBO reference manual).
#define TRANSMITTER_PULSE_WIDTH 20000 // Based on a system tick-rate of 100 kHz.
#define TRANSMITTER_HIGH_VALUE 1 //high value to be passed to transmitter
#define TRANSMITTER_LOW_VALUE 0 //low value to be passed to transmitter
#define TRANSMITTER_TEST_TICK_PERIOD_IN_MS 10 //the tick period in ms
#define BOUNCE_DELAY 5 //delay needed for running tests
#define HALF 2 //constant used to divide by 2
#define TEST_START_MSG "starting transmitter test\n" //message for the start of a test
#define TEST_DONE_MSG "completed one test period.\n" //one test period is finished
#define TEST_EXIT_MSG "exiting transmitter test\n" //exiting the transmitter test

//global variable for the freqency number
volatile uint16_t freqNumber;
//global variable for the player freqency based on the freqeuncy number
volatile uint16_t playerFreqTick;
//global bool for continuous mode
volatile bool continuousMode;
//global bool for start
volatile bool start;
//time between each transition corresponding to duty cycles
volatile uint16_t wait_cnt;
//count for the length of the signal
volatile uint16_t waveform_cnt;
//the number of ticks for each transition
volatile uint16_t wait_num_ticks;
//the number of the tick corresponding to total length of the waveform
volatile uint16_t waveform_num_ticks;
//states for the transmitter state machine
enum transmitter_st_t{
    INIT_STATE,
    HIGH_WV_STATE,
    LOW_WV_STATE,
    FINISHED_STATE,
};
//current state variable for state machine
volatile static uint32_t currentState;


// The transmitter state machine generates a square wave output at the chosen
// frequency as set by transmitter_setFrequencyNumber(). The step counts for the
// frequencies are provided in filter.h

//sets pin jf1 to high
void transmitter_set_jf1_to_one();

//sets pin jf1 to low
void transmitter_set_jf1_to_zero();

// Standard init function.
void transmitter_init(){
    mio_init(false);  // false disables any debug printing if there is a system failure during init.
    mio_setPinAsOutput(TRANSMITTER_OUTPUT_PIN);  // Configure the signal direction of the pin to be an output.
    playerFreqTick = filter_frequencyTickTable[freqNumber];
    currentState = INIT_STATE;
    wait_cnt = 0;
    waveform_cnt = 0;
    wait_num_ticks = 0;
    transmitter_set_jf1_to_zero();
    waveform_num_ticks = TRANSMITTER_PULSE_WIDTH;
    continuousMode = false;
    start = false;
}

// Standard tick function.
void transmitter_tick() {
    //state transition logic state machine
    switch(currentState){
        case INIT_STATE:
            // The state machine should only change frequencies when it is inactive or after it has completed transmitting the waveform for 200 ms.
            playerFreqTick = filter_frequencyTickTable[freqNumber];
            wait_num_ticks = playerFreqTick/HALF;
            currentState = FINISHED_STATE;
            break;
        case HIGH_WV_STATE:
            if(waveform_cnt >= waveform_num_ticks){
                waveform_cnt = 0;
                currentState = FINISHED_STATE;
                transmitter_set_jf1_to_zero();
            }
            else if(wait_cnt >= wait_num_ticks ){
                wait_cnt = 0;
                currentState = LOW_WV_STATE;
                transmitter_set_jf1_to_zero();//Only send a single '1' or '0' to JF-1 when the waveform transitions from '1' to '0' or vice versa
            }
            else{
                currentState = HIGH_WV_STATE;
            }
            break;
        case LOW_WV_STATE:
            if( waveform_cnt >= waveform_num_ticks){
            waveform_cnt = 0;
            currentState = FINISHED_STATE;
            transmitter_set_jf1_to_zero();
            }
            else if(wait_cnt >= wait_num_ticks ){
                wait_cnt = 0;
                currentState = HIGH_WV_STATE;
                //Only send a single '1' or '0' to JF-1 when the waveform transitions from '1' to '0' or vice versa
                transmitter_set_jf1_to_one();
            }
            else{
                currentState = LOW_WV_STATE;
            }
            break;
        case FINISHED_STATE:
            if((continuousMode) || (start)){
                currentState = HIGH_WV_STATE;
                playerFreqTick = filter_frequencyTickTable[freqNumber];
                wait_num_ticks = playerFreqTick/HALF;
                start = false;
            }            
            break;

        default:
            break;
    }

    //action state machine
    switch(currentState) {
        case INIT_STATE:
            break;
        case HIGH_WV_STATE:
            wait_cnt++;
            waveform_cnt++;
            break;
        case LOW_WV_STATE:
            wait_cnt++;
            waveform_cnt++;
            break;
        case FINISHED_STATE:
            break;
    }
}

// Activate the transmitter.
void transmitter_run() {
    start = true;
}

// Returns true if the transmitter is still running.
bool transmitter_running() {
    return (((currentState != FINISHED_STATE) && (currentState != INIT_STATE)) || start);
}

// Sets the frequency number. If this function is called while the
// transmitter is running, the frequency will not be updated until the
// transmitter stops and transmitter_run() is called again.
void transmitter_setFrequencyNumber(uint16_t frequencyNumber){
    freqNumber = frequencyNumber;
}

//sets pin jf1 to high
void transmitter_set_jf1_to_one() {
  mio_writePin(TRANSMITTER_OUTPUT_PIN, TRANSMITTER_HIGH_VALUE); // Write a '1' to JF-1.
}

//sets pin jf1 to low
void transmitter_set_jf1_to_zero() {
  mio_writePin(TRANSMITTER_OUTPUT_PIN, TRANSMITTER_LOW_VALUE); // Write a '0' to JF-1.
}

// Returns the current frequency setting.
uint16_t transmitter_getFrequencyNumber() {
    return freqNumber;
}

// Runs the transmitter continuously.
// if continuousModeFlag == true, transmitter runs continuously, otherwise, it
// transmits one burst and stops. To set continuous mode, you must invoke
// this function prior to calling transmitter_run(). If the transmitter is
// currently in continuous mode, it will stop running if this function is
// invoked with continuousModeFlag == false. It can stop immediately or wait
// until a 200 ms burst is complete. NOTE: while running continuously,
// the transmitter will only change frequencies in between 200 ms bursts.
void transmitter_setContinuousMode(bool continuousModeFlag) {
    continuousMode = continuousModeFlag;
}

/******************************************************************************
***** Test Functions
******************************************************************************/

// Prints out the clock waveform to stdio. Terminates when BTN1 is pressed.
// Prints out one line of 1s and 0s that represent one period of the clock signal, in terms of ticks.
void transmitter_runTest() {
  printf(TEST_START_MSG);
  transmitter_init();                                     // init the transmitter.
  while (!(buttons_read() & BUTTONS_BTN3_MASK)) {         // Run continuously until BTN3 is pressed.
    uint16_t switchValue = switches_read() % FILTER_FREQUENCY_COUNT;  // Compute a safe number from the switches.
    transmitter_setFrequencyNumber(switchValue);          // set the frequency number based upon switch value.
    transmitter_run();                                    // Start the transmitter.
    while (transmitter_running()) {                       // Keep ticking until it is done.
      transmitter_tick();                                 // tick.
      utils_msDelay(TRANSMITTER_TEST_TICK_PERIOD_IN_MS);  // short delay between ticks.
    }
    printf(TEST_DONE_MSG);
  }
  do {utils_msDelay(BOUNCE_DELAY);} while (buttons_read());
  printf(TEST_EXIT_MSG);
}

// Tests the transmitter in non-continuous mode.
// The test runs until BTN3 is pressed.
// To perform the test, connect the oscilloscope probe
// to the transmitter and ground probes on the development board
// prior to running this test. You should see about a 300 ms dead
// spot between 200 ms pulses.
// Should change frequency in response to the slide switches.
// Depends on the interrupt handler to call tick function.
void transmitter_runTestNoncontinuous() {
 printf(TEST_START_MSG);
  transmitter_init();                                     // init the transmitter.
  while (!(buttons_read() & BUTTONS_BTN3_MASK)) {         // Run continuously until BTN3 is pressed.
    uint16_t switchValue = switches_read() % FILTER_FREQUENCY_COUNT;  // Compute a safe number from the switches.
    transmitter_setFrequencyNumber(switchValue);          // set the frequency number based upon switch value.
    transmitter_run();                                    // Start the transmitter.
    while (transmitter_running()) {                       // Keep ticking until it is done.
    }
      utils_msDelay(400);  // short delay between ticks.
    printf(TEST_DONE_MSG);
  }
  do {utils_msDelay(BOUNCE_DELAY);} while (buttons_read());
  printf(TEST_EXIT_MSG);
}

// Tests the transmitter in continuous mode.
// To perform the test, connect the oscilloscope probe
// to the transmitter and ground probes on the development board
// prior to running this test.
// Transmitter should continuously generate the proper waveform
// at the transmitter-probe pin and change frequencies
// in response to changes in the slide switches.
// Test runs until BTN3 is pressed.
// Depends on the interrupt handler to call tick function.
void transmitter_runTestContinuous() {
     printf(TEST_START_MSG);
  transmitter_init();                                     // init the transmitter.
  while (!(buttons_read() & BUTTONS_BTN3_MASK)) {         // Run continuously until BTN3 is pressed.
    uint16_t switchValue = switches_read() % FILTER_FREQUENCY_COUNT;  // Compute a safe number from the switches.
    transmitter_setFrequencyNumber(switchValue);          // set the frequency number based upon switch value.
    transmitter_run();                                    // Start the transmitter.
    while (transmitter_running()) {                       // Keep ticking until it is done
    }
    printf(TEST_DONE_MSG);
  }
  do {utils_msDelay(BOUNCE_DELAY);} while (buttons_read());
  printf(TEST_EXIT_MSG);
}
