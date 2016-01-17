alter table contacts
  add column email text not null default 'UNKNOWN' collate nocase;
