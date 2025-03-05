#include "FSA_QueriesAutomaton.h"
using namespace std;
void QueriesAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'Q') {
        Accept();
        S1();
    }
    else {
        Serr();
    }
}

void QueriesAutomaton::S1() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'u') {
        Accept();
        S2();
    }
    else {
        Serr();
    }
}


void QueriesAutomaton::S2() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'e') {
        Accept();
        S3();
    }
    else {
        Serr();
    }
}

void QueriesAutomaton::S3() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'r') {
        Accept();
        S4();
    }
    else {
        Serr();
    }
}

void QueriesAutomaton::S4() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'i') {
        Accept();
        S5();
    }
    else {
        Serr();
    }
}

void QueriesAutomaton::S5() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'e') {
        Accept();
        S6();
    }
    else {
        Serr();
    }
}

void QueriesAutomaton::S6() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 's') {
        Accept();
    }
    else {
        Serr();
    }
}


