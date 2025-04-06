CREATE OR REPLACE FUNCTION consulta_track(data_inicio TIMESTAMP, data_fim TIMESTAMP)
RETURNS void AS $$
DECLARE
    ano_inicio INT := EXTRACT(YEAR FROM data_inicio);
    ano_fim INT := EXTRACT(YEAR FROM data_fim);
    ano_atual INT := EXTRACT(YEAR FROM NOW());
    i INT := ano_inicio;
    tabela_nome TEXT;
    sql TEXT := '';
    union_needed BOOLEAN := FALSE;
BEGIN
    WHILE i <= ano_fim LOOP
        IF i = ano_atual THEN
            tabela_nome := 'tabela_track';
        ELSE
            tabela_nome := 'tabela_track_' || i;
        END IF;

        -- Verifica se a tabela existe
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name = tabela_nome
        ) THEN
            IF union_needed THEN
                sql := sql || ' UNION ALL ';
            END IF;

            sql := sql || format(
                'SELECT * FROM %I WHERE data_evento BETWEEN %L AND %L',
                tabela_nome, data_inicio, data_fim
            );

            union_needed := TRUE;
        END IF;

        i := i + 1;
    END LOOP;

    IF sql != '' THEN
        EXECUTE sql;
    ELSE
        RAISE EXCEPTION 'Nenhuma tabela encontrada para o intervalo informado.';
    END IF;
END;
$$ LANGUAGE plpgsql;
