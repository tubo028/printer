create table print_queries (
       id          integer      primary key autoincrement,
       team_name   text,
       language    text,
       source      text,
       created_at  TIMESTAMP    default (DATETIME('now','localtime')),
       printed_at  integer      default null,
       printed_flg integer      default 0
);

