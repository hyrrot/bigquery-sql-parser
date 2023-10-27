query_statement: /* SQL Syntax https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#sql_syntax */
    query_expr

query_expr: /* SQL Syntax https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#sql_syntax */
  [ WITH [ RECURSIVE ] { non_recursive_cte | recursive_cte }[, ...] ]
  { select | ( query_expr ) | set_operation }
  [ ORDER BY expression [{ ASC | DESC }] [, ...] ]
  [ LIMIT count [ OFFSET skip_rows ] ]

select: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#select_list */
  SELECT
    [ WITH differential_privacy_clause ]
    [ { ALL | DISTINCT } ]
    [ AS { STRUCT | VALUE } ]
    select_list
  [ FROM from_clause[, ...] ]
  [ WHERE bool_expression ]
  [ GROUP BY group_by_specification ]
  [ HAVING bool_expression ]
  [ QUALIFY bool_expression ]
  [ WINDOW window_clause ]

select_list: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#select_list */
  { select_all | select_expression } [, ...]

select_all: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#select_list */
  [ expression. ]*
  [ EXCEPT ( column_name [, ...] ) ]
  [ REPLACE ( expression [ AS ] column_name [, ...] ) ]

select_expression: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#select_list */
  expression [ [ AS ] alias ]

from_clause: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#from_clause */
  from_item
  [ { pivot_operator | unpivot_operator } ]
  [ tablesample_operator ]

from_item: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#from_clause */
  { table_name [ as_alias ] [ FOR SYSTEM_TIME AS OF timestamp_expression ]  | { join_operation | ( join_operation ) }    | ( query_expr ) [ as_alias ]    | field_path    | unnest_operator    | cte_name [ as_alias ] }

as_alias: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#from_clause */
  [ AS ] alias

unnest_operator: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#unnest_operator */
  { UNNEST ( array_expression ) | UNNEST ( array_path ) | array_path }
  [ as_alias ]
  [ WITH OFFSET [ as_alias ] ]

pivot_operator: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#pivot_operator */
  PIVOT (
    aggregate_function_call [as_alias][, ...]
    FOR input_column
    IN ( pivot_column [as_alias][, ...] )
  ) [AS alias]

join_operation: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#join_types */
  { cross_join_operation | condition_join_operation }

cross_join_operation: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#join_types */
  from_item cross_join_operator from_item

condition_join_operation: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#join_types */
  from_item condition_join_operator from_item join_condition

cross_join_operator: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#join_types */
  { CROSS JOIN | , }

condition_join_operator: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#join_types */
  {    [INNER] JOIN    | FULL [OUTER] JOIN    | LEFT [OUTER] JOIN    | RIGHT [OUTER] JOIN }

join_condition: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#join_types */
  { on_clause | using_clause }

on_clause: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#join_types */
  ON bool_expression

using_clause: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#join_types */
  USING ( column_list )

group_by_specification: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#group_by_clause */
  {    groupable_items    | grouping_sets_specification    | rollup_specification    | cube_specification    | LPAREN_RPAREN }

groupable_item: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#group_by_grouping_item */
  {    value    | value_alias    | column_ordinal  }

grouping_list: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#group_by_grouping_sets */
  {    rollup_specification    | cube_specification    | groupable_item    | groupable_item_set  }[, ...]

groupable_item_set: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#group_by_grouping_sets */
  ( [ groupable_item[, ...] ] )

rouping_list: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#group_by_rollup */
  { groupable_item | groupable_item_set }[, ...]

named_window_expression: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#window_clause */
  named_window AS { named_window | ( [ window_specification ] ) }

set_operation: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#set_operators */
  query_expr set_operator query_expr

set_operator: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#set_operators */
  {    UNION { ALL | DISTINCT } |    INTERSECT DISTINCT |    EXCEPT DISTINCT }

privacy_parameters: /* https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax#dp_clause */
  epsilon = expression,
  delta = expression,
  [ max_groups_contributed = expression ],
  privacy_unit_column = column_name