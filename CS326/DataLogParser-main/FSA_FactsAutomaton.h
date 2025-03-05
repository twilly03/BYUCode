#ifndef FACTSAUTOMATON_H
#define FACTSAUTOMATON_H

#include "Automaton.h"

class FactsAutomaton : public Automaton
{
private:
    void S1();
    void S2();
    void S3();
    void S4();
public:
    FactsAutomaton() : Automaton(TokenType::FACTS) {}  // Call the base constructor
    void S0();
};

#endif // FACTSAUTOMATON_H