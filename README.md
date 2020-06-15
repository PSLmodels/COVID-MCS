
## COVID-MCS

### Introduction

COVID-MCS is an R package that allows users to apply the model confidence set (MCS) hypothesis testing framework developed in Hansen et. al (2011) to public health data in an effort to test hypotheses surrounding questions about temporal trends in the data. See [Ganz (2020)](https://www.aei.org/profile/scott-c-ganz/) for more details on the implementation of the test.
### Why COVID-MCS?

Policymakers and public health researchers have had difficulty determining whether benchmarks surrounding trends in the intensity of the COVID-19 pandemic. One reason for the confusion is that commonly-used hypothesis testing methods, e.g., t-tests for mean comparisons or linear regression models, are poorly suited for questions about shapes of trends in data, e.g., “consistent decline”.

One hypothesis testing framework that is suitable to ask questions like “has a region experienced a specified number of days of declining COVID-19 cases?” applies the MCS framework to shape-constrained regression. Based on the output of the test, the analyst can determine whether the hypothesized shape is a good fit for the data -- in the model confidence set -- and whether alternative shapes inconsistent with the data are a bad fit -- i.e., not in the model confidence set.

These results can then be used to inform policy decisions about whether necessary public health criteria are satisfied to justify the phased reopening of the local economy.

### Applying the test to your own data

#### Analyze data from your web browser

* The easiest way to apply this methodology is to use the web application hosted on [Compute Studio](https://compute.studio/PSLmodels/COVID-MCS/).

#### Analyze data using your own computer

* The methodology can be used on your personal computer by using either R or Python.

##### Installing COVID-MCS

* To install COVID-MCS, run the following in the folder you wish to store the files:
```
git clone https://github.com/PSLmodels/COVID-MCS
cd COVID-MCS
pip install -e .
```

##### Using R

* All necessary functions can be called from ```COVID-MCS/main.R```. View a summary of the test by called ```summary(m)```.

##### Using Python

* Modify the default values defined in ```COVID-MCS/defaults.json``` in ```COVID-MCS/adjustment_file.json```.
* Create an instance of the ```COVID_MCS_TEST``` class by calling ```c = COVID_MCS_TEST()```.
* Return the summary text and graphs by calling ```summary, graphs = c.MCS_Test()```
