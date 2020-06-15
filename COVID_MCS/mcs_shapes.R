require(quadprog)

# COUNTER FOR NUMBER OF FREE PARAMETERS

nstep = function(x) sum(abs(diff(x)) > .0001) + 1

# CREATE DIFFERENCING MATRIX

matrix_diff = function(N, lag) {
  x <- matrix(0, nrow = (N - lag), ncol = N)
  x[ cbind(1:(N-lag), 1:(N-lag)) ] <- -1
  x[ cbind(1:(N-lag), (lag+1):(N)) ] <- 1
  return(x)
}

# BEST FIT IUS

best_ius = function(X, y, R, N, lag) {
  a <- rep(1, N-lag)
  b <- 1:(N-lag)
  ius <- list()
  best.fit <- Inf
  for (i in 1:N) {
    d <- a
    d[ b >= i]  <- -1
    R2 <- R * matrix(d,nrow=N-lag,ncol=N )
    tmp <- solve.QP( Dmat = t(X) %*% X, dvec = t(y) %*% X, Amat = t(R2))
    tmp.fit <- sum( (y - as.vector(X %*% tmp$solution) )^2 )
    if (tmp.fit < best.fit) {
      ius <- tmp
      best.fit <- tmp.fit
    }
  }
  return(ius)
}

best_ius_cei = function(X, y, R, N, lag, ceiling) {
  a <- rep(1, N-lag)
  b <- 1:(N-lag)
  ius <- list()
  best.fit <- Inf
  for (i in 1:N) {
    d <- a
    d[ b >= i]  <- -1
    R2 <- R * matrix(d,nrow=N-lag,ncol=N )
    tmp <- solve.QP( Dmat = t(X) %*% X, dvec = t(y) %*% X, 
                     Amat = cbind(t(R2), -diag(N)),
                     bvec = c(rep(0, nrow(R)), rep(-ceiling, N)))
    tmp.fit <- sum( (y - as.vector(X %*% tmp$solution) )^2 )
    if (tmp.fit < best.fit) {
      ius <- tmp
      best.fit <- tmp.fit
    }
  }
  return(ius)
}



mcs_shapes = function(t, 
                                n, 
                                y1, 
                                shape = "dec", 
                                lag = 1, 
                                ceiling = 1,
                                boot = F) {
  # if (debug) cat("--- in fit_shape_constraint ---\n")
  
  # CONVERTS STRINGS AND STRING VECTORS TO LISTS FOR PROCESSING
  
  if (typeof(shape)=="character")  {
    vshape <- shape
    shape  <- list()
    for (ii in 1:length(vshape)) {
      shape[[ii]] <- list(type=vshape[ii],
                          name = vshape[ii])
    }
  }
  
  
  # if (debug) cat("--- extract shape ---\n")
  
  # EXTRACT NECESSARY INFORMATION
  N <- length(t)
  p_t <- y1/n
  p <- sum(y1)/sum(n)

  # CREATE 'X' MATRIX, 'y' VECTOR
  X <- matrix(0, nrow = sum(n), ncol = length(t))
  y <- vector()
  
  for (i in 1:length(t)) {
    X[(cumsum(c(0,n)) + 1)[i]:cumsum(n)[i], i] <- 1
    y <- c(y, rep(1, y1[i]), rep(0, n[i] - y1[i]))
  }
  
  R <- matrix_diff(N, lag = lag)
  model_output <- list()
  model_output$shape <- shape
  model_output$model <- list()

  for (ii in 1:length(shape)) {
    model_output$model[[ii]] <- list()
    
    # FIT SHAPES
    
    if ("con" == shape[[ii]]$type) {
      model_output$model[[ii]]$mean <- rep(p, N)
      model_output$model[[ii]]$df <- 1
      model_output$model[[ii]]$fitted <- p_hat <- rep(model_output$model[[ii]]$mean, n)
      model_output$model[[ii]]$Q <- -2 * sum(y * log(p_hat) + (1-y) * log(1-p_hat))
      rm(p_hat)
    }
    
    if ("con_cei" == shape[[ii]]$type) {
      model_output$model[[ii]]$mean <- rep(ifelse(p > ceiling, ceiling, p), N)
      model_output$model[[ii]]$df <- 1
      model_output$model[[ii]]$fitted <- p_hat <- rep(model_output$model[[ii]]$mean, n)
      model_output$model[[ii]]$Q <- -2 * sum(y * log(p_hat) + (1-y) * log(1-p_hat))
      rm(p_hat)
    }
    
    if ("inc" == shape[[ii]]$type) {
      model_output$model[[ii]] <- solve.QP( Dmat = t(X) %*% X, dvec = t(y) %*% X, Amat = t(R))
      model_output$model[[ii]]$mean <- model_output$model[[ii]]$solution
      model_output$model[[ii]]$df <- nstep(model_output$model[[ii]]$solution)
      model_output$model[[ii]]$fitted <- p_hat <- rep(model_output$model[[ii]]$mean, n)
      model_output$model[[ii]]$Q <- -2 * sum(y * log(p_hat) + (1-y) * log(1-p_hat))
      rm(p_hat)
    }
    
    if ("inc_cei" == shape[[ii]]$type) {
      model_output$model[[ii]] <- solve.QP( Dmat = t(X) %*% X, 
                                            dvec = t(y) %*% X, 
                                            Amat = cbind(t(R), -diag(N)),
                                            bvec = c(rep(0, nrow(R)), rep(-ceiling, N)))
      model_output$model[[ii]]$mean <- model_output$model[[ii]]$solution
      model_output$model[[ii]]$df <- nstep(model_output$model[[ii]]$solution)
      model_output$model[[ii]]$fitted <- p_hat <- rep(model_output$model[[ii]]$mean, n)
      model_output$model[[ii]]$Q <- -2 * sum(y * log(p_hat) + (1-y) * log(1-p_hat))
      rm(p_hat)
    }
    
    
    if ("dec_cei" == shape[[ii]]$type) {
      model_output$model[[ii]] <- solve.QP( Dmat = t(X) %*% X, 
                                            dvec = t(y) %*% X, 
                                            Amat = cbind(t(-1*R), -diag(N)),
                                            bvec = c(rep(0, nrow(R)), rep(-ceiling, N)))
      model_output$model[[ii]]$mean <- model_output$model[[ii]]$solution
      model_output$model[[ii]]$df <- nstep(model_output$model[[ii]]$solution)
      model_output$model[[ii]]$fitted <- p_hat <- rep(model_output$model[[ii]]$mean, n)
      model_output$model[[ii]]$Q <- -2 * sum(y * log(p_hat) + (1-y) * log(1-p_hat))
      rm(p_hat)
    }
    
    
    if ("dec" == shape[[ii]]$type) {
      model_output$model[[ii]] <- solve.QP( Dmat = t(X) %*% X, dvec = t(y) %*% X, Amat = t(-1*R))
      model_output$model[[ii]]$mean <- model_output$model[[ii]]$solution
      model_output$model[[ii]]$df <- nstep(model_output$model[[ii]]$solution)
      model_output$model[[ii]]$fitted <- p_hat <- rep(model_output$model[[ii]]$mean, n)
      model_output$model[[ii]]$Q <- -2 * sum(y * log(p_hat) + (1-y) * log(1-p_hat))
      rm(p_hat)
    }
    
    if ("ius_cei" == shape[[ii]]$type) {
      model_output$model[[ii]] <- best_ius_cei(X, y, R, N, lag, ceiling)
      model_output$model[[ii]]$mean <- model_output$model[[ii]]$solution
      model_output$model[[ii]]$df <- nstep(model_output$model[[ii]]$solution)
      model_output$model[[ii]]$fitted <- p_hat <- rep(model_output$model[[ii]]$mean, n)
      model_output$model[[ii]]$Q <- -2 * sum(y * log(p_hat) + (1-y) * log(1-p_hat))
      rm(p_hat)
    }
    
    
    if ("ius" == shape[[ii]]$type) {
      model_output$model[[ii]] <- best_ius(X, y, R, N, lag)
      model_output$model[[ii]]$mean <- model_output$model[[ii]]$solution
      model_output$model[[ii]]$df <- nstep(model_output$model[[ii]]$solution)
      model_output$model[[ii]]$fitted <- p_hat <- rep(model_output$model[[ii]]$mean, n)
      model_output$model[[ii]]$Q <- -2 * sum(y * log(p_hat) + (1-y) * log(1-p_hat))
      rm(p_hat)
    }
    
    if ("cei" == shape[[ii]]$type) {    
      model_output$model[[ii]] <- solve.QP( Dmat = t(X) %*% X, dvec = t(y) %*% X, Amat = -diag(N),
                                            bvec = rep(-ceiling, N))
      model_output$model[[ii]]$mean <- model_output$model[[ii]]$solution
      model_output$model[[ii]]$df <- nstep(model_output$model[[ii]]$solution)
      model_output$model[[ii]]$fitted <- p_hat <- rep(model_output$model[[ii]]$mean, n)
      model_output$model[[ii]]$Q <- -2 * sum(y * log(p_hat) + (1-y) * log(1-p_hat))
      rm(p_hat)
    }
    
    if ("unr" == shape[[ii]]$type) {    
      model_output$model[[ii]]$mean <- p_t
      model_output$model[[ii]]$df <- length(model_output$model[[ii]]$mean)
      model_output$model[[ii]]$fitted <- p_hat <- rep(model_output$model[[ii]]$mean, n)
      model_output$model[[ii]]$Q <- -2 * sum(y * log(p_hat) + (1-y) * log(1-p_hat))
      rm(p_hat)
    }
  }
  
  if(!boot) {
    model_output$passed_params <- list(t = t,
                                n = n,
                                y1 = y1,
                                lag = lag,
                                ceiling = ceiling)
  }
  
  return(model_output)
}
  

