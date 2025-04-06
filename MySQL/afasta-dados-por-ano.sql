DELIMITER $$

CREATE PROCEDURE afasta_dados_por_ano()
BEGIN
    DECLARE ano_atual INT;
    DECLARE ano_min INT;
    DECLARE ano INT;
    DECLARE tabela_destino VARCHAR(128);
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR
        SELECT DISTINCT YEAR(data_evento)
        FROM tabela_track
        WHERE YEAR(data_evento) < YEAR(CURDATE());

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET ano_atual = YEAR(CURDATE());

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO ano;
        IF done THEN
            LEAVE read_loop;
        END IF;

        SET tabela_destino = CONCAT('tabela_track_', ano);

        -- Cria a tabela se não existir
        SET @sql := CONCAT(
            'CREATE TABLE IF NOT EXISTS ', tabela_destino,
            ' LIKE tabela_track'
        );
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- Move os dados
        SET @sql := CONCAT(
            'INSERT INTO ', tabela_destino,
            ' SELECT * FROM tabela_track WHERE YEAR(data_evento) = ', ano
        );
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @sql := CONCAT(
            'DELETE FROM tabela_track WHERE YEAR(data_evento) = ', ano
        );
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;
