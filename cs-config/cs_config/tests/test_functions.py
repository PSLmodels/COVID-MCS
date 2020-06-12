from cs_kit import CoreTestFunctions

from cs_config import functions


class TestFunctions1(CoreTestFunctions):
    get_version = functions.get_version
    get_inputs = functions.get_inputs
    validate_inputs = functions.validate_inputs
    run_model = functions.run_model
    ok_adjustment = {
        "Model Parameters" : {
               "Tests":[
                 {"value" : [[500, 100], [500, 300], [500, 200], [500, 100]]}
               ]
        }
    }
    bad_adjustment = {
      "Model Parameters" :
      {
      "Days": [
        {"value" : True}
      ]
      }
    }
