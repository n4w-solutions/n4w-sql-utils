CREATE PROCEDURE sp_afasta_dados_por_ano
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ano_atual INT = YEAR(GETDATE());
    DECLARE @ano_min INT;
    DECLARE @ano INT;
    DECLARE @tabela_destino NVARCHAR(128);
    DECLARE @sql NVARCHAR(MAX);

    -- Descobre o menor ano presente na tabela
    SELECT @ano_min = MIN(YEAR(data_evento)) FROM tabela_track;

    SET @ano = @ano_min;

    WHILE @ano < @ano_atual
    BEGIN
        SET @tabela_destino = 'tabela_track_' + CAST(@ano AS VARCHAR);

        -- Cria a tabela do ano se não existir (estrutura igual à principal)
        IF OBJECT_ID(@tabela_destino, 'U') IS NULL
        BEGIN
            SET @sql = 'SELECT TOP 0 * INTO ' + QUOTENAME(@tabela_destino) + ' FROM tabela_track';
            EXEC sp_executesql @sql;
        END

        -- Move os dados do ano para a tabela anual
        SET @sql = '
            INSERT INTO ' + QUOTENAME(@tabela_destino) + '
            SELECT * FROM tabela_track
            WHERE YEAR(data_evento) = ' + CAST(@ano AS VARCHAR) + ';

            DELETE FROM tabela_track WHERE YEAR(data_evento) = ' + CAST(@ano AS VARCHAR) + ';
        ';
        EXEC sp_executesql @sql;

        SET @ano = @ano + 1;
    END
END
