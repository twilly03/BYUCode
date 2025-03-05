#ifndef QMARKAUTOMATON_H
#define QMARKAUTOMATON_H

#include "Automaton.h"

class QMarkAutomaton : public Automaton
{
public:
    QMarkAutomaton() : Automaton(TokenType::Q_MARK) {}  // Call the base constructor
    void S0();
};

#endif // QMarkAUTOMATON_H