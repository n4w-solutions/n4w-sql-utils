DELIMITER $$

CREATE PROCEDURE consulta_track(
    IN data_inicio DATETIME,
    IN data_fim DATETIME,
    IN pagina_atual INT,
    IN registros_por_pagina INT
)
BEGIN
    DECLARE ano_inicio INT DEFAULT YEAR(data_inicio);
    DECLARE ano_fim INT DEFAULT YEAR(data_fim);
    DECLARE ano_atual INT DEFAULT YEAR(CURDATE());
    DECLARE i INT DEFAULT ano_inicio;
    DECLARE tabela_nome VARCHAR(128);
    DECLARE sql_text LONGTEXT DEFAULT '';
    DECLARE count_sql LONGTEXT DEFAULT '';
    DECLARE total_rows INT DEFAULT 0;
    DECLARE total_paginas INT DEFAULT 0;
    DECLARE offset_val INT DEFAULT (pagina_atual - 1) * registros_por_pagina;
    DECLARE union_needed BOOLEAN DEFAULT FALSE;

    WHILE i <= ano_fim DO
        SET tabela_nome = IF(i = ano_atual, 'tabela_track', CONCAT('tabela_track_', i));

        IF EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = DATABASE() AND table_name = tabela_nome
        ) THEN
            IF union_needed THEN SET sql_text = CONCAT(sql_text, ' UNION ALL '); END IF;
            SET sql_text = CONCAT(sql_text,
                'SELECT * FROM ', tabela_nome,
                ' WHERE data_evento BETWEEN ''', data_inicio, ''' AND ''', data_fim, ''''
            );
            SET union_needed = TRUE;
        END IF;
        SET i = i + 1;
    END WHILE;

    IF sql_text = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nenhuma tabela disponível para o período.';
    END IF;

    SET @count_sql = CONCAT('SELECT COUNT(*) INTO @total_rows FROM (', sql_text, ') AS contagem');
    PREPARE stmt FROM @count_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET total_rows = @total_rows;
    SET total_paginas = CEIL(total_rows / registros_por_pagina);

    SET @final_sql = CONCAT(
        'SELECT *, ', pagina_atual, ' AS pagina_atual, ', total_paginas,
        ' AS total_paginas FROM (', sql_text, 
        ') AS resultado ORDER BY data_evento LIMIT ', registros_por_pagina,
        ' OFFSET ', offset_val
    );

    PREPARE stmt FROM @final_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;
