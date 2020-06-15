##### LOAD PACKAGES
capture.output(require(dplyr))
capture.output(require(lubridate))

#### SET WORKING DIRECTORY TO SOURCE FILE LOCATION
dir <- dirname(parent.frame(2)$ofile)
setwd(dir)

##### LOAD HELPER FUNCTIONS
source("mcs_shapes.R")
source("mcs_shapes_boot.R")
source("mcs_test.R")

##### UPLOAD DATA
# t = NULL
# n = NULL
# y1 = NULL
# shape = NULL # c("con_cei", "dec_cei", "ius_cei", "cei", "unr")
# nsim = NULL # 1000

##### STEP 1: ESTIMATE MODELS ON SAMPLE
# z <- mcs_shapes(t, n, y1, shape)

##### STEP 2: CALCULATE K-STAR CONDITIONAL ON NULL
# zb <- mcs_shapes_boot(z, nsim)

##### STEP 3: RUN MCS FRAMEWORK
# m <- mcs_shapes_test(z, zb, alpha)

# summary(m)