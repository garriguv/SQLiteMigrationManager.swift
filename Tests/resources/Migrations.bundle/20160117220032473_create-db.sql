create table contacts (
  id integer primary key,
  name text not null collate nocase,
  phone text not null default 'UNKNOWN',
  unique (name, phone) );
