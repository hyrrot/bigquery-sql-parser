// https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#sql_syntax
query_statement =
    query_expr

// Level 1: CTEs and set operations
query_expr =
    // [ WITH [ RECURSIVE ] { non_recursive_cte | recursive_cte }[, ...] ]
    ( K_WITH _ K_RECURSIVE? _ ( non_recursive_cte / recursive_cte ) |.., _ COMMA _| )? _

    // * See 1. in limitations.txt
    query_expr_02 |.., _ set_operator _ query_expr_02|


// Level 2: SELECT, ORDER, LIMIT
query_expr_02 =
    (LPAREN _ query_expr _ RPAREN / select)

    _

    // [ ORDER BY expression [{ ASC | DESC }] [, ...] ]
    ( K_ORDER _ K_BY _ expression _ ( K_ASC / K_DESC  )? )* _
    
    // [ LIMIT count [ OFFSET skip_rows ] ]
    ( K_LIMIT _ count _ ( K_OFFSET _ skip_rows )? )?

// TODO fix count and skip_rows
count = expression
skip_rows = expression


select =
    // SELECT
    K_SELECT _
    
    // [ WITH differential_privacy_clause ]
    ( K_WITH _ differential_privacy_clause )? _
    
    // [ { ALL | DISTINCT } ]
    ( K_ALL / K_DISTINCT )? _
    
    // [ AS { STRUCT | VALUE } ]
    ( K_AS _ ( K_STRUCT / K_VALUE ) )? _
    
    // select_list
    select_list _
    
    // [ FROM from_clause[, ...] ]
    ( K_FROM _ from_clause|.., _ COMMA _| )? _
    
    // [ WHERE bool_expression ]
    ( K_WHERE _ bool_expression )? _
    
    // [ GROUP BY group_by_specification ]
    ( K_GROUP _ K_BY _ group_by_specification )? _
    
    // [ HAVING bool_expression ]
    ( K_HAVING _ bool_expression )? _
    
    // [ QUALIFY bool_expression ]
    ( K_QUALIFY _ bool_expression )? _
    
    // [ WINDOW window_clause ]
    ( K_WINDOW _ window_clause )?


// https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#select_list
select_list =
    // { select_all | select_expression } [, ...]
    ( select_all / select_expression )|.., _ COMMA _|

select_all =
    // [ expression. ]*
    ( expression _ DOT )? _ "*" _
    
    // [ EXCEPT ( column_name [, ...] ) ]
    ( K_EXCEPT _ LPAREN _ column_name|.., _ COMMA _| RPAREN )? _
    
    // [ REPLACE ( expression [ AS ] column_name [, ...] ) ]
    ( K_REPLACE _ LPAREN _ (expression _ ( K_AS )? _ column_name)|.., _ COMMA _| _ RPAREN )?

select_expression =
    // expression [ [ AS ] alias ]
    expression _ ( ( K_AS )? _ alias )?

from_clause =
    // from_item
    // * Handle joins here (to avoid left recursion)
    from_item _ 
    // [ { pivot_operator | unpivot_operator } ]
    ( ( pivot_operator / unpivot_operator ) )? _
    // [ tablesample_operator ]
    ( tablesample_operator )?

from_item =
    from_item_without_join /
    from_item_with_join

from_item_with_join = 
    from_item_with_join_with_paren _ (cross_join_operator / condition_join_operator) _ from_item_with_join_with_paren

from_item_with_join_with_paren =
    LPAREN _ from_item _ RPAREN /
    from_item_without_join




from_item_without_join =
    // table_name [ as_alias ] [ FOR SYSTEM_TIME AS OF timestamp_expression ]
    table_name _ ( as_alias )? _ ( K_FOR _ K_SYSTEM_TIME _ K_AS _ K_OF _ timestamp_expression )?
    // ( query_expr ) [ as_alias ]
    / LPAREN _ query_expr _ RPAREN _ ( as_alias )? 
    // field_path
    / field_path
    // unnest_operator
    / unnest_operator
    // cte_name [ as_alias ]
    / cte_name _ ( as_alias )?


// TODO: fix this
field_path = [a-zA-Z\.]+

// TODO: fix this
cte_name = [a-zA-Z]+

as_alias =
    ( K_AS )? _ alias

unnest_operator =
    ( K_UNNEST _ LPAREN _ array_expression _ RPAREN 
    / K_UNNEST _ LPAREN _ array_path _ RPAREN 
    / array_path ) 
    _ ( as_alias )? 
    _ ( K_WITH _ K_OFFSET _ ( as_alias )? )?

// TODO: fix this
array_path = "a.ary"

// TODO: fix this
array_expression = "[1,2,3]"

pivot_operator =
    K_PIVOT _ LPAREN _ aggregate_function_call _ ( as_alias )? _ ( COMMA _ /* TODO ELLIPSIS */  )? _ K_FOR _ input_column _ K_IN _ LPAREN _ pivot_column _ ( as_alias )? _ ( COMMA _ /* TODO ELLIPSIS */  )? _ RPAREN _ RPAREN _ ( K_AS _ alias )?

// TODO: fix this
aggregate_function_call =
    "SUM(sales)"

// TODO: fix this
input_column =
    "col"

// TODO: fix this
pivot_column = "'Q1'"


// https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#unpivot_operator
unpivot_operator = 
  K_UNPIVOT _ ( ( K_INCLUDE _ K_NULLS ) / ( K_EXCLUDE _ K_NULLS ) )? LPAREN _
    ( single_column_unpivot / multi_column_unpivot ) _
  RPAREN _ (unpivot_alias)?

single_column_unpivot =
  values_column _
  K_FOR _ name_column _
  K_IN _  LPAREN _ columns_to_unpivot _ RPAREN

// TODO: fix this
values_column = "col"

// TODO: fix this
name_column = "col"

multi_column_unpivot =
  values_column_set _
  K_FOR _ name_column _
  K_IN _ LPAREN _ column_sets_to_unpivot _ RPAREN

values_column_set = 
  LPAREN values_column|.., _ COMMA _| RPAREN

join_operation =
    ( cross_join_operation / condition_join_operation )

columns_to_unpivot =
  unpivot_column _ (row_value_alias|.., _ COMMA _|)?

// TODO: fix this
unpivot_column =
  "col"

column_sets_to_unpivot =
  LPAREN _ unpivot_column _ (row_value_alias|.., _ COMMA _|)? _ RPAREN

unpivot_alias =
  K_AS? _ alias

row_value_alias =
  K_AS? _ alias

// https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#tablesample_operator
tablesample_operator =
  K_TABLESAMPLE _ K_SYSTEM _ LPAREN _ percent _ K_PERCENT _ RPAREN

// TODO: fix this
// "Replace percent with the percentage of the dataset that you want to include in the results. The value must be between 0 and 100. The value can be a literal value or a query parameter. It cannot be a variable."
percent = [0-9]+

cross_join_operation =
    from_item _ cross_join_operator _ from_item

condition_join_operation =
    from_item _ condition_join_operator _ from_item _ join_condition

cross_join_operator =
    ( K_CROSS _ K_JOIN / COMMA )

condition_join_operator =
    ( ( K_INNER )? _ K_JOIN / K_FULL _ ( K_OUTER )? _ K_JOIN / K_LEFT _ ( K_OUTER )? _ K_JOIN / K_RIGHT _ ( K_OUTER )? _ K_JOIN )

join_condition =
    ( on_clause / using_clause )

on_clause =
    K_ON _ bool_expression

using_clause =
    K_USING _ LPAREN _ column_list _ RPAREN

// TODO: implement this
column_list =
    column_name|.., _ COMMA _|

group_by_specification =
    ( groupable_items / grouping_sets_specification / rollup_specification / cube_specification / LPAREN_RPAREN )

// TODO: fix this
grouping_sets_specification = "(a,(b,c),d)"

// TODO: fix this
rollup_specification = "ROLLUP(a,b,c)"

// TODO: fix this
cube_specification = "(a,b,c)"

groupable_items =
    // ( value / value_alias / column_ordinal )|.., _ COMMA _|
    // TODO fix this
    expression|.., _ COMMA _|


// grouping_list =
//     ( rollup_specification / cube_specification / groupable_item / groupable_item_set )|.., _ COMMA _|

// groupable_item_set =
//     LPAREN _ ( groupable_item|.., _ COMMA _| )? _ RPAREN

// grouping_list =
//     ( groupable_item / groupable_item_set ) |.., _ COMMA _|

// WINDOW named_window_expression [, ...]
// https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#window_clause
window_clause =
    named_window_expression |.., _ COMMA _|

named_window_expression =
    named_window _ K_AS _ ( named_window / LPAREN _ ( window_specification )? _ RPAREN )

// TODO: fix this
named_window = "window_name"

// window_specification:
window_specification =
//   [ named_window ]
    named_window? _
//   [ PARTITION BY partition_expression [, ...] ]
    ( K_PARTITION _ K_BY _ partition_expression|.., _ COMMA _| )? _
//   [ ORDER BY expression [ { ASC | DESC } ] [, ...] ]
    ( K_ORDER _ K_BY _ expression _ ( K_ASC / K_DESC )|.., _ COMMA _| )? _
//   [ window_frame_clause ]
    window_frame_clause?

// TODO: fix this
partition_expression = "col"

// window_frame_clause:
window_frame_clause =
//   { rows_range } { frame_start | frame_between }
    rows_range _ ( frame_start / frame_between )

// rows_range:
rows_range =
//   { ROWS | RANGE }
    ( K_ROWS / K_RANGE ) _

// frame_between:
frame_between =
//   {
//     BETWEEN  unbounded_preceding AND frame_end_a
//     | BETWEEN numeric_preceding AND frame_end_a
//     | BETWEEN current_row AND frame_end_b
//     | BETWEEN numeric_following AND frame_end_c
//   }
    K_BETWEEN _
    (unbounded_preceding _ K_AND _ frame_end_a)
    / (numeric_preceding _ K_AND _ frame_end_a)
    / (current_row _ K_AND _ frame_end_b)

// frame_start:
frame_start =
//   { unbounded_preceding | numeric_preceding | [ current_row ] }
    unbounded_preceding
    / numeric_preceding
    / current_row?

// frame_end_a:
frame_end_a =
//   { numeric_preceding | current_row | numeric_following | unbounded_following }
    numeric_preceding
    / current_row
    / numeric_following
    / unbounded_following

// frame_end_b:
frame_end_b =
//   { current_row | numeric_following | unbounded_following }
    current_row
    / numeric_following
    / unbounded_following

// frame_end_c:
frame_end_c =
//   { numeric_following | unbounded_following }
    numeric_following
    / unbounded_following

// unbounded_preceding:
unbounded_preceding =
//   UNBOUNDED PRECEDING
    K_UNBOUNDED _ K_PRECEDING

// numeric_preceding:
numeric_preceding =
//   numeric_expression PRECEDING
    numeric_expression _ K_PRECEDING

// TODO fix this
numeric_expression =
    expression

// unbounded_following:
unbounded_following =
//   UNBOUNDED FOLLOWING
    K_UNBOUNDED _ K_FOLLOWING

// numeric_following:
numeric_following =
//   numeric_expression FOLLOWING
    numeric_expression _ K_FOLLOWING

// current_row:
current_row =
//   CURRENT ROW
    K_CURRENT _ K_ROW

// set_operation =
//     query_expr_without_cte _ set_operator _ query_expr_without_cte

set_operator =
    ( K_UNION _ ( K_ALL / K_DISTINCT ) / K_INTERSECT _ K_DISTINCT / K_EXCEPT _ K_DISTINCT )

// privacy_parameters =
//     epsilon _ EQUAL _ expression _ COMMA _ delta _ EQUAL _ expression _ COMMA _ ( max_groups_contributed _ EQUAL _ expression )? _ COMMA _ privacy_unit_column _ EQUAL _ column_name

non_recursive_cte =
  cte_name _ K_AS _ LPAREN _ query_expr _ RPAREN

recursive_cte =
  cte_name _ K_AS _ LPAREN _ recursive_union_operation _ RPAREN

recursive_union_operation =
  base_term _ union_operator _ recursive_term

base_term =
  query_expr

recursive_term =
  query_expr

union_operator =
  K_UNION _ K_ALL

// https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#dp_clause
differential_privacy_clause =
  K_WITH _ K_DIFFERENTIAL_PRIVACY _ K_OPTIONS _ LPAREN _ privacy_parameters _ RPAREN

privacy_parameters =
  "epsilon" _ EQUAL _ expression _ COMMA _
  "delta" _ EQUAL _ expression _ COMMA _
  ( "max_groups_contributed" _ EQUAL _ expression _ COMMA )? _ 
  "privacy_unit_column" _ EQUAL _ column_name



// Expressions

// TODO: Add support for expressions
expression = "1"i
bool_expression = "true"i
column_name = [a-zA-Z]+
alias = [a-zA-Z]+
table_name = [a-zA-Z]+
timestamp_expression = "1"i

// Define keywords

_ "WHITESPACE" =
    [ \t\n\r]*

K_AND = 'AND'i
K_ALL = 'ALL'i
K_AS = 'AS'i
K_ASC = 'ASC'i
K_BETWEEN = 'BETWEEN'i
K_BY = 'BY'i
K_CURRENT = 'CURRENT'i
K_CROSS = 'CROSS'i
K_DESC = 'DESC'i
K_DIFFERENTIAL_PRIVACY = 'DIFFERENTIAL_PRIVACY'i
K_DISTINCT = 'DISTINCT'i
K_EXCEPT = 'EXCEPT'i
K_EXCLUDE = 'EXCLUDE'i
K_FOR = 'FOR'i
K_FOLLOWING = 'FOLLOWING'i
K_FROM = 'FROM'i
K_FULL = 'FULL'i
K_GROUP = 'GROUP'i
K_HAVING = 'HAVING'i
K_IN = 'IN'i
K_INCLUDE = 'INCLUDE'i
K_INNER = 'INNER'i
K_INTERSECT = 'INTERSECT'i
K_JOIN = 'JOIN'i
K_LEFT = 'LEFT'i
K_LIMIT = 'LIMIT'i
K_NULLS = 'NULLS'i
K_OF = 'OF'i
K_OFFSET = 'OFFSET'i
K_ON = 'ON'i
K_OPTIONS = 'OPTIONS'i
K_ORDER = 'ORDER'i
K_OUTER = 'OUTER'i
K_PARTITION = 'PARTITION'i
K_PERCENT = 'PERCENT'i
K_PRECEDING = 'PRECEDING'i
K_PIVOT = 'PIVOT'i
K_QUALIFY = 'QUALIFY'i
K_RANGE = 'RANGE'i
K_RECURSIVE = 'RECURSIVE'i
K_REPLACE = 'REPLACE'i
K_ROW = 'ROW'i
K_ROWS = "ROWS"i
K_RIGHT = 'RIGHT'i
K_SELECT = 'SELECT'i
K_STRUCT = 'STRUCT'i
K_SYSTEM = 'SYSTEM'i
K_SYSTEM_TIME = "SYSTEM_TIME"i
K_TABLESAMPLE = 'TABLESAMPLE'i
K_UNBOUNDED = 'UNBOUNDED'i
K_UNION = 'UNION'i
K_UNNEST = 'UNNEST'i
K_UNPIVOT = 'UNPIVOT'i
K_USING = 'USING'i
K_VALUE = 'VALUE'i
K_WHERE = 'WHERE'i
K_WINDOW = 'WINDOW'i
K_WITH = 'WITH'i

LPAREN = "("i
RPAREN = ")"i
LPAREN_RPAREN = '()'i
EQUAL = "="i
COMMA = ","i
DOT = "."i