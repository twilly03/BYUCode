#ifndef IDAUTOMATON_H
#define IDAUTOMATON_H

#include "Automaton.h"

class StringAutomaton : public Automaton
{
private:
    // void S1();

public:
    StringAutomaton() : Automaton(TokenType::STRING) {}  // Call the base constructor
    void S0();
};

#endif // STRINGAUTOMATON_H