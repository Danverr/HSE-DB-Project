-- Создание героя для пользователя
CREATE OR REPLACE FUNCTION
    create_player(name varchar)
RETURNS int
AS $$
DECLARE
    new_player_id int;
BEGIN
    INSERT INTO players VALUES (
        DEFAULT, -- player_id
        name,    -- name
        1,       -- level
        0,       -- xp
        100,     -- health
        10       -- damage
    ) RETURNING player_id INTO new_player_id;
    RETURN new_player_id;
END 
$$ LANGUAGE plpgsql;

-- Создание учетной записи пользователя
CREATE OR REPLACE FUNCTION
    create_account(name varchar, phone_number varchar, password varchar) RETURNS record
AS $$
DECLARE
    new_player_id int;
    new_account_id int;
BEGIN
    SELECT create_player(name) INTO new_player_id;
    INSERT INTO accounts_info VALUES (
        DEFAULT,       -- account_id
        new_player_id, -- player_id
        phone_number,  -- phone_number
        password       -- password
    ) RETURNING account_id INTO new_account_id;
    RETURN (new_account_id, new_player_id);
END
$$ LANGUAGE plpgsql;

-- Добавление предметов (предмет имеет тип и может иметь бонусы к здоровью и/или атаке)
CREATE OR REPLACE FUNCTION
    create_item_info(
        name varchar,
        type varchar,
        could_be_equipped bool,
        hp_buff int,
        dmg_buff int
    )
    RETURNS int
AS $$
DECLARE
    new_item_id int;
BEGIN
    INSERT INTO items_info VALUES (
        DEFAULT,           -- item_id
        name,              -- name
        type,              -- type
        could_be_equipped, -- could_be_equipped
        hp_buff,           -- hp_buff
        dmg_buff           -- dmg_buff
    ) RETURNING item_id INTO new_item_id;
    RETURN new_item_id;
END
$$ LANGUAGE plpgsql;

-- Удаление предметов (предмет имеет тип и может иметь бонусы к здоровью и/или атаке)
CREATE OR REPLACE FUNCTION
    delete_item_info(id int) RETURNS void
AS $$
BEGIN
    DELETE FROM items_info WHERE item_id = id;
END
$$ LANGUAGE plpgsql;

-- Выдача предметов внутри игры
CREATE OR REPLACE FUNCTION
    give_or_update_item(_item_id int, _player_id int, _count int) RETURNS void
AS $$
BEGIN
    INSERT INTO items VALUES (
        _item_id,   -- item_id
        _player_id, -- player_id
        _count,     -- count
        false       -- equipped
    )
    ON CONFLICT(item_id, player_id) DO UPDATE
    SET count = _count;
END
$$ LANGUAGE plpgsql;

-- Удалить предмет из инвентаря
CREATE OR REPLACE FUNCTION
    delete_item(_item_id int, _player_id int) RETURNS void
AS $$
BEGIN
    DELETE FROM items WHERE item_id = _item_id AND player_id = _player_id;
END
$$ LANGUAGE plpgsql;

-- Одеть/снять предмет на персонажа
CREATE OR REPLACE FUNCTION
    set_equipped(_player_id int, _item_id int, _equipped bool) RETURNS bool
AS $$
DECLARE
    could_be_equipped_res bool;
    updated_rows int;
BEGIN
    SELECT could_be_equipped INTO could_be_equipped_res FROM items_info WHERE item_id = _item_id;
    IF (could_be_equipped_res = false)
        THEN RETURN false;
    END IF;

    UPDATE items SET equipped = _equipped
    WHERE
        player_id = _player_id
        AND item_id = _item_id
        AND count > 0
    RETURNING * INTO updated_rows;
    RETURN updated_rows > 0;
END
$$ LANGUAGE plpgsql;

-- Заявка на обмен предметов с другим игроком (если предмет - золото, то это покупка/продажа)
CREATE OR REPLACE FUNCTION
    create_offer(
        seller_player_id int,
        seller_item_id int,
        seller_item_count int,
        buyer_player_id int,
        buyer_item_id int,
        buyer_item_count int
    )
    RETURNS int
AS $$
DECLARE
    new_offer_id int;
BEGIN
    INSERT INTO offers VALUES (
        DEFAULT,           -- offer_id
        false,             -- accepted
        seller_player_id,  -- seller_player_id
        seller_item_id,    -- seller_item_id
        seller_item_count, -- seller_item_count
        buyer_player_id,   -- buyer_player_id
        buyer_item_id,     -- buyer_item_id
        buyer_item_count   -- buyer_item_count
    ) RETURNING offer_id INTO new_offer_id;
    RETURN new_offer_id;
END
$$ LANGUAGE plpgsql;

-- Принятие заявки на обмен предметов от игрока
CREATE OR REPLACE FUNCTION
    accept_offer(id int) RETURNS void
AS $$
BEGIN
    UPDATE offers SET (accepted) = true WHERE offer_id = id;
END
$$ LANGUAGE plpgsql;

-- Добавление очков опыта к уровню персонажа
CREATE OR REPLACE FUNCTION
    add_xp(_player_id int, xp_delta int) RETURNS record
AS $$
DECLARE
    result record;
BEGIN
    UPDATE players SET (xp, level) = (xp + xp_delta, floor(log(2, 2 + xp + xp_delta)))
    WHERE player_id = _player_id
    RETURNING (xp, level) INTO result;
    RETURN result;
END
$$ LANGUAGE plpgsql;

-- Вычисление здоровья и атаки персонажа (исходя из очков опыта, и силы/защиты снаряжения)
CREATE OR REPLACE FUNCTION
    get_player_hp_and_dmg(_player_id int) RETURNS record
AS $$
DECLARE
    base_params record;
    total_buff record;
    _level int;
BEGIN
    SELECT
        COALESCE(SUM(info.hp_buff), 0) AS hp_buff,
        COALESCE(SUM(info.dmg_buff), 0) AS dmg_buff
    INTO total_buff
    FROM items item, items_info info
    WHERE
        item.item_id = info.item_id
        AND item.equipped = true
        AND item.player_id = _player_id;

    SELECT health, damage
    INTO base_params
    FROM players
    WHERE player_id = _player_id;

    SELECT level
    INTO _level
    FROM players
    WHERE player_id = _player_id;
    
    RETURN (
        FLOOR(1 + _level / 100) * (base_params.health + total_buff.hp_buff) AS hp,
        FLOOR(1 + _level / 100) * (base_params.damage + total_buff.dmg_buff) AS dmg
    );
END
$$ LANGUAGE plpgsql;

-- Добавление монстра
CREATE OR REPLACE FUNCTION
    create_monster(
        name varchar,
        hp int,
        damage int,
        description varchar,
        reward int
    )
    RETURNS int
AS $$
DECLARE
    new_monster_id int;
BEGIN
    INSERT INTO monster VALUES (
        DEFAULT,     -- monster_id
        name,        -- name
        hp,          -- hp
        damage,      -- damage
        description, -- description
        reward       -- reward
    ) RETURNING monster_id INTO new_monster_id;
    RETURN new_monster_id;
END
$$ LANGUAGE plpgsql;

-- Удаление монстра
CREATE OR REPLACE FUNCTION
    delete_monster(id int) RETURNS void
AS $$
BEGIN
    DELETE FROM monster WHERE monster_id = id;
END
$$ LANGUAGE plpgsql;

-- Добавление квеста
CREATE OR REPLACE FUNCTION
    create_quests_info(
        name varchar,
        description varchar,
        xp int
    )
    RETURNS int
AS $$
DECLARE
    new_quest_id int;
BEGIN
    INSERT INTO quests_info VALUES (
        DEFAULT,     -- quest_id
        name,        -- name
        description, -- description
        xp           -- xp
    ) RETURNING quest_id INTO new_quest_id;
    RETURN new_quest_id;
END
$$ LANGUAGE plpgsql;

-- Удаление квеста
CREATE OR REPLACE FUNCTION
    delete_quest(id int) RETURNS void
AS $$
BEGIN
    DELETE FROM quests_info WHERE quest_id = id;
END
$$ LANGUAGE plpgsql;

-- Выдача заданий пользователю
CREATE FUNCTION
    create_quests(_player_id int)
    RETURNS TABLE(name varchar, description varchar, xp int)
AS $$
    SELECT name, description, xp
    FROM quests_info
    WHERE quest_id NOT IN (
        SELECT quests.quest_id 
        FROM quests 
        WHERE quests.player_id  = _player_id
    )
$$ LANGUAGE plpgsql;

-- Получение награды за выполненный квест
CREATE OR REPLACE FUNCTION
    give_reward(_player_id int, _quest_id int) RETURNS void
AS $$
DECLARE
    xp_delta int;
BEGIN
    SELECT xp INTO xp_delta FROM quests_info WHERE quests_id = _quest_id;

    add_xp(xp_delta);

    SELECT give_or_update_item(reward_item_id, _player_id, reward_item_count)
    FROM quests_reward, items
    WHERE
        quests_reward.quest_id = _quest_id;
END
$$ LANGUAGE plpgsql;


-- Расчет суммарных показателей атаки и здоровья группы монстров
CREATE OR REPLACE FUNCTION
    get_monster_group_hp_and_dmg(_quest_id int) RETURNS record
AS $$
DECLARE
    result record;
BEGIN
    SELECT
        COALESCE(SUM(monster.hp), 0) AS hp,
        COALESCE(SUM(monster.damage), 0) AS dmg
    INTO result
    FROM monster, quests_monsters
    WHERE
        quests_monsters.quest_id = _quest_id
        AND monster.monster_id = quests_monsters.monster_id

    RETURN result;
END
$$ LANGUAGE plpgsql;

-- Смерть героя
CREATE OR REPLACE FUNCTION
    kill_player(_player_id int, _quest_id int) RETURNS void
AS $$
    _gold_id int;
    _gold_count int;
BEGIN
    SELECT id INTO _gold_id FROM items_info WHERE name = 'gold';

    SELECT count INTO _gold_count FROM items WHERE item_id = _gold_id AND player_id = _player_id;

    give_or_update_item(_gold_id, _player_id, FLOOR(0.9 * _gold_count));
END
$$ LANGUAGE plpgsql;

-- Завершение задания
CREATE OR REPLACE FUNCTION
    complete_quest(_player_id int, _quests_id int) RETURNS bool
AS $$
DECLARE
    player_hp_and_dmg record;
    monster_group_hp_and_dmg record;
BEGIN
    player_hp_and_dmg = get_player_hp_and_dmg(_player_id);
    monster_group_hp_and_dmg = get_monster_group_hp_and_dmg(_quest_id);

    IF (CEILING(player_hp_and_dmg.hp / monster_group_hp_and_dmg.dmg)
        >= CEILING(monster_group_hp_and_dmg.hp / player_hp_and_dmg.dmg))
    THEN give_reward(player_id, quest_id);
    ELSE kill_player(player_id);
    END IF;

    UPDATE quests SET status = 'Done'
    WHERE player_id = _player_id AND quest_id = _quest_id
END
$$ LANGUAGE plpgsql;

-- Просмотр топ 10 лучших игроков по количеству опыта

CREATE OR REPLACE FUNCTION
    get_best_players()
    RETURNS TABLE(name varchar, xp int)
AS $$
    SELECT name, xp
    FROM players
    ORDER BY xp DESC
    LIMIT 10;
$$ LANGUAGE plpgsql;