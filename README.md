## COVID-MCS

### Introduction

COVID-MCS is an R package that allows users to apply the model confidence set (MCS) hypothesis testing framework developed in Hansen et. al (2011) to public health data in an effort to test hypotheses surrounding questions about temporal trends in the data. See [Ganz (2020)](https://www.aei.org/profile/scott-c-ganz/) for more details on the implementation of the test, and the [Github](https://github.com/PSLmodels/COVID-MCS) for all underlying code.

### Why COVID-MCS?

Policymakers and public health researchers have had difficulty determining whether benchmarks surrounding trends in the intensity of the COVID-19 pandemic. One reason for the confusion is that commonly-used hypothesis testing methods, e.g., t-tests for mean comparisons or linear regression models, are poorly suited for questions about shapes of trends in data, e.g., “consistent decline”.

One hypothesis testing framework that is suitable to ask questions like “has a region experienced a specified number of days of declining COVID-19 cases?” applies the MCS framework to shape-constrained regression. Based on the output of the test, the analyst can determine whether the hypothesized shape is a good fit for the data -- in the model confidence set -- and whether alternative shapes inconsistent with the data are a bad fit -- i.e., not in the model confidence set.

These results can then be used to inform policy decisions about whether necessary public health criteria are satisfied to justify the phased reopening of the local economy.

### Using this web app
