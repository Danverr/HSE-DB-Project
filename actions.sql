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
        0,       -- xp
        100,     -- health
        10,      -- damage
        null,    -- sword_id
        null,    -- helmet_id
        null,    -- chestplate_id
        null,    -- leggings_id
        null     -- boots_id
    ) RETURNING player_id INTO new_player_id;
    RETURN new_player_id;
END 
$$ LANGUAGE plpgsql;

-- Создание учетной записи пользователя
CREATE OR REPLACE FUNCTION
    create_account(name varchar, phone_number varchar, password_hash varchar) RETURNS record
AS $$
DECLARE
    new_player_id int;
    new_account_id int;
BEGIN
    SELECT create_player(name) INTO new_player_id;
    INSERT INTO accounts VALUES (
        DEFAULT,       -- account_id
        new_player_id, -- player_id
        phone_number,  -- phone_number
        password_hash  -- password_hash
    ) RETURNING account_id INTO new_account_id;
    RETURN (new_account_id, new_player_id);
END
$$ LANGUAGE plpgsql;

-- Добавление предметов (предмет имеет тип и может иметь бонусы к здоровью и/или атаке)
CREATE OR REPLACE FUNCTION
    create_item_info(
        name varchar,
        type varchar,
        hp_buff int,
        dmg_buff int
    )
    RETURNS int
AS $$
DECLARE
    new_item_id int;
BEGIN
    INSERT INTO items_info VALUES (
        DEFAULT, -- item_id
        name,    -- name
        type,    -- type
        hp_buff, -- hp_buff
        dmg_buff -- dmg_buff
    ) RETURNING item_id INTO new_item_id;
    RETURN new_item_id;
END
$$ LANGUAGE plpgsql;

-- Удаление предметов (предмет имеет тип и может иметь бонусы к здоровью и/или атаке)
CREATE OR REPLACE FUNCTION
    delete_item_info(_item_id int) RETURNS void
AS $$
BEGIN
    DELETE FROM items_info WHERE item_id = _item_id;
END
$$ LANGUAGE plpgsql;

-- Получить тип предмета
CREATE OR REPLACE FUNCTION
    get_item_type(_item_id int) RETURNS varchar
AS $$
DECLARE
    _type varchar;
BEGIN
    SELECT type
    INTO _type
    FROM items_info
    WHERE item_id = _item_id;

    RETURN _type;
END
$$ LANGUAGE plpgsql;

-- Получить количество предмета в инвентаре
CREATE OR REPLACE FUNCTION
    get_item_count(_item_id int, _player_id int) RETURNS int
AS $$
DECLARE
    _count int;
BEGIN
    SELECT count
    INTO _count
    FROM items
    WHERE item_id = _item_id
      AND player_id = _player_id;
    
    RETURN COALESCE(_count, 0);
END
$$ LANGUAGE plpgsql;

-- Установить количество предмета в инвентаре
CREATE OR REPLACE FUNCTION
    set_item_count(_item_id int, _player_id int, _count int) RETURNS void
AS $$
BEGIN
    INSERT INTO items VALUES (
        _item_id,   -- item_id
        _player_id, -- player_id
        _count      -- count
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

-- Можно ли носить предмет
CREATE OR REPLACE FUNCTION
    can_be_equipped(_item_id int) RETURNS bool
AS $$
DECLARE
    _type varchar;
BEGIN
    SELECT get_item_type(_item_id) INTO _type;

    RETURN _type = 'SWORD' 
        OR _type = 'HELMET' 
        OR _type = 'CHESTPLATE' 
        OR _type = 'LEGGINGS' 
        OR _type = 'BOOTS';
END
$$ LANGUAGE plpgsql;

-- Какой предмет конкретного типа сейчас на персонаже
CREATE OR REPLACE FUNCTION
    get_equipped_item_id_by_type(_player_id int, _type varchar) RETURNS int
AS $$
DECLARE
    _equipped_item_id int;
BEGIN
    IF (_type = 'SWORD') THEN
        SELECT sword_id
        INTO _equipped_item_id
        FROM players
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'HELMET') THEN
        SELECT helmet_id
        INTO _equipped_item_id
        FROM players
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'CHESTPLATE') THEN
        SELECT chestplate_id
        INTO _equipped_item_id
        FROM players
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'LEGGINGS') THEN
        SELECT leggings_id
        INTO _equipped_item_id
        FROM players
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'BOOTS') THEN
        SELECT boots_id
        INTO _equipped_item_id
        FROM players
        WHERE player_id = _player_id;
    END IF;

    RETURN _equipped_item_id;
END
$$ LANGUAGE plpgsql;

-- Надеть предмет на персонажа
CREATE OR REPLACE FUNCTION
    equip(_item_id int, _player_id int) RETURNS void
AS $$
DECLARE
    _count int;
    _type varchar;
BEGIN
    IF (can_be_equipped(_item_id) = false) THEN 
        RETURN;
    END IF;

    SELECT get_item_count(_item_id, _player_id) INTO _count;

    IF (COALESCE(_count, 0) = 0) THEN
        RETURN;
    END IF;

    SELECT get_item_type(_item_id) INTO _type;

    IF (get_equipped_item_id_by_type(_player_id, _type) IS NOT NULL) THEN
        RETURN;
    END IF;

    IF (_type = 'SWORD') THEN
        UPDATE players SET sword_id = _item_id
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'HELMET') THEN
        UPDATE players SET helmet_id = _item_id
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'CHESTPLATE') THEN
        UPDATE players SET chestplate_id = _item_id
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'LEGGINGS') THEN
        UPDATE players SET leggings_id = _item_id
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'BOOTS') THEN
        UPDATE players SET boots_id = _item_id
        WHERE player_id = _player_id;
    END IF;

    PERFORM set_item_count(_item_id, _player_id, _count - 1);

    RETURN;
END
$$ LANGUAGE plpgsql;

-- Снять предмет данного типа с персонажа
CREATE OR REPLACE FUNCTION
    unequip(_player_id int, _type varchar) RETURNS void
AS $$
DECLARE
    _equipped_item_id int;
BEGIN
    SELECT get_equipped_item_id_by_type(_player_id, _type) INTO _equipped_item_id;

    IF (_equipped_item_id IS NULL) THEN
        RETURN;
    END IF;

    PERFORM set_item_count(_equipped_item_id, _player_id, get_item_count(_equipped_item_id, _player_id) + 1);

    IF (_type = 'SWORD') THEN
        UPDATE players SET sword_id = null
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'HELMET') THEN
        UPDATE players SET helmet_id = null
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'CHESTPLATE') THEN
        UPDATE players SET chestplate_id = null
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'LEGGINGS') THEN
        UPDATE players SET leggings_id = null
        WHERE player_id = _player_id;
    END IF;
    IF (_type = 'BOOTS') THEN
        UPDATE players SET boots_id = null
        WHERE player_id = _player_id;
    END IF;
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

-- Удаление заявки на обмен
CREATE OR REPLACE FUNCTION
    delete_offer(_offer_id int) RETURNS void
AS $$
BEGIN
    DELETE FROM offers WHERE offer_id = _offer_id;
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

-- Подсчет уровня героя по количеству опыта
CREATE OR REPLACE FUNCTION
    get_level(_player_id int) RETURNS int
AS $$
DECLARE
    level int;
BEGIN
    SELECT floor(log(2, 2 + xp))
    INTO level
    FROM players
    WHERE player_id = _player_id;

    RETURN level;
END
$$ LANGUAGE plpgsql;

-- Добавление очков опыта к уровню персонажа
CREATE OR REPLACE FUNCTION
    add_xp(_player_id int, xp_delta int) RETURNS void
AS $$
BEGIN
    UPDATE players SET xp = xp + xp_delta
    WHERE player_id = _player_id;
END
$$ LANGUAGE plpgsql;

-- Получение бонуса к здоровью от предмета конкретного типа
CREATE OR REPLACE FUNCTION
    get_item_hp_buff_by_type(_player_id int, _type varchar) RETURNS int
AS $$
DECLARE
    _item_id int;
    _hp_buff int;
BEGIN
    SELECT get_equipped_item_id_by_type(_player_id, _type) INTO _item_id;

    SELECT hp_buff
    INTO _hp_buff
    FROM items_info
    WHERE item_id = _item_id;

    RETURN COALESCE(_hp_buff, 0);
END
$$ LANGUAGE plpgsql;

-- Получение бонуса к атакe от предмета конкретного типа
CREATE OR REPLACE FUNCTION
    get_item_dmg_buff_by_type(_player_id int, _type varchar) RETURNS int
AS $$
DECLARE
    _item_id int;
    _dmg_buff int;
BEGIN
    SELECT get_equipped_item_id_by_type(_player_id, _type) INTO _item_id;

    SELECT dmg_buff
    INTO _dmg_buff
    FROM items_info
    WHERE item_id = _item_id;

    RETURN COALESCE(_dmg_buff, 0);
END
$$ LANGUAGE plpgsql;

-- Получение суммарного бонуса к здоровью от предметов
CREATE OR REPLACE FUNCTION
    get_total_hp_buff(_player_id int) RETURNS int
AS $$
DECLARE
    total_hp_buff int;
BEGIN
    SELECT 
        get_item_hp_buff_by_type(_player_id, 'SWORD') +
        get_item_hp_buff_by_type(_player_id, 'HELMET') + 
        get_item_hp_buff_by_type(_player_id, 'CHESTPLATE') +
        get_item_hp_buff_by_type(_player_id, 'LEGGINGS') +
        get_item_hp_buff_by_type(_player_id, 'BOOTS')
    INTO total_hp_buff;

    RETURN total_hp_buff;
END
$$ LANGUAGE plpgsql;

-- Получение суммарного бонуса к атаке от предметов
CREATE OR REPLACE FUNCTION
    get_total_dmg_buff(_player_id int) RETURNS int
AS $$
DECLARE
    total_dmg_buff int;
BEGIN
    SELECT 
        get_item_dmg_buff_by_type(_player_id, 'SWORD') +
        get_item_dmg_buff_by_type(_player_id, 'HELMET') + 
        get_item_dmg_buff_by_type(_player_id, 'CHESTPLATE') +
        get_item_dmg_buff_by_type(_player_id, 'LEGGINGS') +
        get_item_dmg_buff_by_type(_player_id, 'BOOTS')
    INTO total_dmg_buff;

    RETURN total_dmg_buff;
END
$$ LANGUAGE plpgsql;

-- Вычисление здоровья и атаки персонажа (исходя из очков опыта, и силы/защиты снаряжения)
CREATE OR REPLACE FUNCTION
    get_player_hp_and_dmg(_player_id int) RETURNS record
AS $$
DECLARE
    _health int;
    _damage int;
    _total_hp_buff int;
    _total_dmg_buff int;
	result record;
BEGIN
    SELECT health, damage
    INTO _health, _damage
    FROM players
    WHERE player_id = _player_id;

    SELECT get_total_hp_buff(_player_id) INTO _total_hp_buff;

    SELECT get_total_dmg_buff(_player_id) INTO _total_dmg_buff;

	SELECT 
        FLOOR((1 + get_level(_player_id) / 100.0) * (_health + _total_hp_buff)) AS hp,
        FLOOR((1 + get_level(_player_id) / 100.0) * (_damage + _total_dmg_buff)) AS dmg
	INTO result;
	
    RETURN result;
END
$$ LANGUAGE plpgsql;

-- Добавление монстра
CREATE OR REPLACE FUNCTION
    create_monster(
        name varchar,
        health int,
        damage int,
        description varchar
    )
    RETURNS int
AS $$
DECLARE
    new_monster_id int;
BEGIN
    INSERT INTO monsters VALUES (
        DEFAULT,     -- monster_id
        name,        -- name
        health,      -- health
        damage,      -- damage
        description  -- description
    ) RETURNING monster_id INTO new_monster_id;
    RETURN new_monster_id;
END
$$ LANGUAGE plpgsql;

-- Удаление монстра
CREATE OR REPLACE FUNCTION
    delete_monster(monster_id int) RETURNS void
AS $$
BEGIN
    DELETE FROM monster WHERE monster_id = _monster_id;
END
$$ LANGUAGE plpgsql;

-- Добавление квеста
CREATE OR REPLACE FUNCTION
    create_quest_info(
        name varchar,
        description varchar,
        xp_reward int
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
        xp_reward    -- xp_reward
    ) RETURNING quest_id INTO new_quest_id;
    RETURN new_quest_id;
END
$$ LANGUAGE plpgsql;

-- Удаление квеста
CREATE OR REPLACE FUNCTION
    delete_quest_info(_quest_id int) RETURNS void
AS $$
BEGIN
    DELETE FROM quests_info WHERE quest_id = _quest_id;
END
$$ LANGUAGE plpgsql;

-- Добавление наград в квест
CREATE OR REPLACE FUNCTION
    create_quest_rewards(
        quest_id int,
        reward_item_id int,
        reward_item_count int
    )
    RETURNS void
AS $$
BEGIN
    INSERT INTO quests_rewards VALUES (
        quest_id,         -- quest_id       
        reward_item_id,   -- reward_item_id
        reward_item_count -- reward_item_count
    );
END
$$ LANGUAGE plpgsql;

-- Удаление наград из квеста
CREATE OR REPLACE FUNCTION
    delete_quest_rewards(_quest_id int, _reward_item_id int) RETURNS void
AS $$
BEGIN
    DELETE FROM quests_rewards WHERE quest_id = _quest_id AND reward_item_id = _reward_item_id;
END
$$ LANGUAGE plpgsql;

-- Добавление монстров в квест
CREATE OR REPLACE FUNCTION
    create_quest_monsters(
        quest_id int,
        monster_id int,
        monster_count int
    )
    RETURNS void
AS $$
BEGIN
    INSERT INTO quests_monsters VALUES (
        quest_id,     -- quest_id       
        monster_id,   -- monster_id
        monster_count -- monster_count
    );
END
$$ LANGUAGE plpgsql;

-- Удаление монстров из квеста
CREATE OR REPLACE FUNCTION
    delete_quest_monsters(_quest_id int, monster_id int) RETURNS void
AS $$
BEGIN
    DELETE FROM quests_monsters WHERE quest_id = _quest_id AND monster_id = _monster_id;
END
$$ LANGUAGE plpgsql;

-- Получение квеста героем
CREATE OR REPLACE FUNCTION
    get_quest(_quest_id int, _player_id int) RETURNS void
AS $$
DECLARE
    quest_in_progress_id int;
BEGIN
    SELECT quest_id
    INTO quest_in_progress_id
    FROM quests
    WHERE player_id = _player_id
      AND status = 'IN_PROGRESS';

    if (quest_in_progress_id IS NOT NULL) THEN
        RETURN;
    END IF;

    IF (get_quest_status(_quest_id, _player_id) IS NOT NULL) THEN
        RETURN;
    END IF;

    INSERT INTO quests VALUES (
        _quest_id,     -- quest_id
        _player_id,    -- player_id
        'IN_PROGRESS' -- status
    );
END
$$ LANGUAGE plpgsql;

-- Получение статуса квеста
CREATE OR REPLACE FUNCTION
    get_quest_status(_quest_id int, _player_id int) RETURNS varchar
AS $$
DECLARE
    _status varchar;
BEGIN
    SELECT status
    INTO _status
    FROM quests
    WHERE quest_id = _quest_id
      AND player_id = _player_id;

    RETURN _status;
END
$$ LANGUAGE plpgsql;

-- Отказ героя от квеста
CREATE OR REPLACE FUNCTION
    fail_quest(_quest_id int, _player_id int) RETURNS void
AS $$
BEGIN
    IF (get_quest_status(_quest_id, _player_id) != 'IN_PROGRESS') THEN
        RETURN;
    END IF;

    UPDATE quests SET status = 'FAILED'
    WHERE quest_id = _quest_id 
      AND player_id = _player_id;
END
$$ LANGUAGE plpgsql;

-- Получение награды за выполненный квест
CREATE OR REPLACE FUNCTION
    give_reward(_player_id int, _quest_id int) RETURNS void
AS $$
DECLARE
    _xp_reward int;
BEGIN
    SELECT xp_reward INTO _xp_reward FROM quests_info WHERE quest_id = _quest_id;

    PERFORM add_xp(_player_id, _xp_reward);

    PERFORM set_item_count(reward_item_id, _player_id, get_item_count(_player_id, reward_item_id) + reward_item_count)
    FROM quests_rewards
    WHERE quest_id = _quest_id;
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
        COALESCE(SUM(monsters.health * quests_monsters.monster_count), 0) AS hp,
        COALESCE(SUM(monsters.damage * quests_monsters.monster_count), 0) AS dmg
    INTO result
    FROM monsters, quests_monsters
    WHERE quests_monsters.quest_id = _quest_id
      AND monsters.monster_id = quests_monsters.monster_id;

    RETURN result;
END
$$ LANGUAGE plpgsql;

-- Смерть героя
CREATE OR REPLACE FUNCTION
    kill_player(_player_id int) RETURNS void
AS $$
DECLARE
    _gold_id int;
    _gold_count int;
BEGIN
    SELECT item_id INTO _gold_id FROM items_info WHERE type = 'GOLD';

    SELECT get_item_count(_gold_id, _player_id) INTO _gold_count;

    PERFORM set_item_count(_gold_id, _player_id, CAST(FLOOR(0.9 * _gold_count) AS INTEGER));
END
$$ LANGUAGE plpgsql;

-- Завершение задания
CREATE OR REPLACE FUNCTION
    complete_quest(_quest_id int, _player_id int) RETURNS void
AS $$
DECLARE
    player_hp_and_dmg record;
    monster_group_hp_and_dmg record;
BEGIN
    IF (get_quest_status(_quest_id, _player_id) != 'IN_PROGRESS') THEN
        RETURN;
    END IF;
    player_hp_and_dmg = get_player_hp_and_dmg(_player_id);
    monster_group_hp_and_dmg = get_monster_group_hp_and_dmg(_quest_id);

    IF (CEILING(player_hp_and_dmg.hp / monster_group_hp_and_dmg.dmg)
        >= CEILING(monster_group_hp_and_dmg.hp / player_hp_and_dmg.dmg)) 
    THEN 
		PERFORM give_reward(_player_id, _quest_id);
    	UPDATE quests SET status = 'DONE'
    	WHERE player_id = _player_id AND quest_id = _quest_id;
    ELSE 
		PERFORM kill_player(_player_id);
    	UPDATE quests SET status = 'FAILED'
    	WHERE player_id = _player_id AND quest_id = _quest_id;
    END IF;
END
$$ LANGUAGE plpgsql;
