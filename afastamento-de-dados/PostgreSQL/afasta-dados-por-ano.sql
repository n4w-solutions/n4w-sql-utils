CREATE OR REPLACE FUNCTION afasta_dados_por_ano()
RETURNS void AS $$
DECLARE
    ano_atual INT := EXTRACT(YEAR FROM NOW());
    ano_min INT;
    ano INT;
    tabela_destino TEXT;
    sql TEXT;
BEGIN
    SELECT MIN(EXTRACT(YEAR FROM data_evento))::INT INTO ano_min FROM tabela_track;

    FOR ano IN ano_min..(ano_atual - 1) LOOP
        tabela_destino := 'tabela_track_' || ano;

        -- Cria a tabela se não existir
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name = tabela_destino
        ) THEN
            EXECUTE format('CREATE TABLE %I (LIKE tabela_track INCLUDING ALL)', tabela_destino);
        END IF;

        -- Move os dados
        EXECUTE format(
            'INSERT INTO %I SELECT * FROM tabela_track WHERE EXTRACT(YEAR FROM data_evento) = %L',
            tabela_destino, ano
        );
        EXECUTE format(
            'DELETE FROM tabela_track WHERE EXTRACT(YEAR FROM data_evento) = %L',
            ano
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
