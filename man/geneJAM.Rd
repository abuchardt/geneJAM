% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geneJAM.R
\name{geneJAM}
\alias{geneJAM}
\title{Cluster multiple traits via polygenic scores}
\usage{
geneJAM(
  x,
  y,
  rho = NULL,
  nrho = ifelse(is.null(rho), 20, length(rho)),
  logrho = FALSE,
  rho.min.ratio = 0.001
)
}
\arguments{
\item{x}{Input matrix, of dimension nobs x nvars of PGSs with nvars = nouts. Can be in sparse matrix format.}

\item{y}{Quantitative response matrix, of dimension nobs x nouts.}

\item{rho}{(Non-negative) regularisation parameter for lasso passed to glasso. \code{rho=0} means no regularisation. Can be a scalar (usual) or a symmetric nouts by nouts matrix, or a vector of length nouts. In the latter case, the penalty matrix has jkth element sqrt(rho[j]*rho[k]).}

\item{nrho}{The number of rho values - default is 40.}

\item{logrho}{Logical flag for log transformation of the rho sequence. Default is \code{logrho = FALSE}.}

\item{rho.min.ratio}{Smallest value for rho, as a fraction of rho.max, the (data derived) entry value (i.e. the smallest value for which all coefficients are zero) - default is 10e-04.}
}
\value{
An object of class "geneJAM" is returned. \item{call}{The call that produced this object.} \item{xi}{A matrix of intercepts of dimension nouts x length(rho)} \item{beta}{A matrix of coefficients for the PSs of dimension nouts x length(rho)} \item{A}{A length(rho) list of estimated adjacency matrices A of 0s and 1s, where A_{ij} is equal to 1 iff edges i and j are adjacent and A_{ii} is 0.} \item{P}{A length(rho) list of estimated precision matrices (matrix inverse of correlation matrices).} \item{Sigma}{A length(rho) list of estimated correlation matrices.} \item{rho}{The actual sequence of rho values used.} \item{PS}{Polygenic scores used. If  \code{scores = FALSE} they are computed by \code{\link{ps.geneJAM}}} \item{logrho}{Logical flag for log transformation of the rho sequence. Default is \code{logrho = FALSE}.} \item{nobs}{Number of observations.} \item{xiStderr}{Standard error of coefficients \code{xi}.} \item{betaStderr}{Standard error of coefficients \code{beta}.} \item{betaSD}{Standard error of the mean of coefficients \code{beta} for clustered traits.} \item{betaSD0}{Standard error of the mean of all coefficients \code{beta}.} \item{rho.min}{Value of rho that gives minimum non-zero betaSD.}
}
\description{
This function clusters traits that share some genetic component via polygenic scores (PSs). It fits a sparse precision matrix via graphical lasso. The regularisation path is computed for the lasso penalty at a grid of values for the regularisation parameter rho. The clusters are used to specify the structure of the error covariance matrix of a GLS model and the feasible GLS estimator is used for estimating the unknown parameters in a linear regression model with a certain unknown degree of correlation between the residuals.
}
\details{
...
}
\examples{
N <- 1000 #
q <- 10 #
p <- 1000 #
set.seed(1)
# Sample 1
X0 <- matrix(rbinom(n = N*p, size = 2, prob = 0.3), nrow=N, ncol=p)
B <- matrix(0, nrow = p, ncol = q)
B[1, 1:2] <- 1
B[3, 3] <- 2
y0 <- X0 \%*\% B + matrix(rnorm(N*q), nrow = N, ncol = q)
#y0 <- apply(y0, 2, scale)
beta <- ps.geneJAM(X0, y0)$beta
# Sample 2
X <- matrix(rbinom(n = N*p, size = 2, prob = 0.3), nrow=N, ncol=p)
y <- X \%*\% B + matrix(rnorm(N*q), nrow = N, ncol = q)
#y <- apply(y, 2, scale)
#Sigma <- diag(1, q)
#Sigma[1, 2] <- Sigma[2, 1] <- .8
#y <- X \%*\% B + MASS::mvrnorm(n = N, mu = rep(0, q), Sigma = Sigma)
x <- X \%*\% beta
#x <- MASS::mvrnorm(n = N, mu = rep(0, q), Sigma = diag(1, q))
###
pc <- geneJAM(x, y)

}
