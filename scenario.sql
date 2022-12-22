-- Подготовительные работы
-- create_item_info(name varchar, type varchar, hp_buff int, dmg_buff int)
SELECT create_item_info('Coin', 'GOLD', 0, 0);
SELECT create_item_info('Stick', 'SWORD', 0, 1);
SELECT create_item_info('Trousers', 'LEGGINGS', 10, 0);
SELECT create_item_info('Steel sword', 'SWORD', 0, 10);
SELECT create_item_info('Dragon chestplate', 'CHESTPLATE', 100, 5);
-- create_monster(name varchar, health int, damage int, description varchar)
SELECT create_monster('Rat', 1, 1, 'Just a rat');
SELECT create_monster('Goblin', 30, 3, 'Evil humanoid monster');
SELECT create_monster('Dragon', 100, 30, 'Reptilian legendary creature');
SELECT create_monster('GOD', 10000000, 10000000, 'GOD');
-- create_quest_info(name varchar, description varchar, xp_reward int)
-- create_quest_monsters(quest_id int, monster_id int, monster_count int)
-- create_quest_rewards(quest_id int, reward_item_id int, reward_item_count int)
-- Квест один
SELECT create_quest_info('First quest', 'Kill some rats in basement', 100);
SELECT create_quest_monsters(1, 1, 10);
SELECT create_quest_rewards(1, 1, 10);
SELECT create_quest_rewards(1, 2, 1);
SELECT create_quest_rewards(1, 3, 2);
-- Квест два
SELECT create_quest_info('Goblins in cave', 'Kill a family of goblins in nearby cave and a rat', 1000);
SELECT create_quest_monsters(2, 2, 3);
SELECT create_quest_monsters(2, 1, 1);
SELECT create_quest_rewards(2, 1, 500);
SELECT create_quest_rewards(2, 4, 1);
-- Квест три
SELECT create_quest_info('Village in danger', 'Kill a dragon', 100000);
SELECT create_quest_monsters(3, 3, 1);
SELECT create_quest_rewards(3, 5, 1);
SELECT create_quest_rewards(3, 1, 1000000);
-- Квест четыре
SELECT create_quest_info('Killing God', 'How dare you', 0);
SELECT create_quest_monsters(4, 4, 1);

-- Путь героя
-- create_account(name varchar, phone_number varchar, password_hash varchar)
SELECT create_account('Dude', '89871234567', '1234');
-- get_quest(_quest_id int, _player_id int)
-- complete_quest(_player_id int, _quest_id int)
-- equip(_item_id int, _player_id int)
-- Квест один
SELECT get_quest(1, 1);
SELECT complete_quest(1, 1);
SELECT equip(2, 1);
SELECT equip(3, 1);
-- Квест два
SELECT get_quest(2, 1);
SELECT complete_quest(2, 1);
SELECT unequip(1, 'SWORD');
SELECT equip(4, 1);
-- Квест три
SELECT get_quest(3, 1);
SELECT complete_quest(3, 1);
SELECT equip(5, 1);
-- Квест четыре
SELECT get_quest(4, 1);
SELECT complete_quest(4, 1);
-- Ты умер