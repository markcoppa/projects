drop table if exists buyers;

CREATE TABLE buyers
(
id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
first_name varchar(255) DEFAULT null,
last_name varchar(255) DEFAULT null,
street varchar(255) DEFAULT null,
city varchar(255) DEFAULT null,
state varchar(10) DEFAULT null,
zip varchar(30) DEFAULT null,
phone varchar(32) DEFAULT null,
email varchar(255) DEFAULT null,
paddle varchar(255) DEFAULT null,
paid_auction boolean DEFAULT false
);

drop table if exists items;

CREATE TABLE items (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  donor varchar(255) DEFAULT NULL, 
  website varchar(255) DEFAULT NULL, 
  description text DEFAULT NULL, 
  value float DEFAULT NULL, 
  auction_type varchar(255) DEFAULT NULL, 
  buyers_id integer DEFAULT NULL, 
  final_price float DEFAULT NULL,
  paid boolean default false
);

drop table if exists dutch_items;

CREATE TABLE dutch_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  description text default NULL,
  amount float DEFAULT 0
);

drop table if exists dutch_buyers;

CREATE TABLE dutch_buyers (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  buyer_id INTEGER DEFAULT NULL,
  dutch_items_id INTEGER DEFAULT NULL,
  quantity integer DEFAULT 0
);
