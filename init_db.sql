DROP TABLE players;
DROP TABLE accounts_info;
DROP TABLE inventories;
DROP TABLE quests;
DROP TABLE quests_rewards;
DROP TABLE quests_done;
DROP TABLE monster;
DROP TABLE quests_monsters;
DROP TABLE items;
DROP TABLE offers;
DROP TABLE offer_info;

CREATE TABLE players
(
    player_id serial primary key,
    name varchar,
    level INT,
    xp INT,
    hp INT,
    attack INT,
    money INT,
    current_quest_id INT,
    weapon_id INT,
    armor_id INT,
    helmet_id INT,
    gloves_id INT
);

CREATE TABLE accounts_info
(
    account_id serial primary key,
    phone_number varchar,
    password varchar,
    player_id INT
);


CREATE TABLE inventories
(
    player_id INT,
    item_id INT,
    item_number INT
);

CREATE TABLE quests
(
    quest_id INT primary key,
    name varchar,
    description varchar,
    xp INT
);

CREATE TABLE quests_rewards
(
    quest_id INT,
    reward_item_id INT,
    reward_item_num INT
);

-- квесты, которые пользователи прошли
CREATE TABLE quests_done
(
    player_id INT,
    quest_id INT
);


CREATE TABLE monster
(
    monster_id INT primary key,
    name varchar,
    hp INT,
    damage INT,
    description varchar,
    reward INT
);

CREATE TABLE quests_monsters
(
    quest_id INT,
    monster_id INT
);

CREATE TABLE items
(
    item_id INT,
    name varchar,
    type varchar,
    buff_hp INT,
    buff_damage INT
);

CREATE TABLE offers
(
    offer_id INT primary key,
    player_1_id INT,
    player_2_id INT
);

CREATE TABLE offer_info
(
    offer_id INT,
    item_to_id INT,
    item_to_num INT,
    item_from_id INT,
    item_from_num INT
);