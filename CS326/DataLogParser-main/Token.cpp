#include "Token.h"
#include <iostream>
using namespace std;
Token::Token(TokenType type, string description, int line) {
    // TODO: initialize all member variables
    this->type = type;
    this->description = description;
    this->line = line;
}
void Token::toString(){
    TokenType type = this->type;
    string description = this->description;
    int line = this->line;
    cout << "(" << enumToString(type) << "," << "\"" << description << "\"" << "," << line << ")" << endl;
}

string Token::enumToString(TokenType type) {
    switch(type){
        case TokenType::COMMA: return "COMMA";
        case TokenType::PERIOD: return "PERIOD";
        case TokenType::Q_MARK: return "Q_MARK";
        case TokenType::LEFT_PAREN: return "LEFT_PAREN";
        case TokenType::RIGHT_PAREN: return "RIGHT_PAREN";
        case TokenType::COLON: return "COLON";
        case TokenType::COLON_DASH: return "COLON_DASH";
        case TokenType::MULTIPLY: return "MULTIPLY";
        case TokenType::ADD: return "ADD";
        case TokenType::SCHEMES: return "SCHEMES";
        case TokenType::FACTS: return "FACTS";
        case TokenType::RULES: return "RULES";
        case TokenType::QUERIES: return "QUERIES";
        case TokenType::ID: return "ID";
        case TokenType::STRING: return "STRING";
        case TokenType::COMMENT: return "COMMENT";
        case TokenType::UNDEFINED: return "UNDEFINED";
        case TokenType::EOF_TOKEN: return "EOF";
    }
}
