##### I NEED TWO FUNCTIONS:
# The first function loops through the models, where each
# is sequentially treated as the null model

# The second function applies the algorithm in Shibata to
# all the models conditional on the null.

# In addition, I need to keep track of the seeds, so that
# we use the same bootstrap sample in each set of comparisons

mcs_shapes_boot = function(z, nsim, seed = NULL, verbose = F) {
  t <- z$passed_params$t
  n <- z$passed_params$n
  y1 <- z$passed_params$y1
  lag <- z$passed_params$lag
  ceiling <- z$passed_params$ceiling
  if (!is.null(seed)) set.seed(seed)
  #seeds <- 1:nsim
  seeds <- sample.int(1e7, nsim)   
  nshape <- length(z$shape)
  
  zb <- list()
  zb$boot <- list()
  zb$kstar <- list()
  
  for (ii in 1:nshape ) {
    if (verbose) cat("boot null:", z$shape[[ii]]$name ,"\n")
    zb$boot[[ii]] <- bootstrap_shape_constraints(t, n, y1, lag, ceiling, z, nsim, ii, seeds, verbose)
    zb$kstar[[ii]] <- rep(NA, nshape)
    for (jj in 1:nshape) {
      zb$kstar[[ii]][[jj]] <- 
        mean(matrix(lapply(zb$boot[[ii]], function(x) x$Q10) %>% unlist, nrow = length(zb$boot[[ii]])) -
      matrix(lapply(zb$boot[[ii]], function(x) x$Q11) %>% unlist, byrow = T, nrow = length(zb$boot[[ii]]))[,jj])
    }
  }
  return(zb)
}

bootstrap_shape_constraints = function(t, n, y1, lag, ceiling, z, nsim, ii, seeds, verbose) {
  null_model <- z$shape[[ii]]$name
  null_mean <- z$model[[ii]]$mean
  null_fitted <- z$model[[ii]]$fitted
  models <- z$shape
  boot_out <- list()
  for (i in 1:nsim) {
    if (verbose & i%%50 == 0) cat("sim",i,"\n")
    set.seed(seeds[i])
    y1_b <- vector()
    y_b <- vector()
    
    for (tt in 1:length(t)) {
      y_b_tt <- rbinom(n[tt], 1, null_mean[tt])
      y_b_tt[1] <- ifelse(mean(y_b_tt) == 0, 1, y_b_tt[1])
      y_b_tt[1] <- ifelse(mean(y_b_tt) == 1, 0, y_b_tt[1])
      y_b <- c(y_b, y_b_tt)
      y1_b <- c(y1_b, sum(y_b_tt))
      rm(y_b_tt)
    }
    boot_out[[i]] <- list()
    zb <- mcs_shapes(t, n, y1_b, z$shape, lag, ceiling, boot = T)
    boot_out[[i]]$Q11 <- unlist(lapply(zb$model, function(x) x$Q))
    boot_out[[i]]$Q10 <- -2 * sum( y_b * log(null_fitted) + (1-y_b) * log(1-null_fitted))
    # if (verbose & !(min(y1_b/n) > 0 & max(y1_b/n) < 1)) {
    #   cat("warning -- invalid sample, y1_b/n in [", min(y1_b/n), ",",
    #       max(y1_b/n), "] \n")
    # }
    rm(y1_b, y_b)
  }
  return(boot_out)
}

