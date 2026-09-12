{# CHANGE LOG (2026-09-12)
   CHANGED : this file held a second copy of log_model_end, which stopped
             dbt parsing the project. It now holds log_model_start, moved
             unchanged from mark_failed_jobs.sql.
   CHANGED : app_name is looked up from model.config.schema (the folder-level
             +schema in dbt_project.yml) instead of model.schema, as in the
             cigma project. model.schema is only the target's default schema
             when the pre_hook is built, and Snowflake's deploy-time compile
             did not find it in app_name_by_schema ("Missing required
             app_name" in CD). #}

{% macro log_model_start(model_name, autosys_job_name) %}

    {# stop the run if not provided #}
    {% if not autosys_job_name  or (autosys_job_name | trim) == '' %}
        {{exceptions.raise_compiler_error(
            "Mising required autosys_job_name for this model"
        )
        }}
    {% endif %}

    {# app_name for table name (from folder +vars fallback)#}
    {{ log("app_name= " ~ var('app_name_by_schema').get(model.config.schema) , info= True)}}
    {% set app_name= var('app_name_by_schema').get(model.config.schema | upper) %}

    {% if app_name is none %}
         {{exceptions.raise_compiler_error(
            "Missing required app_name for this model: schema '" ~ model.config.schema
            ~ "' is not a key in app_name_by_schema"
        )
        }}
    {% endif %}   

    {% set exec_table = model.database ~ '.METADATA.' ~ app_name ~ '_JOB_EXECUTION'%}


    insert into {{exec_table}} (
        JOB_NAME,
        AUTOSYS_JOB_NAME,
        JOB_STATUS,
        START_TIMESTAMP,
        END_TIMESTAMP,
        ROW_CREATE_TIMESTAMP,
        ROW_UPDATE_TIMESTAMP,
        SOURCE_OBJECT,
        TARGET_OBJECT,
        RECORDS_PROCESSED,
        ERROR_MESSAGE
        )

    values (
        '{{model_name.name}}',
        '{{autosys_job_name}}',
        'STARTED',
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ,
        NULL,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ,
        NULL,
        NULL,
        NULL,
        NULL);


{% endmacro %}




