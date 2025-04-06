CREATE PROCEDURE sp_consulta_track
    @data_inicio DATETIME,
    @data_fim DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ano_inicio INT = YEAR(@data_inicio);
    DECLARE @ano_fim INT = YEAR(@data_fim);
    DECLARE @ano_atual INT = YEAR(GETDATE());

    DECLARE @sql NVARCHAR(MAX) = '';
    DECLARE @i INT = @ano_inicio;
    DECLARE @tabela_nome NVARCHAR(128);
    DECLARE @tabela_existe BIT;
    DECLARE @union_needed BIT = 0;

    WHILE @i <= @ano_fim
    BEGIN
        IF @i = @ano_atual
        BEGIN
            SET @tabela_nome = 'Tabela_track';
        END
        ELSE
        BEGIN
            SET @tabela_nome = 'Tabela_track_' + CAST(@i AS VARCHAR);
        END

        -- Verifica se a tabela existe
        IF OBJECT_ID(@tabela_nome, 'U') IS NOT NULL
        BEGIN
            IF @union_needed = 1
            BEGIN
                SET @sql += ' UNION ALL ';
            END

            SET @sql += '
            SELECT * FROM ' + QUOTENAME(@tabela_nome) + '
            WHERE data_evento BETWEEN ''' + CONVERT(VARCHAR, @data_inicio, 120) + ''' AND ''' + CONVERT(VARCHAR, @data_fim, 120) + '''';

            SET @union_needed = 1;
        END

        SET @i += 1;
    END

    IF @sql <> ''
    BEGIN
        EXEC sp_executesql @sql;
    END
    ELSE
    BEGIN
        RAISERROR('Nenhuma tabela correspondente encontrada para o intervalo informado.', 16, 1);
    END
END
