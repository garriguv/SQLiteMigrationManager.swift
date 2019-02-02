alter table contacts
  add column occupation text not null default 'UNKNOWN' collate nocase;
