#ifndef IDAUTOMATON_H
#define IDAUTOMATON_H

#include "Automaton.h"

class IDAutomaton : public Automaton
{
private:
    void S1();

public:
    IDAutomaton() : Automaton(TokenType::ID) {}  // Call the base constructor
    void S0();


};

#endif // IDAUTOMATON_H