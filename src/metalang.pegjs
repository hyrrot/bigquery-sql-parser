Grammar =
    WHITESPACE d:Definition|.., DOUBLE_NEWLINE| {
      return d.map((x) => x.peggyjscode).join("\n\n");
      //return d;
    }

Definition =
    ident:IDENT COLON WHITESPACE ( "/*" (!"*/" .)* "*/"  WHITESPACE )? SINGLE_NEWLINE
    WHITESPACE def:Expression WHITESPACE {
        return {
            "name" : ident.name,
            "definition": def,
            "peggyjscode": ident.name + " =\n    " + def.map((x) => x.peggyjscode).join(" _ ")
         };
    }
    
Expression =
    ExpressionNode|.., SINGLE_NEWLINE? WHITESPACE SINGLE_NEWLINE? WHITESPACE|

ExpressionNode =
    IDENT
    / LITERAL
    / DOT
    / OptionalClause
    / LogicalORClause
    / ELLIPSIS
    / QUANTIFIER

OptionalClause =
    SQUARE_BRACKET_L WHITESPACE
    e:Expression WHITESPACE
    SQUARE_BRACKET_R {
      return {
        "type" : "optional_clause",
        "value": e,
        "peggyjscode": "( " + e.map((x) => x.peggyjscode).join(" _ ") + " )?"
      }
    }

LogicalORClause =
    CURLY_BRACE_L WHITESPACE
    e:Expression|.., WHITESPACE VERTICAL_BAR WHITESPACE | WHITESPACE
    CURLY_BRACE_R {
      return {
        "type": "logical_or_clause",
        "value": e,
        "peggyjscode": "( " + e.map((x) => x.map((y) => y.peggyjscode).join(" _ ")).join(" / ") + " )"
      }
    }

IDENT = $[a-z_]+ {
  return {"type": "identifier", "name": text(), "peggyjscode": text() };
}
LITERAL = $[A-Z,\(\)=]+ {
  return {"type": "literal", "value": text(),
  	"peggyjscode": text() == "," ? "COMMA" :
    							text() == "(" ? "LPAREN" :
                                text() == ")" ? "RPAREN" :
                                text() == "=" ? "EQUAL" :
                                "K_" + text()};
}
DOT = $"\." !"\." {
  return {"type": "literal", "value": text(),
  	"peggyjscode": "DOT" };
}

QUANTIFIER = "*" {
  return {"type": "quantifier", "value": text(),
  	"peggyjscode":  text() };
}

COLON = $":"
ELLIPSIS = "..." {
  return {"type": "ellipsis", "peggyjscode": "/* TODO ELLIPSIS */ " }
}
SQUARE_BRACKET_L = "["
SQUARE_BRACKET_R = "]"
CURLY_BRACE_L = "{"
CURLY_BRACE_R = "}"
VERTICAL_BAR = "|"

NEWLINE = "\n"
SINGLE_NEWLINE = NEWLINE !NEWLINE
DOUBLE_NEWLINE = "\n\n"
WHITESPACE "whitespace"
  = [ \t]*
