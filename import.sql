create table print_queries (
       id          integer      primary key autoincrement,
       team_name   text         default '774',
       language    text         default 'text',
       source      text         default '',
       comment     text         default '',
       created_at  TIMESTAMP    default (DATETIME('now','localtime')),
       printed_at  integer      default null,
       printed_flg integer      default 0
);

