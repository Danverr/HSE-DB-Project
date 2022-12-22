DROP TABLE IF EXISTS players CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS quests_info CASCADE;
DROP TABLE IF EXISTS quests_rewards CASCADE;
DROP TABLE IF EXISTS quests CASCADE;
DROP TABLE IF EXISTS monsters CASCADE;
DROP TABLE IF EXISTS quests_monsters CASCADE;
DROP TABLE IF EXISTS items CASCADE;
DROP TABLE IF EXISTS items_info CASCADE;
DROP TABLE IF EXISTS offers CASCADE;

CREATE TABLE players
(
    player_id serial primary key,
    UNIQUE(player_id),
    name varchar,
    xp int,
    health int,
    damage int,
    sword_id int,
    helmet_id int,
    chestplate_id int,
    leggings_id int,
    boots_id int
);

CREATE TABLE accounts
(
    account_id serial primary key,
    UNIQUE(account_id),
    player_id serial REFERENCES players(player_id),
    phone_number varchar,
    password_hash varchar
);


CREATE TABLE items_info
(
    item_id serial primary key,
    UNIQUE(item_id),
    name varchar,
    type varchar, -- 'SWORD', 'HELMET', 'CHESTPLATE', 'LEGGINGS', 'BOOTS', 'GOLD'
    hp_buff int,
    dmg_buff int
);

CREATE TABLE items
(
    item_id serial REFERENCES items_info(item_id),
    player_id serial REFERENCES players(player_id),
    UNIQUE(item_id, player_id),
    count int
);

CREATE TABLE monsters
(
    monster_id serial primary key,
    UNIQUE(monster_id),
    name varchar,
    health int,
    damage int,
    description varchar
);

CREATE TABLE quests_info
(
    quest_id serial primary key,
    UNIQUE(quest_id),
    name varchar,
    description varchar,
    xp_reward int
);

CREATE TABLE quests_rewards
(
    quest_id serial REFERENCES quests_info(quest_id),
    reward_item_id serial REFERENCES items_info(item_id),
    reward_item_count int
);

CREATE TABLE quests_monsters
(
    quest_id serial REFERENCES quests_info(quest_id),
    monster_id serial REFERENCES monsters(monster_id),
    monster_count int
);

CREATE TABLE quests
(
    quest_id serial REFERENCES quests_info(quest_id),
    player_id serial REFERENCES players(player_id),
    status varchar
);

CREATE TABLE offers
(
    offer_id serial primary key,
    UNIQUE(offer_id),
    accepted bool,
    seller_player_id serial REFERENCES players(player_id),
    seller_item_id serial REFERENCES items_info(item_id),
    seller_item_count int,
    buyer_player_id serial REFERENCES players(player_id),
    buyer_item_id serial REFERENCES items_info(item_id),
    buyer_item_count int
);