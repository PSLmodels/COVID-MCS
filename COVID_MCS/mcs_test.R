f.maxij = function(x) max(abs(outer(x,x,'-')))

mcs_shapes_test = function(z, zb, alpha, nested, verbose = F) {
  M <- M0 <- length(zb$boot)          #M0 = how many models, M is a counter
  models <- models0 <- unlist(lapply(z$shape,function(z) z$name )) #names of models
  model.ix <- 1:M
  B <- length(zb$boot[[1]])      #how many bootstraps
  mcs_output <- NULL                    #what we return
  
  p.mcs <- 0    #p.value of model set, starts at zero
  iter <- 0     #iteration      
  
  while(M > 1) {
    ## models assumed to be ordered by decreasing restrictiveness, and nested
    which.null <- min(model.ix)
    ## offset for picking kstar
    ## kstar is a (M0 * M0) length vector
    ## each set of M0 is based on a different null model / simulation
    off <- (which.null-1) * M0
    ## as such QL differs depending on which null model is currently "best"
    #    print(off)
    #    print(model.ix)
    #    print( z$model[[1]]$Q)
    #    print( z$model[[2]]$Q)    
    #    print( unlist(lapply(z$model, function(x) x$Q)) )
    #    print( unlist(lapply(z$model, function(x) x$Q))[model.ix] )
    #    print( unlist(x$kstar)[off + model.ix] )
    
    if (nested == TRUE) {
      kstar <- unlist(zb$kstar)[off + model.ix]
      QL <- unlist(lapply(z$model, function(xx) xx$Q))[model.ix] + kstar
    } else {
      kstar <- (matrix(unlist(zb$kstar), nrow = M0, byrow = T) %>% diag())
      QL <- unlist(lapply(z$model, function(xx) xx$Q))[model.ix] + kstar[model.ix]
    }
    
    QB <- NULL
    for (jj in model.ix) {
      if (nested == TRUE) {
        QB<- cbind(QB,
                   unlist(lapply(zb$boot[[which.null]], function(xx) xx$Q11[[jj]])) +
                     rep(zb$kstar[[which.null]][jj] ))
      } else {
        QB<- cbind(QB,
                   unlist(lapply(zb$boot[[jj]], function(xx) xx$Q11[[jj]])) +
                     rep(kstar[jj]) - unlist(lapply(zb$boot[[jj]], function(xx) xx$Q10)))
      }
    }
    Trm <- f.maxij(QL)
    Trmb<- apply( QB, 1, f.maxij )
    n.ho<- sum(Trmb + .0001 >= Trm)
    p.ho <- mean(Trmb + .0001 >= Trm)
    worst <- which.max(QL)
    drop <- models[worst]
    
    if (verbose == T) {
      cat("MAX\n")
      print(QL)
      print(apply(QB,2,range))
      cat("Trm",round(Trm,2),"\n")
      cat("Trmb\n")
      print(round(summary(Trmb),2))
      cat("p.ho",p.ho,"n.ho",n.ho,"\n")
    }
    
    if (p.ho > alpha) {
      drop <- ""
    }
    ##Step 3c
    if (verbose) cat(iter," & ",p.ho," & ",paste(models,collapse=",")," & ",drop,"\n" )
    
    iter <- iter+1
    p.mcs <- max(p.mcs, p.ho)  ##p.mcs is cumulative largest of p.ho
    
    ##Step 3d
    if (p.ho <= alpha) {
      models <- models[-worst]
      model.ix <- model.ix[-worst]
      QL <- QL[-worst]
      QB <- QB[,-worst]
      M <- M-1
    } 
    
    
    
    rr <- data.frame(
      iter=iter,
      "N"=n.ho,
      "P(H0)"=p.ho,
      "P(MCS)"=p.mcs,
      "MCS"=paste(models,sep="",collapse=", "),
      "Model Drop" = drop )
    mcs_output <- rbind( mcs_output, rr )
    
    if (p.ho > alpha)
      break
  }
  
  if (verbose) cat ("Best models are: ", models, "\n")
  
  ##return summary, and other info that could be printed
  info <- list(B=B, alpha=alpha, nmodels=M0,
               M0=models0, Mstar=models,
               Mstar.ix = model.ix,
               summary=mcs_output, 
               p.mcs=p.mcs, p.ho=p.ho)
  class(info) <- "mcs"
  return(info)
}

summary.mcs <- function(y) {
  cat("Testing at level", y$alpha, "with", y$B, "bootstraps\n\n")
  cat("Final models: \n")
  print(y$Mstar)
  
  cat("\n Summary: \n")
  print(y$summary)
}
