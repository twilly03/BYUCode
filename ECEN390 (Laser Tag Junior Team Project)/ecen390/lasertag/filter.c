#include <stdint.h>
#include "filter.h"
#include "queue.h"
#include  <math.h>

//we initialize all queues to 0 rather than leave empty
#define QUEUE_INIT_VALUE 0.0
//The a coefficent count subtracting the constant 1
#define IIR_A_COEFFICIENT_COUNT 10
//All 11 of the b coefficients
#define IIR_B_COEFFICIENT_COUNT 11
//All 81 of the FIR coefficients 
#define FIR_A_COEFFICIENT_COUNT 81
//the size of the output queue
#define OUTPUT_COUNT 2000

#define FILTER_FREQUENCY_COUNT 10

//X Queue initilization and declaration box
#define X_QUEUE_SIZE FIR_A_COEFFICIENT_COUNT 
//declaring xQueue
static queue_t xQueue;

//Y Queue initilization and declaration box
#define Y_QUEUE_SIZE IIR_B_COEFFICIENT_COUNT 
//declaring yQueue
static queue_t yQueue;

//Z Queue initilization and declaration box
#define Z_QUEUE_SIZE IIR_A_COEFFICIENT_COUNT
//declaring zQueue
static queue_t zQueue[FILTER_FREQUENCY_COUNT];  

//Output Queue initilization and declaration box
#define OUTPUT_QUEUE_SIZE OUTPUT_COUNT
//declaring output Queue
static queue_t OutputQueue[FILTER_FREQUENCY_COUNT]; 

//a static double array to hold power outputs
static double Power_Output[10];

//a double array to hold current power values
double currentPowerValue[10];

//a double array to store the oldest values of power
double oldestValue[FILTER_FREQUENCY_COUNT] = {0};

#define FILTER_SAMPLE_FREQUENCY_IN_KHZ 100
#define FIR_FILTER_TAP_COUNT 81
#define FILTER_FIR_DECIMATION_FACTOR 10 // FIR-filter needs this many new inputs to compute a new output.
#define FILTER_INPUT_PULSE_WIDTH 2000 // This is the width of the pulse you are looking for, in terms of decimated sample count.

// Filtering routines for the laser-tag project.
// Filtering is performed by a two-stage filter, as described below.

// 1. First filter is a decimating FIR filter with a configurable number of taps
// and decimation factor.
// 2. The output from the decimating FIR filter is passed through a bank of 10
// IIR filters. The characteristics of the IIR filter are fixed.

const static double firCoefficients[FIR_FILTER_TAP_COUNT] = { //TODO not sure what the FIR_FILTER_TAP_COUNT is?
0.00037419571351545599, 0.00056107025450771015, 0.00070485560843889779, 0.00078345260017241168, 0.00076531807459718798, 0.00061483250425668876, 0.00030299127501839701, -0.0001786628793685856,
-0.00080436317045205557, -0.0015049058142676262, -0.0021668542659151547, -0.0026428264244158983, -0.0027733700303716291, -0.0024182708495079442, -0.0014925028487866251, 1.7025606386693358e-18, 0.001942474896481529,
0.004098522623990168, 0.0061273985480923762, 0.0076229831789790771, 0.0081737286693190966, 0.0074364876821648926, 0.0052134545283215499, 0.0015192526199921787, -0.0033749454983488881, -0.0089312331769856451,
-0.01437539362163673, -0.018768706784490437, -0.021115275608450529, -0.020492696615090733, -0.016188999774824797, -0.0078262131985495486, 0.0045487451768411163, 0.020421750466476832, 0.038827547144203035,
0.058426090129624006, 0.077632371517867949, 0.094784922486338019, 0.10833203760139169, 0.11701152340675655, 0.12, 0.11701152340675655, 0.10833203760139169, 0.094784922486338019, 0.077632371517867949,
0.058426090129624006, 0.038827547144203035, 0.020421750466476832, 0.0045487451768411163, -0.0078262131985495486, -0.016188999774824797, -0.020492696615090733, -0.021115275608450529, -0.018768706784490437,
-0.01437539362163673, -0.0089312331769856451, -0.0033749454983488881, 0.0015192526199921787, 0.0052134545283215499, 0.0074364876821648926, 0.0081737286693190966, 0.0076229831789790771, 0.0061273985480923762,
0.004098522623990168, 0.001942474896481529, 1.7025606386693358e-18, -0.0014925028487866251, -0.0024182708495079442, -0.0027733700303716291, -0.0026428264244158983, -0.0021668542659151547, -0.0015049058142676262,
-0.00080436317045205557, -0.0001786628793685856, 0.00030299127501839701, 0.00061483250425668876, 0.00076531807459718798, 0.00078345260017241168, 0.00070485560843889779, 0.00056107025450771015, 0.00037419571351545599};

const static double iirACoefficientConstants[FILTER_FREQUENCY_COUNT][IIR_A_COEFFICIENT_COUNT] = {
{	-5.96377270701641,	19.1253393330783,	-40.3414745407443,	61.5374668753691,	-70.0197179514726,	60.2988142352393,	-38.7337928625666,	17.9935332795812,	-5.49790612248682,	0.903328285338005},
{	-4.63779471190714,	13.5022157494616,	-26.1559524052697,	38.5896683307382,	-43.0389903032525,	37.8129275995370,	-25.1135980881137,	12.7031827018880,	-4.27550833911433,	0.903328285337998},
{	-3.05913179157509,	8.64174896096375,	-14.2787902538088,	21.3022682833043,	-22.1938539720792,	20.8734997911054,	-13.7097645206094,	8.13035535779316,	-2.82016438799005,	0.903328285337999},
{	-1.40717491859968,	5.69041414706975,	-5.73747182736763,	11.9580283628689,	-8.54352805983546,	11.7173455838360,	-5.50882908769987,	5.35367872860777,	-1.29725192096556,	0.903328285338001},
{	0.820109061177603,	5.16737565792686,	3.25803509092209,	10.3929037639192,	4.81017764086691,	10.1837245070925,	3.12820007121268,	4.86159333655720,	0.756045350831449,	0.903328285338001},
{	2.70808698561545, 7.83190712179958,	12.2016079909808,	18.6515004436817,	18.7581575680046,	18.2760880959991,	11.7153613030190,	7.36843946212540,	2.49654182845121,	0.903328285338012},
{	4.94798352500759,	14.6916070031776,	29.0824147721011,	43.1798391088693,	48.4407916446889,	42.3107039623943,	27.9234342477064,	13.8221865104710,	4.56146641606544,	0.903328285338000},
{	6.17018933522799,	20.1272258768103,	42.9741933980717,	65.9580453212535,	75.2304376678666,	64.6304113557399,	41.2615910792441,	18.9361287919505,	5.68819829151803,	0.903328285337998},
{	7.40929128700724,	26.8579444602901,	61.5787878112023,	98.2582558398873,	113.594601536963,	96.2804521430262,	59.1247420257764,	25.2685275765242,	6.83050644807432,	0.903328285338002},
{	8.57430557763477,	34.3065847531179,	84.0352904110371,	139.285108440568,	163.051154181616,	136.481472218958,	80.6862886232999,	32.2763619038722,	7.90451438162449,	0.903328285337999}
};

const static double iirBCoefficientConstants[FILTER_FREQUENCY_COUNT][IIR_B_COEFFICIENT_COUNT] = {
{9.09286611481768e-10,	0,	-4.54643305740884e-09,	0,	9.09286611481768e-09,	0,	-9.09286611481768e-09,	0,	4.54643305740884e-09,	0,	-9.09286611481768e-10},
{9.09286611482031e-10,	0,	-4.54643305741016e-09,	0,	9.09286611482031e-09,	0,	-9.09286611482031e-09,	0,	4.54643305741016e-09,	0,	-9.09286611482031e-10},
{9.09286611481969e-10,	0,	-4.54643305740984e-09,	0,	9.09286611481969e-09,	0,	-9.09286611481969e-09,	0,	4.54643305740984e-09,	0,	-9.09286611481969e-10},
{9.09286611482034e-10,	0,	-4.54643305741017e-09,	0,	9.09286611482034e-09,	0,	-9.09286611482034e-09,	0,	4.54643305741017e-09,	0,	-9.09286611482034e-10},
{9.09286611482030e-10,	0,	-4.54643305741015e-09,	0,	9.09286611482030e-09,	0,	-9.09286611482030e-09,	0,	4.54643305741015e-09,	0,	-9.09286611482030e-10},
{9.09286611481643e-10,	0,	-4.54643305740822e-09,	0,	9.09286611481643e-09,	0,	-9.09286611481643e-09,	0,	4.54643305740822e-09,	0,	-9.09286611481643e-10},
{9.09286611481937e-10,	0,	-4.54643305740968e-09,	0,	9.09286611481937e-09,	0,	-9.09286611481937e-09,	0,	4.54643305740968e-09,	0,	-9.09286611481937e-10},
{9.09286611481921e-10,	0,	-4.54643305740961e-09,	0,	9.09286611481921e-09,	0,	-9.09286611481921e-09,	0,	4.54643305740961e-09,	0,	-9.09286611481921e-10},
{9.09286611481817e-10,	0,	-4.54643305740909e-09,	0,	9.09286611481817e-09,	0,	-9.09286611481817e-09,	0,	4.54643305740909e-09,	0,	-9.09286611481817e-10},
{9.09286611481893e-10,	0,	-4.54643305740946e-09,	0,	9.09286611481893e-09,	0,	-9.09286611481893e-09,	0,	4.54643305740946e-09,	0,	-9.09286611481893e-10}
};

/******************************************************************************
***** Main Filter Functions
******************************************************************************/
// initilizing ZQueue
void initXQueue();

// initilizing ZQueue
void initYQueue();

// initilizing ZQueue
void initZQueues();

// initilizing output Queue
void initOutputQueues();

// Must call this prior to using any filter functions.
void filter_init(){
  // Init queues and fill them with 0s.
  initXQueue();  // Call queue_init() on xQueue and fill it with zeros.
  initYQueue();  // Call queue_init() on yQueue and fill it with zeros.
  initZQueues(); // Call queue_init() on all of the zQueues and fill each z queue with zeros.
  initOutputQueues();  // Call queue_init() on all of the outputQueues and fill each outputQueue with zeros.
}

// Use this to copy an input into the input queue of the FIR-filter (xQueue).
void filter_addNewInput(double x){
  queue_overwritePush(filter_getXQueue(), x);
}

// Invokes the FIR-filter. Input is contents of xQueue.
// Output is returned and is also pushed on to yQueue.
double filter_firFilter(){
  double y = 0.0;
  for(uint32_t i = 0; i < FIR_A_COEFFICIENT_COUNT; i++){
    y += queue_readElementAt(filter_getXQueue(), FIR_A_COEFFICIENT_COUNT-1-i)*firCoefficients[i];
  }
  queue_overwritePush(filter_getYQueue(), y);
  return y;
}

// Use this to invoke a single iir filter. Input comes from yQueue.
// Output is returned and is also pushed onto zQueue[filterNumber].
double filter_iirFilter(uint16_t filterNumber){
  double z_a = 0.0;
  double z_b = 0.0;
  double z = 0.0;

  for(uint32_t k = 0; k < IIR_B_COEFFICIENT_COUNT; k++){
    z_b += (iirBCoefficientConstants[filterNumber][k]*queue_readElementAt(filter_getYQueue(), IIR_B_COEFFICIENT_COUNT-1-k));
  }
  for(uint32_t k = 0; k < IIR_A_COEFFICIENT_COUNT; k++){
    z_a += (iirACoefficientConstants[filterNumber][k]*queue_readElementAt(filter_getZQueue(filterNumber), IIR_A_COEFFICIENT_COUNT-1-k));
  }
  z = z_b - z_a;
  queue_overwritePush(filter_getZQueue(filterNumber), z);
  queue_overwritePush(filter_getIirOutputQueue(filterNumber), z);
  return z;
}

// Use this to compute the power for values contained in an outputQueue.
// If force == true, then recompute power by using all values in the
// outputQueue. This option is necessary so that you can correctly compute power
// values the first time. After that, you can incrementally compute power values
// by:
// 1. Keeping track of the power computed in a previous run, call this
// prev-power.
// 2. Keeping track of the oldest outputQueue value used in a previous run, call
// this oldest-value.
// 3. Get the newest value from the power queue, call this newest-value.
// 4. Compute new power as: prev-power - (oldest-value * oldest-value) +
// (newest-value * newest-value). Note that this function will probably need an
// array to keep track of these values for each of the 10 output queues.
double filter_computePower(uint16_t filterNumber, bool forceComputeFromScratch,bool debugPrint){
  if(forceComputeFromScratch){
    double filterSum = 0;
    //queue_t que = OutputQueue(filterNumber);
    for(uint16_t i = 0; i < OUTPUT_QUEUE_SIZE; i++){
      filterSum += (queue_readElementAt(&OutputQueue[filterNumber], i))*(queue_readElementAt(&OutputQueue[filterNumber], i));
    }
    currentPowerValue[filterNumber] = filterSum;
  }
  else{
    double newestValue = queue_readElementAt(&OutputQueue[filterNumber],OUTPUT_QUEUE_SIZE-1);
    currentPowerValue[filterNumber] = currentPowerValue[filterNumber] - (oldestValue[filterNumber])*(oldestValue[filterNumber]) + (newestValue)*(newestValue);
  }
    oldestValue[filterNumber] = queue_readElementAt(&OutputQueue[filterNumber],0);
    return currentPowerValue[filterNumber];
}

// Returns the last-computed output power value for the IIR filter
// [filterNumber].
double filter_getCurrentPowerValue(uint16_t filterNumber){
  return currentPowerValue[filterNumber];
}

// Sets a current power value for a specific filter number.
// Useful in testing the detector.
void filter_setCurrentPowerValue(uint16_t filterNumber, double value){
  currentPowerValue[filterNumber] = value;
}

// Get a copy of the current power values.
// This function copies the already computed values into a previously-declared
// array so that they can be accessed from outside the filter software by the
// detector. Remember that when you pass an array into a C function, changes to
// the array within that function are reflected in the returned array.
void filter_getCurrentPowerValues(double powerValues[]){
  for(int i = 0; i < FILTER_FREQUENCY_COUNT; i++){
    powerValues[i] = currentPowerValue[i];
  }
}

// Using the previously-computed power values that are currently stored in
// currentPowerValue[] array, copy these values into the normalizedArray[]
// argument and then normalize them by dividing all of the values in
// normalizedArray by the maximum power value contained in currentPowerValue[].
// The pointer argument indexOfMaxValue is used to return the index of the
// maximum value. If the maximum power is zero, make sure to not divide by zero
// and that *indexOfMaxValue is initialized to a sane value (like zero).
void filter_getNormalizedPowerValues(double normalizedArray[],uint16_t *indexOfMaxValue){
  double largestValue = 0;
  for(uint16_t i = 0; i < FILTER_FREQUENCY_COUNT; i++){
    if(currentPowerValue[i] >= largestValue){
      largestValue = currentPowerValue[i];
      *indexOfMaxValue = i;
    }
  }
  for(int i = 0; i < FILTER_FREQUENCY_COUNT; i++){
    normalizedArray[i] = currentPowerValue[i]/largestValue;
  }

}

/******************************************************************************
***** Verification-Assisting Functions
***** External test functions access the internal data structures of filter.c
***** via these functions. They are not used by the main filter functions.
******************************************************************************/

// Returns the array of FIR coefficients.
const double *filter_getFirCoefficientArray(){
  return firCoefficients;
}

// Returns the number of FIR coefficients.
uint32_t filter_getFirCoefficientCount(){
  return FIR_A_COEFFICIENT_COUNT;
}

// Returns the array of coefficients for a particular filter number.
const double *filter_getIirACoefficientArray(uint16_t filterNumber){
  return iirACoefficientConstants[filterNumber];
}

// Returns the array of coefficients for a particular filter number.
const double *filter_getIirBCoefficientArray(uint16_t filterNumber){
  return iirBCoefficientConstants[filterNumber];
}

// Returns the number of B coefficients.
uint32_t filter_getIirBCoefficientCount(){
  return IIR_B_COEFFICIENT_COUNT;
}

// Returns the number of A coefficients.
uint32_t filter_getIirACoefficientCount(){
  return IIR_A_COEFFICIENT_COUNT;
}

// Returns the size of the yQueue.
uint32_t filter_getYQueueSize(){
  return Y_QUEUE_SIZE;
}

// Returns the decimation value.
uint16_t filter_getDecimationValue(){
  return FILTER_FIR_DECIMATION_FACTOR;
}

// initilizing XQueue
void initXQueue() {
    queue_init(filter_getXQueue(), X_QUEUE_SIZE, "xQueue");
    for (uint32_t j = 0; j < X_QUEUE_SIZE; j++)
     queue_overwritePush(filter_getXQueue(), QUEUE_INIT_VALUE);
}

// initilizing YQueue
void initYQueue() {
    queue_init(filter_getYQueue(), Y_QUEUE_SIZE, "yQueue");
    for (uint32_t j = 0; j < Y_QUEUE_SIZE; j++)
     queue_overwritePush(filter_getYQueue(), QUEUE_INIT_VALUE);
}

// initilizing ZQueue
void initZQueues() {
  for (uint32_t i = 0; i < FILTER_FREQUENCY_COUNT; i++) {
    queue_init(&(zQueue[i]), Z_QUEUE_SIZE, "zQueue");
    for (uint32_t j = 0; j < Z_QUEUE_SIZE; j++)
     queue_overwritePush(&(zQueue[i]), QUEUE_INIT_VALUE);
  }
}

// initilizing OutputQueue
void initOutputQueues() {
    for (uint32_t i = 0; i < FILTER_FREQUENCY_COUNT; i++) {
    queue_init(&(OutputQueue[i]), OUTPUT_QUEUE_SIZE, "OutputQueue");
    for (uint32_t j = 0; j < OUTPUT_QUEUE_SIZE; j++)
     queue_overwritePush(filter_getIirOutputQueue(i), QUEUE_INIT_VALUE);
  }
}

// Returns the address of xQueue.
queue_t *filter_getXQueue(){
  return (&xQueue);
}

// Returns the address of yQueue.
queue_t *filter_getYQueue(){
  return (&yQueue);
}

// Returns the address of zQueue for a specific filter number.
queue_t *filter_getZQueue(uint16_t filterNumber){
  return &(zQueue[filterNumber]);
}

// Returns the address of the IIR output-queue for a specific filter-number.
queue_t *filter_getIirOutputQueue(uint16_t filterNumber){
  return &(OutputQueue[filterNumber]);
}