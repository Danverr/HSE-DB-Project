-- Создание героя для пользователя
CREATE OR REPLACE FUNCTION
    create_player(name varchar)
RETURNS INT
AS $$
DECLARE
    new_player_id INT;
BEGIN
    INSERT INTO players VALUES (
        DEFAULT, -- player_id
        name,    -- name
        1,       -- level
        0,       -- xp
        100,     -- hp
        10,      -- attack
        100,     -- money
        NULL,    -- current_quest_id
        NULL,    -- weapon_id
        NULL,    -- armor_id
        NULL,    -- helmet_id
        NULL     -- gloves_id
    ) RETURNING player_id INTO new_player_id;
    RETURN new_player_id;
END $$ LANGUAGE plpgsql;

-- Создание учетной записи пользователя
CREATE OR REPLACE FUNCTION
    create_account(name varchar, phone_number varchar, password varchar) RETURNS INT
AS $$
DECLARE
    new_player_id INT;
    new_account_id INT;
BEGIN
    SELECT create_player(name) INTO new_player_id;
    INSERT INTO accounts_info VALUES (
        DEFAULT,       -- account_id
        phone_number,  -- phone_number
        password,      -- password
        new_player_id -- player_id
    ) RETURNING account_id INTO new_account_id;
    RETURN new_account_id;
END
$$ LANGUAGE plpgsql;

-- Добавление/удаление предметов (предмет имеет тип и может иметь бонусы к здоровью и/или атаке)
-- TODO: Даня

-- Заявка на обмен предметов с другим игроком (если предмет - золото, то это покупка/продажа)
-- TODO: Даня

-- Принятие заявки на обмен предметов от игрока
-- TODO: Даня

-- Экипировка предметов типа “Меч”, “Броня” “Шлем” “Сапоги” “Перчатки” на персонажа
-- TODO: Даня

-- Добавление очков опыта к уровню персонажа
-- TODO: Даня

-- Вычисление атаки и здоровья персонажа (исходя из очков опыта, и силы/защиты снаряжения)
-- TODO: Даня

