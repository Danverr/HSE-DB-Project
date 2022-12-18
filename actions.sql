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
        10,      -- damage
        NULL     -- current_quest_id
    ) RETURNING player_id INTO new_player_id;
    RETURN new_player_id;
END $$ LANGUAGE plpgsql;

-- Создание учетной записи пользователя
CREATE OR REPLACE FUNCTION
    create_account(name varchar, phone_number varchar, password varchar) RETURNS int
AS $$
DECLARE
    new_player_id int;
    new_account_id int;
BEGIN
    SELECT create_player(name) INTO new_player_id;
    INSERT INTO accounts_info VALUES (
        DEFAULT,      -- account_id
        phone_number, -- phone_number
        password,     -- password
        new_player_id -- player_id
    ) RETURNING account_id INTO new_account_id;
    RETURN new_account_id;
END
$$ LANGUAGE plpgsql;

-- Добавление предметов (предмет имеет тип и может иметь бонусы к здоровью и/или атаке)
CREATE OR REPLACE FUNCTION
    create_item_info(name varchar, type varchar, could_be_equipped bool, hp_buff int, dmg_buff int) RETURNS int
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
    give_or_update_item(item_id int, player_id int, new_count int) RETURNS void
AS $$
BEGIN
    INSERT INTO items VALUES (
        item_id,   -- item_id
        player_id,  -- player_id
        new_count, -- count
        false      -- equipped
    )
    ON CONFLICT DO UPDATE
    SET (count) = (new_count);
END
$$ LANGUAGE plpgsql;

-- Удалить предмет из инвенторя
CREATE OR REPLACE FUNCTION
    delete_item(_item_id int, _player_id int) RETURNS void
AS $$
BEGIN
    DELETE FROM items WHERE item_id = _item_id AND player_id = _player_id;
END
$$ LANGUAGE plpgsql;

-- Одеть/снять предмет на персонажа
CREATE OR REPLACE FUNCTION
    set_equipped(_player_id int, _item_id int, _equipped bool) RETURNS void
AS $$
BEGIN
    UPDATE items SET (equipped) = _equipped
    WHERE
        player_id = _player_id
        AND item_id = _item_id;
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
    result record;
    total_buff record;
BEGIN
    SELECT
        SUM(info.hp_buff) AS hp_buff,
        SUM(info.dmg_buff) AS dmg_buff
    INTO total_buff
    FROM items item, items_info info
    WHERE
        item.item_id = info.item_id
        AND item.equipped = true
        AND item.player_id = _player_id;
    SELECT
        (buff.hp_buff + player.health) AS health,
        (buff.dmg_buff + player.damage) AS damage
    INTO result
    FROM total_buff buff, players player
    WHERE player.player_id = _player_id;
    RETURN result;
END
$$ LANGUAGE plpgsql;