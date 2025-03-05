#include "FSA_CommentAutomaton.h"
using namespace std;
void CommentAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    if (CurrentLetter() == '#') {
        Accept();
        S1();
    }
    else {
        Serr();
    }
}

void CommentAutomaton::S1() {
    if(CurrentLetter()!= '\n') {
        Accept();
        S1();
    }
    else if (EndOfFile() || CurrentLetter() == '\n'){
        Accept();
        return;
    }

}