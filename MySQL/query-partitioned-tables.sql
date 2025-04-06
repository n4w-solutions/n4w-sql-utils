DELIMITER $$

CREATE PROCEDURE consulta_track(IN data_inicio DATETIME, IN data_fim DATETIME)
BEGIN
    DECLARE ano_inicio INT;
    DECLARE ano_fim INT;
    DECLARE ano_atual INT;
    DECLARE i INT;
    DECLARE tabela_nome VARCHAR(128);
    DECLARE sql_text LONGTEXT DEFAULT '';
    DECLARE union_needed BOOLEAN DEFAULT FALSE;

    SET ano_inicio = YEAR(data_inicio);
    SET ano_fim = YEAR(data_fim);
    SET ano_atual = YEAR(CURDATE());

    SET i = ano_inicio;

    WHILE i <= ano_fim DO
        IF i = ano_atual THEN
            SET tabela_nome = 'tabela_track';
        ELSE
            SET tabela_nome = CONCAT('tabela_track_', i);
        END IF;

        -- Verifica se a tabela existe
        IF EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = DATABASE() AND table_name = tabela_nome
        ) THEN
            IF union_needed THEN
                SET sql_text = CONCAT(sql_text, ' UNION ALL ');
            END IF;

            SET sql_text = CONCAT(sql_text,
                'SELECT * FROM ', tabela_nome,
                ' WHERE data_evento BETWEEN ''', data_inicio, ''' AND ''', data_fim, ''''
            );

            SET union_needed = TRUE;
        END IF;

        SET i = i + 1;
    END WHILE;

    IF sql_text != '' THEN
        PREPARE stmt FROM sql_text;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nenhuma tabela encontrada para o intervalo informado.';
    END IF;
END$$

DELIMITER ;
