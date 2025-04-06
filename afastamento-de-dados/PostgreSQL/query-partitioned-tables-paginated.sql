CREATE OR REPLACE FUNCTION consulta_track(
    data_inicio TIMESTAMP,
    data_fim TIMESTAMP,
    pagina_atual INT,
    registros_por_pagina INT
) RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    ano_inicio INT := EXTRACT(YEAR FROM data_inicio);
    ano_fim INT := EXTRACT(YEAR FROM data_fim);
    ano_atual INT := EXTRACT(YEAR FROM NOW());
    i INT := ano_inicio;
    sql TEXT := '';
    union_needed BOOLEAN := FALSE;
    total_rows INT;
    total_paginas INT;
    offset_val INT := (pagina_atual - 1) * registros_por_pagina;
BEGIN
    WHILE i <= ano_fim LOOP
        IF i = ano_atual THEN
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tabela_track') THEN
                IF union_needed THEN sql := sql || ' UNION ALL '; END IF;
                sql := sql || format('SELECT * FROM tabela_track WHERE data_evento BETWEEN %L AND %L', data_inicio, data_fim);
                union_needed := TRUE;
            END IF;
        ELSE
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tabela_track_' || i) THEN
                IF union_needed THEN sql := sql || ' UNION ALL '; END IF;
                sql := sql || format('SELECT * FROM tabela_track_%s WHERE data_evento BETWEEN %L AND %L', i, data_inicio, data_fim);
                union_needed := TRUE;
            END IF;
        END IF;
        i := i + 1;
    END LOOP;

    IF sql = '' THEN
        RAISE EXCEPTION 'Nenhuma tabela disponível para o período.';
    END IF;

    EXECUTE 'SELECT COUNT(*) FROM (' || sql || ') AS count_query' INTO total_rows;
    total_paginas := CEIL(total_rows::NUMERIC / registros_por_pagina);

    sql := format(
        'SELECT *, %s AS pagina_atual, %s AS total_paginas FROM (%s) AS dados ORDER BY data_evento OFFSET %s LIMIT %s',
        pagina_atual, total_paginas, sql, offset_val, registros_por_pagina
    );

    RETURN QUERY EXECUTE sql;
END;
$$;
