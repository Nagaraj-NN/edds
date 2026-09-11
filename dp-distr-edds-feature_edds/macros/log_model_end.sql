{% macro log_model_end(model_name, autosys_job_name) %}

    {% set app_name = var('app_name_by_schema').get(model.schema | upper) %}
    {% set exec_table = model.database ~ '.METADATA.' ~ app_name ~ '_JOB_EXECUTION' %}
    

    update {{ exec_table }}
    set
        JOB_STATUS = 'COMPLETED',
        END_TIMESTAMP = current_timestamp()::timestamp_ntz,
        ROW_UPDATE_TIMESTAMP = current_timestamp()::timestamp_ntz
    WHERE 
        job_name = '{{ model_name.name }}'
        AND autosys_job_name = '{{ autosys_job_name }}'
        AND job_status = 'STARTED'
        AND END_TIMESTAMP IS NULL;

{% endmacro %}