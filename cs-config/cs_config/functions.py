# Write or import your Compute Studio functions here.
import inspect
import os
import json
import traceback
import paramtools
from COVID_MCS.COVID_MCS import COVID_MCS_TEST, COVID_MCS_PARAMETERS
import COVID_MCS


def get_version():
    version = COVID_MCS.__version__
    return f"COVID_MCS v{version}"


def get_inputs(meta_param_dict):

    """
    Return default COVID-MCS parameters

    """


    model_params = COVID_MCS_PARAMETERS()
    model_params.specification(serializable = True)

    model_params = model_params.dump()

    default_params = {
        "Model Parameters": model_params
    }


    return({"meta_parameters" : {}, "model_parameters" : default_params})


def validate_inputs(meta_param_dict, adjustment, errors_warnings):
    params = COVID_MCS_PARAMETERS()
    params.adjust(adjustment['Model Parameters'], raise_errors = False)

    errors_warnings['Model Parameters']['errors'].update(params.errors)

    return {"errors_warnings": errors_warnings}


def run_model(meta_param_dict, adjustment):

    params = COVID_MCS_PARAMETERS()
    params.adjust(adjustment['Model Parameters'])

    c = COVID_MCS_TEST(adjustment = params)
    model_output = c.MCS_Test()

    to_print = model_output.to_html()

    out = {
        "renderable": [{
            "media_type": "table",
            "title": "My Table",
            "data": to_print
        }],
        "downloadable": [{
            "media_type": "CSV",
            "title": "My Table",
            "data": model_output.to_csv()
        }]
    }

    return(out)
