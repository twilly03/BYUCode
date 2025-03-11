#ifndef SCHEMESAUTOMATON_H
#define SCHEMESAUTOMATON_H

#include "Automaton.h"

class SchemesAutomaton : public Automaton
{
private:
    void S1();
    void S2();
    void S3();
    void S4();
    void S5();
    void S6();
public:
    SchemesAutomaton() : Automaton(TokenType::SCHEMES) {}  // Call the base constructor
    void S0();
};

#endif // SCHEMESAUTOMATON_H