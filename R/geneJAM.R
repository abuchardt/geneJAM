#' Cluster multiple traits via polygenic scores
#'
#' This function clusters traits that share some genetic component via polygenic scores (PSs). It fits a sparse precision matrix via graphical lasso. The regularisation path is computed for the lasso penalty at a grid of values for the regularisation parameter rho. The clusters are used to specify the structure of the error covariance matrix of a GLS model and the feasible GLS estimator is used for estimating the unknown parameters in a linear regression model with a certain unknown degree of correlation between the residuals.
#'
#' ...
#'
#' @param x Input matrix, of dimension nobs x nvars of PGSs with nvars = nouts. Can be in sparse matrix format.
#' @param y Quantitative response matrix, of dimension nobs x nouts.
#' @param rho (Non-negative) regularisation parameter for lasso passed to glasso. \code{rho=0} means no regularisation. Can be a scalar (usual) or a symmetric nouts by nouts matrix, or a vector of length nouts. In the latter case, the penalty matrix has jkth element sqrt(rho[j]*rho[k]).
#' @param nrho The number of rho values - default is 40.
#' @param logrho Logical flag for log transformation of the rho sequence. Default is \code{logrho = FALSE}.
#' @param rho.min.ratio Smallest value for rho, as a fraction of rho.max, the (data derived) entry value (i.e. the smallest value for which all coefficients are zero) - default is 10e-04.
#'
#' @return An object of class "geneJAM" is returned. \item{call}{The call that produced this object.} \item{xi}{A matrix of intercepts of dimension nouts x length(rho)} \item{beta}{A matrix of coefficients for the PSs of dimension nouts x length(rho)} \item{A}{A length(rho) list of estimated adjacency matrices A of 0s and 1s, where A_{ij} is equal to 1 iff edges i and j are adjacent and A_{ii} is 0.} \item{P}{A length(rho) list of estimated precision matrices (matrix inverse of correlation matrices).} \item{Sigma}{A length(rho) list of estimated correlation matrices.} \item{rho}{The actual sequence of rho values used.} \item{PS}{Polygenic scores used. If  \code{scores = FALSE} they are computed by \code{\link{ps.geneJAM}}} \item{logrho}{Logical flag for log transformation of the rho sequence. Default is \code{logrho = FALSE}.} \item{nobs}{Number of observations.} \item{xiStderr}{Standard error of coefficients \code{xi}.} \item{betaStderr}{Standard error of coefficients \code{beta}.} \item{betaSD}{Standard error of the mean of coefficients \code{beta} for clustered traits.} \item{betaSD0}{Standard error of the mean of all coefficients \code{beta}.} \item{rho.min}{Value of rho that gives minimum non-zero betaSD.}
#'
#' @examples
#' N <- 1000 #
#' q <- 10 #
#' p <- 1000 #
#' set.seed(1)
#' # Sample 1
#' X0 <- matrix(rbinom(n = N*p, size = 2, prob = 0.3), nrow=N, ncol=p)
#' B <- matrix(0, nrow = p, ncol = q)
#' B[1, 1:2] <- 1
#' B[3, 3] <- 2
#' y0 <- X0 %*% B + matrix(rnorm(N*q), nrow = N, ncol = q)
#' #y0 <- apply(y0, 2, scale)
#' beta <- ps.geneJAM(X0, y0)$beta
#' # Sample 2
#' X <- matrix(rbinom(n = N*p, size = 2, prob = 0.3), nrow=N, ncol=p)
#' y <- X %*% B + matrix(rnorm(N*q), nrow = N, ncol = q)
#' #y <- apply(y, 2, scale)
#' #Sigma <- diag(1, q)
#' #Sigma[1, 2] <- Sigma[2, 1] <- .8
#' #y <- X %*% B + MASS::mvrnorm(n = N, mu = rep(0, q), Sigma = Sigma)
#' x <- X %*% beta
#' #x <- MASS::mvrnorm(n = N, mu = rep(0, q), Sigma = diag(1, q))
#' ###
#' pc <- geneJAM(x, y)
#'
#' @export
#'

geneJAM <- function(x, y, rho = NULL,
                   nrho = ifelse(is.null(rho), 20, length(rho)),
                   logrho = FALSE,
                   rho.min.ratio = 10e-04
                   ) {

  this.call <- match.call()

  x <- as.matrix(x)
  y <- as.matrix(y)

  np <- dim(x)
  if (is.null(np) | (np[2] <= 1))
    stop("x should be a matrix with 2 or more columns")
  nobs <- as.integer(np[1])
  nvars <- as.integer(np[2])
  dimy <- dim(y)
  nrowy <- ifelse(is.null(dimy), length(y), dimy[1])
  nouts <- ifelse(is.null(dimy), 1, dimy[2])
  if (nrowy != nobs)
    stop(paste("number of observations in y (", nrowy, ") not equal to the number of rows of x (",
               nobs, ")", sep = ""))
  if (nvars != nouts)
    stop(paste("number of scores (", nvars, ") not equal to number of outcome components (", nouts, ")", sep = ""))
  vnames <- colnames(x)
  if (is.null(vnames))
    vnames <- paste("V", seq(nvars), sep = "")

  if (is.null(rho)) {
    if (rho.min.ratio >= 1)
      stop("rho.min.ratio should be less than 1")
    flmin <- as.double(rho.min.ratio)
    urho <- double(1)
  } else {
    nrho = as.integer(nrho)
    flmin <- as.double(1)
    if (any(rho < 0))
      stop("rhos should be non-negative")
    urho <- as.double(rev(sort(rho)))
    nrho <- as.integer(length(rho))
    rholist <- as.double(rho)
  }

  xScale <- scale(x, scale = FALSE) #apply(x, 2, scale) #
  #yScale <- apply(y, 2, scale) #y #scale(y) #

  ####################
  # STEP 2
  ####################
  # Covariance matrix (qxq) of PSs
  SigmaPS <- cov(xScale) # cor(x) # cov(x) #

  ## Covariance matrix (qxq) of NOISE
  #Omega <- SigmaPS - cov(yScale)

  # Calculate rho path (first get rho_max):
  if (is.null(rho)) {
    rho_max <- max(colSums(SigmaPS))
    rho_min <- min(abs(SigmaPS)) #rho_max*flmin,
    if(logrho == 0) {
      rholist <- round(seq(rho_min,
                           rho_max,
                           length.out = nrho), digits = 10)
    } else if (logrho == 1) {
      rholist <- round(exp(seq(log(rho_min),
                               log(rho_max),
                               length.out = nrho)), digits = 10)
    } else if (logrho == 2) {
      rholist <- round(log(seq(exp(rho_min),
                               exp(rho_max),
                               length.out = nrho)), digits = 10)
    }
  } else {
    rholist <- rho
  }


  # Graphical lasso
  # Estimates a sparse inverse covariance matrix using a lasso (L1) penalty
  #glPS <- glasso::glassopath(s = SigmaPS, rho = rholist,
  #                            penalize.diagonal = FALSE, trace = 0)
  glPS2 <- lapply(seq_along(rholist), FUN = function(r) {
    glasso::glasso(s = SigmaPS, rho = rholist[r],
                   penalize.diagonal = FALSE,
                   trace = 0)
  })

  rho <- rholist

  P <- lapply(seq_along(rho), function(r) glPS2[[r]]$wi)
  Sigma <- lapply(seq_along(rho), function(r) glPS2[[r]]$w)
  A <- lapply(seq_along(rho), function(r) {
    AA <- P[[r]]
    AA[abs(AA) > 1.5e-8] <- 1
    diag(AA) <- 0
    AA
  })

  xi <- matrix(NA, nouts, nrho)
  beta <- matrix(NA, nouts, nrho)
  xiStderr <- matrix(NA, nouts, nrho)
  betaStderr <- matrix(NA, nouts, nrho)

  summarylist <- vector(mode = "list", length = nrho)
  clusterlist <- vector(mode = "list", length = nrho)

  lmfit <- vector("list", length = nouts)
  res <- matrix(NA, nrow = nobs, ncol = nouts)
  for (l in seq(nouts)) {
    xl <- x[, l]
    lmfit[[l]] <- lm(y[ ,l] ~ xl)
    res[, l] <- resid(lmfit[[l]])
  }

  # 1.b
  yVec <- as.vector(t(y)) #as.vector(t(y[, members])) #as.vector(y) #
  #xVec <- as.vector(t(x[, members]))
  #xList0 <- lapply(apply(x, 1, as.list), unlist) #apply(x, 2, as.list)
  #xList <- #lapply(xList0, FUN = function(x) cbind(1, x[1]))
  xList <-  apply(x, 1, function(xi) Matrix::bdiag(lapply(xi, function(i) cbind(1, i))))
  xMat <- do.call(rbind, xList)
  rm(xList)



  betaSD <- vector("numeric", length = nrho)
  betaSD0 <- vector("numeric", length = nrho)
  NULLrho <- NULL #c()
  for (j in seq(nrho)) {

      lowerA <- A[[j]]
      lowerA[lower.tri(lowerA)] <- 0
      g  <- igraph::graph.adjacency(lowerA)
      clu <- clusterlist[[j]] <- igraph::components(g)

      # 2.
      fglsfit <- .fgls.geneJAM(res, nouts, clu, nobs, xMat, yVec, y)
      betaCov <- fglsfit$betaCov
      betaHat <- fglsfit$betaHat

      if (all(clu$csize == 1)) {
        betaSD[j] <- sqrt(mean(Matrix::diag(betaCov)[c(FALSE, TRUE)]))
      } else {
        groupedTraits <- which(clu$membership %in% which(clu$csize > 1))
        betaSD[j] <- sqrt(mean(Matrix::diag(betaCov)[c(FALSE, TRUE)][groupedTraits]))
      }

      betaSD0[j] <- sqrt(mean(Matrix::diag(betaCov)[c(FALSE, TRUE)]))

      xi[, j] <- betaHat[c(TRUE, FALSE)]
      beta[, j] <- betaHat[c(FALSE, TRUE)]
      xiStderr[, j] <- sqrt(Matrix::diag(betaCov)[c(TRUE, FALSE)])
      betaStderr[, j] <- sqrt(Matrix::diag(betaCov)[c(FALSE, TRUE)])

      if (all(lowerA == 0)) break

  }

  fit <- list(call = this.call,
              clusters = clusterlist,
              A = A, P = P, Sigma = Sigma,
              rho = rho, PS = x, logrho = logrho,
              nobs = nobs,
              xi = xi, beta = beta,
              xiStderr = xiStderr,
              betaStderr = betaStderr,
              betaSD = betaSD,
              betaSD0 = betaSD0)

      idx <- which(fit$betaSD > 0)
      fit$rho.min <- fit$rho[which.min(fit$betaSD[idx])]

  class(fit) <- "geneJAM"
  fit
}

#' @export
#'
#'
.fgls.geneJAM <- function(res, nouts, clu, nobs, xMat, yVec, y) {
  newres <- res
  for (iter in 1:10) {

    covMat <- matrix(0, nouts, nouts)
    for (m in seq(clu$no)) {
      csize <- clu$csize[m]
      members <- which(clu$membership == m)
      if (csize > 1) {
        covMat[members, members] <- cov(newres[, members])
      } else {
        covMat[members, members] <- var(newres[, members])
      }
    }

    invMat <- Matrix::Matrix(solve(covMat))
    OmegaInv <- Matrix::bdiag(replicate(nobs, invMat))

    b1 <- Matrix::crossprod(xMat, OmegaInv) %*% xMat
    b2 <- solve(b1)
    betaHat <- Matrix::tcrossprod(b2, xMat) %*% OmegaInv %*% yVec

    # Convergence
    newres <- y - matrix(xMat %*% betaHat, ncol = nouts, byrow = TRUE)

    if (iter > 1) {
      thr <- abs(Matrix::mean(betaHat - oldbetaHat))
    }
    oldbetaHat <- betaHat
    if (iter > 1 && thr < 1e-6) break
  }

  betaCov <- Matrix::solve(Matrix::crossprod(xMat, OmegaInv) %*% xMat)

  return(list(betaCov = betaCov, betaHat = betaHat))
}
