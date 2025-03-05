#include "FSA_StringAutomaton.h"
using namespace std;
void StringAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == '\'') {
        Accept();
        // S1();
    }
    else {
        Serr();
    }
}
// TODO
/*
void StringAutomaton::S1() {
    if (EndOfFile()){
        Serr();
    }
    else if() {
        Accept();
        S1();
    }
    else {
        Serr();
    }
}
 */