#ifndef TOKEN_H
#define TOKEN_H
#include <string>
using namespace std;

enum class TokenType {
    COMMA,
    PERIOD,
    Q_MARK,
    LEFT_PAREN,
    RIGHT_PAREN,
    COLON,
    COLON_DASH,
    MULTIPLY,
    ADD,
    SCHEMES,
    FACTS,
    RULES,
    QUERIES,
    ID,
    STRING,
    COMMENT,
    UNDEFINED,
    EOF_TOKEN,
};

class Token
{
private:
    TokenType type;
    string description;
    int line;
    // TODO: add member variables for information needed by Token

public:
    Token(TokenType type, std::string description, int line);
    void toString();
    string enumToString(TokenType type);
    // TODO: add other needed methods
};

#endif // TOKEN_H

