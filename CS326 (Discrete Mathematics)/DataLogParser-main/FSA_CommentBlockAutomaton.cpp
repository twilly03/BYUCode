#include "FSA_CommentBlockAutomaton.h"
using namespace std;
void CommentBlockAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    if (CurrentLetter() == '#') {
       if (CurrentLetter() == '|') {
           Accept();
           S1();
       }
       else {
           Serr();
       }
    }
    else {
        Serr();
    }
}

void CommentBlockAutomaton::S1() {
    if(CurrentLetter()!= '\n') {
        Accept();
        S1();
    }
    else if (EndOfFile() || CurrentLetter() == '\n'){
        Accept();
        return;
    }

}