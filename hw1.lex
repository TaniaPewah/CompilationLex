%{

/* Declarations section */
#include <stdio.h>
void showToken(char *);
void toLower(char *);
void handleString();
void handleComment();
void unclose_comment();
int power(int, int);
int getDecValue(int);
void fromHexToDec();
void fromBinToDec();
void fromOctToDec();

char ascii_buffer[6];
char string_buffer[1024];

%}

%option yylineno
%option noyywrap
digit   		([0-9])
letter  		([a-zA-Z])

whitespace		([\t\r\n ])
bin_digit       ([01])
oct_digit       ([0-7])
hex_digit       ([a-f]|[A-F]|[0-9])
hex_num         (0x({hex_digit})+)
sign 		    ([\-|\+])
/* TODO: limit the range 0x20 to 0x7E, 0x09, 0x0A, 0x0D */
ascii          (\\u\{({hex_digit}{hex_digit})\})
escape_char     ([\n|\r|\t|\\|{ascii}|\"])
printable_char  ([\x20-\x7E])
printable_char_first [\x20-\x21]
printable_char_rest [\x23-\x7E]




%%
Int|UInt|Double|Float|Bool|String|Character     showToken("TYPE");

var                                             showToken("VAR");
let                                             showToken("LET");
func                                            showToken("FUNC");
import                                          showToken("IMPORT");
nil                                             showToken("NIL");
while                                           showToken("WHILE");
if                                              showToken("IF");
else                                            showToken("ELSE");
return                                          showToken("RETURN");

;                                               showToken("SC");
,                                               showToken("COMMA");
\(                                               showToken("LPAREN");
\)                                               showToken("RPAREN");
\{                                               showToken("LBRACE");
\}                                               showToken("RBRACE");
\[                                               showToken("LBRACKET");
\]                                               showToken("RBRACKET");
=                                               showToken("ASSIGN");
((\/\*)(([^\*])|(\*([^\/])))*(\*\/))|(\/\/.*)                handleComment();
((\/\*)(([^\*])|(\*([^\/])))*)                  unclose_comment();
==|!=|<|>|<=|>=                                 showToken("RELOP");
&&|\|\|                                         showToken("LOGOP");
\+|\-|\*|\/|%                                   showToken("BINOP");
true                                            showToken("TRUE");
false                                           showToken("FALSE");
->                                              showToken("ARROW");
:                                               showToken("COLON");
0b{bin_digit}+                                  fromBinToDec();
0o{oct_digit}+                                  fromOctToDec();
((0)|[1-9]{digit}*)                             showToken("DEC_INT");
{hex_num}                                       fromHexToDec();
_({letter}|{digit})+|({letter}|{digit})+        showToken("ID");
(({digit}+\.{digit}*)|({digit}*\.{digit}+))((e|E){sign}((0)|[1-9]{digit}*)){0,1}           showToken("DEC_REAL");
{hex_num}[p|P]{sign}((0)|[1-9]{digit}*)         showToken("HEX_FP");


\"((\\\")|[\x20-\x21]|[\x23-\x7E]|[\x09]|[\x0A]|[\x0D])*\"  handleString();

{ascii}                                         showToken("ASCII");


{whitespace}				                    ;
.		                                        printf("Lex doesn't know what that is!\n");

%%

void showToken(char * name)
{
    printf("%d %s %s\n", yylineno, name, yytext);
}

void handleString(){

    int new_lengh = 0;
    int tmp;
    char* buffer_ptr;

    printf("%d STRING ", yylineno);

    if (*(yytext++) == '\"'){ // Double quote string

        while (*yytext ) { // While not end of string


            if ( *yytext == '\\'){

                switch(*(yytext+1)){
                case 'n':
                    printf(" escapechar \n");
                    break;
                case 't':
                    printf(" escapechar \t");
                    break;
                case 'r':
                    printf(" escapechar \r");
                    break;
                case '"':
                    printf(" escapechar \'");
                    break;
                case 'u':
                    printf(" escapechar U");
                    break;
                default :
                    break;
                }
            }


            *(yytext++);
            printf(" %c ", *(yytext));
        }


        //yytext = buffer_ptr; // Set new yytext after change
        //yyleng = new_lengh; // Update new length of yytext
        //yytext[new_lengh] = '\0';
    }

    //printf("%d STRING %s\n", yylineno, yytext);
}

void toLower(char* s) {
	char* ptr = s;
	while (*ptr) {
		if( *ptr >= 'A' && *ptr <= 'Z') {
			*ptr = (*ptr - 'A') + 'a';
		}
		ptr++;
	}
}

void handleComment() {
    char* buffer_ptr = yytext;
    int comment_len = yyleng;
    int num_lines = 1;

    for(int i = 1; i < comment_len - 1; i++) {
        if (buffer_ptr[i] == '/' && buffer_ptr[i + 1] == '*') {
            printf("Warning nested comment\n");
            exit(0);
        }
    }

    for(int i = 0; i < comment_len; i++) {
        if (buffer_ptr[i] == '\n') {
            num_lines++;
        }
    }
    printf("%d COMMENT %d\n", yylineno, num_lines);
}

void unclose_comment(){
    printf("Error unclosed comment\n");
    exit(0);
}


int power(int base, int exp){
    int value = 1;
    for(int i = exp; i > 0; i--){
        value *= base;
    }
    return value;
}


int getDecValue(int base){
    char* new_num;
    int dec_value = 0, exp = 0, current_lsb = 0;

    *(yytext++);
    *(yytext++);
    
    new_num = yytext;

    // printf("new num is: %s\nIt's length is %d\n", new_num, yyleng - 2);
    toLower(new_num);

    for(int i = yyleng - 3; i >= 0; i--){
        if(new_num[i] >= 'a'){
            current_lsb =  (int)(new_num[i] - 'a' + 10);
        }
        else{
            current_lsb =  (int)(new_num[i] - '0');
        }

        dec_value += power(base, exp) *  current_lsb;
        // printf("Current dec_value = %d\n power is = %d\ncurrent lsb = %d\n", dec_value, power(base, exp), current_lsb);
        exp++;
    }
    return dec_value;
}


void fromHexToDec(){
    int dec_value = getDecValue(16);
    printf("%d HEX_INT %d\n", yylineno, dec_value);
}


void fromOctToDec(){
    int dec_value = getDecValue(8);
    printf("%d OCT_INT %d\n", yylineno, dec_value);
}


void fromBinToDec(){
    int dec_value = getDecValue(2);
    printf("%d BIN_INT %d\n", yylineno, dec_value);
}


