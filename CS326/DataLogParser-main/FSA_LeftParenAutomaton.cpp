#include "FSA_LeftParenAutomaton.h"
using namespace std;
void LeftParenAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == '(') {
        Accept();
    }
    else {
        Serr();
    }
}