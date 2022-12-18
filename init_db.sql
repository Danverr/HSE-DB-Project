DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS accounts_info;
DROP TABLE IF EXISTS quests;
DROP TABLE IF EXISTS quests_rewards;
DROP TABLE IF EXISTS quests_done;
DROP TABLE IF EXISTS monster;
DROP TABLE IF EXISTS quests_monsters;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS items_info;
DROP TABLE IF EXISTS offers;

CREATE TABLE players
(
    player_id serial primary key,
    name varchar,
    level int,
    xp int,
    health int,
    attack int,
    current_quest_id int
);

CREATE TABLE accounts_info
(
    account_id serial primary key,
    phone_number varchar,
    password varchar,
    player_id int
);

CREATE TABLE quests
(
    quest_id int primary key,
    name varchar,
    description varchar,
    xp int
);

CREATE TABLE quests_rewards
(
    quest_id int,
    reward_item_id int,
    reward_item_num int
);

-- квесты, которые пользователи прошли
CREATE TABLE quests_done
(
    player_id int,
    quest_id int
);

CREATE TABLE monster
(
    monster_id int primary key,
    name varchar,
    hp int,
    damage int,
    description varchar,
    reward int
);

CREATE TABLE quests_monsters
(
    quest_id int,
    monster_id int
);

CREATE TABLE items
(
    item_id serial,
    owner_id int,
    count int,
    equipped bool
);

CREATE TABLE items_info
(
    item_id serial,
    name varchar,
    type varchar,
    could_be_equipped bool,
    buff_hp int,
    buff_damage int
);

CREATE TABLE offers
(
    offer_id serial primary key,
    accepted bool,
    seller_player_id int,
    seller_item_id int,
    seller_item_count int,
    buyer_player_id int,
    buyer_item_id int,
    buyer_item_count int
);