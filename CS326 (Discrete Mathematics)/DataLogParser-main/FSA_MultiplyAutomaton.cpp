#include "FSA_MultiplyAutomaton.h"
using namespace std;
void MultiplyAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == '*') {
        Accept();
    }
    else {
        Serr();
    }
}