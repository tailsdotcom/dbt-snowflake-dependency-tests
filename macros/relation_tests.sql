{#
-- This is a macro to assert which schemas and databases a given view depends on.
-- Use this in dbt_projects.yml as a hook:
-- post-hook:
--  - "{{ assert_refs(allow_rules=['.*_base', 'airflow_db\\..*']) }}"
#}

{% macro assert_refs(allow_rules=[], except_models=[]) %}

    {%- if config.get('materialized', default='meh') == 'view' and this.name not in except_models -%}
        {%- call statement('get_deps', fetch_result=True) %}

            WITH deps AS (
                select 
                    database_name,
                    schema_name,
                    object_name, 
                    database_name || '.' || schema_name || '.' || object_name AS qualified_object_name,
                    referenced_database_name,
                    referenced_schema_name,
                    referenced_database_name || '.' || referenced_schema_name AS qualified_referenced_schema_name
                from table(get_object_references(
                    database_name=>'{{ this.database }}',
                    schema_name=>'{{ this.schema }}',
                    object_name=>'{{ this.name }}'))
                ),
                allow_rules AS (
                    SELECT
                        column1 AS allow_rule
                    FROM VALUES
                        {%- for allow_rule in allow_rules -%}
                            ('{{ allow_rule }}')
                            {%- if not loop.last -%}
                                ,
                            {%- endif -%}
                        {% else %}
                            {{ exceptions.raise_compiler_error("No allow_rules given!") }}
                        {%- endfor -%}
                ),
                matches AS (
                    SELECT
                        deps.*,
                        allow_rules.*,
                        -- Matching should be case insensitive
                        REGEXP_LIKE(
                            deps.qualified_referenced_schema_name,
                            allow_rules.allow_rule,
                            'i') AS rule_match,
                        CASE WHEN rule_match THEN 1 ELSE 0 END AS rule_flag
                    FROM deps
                    LEFT JOIN allow_rules
                ),
                assertions AS (
                    SELECT
                        qualified_object_name,
                        qualified_referenced_schema_name,
                        max(rule_flag) AS rule_match,
                        listagg(CASE WHEN rule_match THEN allow_rule ELSE NULL END) AS matched_rules
                    FROM matches
                    GROUP BY 1, 2
                )
            SELECT
                qualified_object_name,
                listagg(qualified_referenced_schema_name, ', ') AS problem_references
            FROM assertions
            WHERE rule_match = 0
            GROUP BY qualified_object_name

        {%- endcall -%}

        {%- set dep_list = load_result('get_deps') -%}

        {%- if dep_list and dep_list['table'] -%}
            -- There should only be one row if there is any result
            {%- for row in dep_list['table'] -%}
                {{ exceptions.raise_database_error("Invalid Dependencides for view. Invalid dependencies: " ~ row[1] ~". Allowed patterns are: " ~ allow_rules) }}
            {% else %}
                select 'everything good' as result
            {%- endfor -%}
        {% else %}
            select 'everything good' as result
        {%- endif -%}
    {% else %}
        select 'everything good' as result
    {%- endif -%}

{% endmacro %}
