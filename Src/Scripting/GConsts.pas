unit GConsts;

interface

uses
  GTypes;

const
  GE_ExpectedChar  = $00000000;
  GE_IllegalChar   = $00000001;
  GE_UnexpectedEnd = $00000002;

  GE_FuncNotFound  = $10000000;
  GE_Script        = $10000001;
  GE_VarNotFound   = $10000002;
  GE_IOError       = $10000003;

  GE_CTStr: array[0..2] of string = (
    'Missing character',
    'Illegal character',
    'Unexpected end'
  );

  GE_RTStr: array[0..3] of string = (
    'Function not found',
    'Script error',
    'Variable not found',
    'Input/Output error'
  );

  GC_StructureId: array[TGStructureType] of string = ( //lowercase
    'function',
    'if',
    'for',
    'while',
    'repeat',
    'foreach',
    'return',
    ''
  );
  GC_ElseId = 'else';
  GC_ElseIfId = 'elseif';

  GC_FunctionId: array[TGFunctionType] of string = ( //lowercase
    'global',
    'local',
    ''
  );

  GC_OperatorChars: set of Char = ['+', '-', '*', '/', '!', '&', '|', '=', '<', '>', '~', '%', '^'];
  GC_OperatorId: array[TGOperatorType] of string = (
    '+', // $I/F/S/A = I/F/S/A + I/F/S/X;
    '-', // $I/F = I/F - I/F;
    '*', // $I/F = I/F * I/F;
    '/', // $I/F = I/F / I/F;
    '%', // $I/F = I/F % I/F;
    '^', // $I/F = I/F ^ I/F;
    '~', // $S = S ~ R;
    '~/', // $A = S ~ R;
    '!', // $B/I = !B/I;
    '&', // $B/I = B/I & B/I;
    '|', // $B/I = B/I | B/I;
    '!!', // $B/I = $B/I!!; $B/I = !!$B/I;
    '&&', // $B/I = B/I && B/I;
    '||', // $B/I = B/I || B/I;
    '^^', // $B/I = B/I ^^ B/I;
    '&=', // $B/I &= B/I;
    '|=', // $B/I |= B/I;
    '^^=', // $B/I ^^= B/I;
    '==', // $B = X == X;
    '!=', // $B = X != X;
    '<>', // $B = X <> X;
    '<', // $B = X < X;
    '>', // $B = X > X;
    '<=', // $B = X <= X;
    '>=', // $B = X >= X;
    '===', // $B = X === X;
    '!==', // $B = X !== X;
    '~~', // $B = S ~~ R;
    '!~', // $B = S !~ R;
    '=', // $X = X;
    '=~', // $S =~ R;
    '++', // $I = $I++; $I = ++$I;
    '--', // $I = $I--; $I = --$I;
    '+=', // $I/F/S/A += I/F/S/X;
    '=+', // $S =+ S;
    '-=', // $I/F += I/F;
    '*=', // $I/F *= I/F;
    '/=', // $I/F /= I/F;
    '%=', // $I/F %= I/F;
    '^=', // $I/F ^= I/F;
    '<<', // $I = $I << I;
    '>>', // $I = $I >> I;
    '<<=', // $I <<= I;
    '>>=', // $I >>= I;
    ''
  );

  GC_OperatorPriority: array[TGOperatorType] of Byte = ( //lowercase
    5, // +
    5, // -
    6, // *
    6, // /
    6, // %
    7, // ^
    4, // ~
    4, // ~/
    4, // !
    2, // &
    2, // |
    4, // !!
    2, // &&
    2, // ||
    2, // ^^
    1, // &=
    1, // |=
    1, // ^^=
    3, // ==
    3, // !=
    3, // <>
    3, // <
    3, // >
    3, // <=
    3, // >=
    3, // ===
    3, // !==
    3, // ~~
    3, // !~
    1, // =
    1, // =~
    8, // ++
    8, // --
    1, // +=
    1, // =+
    1, // -=
    1, // *=
    1, // /=
    1, // %=
    1, // ^=
    2, // <<
    2, // >>
    2, // <<=
    2, // >>=
    0
  );

  GC_BooleanStr: array[False..True] of string = ( //lowercase
    'false',
    'true'
  );

  GC_Tab = #9;
  GC_NewLine = #10;
  GC_CarReturn = #13;
  GC_FormFeed = #$c;
  GC_Alarm = #$7;
  GC_Escape = #$1b;
  GC_ConstantQuote = '\';
  GC_QuoteTab = 't';
  GC_QuoteNewLine = 'n';
  GC_QuoteCarReturn = 'r';
  GC_QuoteFormFeed = 'f';
  GC_QuoteAlarm = 'a';
  GC_QuoteEscape = 'e';
  GC_QuoteHexadecimal = 'x';
  GC_QuoteHexOpen = '{';
  GC_QuoteHexClose = '}';
  GC_QuoteHexChars: set of Char = ['a'..'z', 'A'..'Z', '0'..'9', '{', '}'];
  GC_StructChars: set of Char = ['a'..'z', 'A'..'Z', '_'];
  GC_FuncFirstChars: set of Char = ['a'..'z', 'A'..'Z', '_'];
  GC_FuncChars: set of Char = ['a'..'z', 'A'..'Z', '_', '0'..'9'];
  GC_WhiteSpaceChars: set of Char = [' ', #13, #10, #9];
  GC_SrcEnd = #0;
  GC_Separator = ';';
  GC_FuncSrcOpen = '{';
  GC_FuncSrcClose = '}';
  GC_ParamListOpen = '(';
  GC_ParamListClose = ')';
  GC_ParamListDelimiter = ',';
  GC_VarFirstChar = '$';
  GC_VarChars: set of Char = ['a'..'z', 'A'..'Z', '_', '0'..'9'];
  GC_VarAssign = '=';
  GC_VarKeyDelimiter = '.';
  GC_KeyOpen = '(';
  GC_KeyClose = ')';
  GC_IndexOpen = '[';
  GC_IndexClose = ']';
  GC_CountPrefix = '#';
  GC_CurrentVar = '_';
  GC_StringQuotes: set of Char = ['"', #39];
  GC_SimpleQuote = #39;
  GC_DecimalPoint = '.';
  GC_Numbers: set of Char = ['0'..'9'];
  GC_Comment = '//';

implementation

end.
