CREATE PROCEDURE sp_consulta_track
    @data_inicio DATETIME,
    @data_fim DATETIME,
    @pagina_atual INT,
    @registros_por_pagina INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ano_inicio INT = YEAR(@data_inicio);
    DECLARE @ano_fim INT = YEAR(@data_fim);
    DECLARE @ano_atual INT = YEAR(GETDATE());
    DECLARE @sql NVARCHAR(MAX) = '';
    DECLARE @i INT = @ano_inicio;
    DECLARE @tabela_nome NVARCHAR(128);
    DECLARE @union_needed BIT = 0;
    DECLARE @total INT;
    DECLARE @offset INT = (@pagina_atual - 1) * @registros_por_pagina;
    DECLARE @total_paginas INT;

    -- Monta consulta base
    WHILE @i <= @ano_fim
    BEGIN
        SET @tabela_nome = 
            CASE WHEN @i = @ano_atual THEN 'tabela_track' 
                 ELSE 'tabela_track_' + CAST(@i AS VARCHAR) END;

        IF OBJECT_ID(@tabela_nome, 'U') IS NOT NULL
        BEGIN
            IF @union_needed = 1 SET @sql += ' UNION ALL ';
            SET @sql += 'SELECT * FROM ' + QUOTENAME(@tabela_nome) +
                        ' WHERE data_evento BETWEEN ''' + CONVERT(VARCHAR, @data_inicio, 120) + ''' AND ''' + CONVERT(VARCHAR, @data_fim, 120) + '''';
            SET @union_needed = 1;
        END
        SET @i += 1;
    END

    IF @sql = ''
    BEGIN
        RAISERROR('Nenhuma tabela disponível para o período.', 16, 1);
        RETURN;
    END

    -- Conta total de registros
    DECLARE @count_sql NVARCHAR(MAX) = 'SELECT COUNT(*) FROM (' + @sql + ') AS total_count';
    EXEC sp_executesql @count_sql, N'@total INT OUTPUT', @total = @total OUTPUT;

    SET @total_paginas = CEILING(1.0 * @total / @registros_por_pagina);

    -- Query final paginada
    SET @sql = '
        SELECT *, ' + CAST(@pagina_atual AS VARCHAR) + ' AS pagina_atual, ' +
        CAST(@total_paginas AS VARCHAR) + ' AS total_paginas
        FROM (' + @sql + ') AS dados
        ORDER BY data_evento
        OFFSET ' + CAST(@offset AS VARCHAR) + ' ROWS FETCH NEXT ' + 
        CAST(@registros_por_pagina AS VARCHAR) + ' ROWS ONLY';

    EXEC sp_executesql @sql;
END
