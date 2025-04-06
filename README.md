# n4w-sql-utils
Consultas ùteis em SQL

🔍 Requisitos:
> Cada tabela (```Tabela_track_2023```, ```Tabela_track_2022```, etc.) deve conter a coluna ```data_evento``` para filtrar pelo intervalo.
> 
> A tabela ```Tabela_track``` contém apenas dados do ano corrente.

🛡️ Destaques:
> Usa ```OBJECT_ID(@tabela_nome, 'U')``` para checar se a tabela existe (```'U'``` = user table).
> 
> Usa ```QUOTENAME``` para proteger contra injeções ou problemas com nomes de tabelas.
> 
> Variável ```@union_needed``` garante que o ```UNION ALL``` só seja adicionado entre blocos válidos.
> 
> Se nenhuma tabela for encontrada no intervalo, é lançado um erro descritivo.

🐘 PostgreSQL – Versão adaptada da procedure
PostgreSQL não tem procedures no mesmo estilo do SQL Server (ainda que existam desde o 11+), mas usaremos uma função com ```EXECUTE``` dinâmico:

🐬 MySQL – Versão adaptada da procedure
O MySQL precisa de uma abordagem diferente porque não permite execução direta de queries múltiplas com ```EXECUTE```. Vamos criar uma procedure com SQL dinâmico e usar ```PREPARE``` + ```EXECUTE```.

⚠️ Observações importantes:
> Todas as versões assumem que o campo de data se chama data_evento.
> 
> As tabelas devem estar no schema padrão (public para PostgreSQL, DATABASE() atual para MySQL).
> 
> PostgreSQL exige uso de format() com EXECUTE para segurança e interpolação correta.
> 
> MySQL exige PREPARE/EXECUTE/DEALLOCATE.

🧠 Regras aplicadas:
> Considera que a tabela tabela_track contém dados de todos os anos.
> 
> Move os dados com base no campo data_evento.
> 
> Cria a tabela do ano automaticamente (se não existir).
> 
> Move os dados do(s) ano(s) anterior(es) e deleta da principal.
> 
> Mantém apenas os dados do ano atual na tabela_track.

📌 Recomendações para execução diária:
> SQL Server: agende via SQL Server Agent.
>
> PostgreSQL: use um cronjob ou pgAgent.
>
> MySQL: use um agendador externo (cron, script bash, etc.).

### Exemplo de uso:

🧪 SQL Server

```sql
EXEC sp_consulta_track
    @data_inicio = '2022-01-01 00:00:00',
    @data_fim = '2022-12-31 23:59:59',
    @pagina_atual = 2,
    @registros_por_pagina = 100;
```

🧪 Postgres SQL

```sql
SELECT * FROM consulta_track(
    '2022-01-01 00:00:00',
    '2022-12-31 23:59:59',
    2,
    100
) AS t(id INT, data_evento TIMESTAMP, evento TEXT, pagina_atual INT, total_paginas INT);
```

🧪 MySQL

```sql
CALL consulta_track(
    '2022-01-01 00:00:00',
    '2022-12-31 23:59:59',
    2,
    100
);
```