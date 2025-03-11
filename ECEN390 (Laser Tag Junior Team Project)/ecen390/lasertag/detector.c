#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include "detector.h"
#include "buffer.h"
#include "filter.h"
#include "mio.h"
#include "switches.h"
#include "interrupts.h"
#include "lockoutTimer.h"
#include "hitLedTimer.h"
 
#define DETECTOR_HIT_ARRAY_SIZE 10 //the size of the detector hit array
#define FREQ_LIST_SIZE 10 // the size of the freqency list
#define MEDIAN_INDEX_SORTED_POWERS 5 // the median index of sorted powers
#define TEMP_FUDGE_FACTOR 15 //the temp fudge factor value
#define THRESHOLD_CONST 0.001 // a constant used to add to the threshold
#define RAW_TO_SCALED_ADC_CONST 4095.0 * 2.0 - 1.0 //a const used to conver to scaled adc
#define PLAYER_0 0 //player 0
#define PLAYER_1 1 //player 1
#define PLAYER_2 2 //player 2
#define PLAYER_3 3 //player 3
#define PLAYER_4 4 //player 4
#define PLAYER_5 5 //player 5
#define PLAYER_6 6 //player 6
#define PLAYER_7 7 //player 7
#define PLAYER_8 8 //player 8
#define PLAYER_9 9 //player 9
#define DETECTOR_TRUE_7000 7000 //true test, value 7000
#define DETECTOR_TRUE_20 20 //true test, value 20
#define DETECTOR_TRUE_40 40 //true test, value 40
#define DETECTOR_TRUE_10 10 //true test, value 10
#define DETECTOR_TRUE_15 15 //true test, value 15
#define DETECTOR_TRUE_30 30 //true test, value 30
#define DETECTOR_TRUE_35 35 //true test, value 35 
#define DETECTOR_TRUE_25 25 //true test, value 25
#define DETECTOR_TRUE_85 85 //true test, value 85
#define DETECTOR_FALSE_500 500 //false test, value 500
#define DETECTOR_FALSE_20 20 //false test, value 20
#define DETECTOR_FALSE_40 40 //false test, value 40
#define DETECTOR_FALSE_10 10 //false test, value 10
#define DETECTOR_FALSE_15 15 //false test, value 15
#define DETECTOR_FALSE_30 30 //false test, value 30
#define DETECTOR_FALSE_35 35 //false test, value 35
#define DETECTOR_FALSE_25 25 //false test, value 25
#define DETECTOR_FALSE_85 85 //false test, value 85


static bool detector_hitDetectedFlag; // a flag used to indicate if a hit
static bool ignoreAllHits; //bool if we are to ignore all hits
static bool ignoredFrequencies[FREQ_LIST_SIZE]; //an array of ignored freqencies
static double scaledAdcValue; //a scaled adc value
static double threshold; //threshold value needed for power values to be greater than
static double maxValue; //max value set after sorting 
static uint16_t frequencyOfLastHit; //frequency of last hit
static uint16_t newInputCount; // count of new input
static uint32_t detectorInvocationCount; //how many times detector has been called
static uint32_t elementCount; //count of all elements
static uint32_t fudgeFactorIndex; //value of the fudge factor
static detector_hitCount_t detector_hitArray[DETECTOR_HIT_ARRAY_SIZE]; //array of hits detected
static double computedPowers[DETECTOR_HIT_ARRAY_SIZE]; //array of computed power values

//function to swap values in an array
void swap(double *xp, double *yp) { 
    int temp = *xp; 
    *xp = *yp; 
    *yp = temp; 
} 

//sub function used to call our hit detection algorithm
void hit_detect();

// Initialize the detector module.
// By default, all frequencies are considered for hits.
// Assumes the filter module is initialized previously.
void detector_init(void) {double
    newInputCount = 0;
    detectorInvocationCount = 0;
    elementCount = 0;
    fudgeFactorIndex = TEMP_FUDGE_FACTOR;

    //set all frequencies available to be hit
    for(uint8_t i = 0; i < FREQ_LIST_SIZE; i++) {
        ignoredFrequencies[i] = false;
    }

    //set the hit counts to zero
    for(uint8_t i = 0; i < DETECTOR_HIT_ARRAY_SIZE; i++) {
        detector_hitArray[i] = 0;
    }

}

// freqArray is indexed by frequency number. If an element is set to true,
// the frequency will be ignored. Multiple frequencies can be ignored.
// Your shot frequency (based on the switches) is a good choice to ignore.
void detector_setIgnoredFrequencies(bool freqArray[]) {
    
    uint32_t switchValueRead = switches_read(); 

    //copy the array over into the global array for access throughout the program.
    for(uint8_t i = 0; i < FREQ_LIST_SIZE; i++) {
        ignoredFrequencies[i] = freqArray[i];
    }
    
    //turn off the player's selected frequency.
    if(switchValueRead < FREQ_LIST_SIZE) {
       ignoredFrequencies[switchValueRead] = true;
    }

}

// Runs the entire detector: decimating FIR-filter, IIR-filters,
// power-computation, hit-detection. If interruptsCurrentlyEnabled = true,
// interrupts are running. If interruptsCurrentlyEnabled = false you can pop
// values from the ADC buffer without disabling interrupts. If
// interruptsCurrentlyEnabled = true, do the following:
// 1. disable interrupts.
// 2. pop the value from the ADC buffer.
// 3. re-enable interrupts.
// Ignore hits on frequencies specified with detector_setIgnoredFrequencies().
// Assumption: draining the ADC buffer occurs faster than it can fill.
void detector(bool interruptsCurrentlyEnabled) {
    elementCount = buffer_elements();
    buffer_data_t rawAdcValue;
    detectorInvocationCount++;

    //loop through the elements in the buffer and perform desired operations to calculate if a hit was detected.
    for(uint16_t i = 0; i < elementCount; i++){
        //If interrupts are enabled (check to see if the interruptsEnabled argument == true), briefly disable interrupts by invoking interrupts_disableArmInts()
        if(interruptsCurrentlyEnabled){
            interrupts_disableArmInts();
            rawAdcValue = buffer_pop();
            interrupts_enableArmInts();
        }
        //if interupts is not enabled
        else{
            rawAdcValue = buffer_pop();
        }
#if 1
        //Scale the integer value contained in rawAdcValue to a double that is between -1.0 and 1.0. Store this value into a variable named scaledAdcValue
        double scaledAdcValue = (double)rawAdcValue / RAW_TO_SCALED_ADC_CONST; //The ADC generates a 12-bit output that ranges from 0 to 4095. 0 would map to -1.0. 4095 maps to 1.0
        filter_addNewInput(scaledAdcValue);
        newInputCount++;
        //If filter_addNewInput() has been called 10 times since the last invocation of the FIR and IIR filters, run the FIR filter, IIR filter and power computation for all 10 channels
        if(newInputCount >= DETECTOR_HIT_ARRAY_SIZE){
            filter_firFilter();
            //iir filter and calculate the power
            for(uint16_t j = 0; j < DETECTOR_HIT_ARRAY_SIZE; j++){
                filter_iirFilter(j);
                filter_computePower(j,false, false);
            }
            //if the lockoutTimer is not running, run the hit-detection algorithm. If you detect a hit and the frequency with maximum power is not an ignored frequency, do the following:
            hit_detect();
            newInputCount = 0;
        }
#endif
    }
}

//sub function used to call our hit detection algorithm
void hit_detect(){
    filter_getCurrentPowerValues(computedPowers);
    double computedPowers_initial[DETECTOR_HIT_ARRAY_SIZE];
    //copy the array of computed powers to get the index of the highest power
    for(uint8_t i = 0; i < DETECTOR_HIT_ARRAY_SIZE; i++){
        computedPowers_initial[i] = computedPowers[i];
    }

    //checking if there was a hit 
    if(!lockoutTimer_running()) {
        detector_hitDetectedFlag = false;
        //For loop that is looping through the computed powers array
        for (uint16_t i = 0; i < DETECTOR_HIT_ARRAY_SIZE - 1; i++){
            /* find the min element in the unsorted a[i .. aLength-1] */

            /* assume the min is the first element */
            int jMin = i;
            /* test against elements after i to find the smallest */
            for (uint16_t j = i+1; j < DETECTOR_HIT_ARRAY_SIZE; j++){
                /* if this element is less, then it is the new minimum */
                if (computedPowers[j] < computedPowers[jMin]){
                   /* found new minimum; remember its index */
                  jMin = j;
                 continue;
                }
            }       

            //swaping the values if needed
            if (jMin != i) {
                swap(&computedPowers[i], &computedPowers[jMin]);
            }
        }

        // printf("%d", fudgeFactorIndex);
        threshold = TEMP_FUDGE_FACTOR * computedPowers[MEDIAN_INDEX_SORTED_POWERS] + THRESHOLD_CONST;
        // printf("Threshold = %f\n\n", threshold);
        maxValue = threshold;

        uint8_t maxvalindex = 0;
        //run the hit detected algorithm
        for(uint8_t i = 0; i < DETECTOR_HIT_ARRAY_SIZE; i++){
            //check for maxvalue and take note of that index
            if(computedPowers_initial[i] >= maxValue){
                 maxValue = computedPowers_initial[i];
                 maxvalindex = i ;
            }
        }
        //printf("%d\n", maxvalindex);

        //if it is not an ignored frequency, do the following steps to accept the defeat (you've been hit)
        if(!ignoredFrequencies[maxvalindex] && (maxValue > threshold)){
            //printf("%f, %f\n", maxValue, threshold);
            //increment detector_hitArray at the index of the frequency of the IIR-filter output where you detected the hit. Note that detector_hitArray is a 10-element integer array that simply holds the current number of hits, for each frequency, that have occurred to this point.
            detector_hitArray[maxvalindex] += 1;
            //start the lockoutTimer.
            lockoutTimer_start();
            //start the hitLedTimer.
            hitLedTimer_start();
            detector_hitDetectedFlag = true;
        }
    }
}   

// Returns true if a hit was detected.
bool detector_hitDetected(void) {
    return detector_hitDetectedFlag;
}

// Returns the frequency number that caused the hit.
uint16_t detector_getFrequencyNumberOfLastHit(void) {
    return frequencyOfLastHit;
}

// Clear the detected hit once you have accounted for it.
void detector_clearHit(void) {
    detector_hitDetectedFlag = false;
}

// Ignore all hits. Used to provide some limited invincibility in some game
// modes. The detector will ignore all hits if the flag is true, otherwise will
// respond to hits normally.
void detector_ignoreAllHits(bool flagValue) {
    ignoreAllHits = flagValue;
}

// Get the current hit counts.
// Copy the current hit counts into the user-provided hitArray
// using a for-loop.
void detector_getHitCounts(detector_hitCount_t hitArray[]) {
    //loop through the the detector hit array and update the passed in hit array
    for(uint8_t i = 0; i < DETECTOR_HIT_ARRAY_SIZE; i++) {
        hitArray[i] = detector_hitArray[i];
    }
}

// Allows the fudge-factor index to be set externally from the detector.
// The actual values for fudge-factors is stored in an array found in detector.c

//THIS IS WRONG, THERE WILL BE AN ARRAY OF FUDGE FACTS BUT FOR RIGHT NOW, FUDGE IT!
void detector_setFudgeFactorIndex(uint32_t factorIdx) {
    fudgeFactorIndex = factorIdx;
}

// Returns the detector invocation count.
// The count is incremented each time detector is called.
// Used for run-time statistics.
uint32_t detector_getInvocationCount(void) {
    return detectorInvocationCount;
}

/******************************************************
******************** Test Routines ********************
******************************************************/

// Students implement this as part of Milestone 3, Task 3.
// Create two sets of power values and call your hit detection algorithm
// on each set. With the same fudge factor, your hit detect algorithm
// should detect a hit on the first set and not detect a hit on the second.
void detector_runTest(void) {
    
    printf("*****ISOLATED DETECTOR TEST*****\n\n");
    fudgeFactorIndex = TEMP_FUDGE_FACTOR;
    filter_setCurrentPowerValue(PLAYER_0, DETECTOR_TRUE_7000);
    filter_setCurrentPowerValue(PLAYER_1, DETECTOR_TRUE_20);
    filter_setCurrentPowerValue(PLAYER_2, DETECTOR_TRUE_40);
    filter_setCurrentPowerValue(PLAYER_3, DETECTOR_TRUE_10);
    filter_setCurrentPowerValue(PLAYER_4, DETECTOR_TRUE_15);
    filter_setCurrentPowerValue(PLAYER_5, DETECTOR_TRUE_30);
    filter_setCurrentPowerValue(PLAYER_6, DETECTOR_TRUE_35);
    filter_setCurrentPowerValue(PLAYER_7, DETECTOR_TRUE_15);
    filter_setCurrentPowerValue(PLAYER_8, DETECTOR_TRUE_25);
    filter_setCurrentPowerValue(PLAYER_9, DETECTOR_TRUE_85);
    filter_getCurrentPowerValues(computedPowers);
    //print the computed power array before sorting
    for(uint8_t i = 0; i < DETECTOR_HIT_ARRAY_SIZE; i++) {
        printf("%d: %f\n", i, computedPowers[i]);
    }
    printf("\n");
    hit_detect();
    //print computer power array after sorting
    for(uint8_t i = 0; i < DETECTOR_HIT_ARRAY_SIZE; i++) {
        printf("%d: %f\n", i, computedPowers[i]);
    }
    printf("\n");
    bool firstTest = detector_hitDetected();
    printf("This should say true(1): %d\n\n", firstTest);

    printf("Lockout timer status: %d\n", lockoutTimer_running());

    //a while loop used to check if the timer is running
    while(lockoutTimer_running()) {
        lockoutTimer_tick();
    }
    printf("Lockout timer status: %d\n\n", lockoutTimer_running());

    filter_setCurrentPowerValue(PLAYER_0, DETECTOR_FALSE_500);
    filter_setCurrentPowerValue(PLAYER_1, DETECTOR_FALSE_20);
    filter_setCurrentPowerValue(PLAYER_2, DETECTOR_FALSE_40);
    filter_setCurrentPowerValue(PLAYER_3, DETECTOR_FALSE_10);
    filter_setCurrentPowerValue(PLAYER_4, DETECTOR_FALSE_15);
    filter_setCurrentPowerValue(PLAYER_5, DETECTOR_FALSE_30);
    filter_setCurrentPowerValue(PLAYER_6, DETECTOR_FALSE_35);
    filter_setCurrentPowerValue(PLAYER_7, DETECTOR_FALSE_15);
    filter_setCurrentPowerValue(PLAYER_8, DETECTOR_FALSE_25);
    filter_setCurrentPowerValue(PLAYER_9, DETECTOR_FALSE_85);
    filter_getCurrentPowerValues(computedPowers);
    //print the computed power array befotre sorting
    for(uint8_t i = 0; i < DETECTOR_HIT_ARRAY_SIZE; i++) {
        printf("%d: %f\n", i, computedPowers[i]);
    }
    printf("\n");
    hit_detect();
    //print computed power array after sorting
    for(uint8_t i = 0; i < DETECTOR_HIT_ARRAY_SIZE; i++) {
        printf("%d: %f\n", i, computedPowers[i]);
    }
    printf("\n");
    bool secondTest = detector_hitDetected();
    printf("This should say false(0): %d\n\n*****END OF ISOLATED DETECTOR TEST*****\n", secondTest);
}