unit G2Consts;

interface

uses
  G2Types;

const
  G2_EXTENSION = '.cgs';
  G2_HEADER = 'CGS2';      // Compiled GScript2
  G2_VERSIONMAJOR = 2;
  G2_VERSIONMINOR = 0;

const
  G2E_NOERROR      = 0;
  G2E_MSG = '[Script %s at %s] %s';
  G2E_ERRORPOS = 'line %d, char %d';

  // Compiler errors
  
  G2CE_INTERNAL    = $1000;
  G2CE_NOSOURCE    = $1001;
  G2CE_ILLEGALCHAR = $1002;
  G2CE_STRTBLFULL  = $1003;
  G2CE_EXPECTCHAR  = $1004;
  G2CE_EXPECTEXPR  = $1005;
  G2CE_EXPECTOPER  = $1006;
  G2CE_STRINGOPEN  = $1007;
  G2CE_MANYPARAMS  = $1008;
  G2CE_MANYITEMS   = $1009;
  G2CE_INVALIDOPER = $100A;
  G2CE_UNKNOWNOPER = $100B;
  G2CE_CONTROLSIZE = $100C;
  G2CE_CONSTCOUNT  = $100D;
  G2CE_BADCTRL     = $100E;
  G2CE_STATEMENT   = $100F;
  G2CE_EXPECTVAR   = $1010;
  G2CE_BADNAME     = $1011;

  G2CE_ERRORS: array[$1000..$1011] of string = (
    'Internal error. You should NEVER see this!',
    'No source to compile.',
    'Illegal Char: "%s".',
    'Maximun string table size (%d) exceeded.',
    '"%s" expected but "%s" found.',
    'Expression expected but "%s" found.',
    'Operator or %s expected but "%s" found.',
    'Unterminated string.',
    'Functions cannot have more than %d parameters.',
    'Typed arrays cannot have more than %d items.',
    'Invalid operation.',
    'Unknown operator: "%s".',
    'Maximum control structure size (%d) exceeded.',
    'Maximum typed constant count (%d) exceeded.',
    'Invalid control structure.',
    'Invalid statement.',
    'Variable expected but "%s" found.',
    'Identifier name "%s" is not allowed.'
  );

  // Runtime errors

  G2RE_INTERNAL    = $2000;
  G2RE_NOSOURCE    = $2001;
  G2RE_BADSRC      = $2002;
  G2RE_SRCVERSION  = $2003;
  G2RE_UNDEFFUNC   = $2004;
  G2RE_COULDNOTGET = $2005;
  G2RE_COULDNOTEXE = $2006;
  G2RE_INVALIDOPER = $2007;
  G2RE_UNDEFVAR    = $2008;
  G2RE_CANTASSIGN  = $2009;
  G2RE_INVALIDREF  = $200A;
  G2RE_ZERODIVIDER = $200B;
  G2RE_INDEX       = $200C;
  G2RE_NOCURITEM   = $200D;
  G2RE_MANYPARAMS  = $200E;
  G2RE_LOWPARAMS   = $200F;
  G2RE_UNDEFMETHOD = $2010;
  G2RE_SCRIPTERROR = $2011;
  G2RE_FNOTFOUND   = $2012;
  G2RE_BADMODULE   = $2013;
  G2RE_BADCLASS    = $2014;
  G2RE_NOREGEXPR   = $2015;
  G2RE_NOOUTPUT    = $2016;
  G2RE_NOSRCGET    = $2017;

  G2RE_ERRORS: array[$2000..$2017] of string = (
    'Internal error. You should NEVER see this!',
    'No source to execute.',
    'Invalid source.',
    'Source version (%u.%.2u) mismatch. Expecting %u.%.2u.',
    'Undefined function: "%s".',
    'Expression has no return value.',
    'Statement cannot be executed.',
    'Invalid operation.',
    'Undefined variable: "%s".',
    'Cannot assign value to target.',
    'Invalid reference.',
    'Division by zero.',
    'Undefined array index (%s).',
    'Current item does not exist.',
    'Too many parameters (Expecting at most %d).',
    'Not enough parameters (Expecting at least %d).',
    'Undefined method: "%s".',
    'Script reported error: "%s".',
    'File "%s" not found.',
    'Unknown module: "%s".',
    'Invalid classname: "%s".',
    'This program has been compiled without regular expression support.',
    'No output method assigned.',
    'No source reader method assigned.'
  );

const
  G2CMD_END        =   0;
  G2CMD_FUNCCALL   =   1;
  G2CMD_CONST      =   2;
  G2CMD_CONSTSTR   =   3;
  G2CMD_CONSTINT   =   4;
  G2CMD_CONSTFLOAT =   5;
  G2CMD_CONSTFALSE =   6;
  G2CMD_CONSTTRUE  =   7;
  G2CMD_CONSTZERO  =   8;
  G2CMD_CONSTONE   =   9;
  G2CMD_CONSTEMPTY =  10;
  G2CMD_VARIABLE   =  11;
  G2CMD_OPER       =  12;
  G2CMD_OPERRIGHT  =  13;
  G2CMD_OPERLEFT   =  14;
  G2CMD_OPERBOTH   =  15;
  G2CMD_ARRAY      =  16;
  G2CMD_INDEX      =  17;
  G2CMD_INDEXNEW   =  18;
  G2CMD_IF         =  19;  
  G2CMD_CONSTNIL   =  20;
  G2CMD_WHILE      =  21;
  G2CMD_FOR        =  22;
  G2CMD_DOWHILE    =  23;
  G2CMD_DOUNTIL    =  24;
  G2CMD_FOREACH    =  25;
  G2CMD_CURITEM    =  26;
  G2CMD_BREAK      =  27;
  G2CMD_CONTINUE   =  28;
  G2CMD_EXIT       =  29;
  G2CMD_NOP        =  30;
  G2CMD_RETURN     =  31;
  G2CMD_RETURNVAL  =  32;
  G2CMD_COREFUNC   =  33;
  G2CMD_PROPERTY   =  34;
  G2CMD_METHODCALL =  35;
  G2CMD_VARGLOBAL  =  36;
  G2CMD_VARLOCAL   =  37;
  G2CMD_CONSTINT32 =  38;
  G2CMD_CONSTFLT32 =  39;
  G2CMD_CONSTINT16 =  40;
  G2CMD_CONSTINT8  =  41;
  G2CMD_ID         =  42;
  G2CMD_FUNCTION   =  43;
  G2CMD_EVENT      =  44;
  G2CMD_CURINDEX   =  45;

const
  G2C_MaxStrTablePos = $FFFF;

  G2C_StructureId: array[TG2StructureType] of string = (
    'function',
    'if',
    'else',
    'for',
    'while',
    'do',
    'until',
    'foreach',
    'return',
    'break',
    'continue',
    'exit',
    'nop',
    'global',
    'local',
    'event',
    'i',
    ''
  );

  G2C_FunctionId: array[TG2FunctionType] of string = ( 
    'keys',
    'keycount',
    'key',
    'error',
    'load',
    'unload',
    'print',
    'echo',
    'random',
    'randseed',
    'lowercase',
    'uppercase',
    'lc',
    'uc',
    'str',
    'bool',
    'int',
    'float',
    'isset',
    'unset',
    'var',
    'create',
    'free',
    'use',
    ''
  );

  G2C_OperatorChars = ['+', '-', '*', '/', '!', '&', '|', '=', '<', '>', '~', '%', '^', '@', '#'];
  G2C_OperatorId: array[TG2OperatorType] of string = (
    '+',   // gotAdd            $I/F/S/A = I/F/S/A + I/F/S/X;
    '-',   // gotSubtract       $I/F = I/F - I/F;
    '*',   // gotMultiply       $I/F = I/F * I/F;
    '/',   // gotDivide         $I/F = I/F / I/F;
    '%',   // gotRemainder      $I/F = I/F % I/F;
    '^',   // gotPower          $I/F = I/F ^ I/F;
    '~',   // gotReplace        $S = S ~ R;
    '~/',  // gotSplit          $A = S ~ R;
    '!',   // gotNot            $B/I = !B/I;
    '&',   // gotAnd            $B/I = B/I & B/I;
    '|',   // gotOr             $B/I = B/I | B/I;
    '!!',  // gotNotSelf        $B/I = $B/I!!; $B/I = !!$B/I;
    '&&',  // gotAnd2           $B/I = B/I && B/I;
    '||',  // gotOr2            $B/I = B/I || B/I;
    '^^',  // gotXor            $B/I = B/I ^^ B/I;
    '&=',  // gotAndSelf        $B/I &= B/I;
    '|=',  // gotOrSelf         $B/I |= B/I;
    '^^=', // gotXorSelf        $B/I ^^= B/I;
    '==',  // gotEqual          $B = X == X;
    '!=',  // gotUnEqual        $B = X != X;
    '<>',  // gotUnEqual2       $B = X <> X;
    '<',   // gotSmaller        $B = X < X;
    '>',   // gotBigger         $B = X > X;
    '<=',  // gotSmallerEq      $B = X <= X;
    '>=',  // gotBiggerEq       $B = X >= X;
    '===', // gotIdentical      $B = X === X;
    '!==', // gotUnIdentical    $B = X !== X;
    '~~',  // gotMatch          $B = S ~~ R;
    '!~',  // gotNoMatch        $B = S !~ R;
    '=',   // gotAssign         $X = X;
    '=~',  // gotRepSelf        $S =~ R;
    '++',  // gotIncOne         $I = $I++; $I = ++$I;
    '--',  // gotDecOne         $I = $I--; $I = --$I;
    '+=',  // gotInc            $I/F/S/A += I/F/S/X;
    '=+',  // gotAddLeft        $S =+ S;
    '-=',  // gotDec            $I/F -= I/F;
    '*=',  // gotMulSelf        $I/F *= I/F;
    '/=',  // gotDivSelf        $I/F /= I/F;
    '%=',  // gotRemSelf        $I/F %= I/F;
    '^=',  // gotPowSelf        $I/F ^= I/F;
    '<<',  // gotShiftLeft      $I = I << I;
    '>>',  // gotShiftRight     $I = I >> I;
    '<<=', // gotShlSelf        $I <<= I;
    '>>=', // gotShrSelf        $I >>= I;
    '@',   // gotReference      $E = @$X;
    '#',   // gotCount          $I = #A
    ''
  );

  G2C_OperatorPriority: array[TG2OperatorType] of Byte = (
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
    9, // @
    9, // #
    0
  );

  G2C_BooleanStr: array[Boolean] of string = ( 
    'false',
    'true'
  );
  G2C_NilStr = 'null';
  G2C_LineComment = '//';
  
  G2C_Tab = #9;
  G2C_NewLine = #10;
  G2C_CarReturn = #13;
  G2C_FormFeed = #$c;
  G2C_Alarm = #$7;
  G2C_Escape = #$1b;
  G2C_ConstantQuote = '\';
  G2C_QuoteTab = 't';
  G2C_QuoteNewLine = 'n';
  G2C_QuoteCarReturn = 'r';
  G2C_QuoteFormFeed = 'f';
  G2C_QuoteAlarm = 'a';
  G2C_QuoteEscape = 'e';
  G2C_QuoteHexadecimal = 'x';
  G2C_QuoteHexOpen = '{';
  G2C_QuoteHexClose = '}';
  G2C_QuoteHexChars = ['a'..'z', 'A'..'Z', '0'..'9', '{', '}'];
  G2C_StructChars = ['a'..'z', 'A'..'Z', '_'];
  G2C_IDFirstChars = ['a'..'z', 'A'..'Z', '_'];
  G2C_IDChars = ['a'..'z', 'A'..'Z', '_', '0'..'9'];
  G2C_WhiteSpaceChars = [' ', #13, #10, #9];
  G2C_SrcEnd = #0;
  G2C_Separator = ';';
  G2C_SrcOpen = '{';
  G2C_SrcClose = '}';
  G2C_ParamListOpen = '(';
  G2C_ParamListClose = ')';
  G2C_ParamListDelimiter = ',';
  G2C_VarChar = '$';
  G2C_FieldDelimiter = '.';
  G2C_ArrayOpen = '[';
  G2C_ArrayClose = ']';
  G2C_ArrayDelimiter = ',';
  G2C_CurrentVar = '_';
  G2C_StringQuotes = ['"', #39];
  G2C_SimpleQuote = #39;
  G2C_DecimalPoint = '.';
  G2C_Numbers = ['0'..'9'];

implementation

end.
