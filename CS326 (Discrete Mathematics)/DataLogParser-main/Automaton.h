#ifndef AUTOMATON_H
#define AUTOMATON_H
#include "Token.h"
using namespace std;

class Automaton
{
protected:
    int numCharsRead = 0;
    int newLines = 0;
    int index = 0;
    string input;
    TokenType type;

public:
    // Default constructor -- since we have a constructor that takes a parameter,
    //   the compiler will autogenerate a default constructor if not explicit.
    Automaton() : Automaton(TokenType::UNDEFINED) {}

    Automaton(TokenType type) { this->type = type; }

    // Start the automaton and return the number of characters read
    //   read == 0 indicates the input was rejected
    //   read  > 0 indicates the input was accepted
    int Start(const std::string& input) {
        this->input = input;
        newLines = 0;
        numCharsRead = 0;
        index = 0;
        this->S0();
        return numCharsRead;
    }

    // Every subclass must define this method
    virtual void S0() = 0;

    void Serr() {
        // Indicate the input was rejected
        numCharsRead = 0;
    }

    virtual Token* CreateToken(std::string input, int lineNumber) { return new Token(type, input, lineNumber); }

    int NewLinesRead() const { return newLines; }

    char CurrentLetter() const { return input[index]; }

    bool EndOfFile() {
        return (numCharsRead >= input.size());
    }
    void Accept(){
        numCharsRead++;
        index++;
    }
};

#endif // AUTOMATON_H

