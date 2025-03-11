#ifndef RULESAUTOMATON_H
#define RULESAUTOMATON_H

#include "Automaton.h"

class RulesAutomaton : public Automaton
{
private:
    void S1();
    void S2();
    void S3();
    void S4();
public:
    RulesAutomaton() : Automaton(TokenType::RULES) {}  // Call the base constructor
    void S0();
};

#endif // RULESAUTOMATON_H