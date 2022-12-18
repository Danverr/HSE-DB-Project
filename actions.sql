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
        10,      -- attack
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
    create_item_info(name varchar, type varchar, could_be_equipped bool, buff_hp int, buff_damage int) RETURNS int
AS $$
DECLARE
    new_item_id int;
BEGIN
    INSERT INTO items_info VALUES (
        DEFAULT,           -- item_id
        name,              -- name
        type,              -- type
        could_be_equipped, -- could_be_equipped
        buff_hp,           -- buff_hp
        buff_damage        -- buff_damage
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
    give_or_update_item(item_id int, owner_id int, new_count int) RETURNS void
AS $$
BEGIN
    INSERT INTO items VALUES (
        item_id,   -- item_id
        owner_id,  -- owner_id
        new_count, -- count
        false      -- equipped
    )
    ON CONFLICT DO UPDATE
    SET (count) = (new_count);
END
$$ LANGUAGE plpgsql;

-- Удалить предмет из инвенторя
CREATE OR REPLACE FUNCTION
    delete_item(_item_id int, _owner_id int) RETURNS void
AS $$
BEGIN
    DELETE FROM items WHERE item_id = _item_id AND owner_id = _owner_id;
END
$$ LANGUAGE plpgsql;

-- Одеть/снять предмет на персонажа
CREATE OR REPLACE FUNCTION
    set_equipped(_owner_id int, _item_id int, _equipped bool) RETURNS void
AS $$
BEGIN
    UPDATE items SET (equipped) = _equipped
    WHERE
        owner_id = _owner_id
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
-- TODO: Даня

-- Вычисление атаки и здоровья персонажа (исходя из очков опыта, и силы/защиты снаряжения)
-- TODO: Даня

