import sys
import os
import json
import numpy as np
import pandas as pd
import sys
import paramtools
import rpy2.robjects as ro
import rpy2.robjects.packages as rp
from rpy2.robjects import pandas2ri
from rpy2.robjects.conversion import localconverter
import warnings
import io
import contextlib


# Install packages if they are not already installed
# utils.install_packages("quadprog", repos = "https://cloud.r-project.org")
# utils.install_packages("lubridate", repos = "https://cloud.r-project.org")
# utils.install_packages("dplyr", repos = "https://cloud.r-project.org")

utils = rp.importr("utils")
base = rp.importr("base")
dplyr = rp.importr("dplyr")


def Extract(lst, n):
    return [item[n] for item in lst]


CURRENT_PATH = os.path.abspath(os.path.dirname(__file__))
mcs_shapes = os.path.join(CURRENT_PATH, "main.R")


class COVID_MCS_PARAMETERS(paramtools.Parameters) :
    defaults = os.path.join(CURRENT_PATH, "defaults.json")

class COVID_MCS_TEST:
    """
    Parameters:

    adjustment_file: a json file with adjusted parameters.

    """
    ADJ_PATH = os.path.join(CURRENT_PATH, "adjustment_file.json")

    def __init__(self, adjustment = ADJ_PATH):
        self.params = COVID_MCS_PARAMETERS()
        self.adjustment = adjustment
        self.params.adjust(self.adjustment)

    def MCS_Test(self):
        nested = self.params.Nested[0].get('value')
        shapes = self.params.Shapes[0].get('value').split(', ')
        lst = self.params.Tests[0].get('value')
        n = Extract(lst, 0)
        n = list(map(int, n))
        y1 = Extract(lst, 1)
        y1 = list(map(int, y1))
        t = list(range(1,len(n) + 1))
        alpha = self.params.Alpha[0].get('value')
        alpha = float(alpha)
        ceil = np.float64(self.params.Ceil[0].get('value'))
        lag = self.params.Lag[0].get('value')
        seed = self.params.Seed[0].get('value')
        seed = float(seed)
        nsim = self.params.nsim[0].get('value')
        if seed == 0:
            seed = ro.r("NULL")

        # Intitalize R object and source main
        r1 = ro.r
        r1['source'](mcs_shapes)



        z = r1['mcs_shapes'](t = ro.IntVector(t), n =  ro.IntVector(n), y1 = ro.IntVector(y1),
                             shape=  ro.StrVector(shapes), ceiling = float(ceil), lag = float(lag))
        zb = r1['mcs_shapes_boot'](z = z, nsim = float(nsim), seed = seed)
        m = r1['mcs_shapes_test'](z, zb, nested = False, alpha = alpha)


        # Convert R DataFrame to Pandas DataFrame
        with localconverter(ro.default_converter + pandas2ri.converter):
            pdf = ro.conversion.rpy2py(m)

        output = dict(zip(pdf.names, map(list,list(pdf))))



        rdf = r1['summary'](m)
        # Convert R DataFrame to Pandas DataFrame
        with localconverter(ro.default_converter + pandas2ri.converter):
            pdf = ro.conversion.rpy2py(rdf)


        return output, pdf


c = COVID_MCS_TEST()
c.MCS_Test()
