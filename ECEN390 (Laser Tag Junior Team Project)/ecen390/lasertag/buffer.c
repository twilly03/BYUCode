#include "buffer.h"
#include <stdint.h>

// This implements a dedicated circular buffer for storing values
// from the ADC until they are read and processed by the detector.
// The function of the buffer is similar to a queue or FIFO.

// Type of elements in the buffer.
typedef uint32_t buffer_data_t;

// Initialize the buffer to empty.
void buffer_init(void);

// Add a value to the buffer. Overwrite the oldest value if full.
void buffer_pushover(buffer_data_t value);

// Remove a value from the buffer. Return zero if empty.
buffer_data_t buffer_pop(void);

// Return the number of elements in the buffer.
uint32_t buffer_elements(void);

// Return the capacity of the buffer in elements.
uint32_t buffer_size(void);

//buffer size 
#define BUFFER_SIZE 32768
//define a struct in order to create our buffer
typedef struct {
    uint32_t indexIn;        // Points to the next open slot.
    uint32_t indexOut;       // Points to the next element to be removed.
    uint32_t elementCount;   // Number of elements in the buffer.
    buffer_data_t data[BUFFER_SIZE]; // Values are stored here.
} buffer_t;

volatile static buffer_t buf;

// Initialize the buffer to empty.
void buffer_init(void) {
    buf.indexIn = 0;
    buf.indexOut = 0;
    buf.elementCount = 0;
}

// Add a value to the buffer. Overwrite the oldest value if full.
void buffer_pushover(buffer_data_t value) {
    //if the buffer is not full
    if (buf.elementCount < BUFFER_SIZE) {
        buf.data[buf.indexIn] = value;
        buf.indexIn = (buf.indexIn + 1) % BUFFER_SIZE;
        //if the buffer is full after we add
        if (buf.elementCount == BUFFER_SIZE) {
            buf.indexOut = (buf.indexOut + 1) % BUFFER_SIZE;
        } 
        //if the buffer is not full after we add
        else {
            buf.elementCount++;
        }
    } 
    //if the buffer is full 
    else {
        // Buffer full, overwrite oldest value
        buf.data[buf.indexOut] = value;
        buf.indexIn = (buf.indexIn + 1) % BUFFER_SIZE;
        buf.indexOut = (buf.indexOut + 1) % BUFFER_SIZE;
    }
}

// Remove a value from the buffer. Return zero if empty.
buffer_data_t buffer_pop(void) {
    buffer_data_t value = 0;
    //as long as the element count is > 0 we remove from the buffer
    if (buf.elementCount > 0) {
        value = buf.data[buf.indexOut];
        buf.indexOut = (buf.indexOut + 1) % BUFFER_SIZE;
        buf.elementCount--;
    }
    return value;
}

// Return the number of elements in the buffer.
uint32_t buffer_elements(void) {
    return buf.elementCount;
}

// Return the capacity of the buffer in elements.
uint32_t buffer_size(void) {
    return BUFFER_SIZE;
}
