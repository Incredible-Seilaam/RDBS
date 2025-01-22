# Příkazy

Nutno vytvořit procedůry a triggery pod MASTER uživatelem, nefungují

### SELECT

- Výpočet průměrného počtu záznamů na jednu tabulku (bez poddotazu):
    - dotaz spočítá průměrný počet záznamů ve všech tabulkách
    - můžeme použít tabulku `pg_stat_user_tables` k získání statistik o počtu řádků
    - `reltuples` je sloupec v tabulce `pg class`
    - `BIGINT` "velký integer" zajišťuje správné zpracování
```sql
SELECT AVG(reltuples::BIGINT) AS prum_poc_zaznam_tab
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' AND c.relkind = 'r';
```

- SELECT s vnořeným SELECTEM
    - dotaz vypíše názvy písní, které jsou oblíbené (mají vyšší průměrné hodnocení než celkový průměr všech hodnocení)

```sql
SELECT AVG(rating) AS average_rating
FROM "Ratings";
```

```sql
SELECT s.title, AVG(r.rating) AS avg_rating
FROM "Songs" s
JOIN "Ratings" r ON s.id = r.song_id
GROUP BY s.id
HAVING AVG(r.rating) > (
  SELECT AVG(rating)
  FROM "Ratings"
)
ORDER BY avg_rating ASC;
```

- SELECT s analytickou funkcí a GROUP BY
    - dotaz spočítá celkový počet přehrání (`stream count`) pro každého uživatele a přidá pořadí podle tohoto počtu (pomocí analytické funkce `RANK`)
    - pokud mají uživatelé stejné množství přehrání, dostanou stejný rank

```sql
SELECT 
    u.username, 
    COUNT(sh.id) AS stream_count,
    RANK() OVER (ORDER BY COUNT(sh.id) DESC) AS rank
FROM "Users" u
LEFT JOIN "StreamingHistory" sh ON u.id = sh.user_id
GROUP BY u.id
ORDER BY stream_count DESC;
```

### VIEW

- veací seznam **písní**, jejich interpretů, žánrů, data vydání a délky trvání
    - pokud píseň nemá žánr, přiřadí se hodnota `Null` (v tomto případě to ale nikdy nenastane)

```sql
CREATE OR REPLACE VIEW song_details AS
SELECT 
    s.title AS song_title,
    a.name AS artist_name,
    g.name AS genre_name,
    s.release_date,
    s.duration
FROM "Songs" s
INNER JOIN "Artists" a ON s.artist_id = a.id
LEFT JOIN "Genres" g ON s.genre_id = g.id;

SELECT * FROM "song_details";
```

### INDEX

- Unikátní index
    - zajišťuje, že hodnoty v daném sloupci jsou jedinečné

```sql
CREATE UNIQUE INDEX idx_unique_email ON "Users" (email);

INSERT INTO "Users" VALUES (96,'hhf','john.doe@example.com',1);
```

- Fulltextový index
    - užitečný pro textová vyhledávání

```sql
CREATE INDEX idx_fulltext_title ON "Songs" USING gin(to_tsvector('english', title));
```

- B-tree index (standardní index)
    - užitečný pro rychlé vyhledávání a řazení na základě hodnot ve sloupci (např. při vyhledávání písní podle data vydání)

```sql
CREATE INDEX idx_release_date ON "Songs" (release_date);
```

### FUNCTION

- Průměrná délka písní v SEKUNDÁCH

```sql
CREATE OR REPLACE FUNCTION get_average_song_duration()
RETURNS numeric AS $$
DECLARE
    avg_duration numeric;
BEGIN
    SELECT AVG(duration) INTO avg_duration
    FROM "Songs";
    RETURN avg_duration;
END;
$$ LANGUAGE plpgsql;
```

```sql
SELECT get_average_song_duration();
```

- Průměrná délka písní v MINUTÁCH

```sql
CREATE OR REPLACE FUNCTION get_average_song_duration_minutes()
RETURNS numeric AS $$
DECLARE
    avg_duration_seconds numeric;
    avg_duration_minutes numeric;
BEGIN
    SELECT AVG(duration) INTO avg_duration_seconds
    FROM "Songs";
    avg_duration_minutes := avg_duration_seconds / 60;
    RETURN avg_duration_minutes;
END;
$$ LANGUAGE plpgsql;

```

```sql
SELECT get_average_song_duration_minutes();
```

### PROCEDURE

- Generování náhodné slevy
    - pomocí `CURSOR` iterujeme přes každý řádek zvlášť

```sql
CREATE OR REPLACE PROCEDURE generate_subscription_discounts()
LANGUAGE plpgsql AS $$
DECLARE
    subscription_cursor CURSOR FOR 
        SELECT id, price FROM "Subscriptions";
    
    v_subscription_id INT;
    v_subscription_price NUMERIC;
    v_discount_percentage NUMERIC;
    v_price_after_discount NUMERIC;
BEGIN
    OPEN subscription_cursor;
    
    LOOP
        FETCH subscription_cursor INTO v_subscription_id, v_subscription_price;
        EXIT WHEN NOT FOUND;

        v_discount_percentage := ROUND((RANDOM() * (50 - 5) + 5)::NUMERIC, 2);

        v_price_after_discount := v_subscription_price * (1 - (v_discount_percentage / 100));

        BEGIN
            INSERT INTO "SubscriptionDiscounts" 
                (subscription_id, discount_percentage, price_before_discount, price_after_discount)
            VALUES 
                (v_subscription_id, v_discount_percentage, v_subscription_price, v_price_after_discount);

            IF (SELECT original_price FROM "Subscriptions" WHERE id = v_subscription_id) IS NULL THEN
                UPDATE "Subscriptions"
                SET original_price = v_subscription_price
                WHERE id = v_subscription_id;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Error inserting discount for subscription ID %', v_subscription_id;
        END;
    END LOOP;

    CLOSE subscription_cursor;

    RAISE NOTICE 'Discount generation completed successfully.';
END;
$$;
```

```sql
CALL generate_subscription_discounts();
```

- Vrácení původní ceny
    - obnoví původní ceny předplatného pro všechny záznamy v tabulce `Subscriptions`

```sql
CREATE OR REPLACE PROCEDURE revert_subscription_prices()
LANGUAGE plpgsql AS $$
DECLARE
    revert_cursor CURSOR FOR 
        SELECT id, original_price FROM "Subscriptions" WHERE original_price IS NOT NULL;
    
    v_subscription_id INT;
    v_original_price NUMERIC;
BEGIN
    OPEN revert_cursor;

    LOOP
        FETCH revert_cursor INTO v_subscription_id, v_original_price;
        EXIT WHEN NOT FOUND;

        BEGIN
            UPDATE "Subscriptions"
            SET price = v_original_price
            WHERE id = v_subscription_id;

            RAISE NOTICE 'Reverted subscription ID % to original price %', v_subscription_id, v_original_price;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Error reverting price for subscription ID %', v_subscription_id;
        END;
    END LOOP;

    CLOSE revert_cursor;

    RAISE NOTICE 'Reverting all subscription prices completed.';
END;
$$;
```

```sql
CALL revert_subscription_prices();
```

### TRIGGER

- Updatuje ceník
    - automatické aktualizaci ceny předplatného v tabulce `Subscriptions` na základě nového záznamu v tabulce `SubscriptionDiscounts`

```sql
CREATE OR REPLACE FUNCTION update_subscription_price_after_discount()
RETURNS TRIGGER AS $$
DECLARE
    discount_cursor CURSOR FOR 
        SELECT subscription_id, price_after_discount FROM "SubscriptionDiscounts"
        WHERE id = NEW.id;
    
    v_subscription_id INT;
    v_price_after_discount NUMERIC;
BEGIN
    OPEN discount_cursor;

    LOOP
        FETCH discount_cursor INTO v_subscription_id, v_price_after_discount;

        EXIT WHEN NOT FOUND;

        BEGIN
            UPDATE "Subscriptions"
            SET price = v_price_after_discount
            WHERE id = v_subscription_id;

            RAISE NOTICE 'Price updated for subscription ID % to %', v_subscription_id, v_price_after_discount;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Error updating price for subscription ID %', v_subscription_id;
        END;
    END LOOP;

    CLOSE discount_cursor;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

```sql
CREATE OR REPLACE TRIGGER update_subscription_price_trigger
AFTER INSERT ON "SubscriptionDiscounts"
FOR EACH ROW
EXECUTE FUNCTION update_subscription_price_after_discount();
```

### TRANSACTION

- Přenáší skladby mezi playlisty

```sql
CREATE OR REPLACE PROCEDURE transfer_song_between_playlists(
    song_id INT,
    source_playlist_id INT,
    target_playlist_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    song_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM "PlaylistSongs"
        WHERE "PlaylistSongs".song_id = transfer_song_between_playlists.song_id 
          AND playlist_id = source_playlist_id
    ) INTO song_exists;

    IF NOT song_exists THEN
        RAISE NOTICE 'Skladba ID % nebyla nalezena v playlistu ID %', song_id, source_playlist_id;
        RETURN;
    END IF;

    BEGIN
        DELETE FROM "PlaylistSongs"
        WHERE "PlaylistSongs".song_id = transfer_song_between_playlists.song_id 
          AND playlist_id = source_playlist_id;

        INSERT INTO "PlaylistSongs" (playlist_id, song_id)
        VALUES (target_playlist_id, transfer_song_between_playlists.song_id);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Chyba při přesunu skladby ID %: %', song_id, SQLERRM;
            RETURN;
    END;

    RAISE NOTICE 'Skladba ID % byla úspěšně přesunuta z playlistu ID % do playlistu ID %', 
                 song_id, source_playlist_id, target_playlist_id;
END;
$$;
```

```sql
CALL transfer_song_between_playlists(121, 1, 2);
```

### USER

- Vytvoření uživatele

```sql
CREATE USER test_uzivatel WITH PASSWORD 'heslo123';
```

- Odstranění uživatele

```sql
DROP USER test_uzivatel;
```

- Odebrání práv uživateli

```sql
REVOKE ALL PRIVILEGES ON DATABASE "Music library v2" FROM test_uzivatel;
```

- Vytvoření role a přidělení práv

```sql
CREATE ROLE test_role;
```

```sql
CREATE ROLE test_role WITH LOGIN PASSWORD 'test_heslo';
```

```sql
GRANT SELECT, INSERT, UPDATE ON TABLE "Songs" TO test_role;
```

- Přidělení role uživateli

```sql
GRANT test_role TO test_uzivatel;
```

- Odebrání práv role a její odstranění

```sql
REVOKE SELECT, INSERT ON TABLE tabulka FROM nova_rola;
```

```sql
DROP ROLE test_role;
```

### Master

```sql
CREATE USER natalie WITH PASSWORD 'Aurhzuar321';

GRANT ALL PRIVILEGES ON DATABASE "Music library v2" TO natalie;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO natalie;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO natalie;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON TABLES TO natalie;
```

### LOCK
- uživatel 2 čeká, dokud uživatel 1 tabulku znovu neodemkne pomocí “COMMIT” nebo “ROLLBACK”

1. uživatel

```sql
BEGIN;

LOCK TABLE "Songs" IN ACCESS EXCLUSIVE MODE;

COMMIT;
--ROLLBACK;
```

2. uživatel

```sql
SELECT * FROM "Songs";
```