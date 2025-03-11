#include "isr.h"
#include "hitLedTimer.h"
#include "trigger.h"
#include "lockoutTimer.h"
#include "buffer.h"
#include "transmitter.h"
#include "interrupts.h"

// The interrupt service routine (ISR) is implemented here.
// Add function calls for state machine tick functions and
// other interrupt related modules.

// Perform initialization for interrupt and timing related modules.
void isr_init() {
    hitLedTimer_init();
    trigger_init();
    transmitter_init();
    lockoutTimer_init();
    buffer_init();
    //this is where we call state machine init functions
}

// This function is invoked by the timer interrupt at 100 kHz.
void isr_function() {
    hitLedTimer_tick();
    trigger_tick();
    lockoutTimer_tick();
    transmitter_tick();
    buffer_pushover(interrupts_getAdcData());
    //this is where we call state machine tick functions
}