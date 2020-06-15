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
from bokeh.plotting import figure, show
from bokeh.embed import json_item
from bokeh.io import curdoc, show
from bokeh.models import Circle, ColumnDataSource, Grid, LinearAxis, Plot


# Install packages if they are not already installed
# utils.install_packages("quadprog", repos = "https://cloud.r-project.org")
# utils.install_packages("lubridate", repos = "https://cloud.r-project.org")
# utils.install_packages("dplyr", repos = "https://cloud.r-project.org")

utils = rp.importr("utils")
base = rp.importr("base")
dplyr = rp.importr("dplyr")

shape_dict = {
    'unr' : 'Unrestricted',
    'dec' : 'Decreasing',
    'dec_cei' : 'Decreasing with ceiling',
    'inc' : 'Increasing',
    'inc_cei' : 'Increasing with ceiling',
    'cei' : 'Ceiling constraint',
    'ius' : 'Inverse U-Shape',
    'ius_cei' : 'Inverse U-Shape with ceiling',
    'con' : 'Constant',
    'con_cei' : 'Constant with ceiling'

}


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
    ADJ_PATH = os.path.join(CURRENT_PATH, 'adjustment_file.json')

    def __init__(self, adjustment = ADJ_PATH):
        self.params = COVID_MCS_PARAMETERS()
        self.adjustment = adjustment
        self.params.adjust(self.adjustment)

    def MCS_Test(self):
        nested = self.params.Nested[0].get('value')
        shapes = self.params.Shapes[0].get('value').split(', ')
        shapes.insert(0,'unr')
        tshapes = shapes

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

        if nested:
            nest = ro.vectors.BoolVector([True])
        else:
            nest = ro.vectors.BoolVector([False])


        # Intitalize R object and source main
        r1 = ro.r
        r1['source'](mcs_shapes)
        z = r1['mcs_shapes'](t = ro.IntVector(t), n =  ro.IntVector(n), y1 = ro.IntVector(y1),
                             shape=  ro.StrVector(shapes), ceiling = float(ceil), lag = float(lag))
        zb = r1['mcs_shapes_boot'](z = z, nsim = float(nsim), seed = seed)
        m = r1['mcs_shapes_test'](z, zb, nested = nest, alpha = alpha)
        rdf = r1['summary'](m)


        # Convert R DataFrame to Pandas DataFrame
        with localconverter(ro.default_converter + pandas2ri.converter):
            pdf = ro.conversion.rpy2py(m)
        output = dict(zip(pdf.names, map(list,list(pdf))))

        with localconverter(ro.default_converter + pandas2ri.converter):
            pdf = ro.conversion.rpy2py(rdf)

        with localconverter(ro.default_converter + pandas2ri.converter):
            means = ro.conversion.rpy2py(z)
        means = dict(zip(means.names, map(list,list(means))))


        # Get the shapes that were rejected
        rejected_shapes = []
        for i in tshapes :
            if i not in output['Mstar'] :
                rejected_shapes.append(i)

        to_print = 'Testing at level ' + str(output['alpha'][0]) + ' with ' + str(output['B'][0]) + ' bootstraps' + \
            '<br><br>' + ' The final models in the model confidence set (MCS) are '


        for i in output['Mstar'] :
            to_print = to_print + shape_dict.get(i) + " "


        if len(rejected_shapes) > 0:

            to_print = to_print + "<br> The test was able to reject the following shapes at a confidence level of " + str(alpha) +  ": <br> "

            x = 0

            for i in rejected_shapes :
                if x == 0:
                    to_print = to_print + shape_dict.get(i)
                    x+=1
                elif x == len(rejected_shapes):
                    to_print = to_print + ", " + shape_dict.get(i) + "."
                else:
                    to_print = to_print + ", " + shape_dict.get(i)
                    x+=1



        if len(tshapes) == 4 and 'unr' in tshapes and 'con' in tshapes and 'ius' in tshapes and 'dec' in tshapes:
            if 'dec' in output['Mstar'] and 'con' in rejected_shapes:
                to_print = to_print + "<br> Because the decreasing model is in the MCS and the constant model is excluded, the data <b>are</b> well-characterized by a "\
                +  str(len(lst)) + " day sustained decline at a confidence level of " + str(alpha) + "."
            elif 'con' in output['Mstar'] :
                to_print = to_print + "<br> Because the constant model is included in the model confidence set, the data <b>are not</b> well-characterized by a "\
                +  str(len(lst)) + " day sustained decline at a confidence level of " + str(alpha) + "."
            elif 'dec' not in output['Mstar']:
                to_print = to_print + "<br> Because the decreasing model is not included in the model confidence set, the data <b>are not</b> well-characterized by a "\
                +  str(len(lst)) + " day sustained decline at a confidence level of " + str(alpha) + "."


        to_print = to_print + '<br><br> The following table describes how the MCS was derived, where each iteration of the test drops the poorest performing model(s):<br>'
        to_print = to_print + pdf.to_html(index = False)

        # Now make the graphs
        plot_list = []

        model_means = pd.DataFrame()

        unr = means.get('model')[0]
        with localconverter(ro.default_converter + pandas2ri.converter):
            unr = ro.conversion.rpy2py(unr)
        unr = dict(zip(unr.names, map(list,list(unr))))
        unr = unr.get('mean')

        model_means['Daily Avg.'] = unr
        # Create plots for each user-inputted shape:
        for i in list(range(1,len(tshapes))):
            print("HERE" + str(i))
            mod = means.get('model')[i]
            with localconverter(ro.default_converter + pandas2ri.converter):
                mod = ro.conversion.rpy2py(mod)
            mod = dict(zip(mod.names, map(list,list(mod))))
            mod = mod.get('mean')

            model_means[shape_dict.get(tshapes[i])] = mod

            t = list(range(1,len(mod) + 1))

            N = len(mod)
            x = t
            y = mod
            sizes = np.linspace(20, 20, N)
            source = ColumnDataSource(dict(x=x, y=y, sizes=sizes))

            p = figure(title= shape_dict.get(tshapes[i]), x_axis_label='Day', y_axis_label='COVID-19 Positive Test Rate')
            p.cross(t, unr, size = 30, color = "black", line_width=3)

            glyph = Circle(x="x", y="y", size="sizes", line_color="red", fill_color="white", line_width=3)
            p.add_glyph(source, glyph)

            p.line(t, unr, legend_label="Daily avg.", line_width=2, color = "black")
            p.line(t, mod, legend_label=shape_dict.get(tshapes[i]), line_width=2, color = "red")
            p.cross(t, unr, size = 30, color = "black", line_width=3)

            j = json_item(p)
            to_append = {
                "media_type" : "bokeh",
                "title" : shape_dict.get(tshapes[i]),
                "data" : j
            }
            plot_list.append(to_append)

        return to_print, model_means, plot_list
