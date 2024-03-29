% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ps.geneJAM.R
\name{ps.geneJAM}
\alias{ps.geneJAM}
\title{Generate polygenic scores}
\usage{
ps.geneJAM(x, y)
}
\arguments{
\item{x}{Input matrix, of dimension nobs x nvars; each row is an observation vector. Can be in sparse matrix format.}

\item{y}{Quantitative response matrix, of dimension nobs x nouts.}
}
\value{
An object of class "ps.geneJAM" is returned. \item{PS}{A matrix of dimension nobs x nouts of polygenic scores.}
}
\description{
This function generates polygenic scores (PSs) by fitting a univariate simple linear regression model for each feature x on each outcome component y.
}
\details{
For each outcome component \eqn{Y_l} we fit a univariate simple linear regression on the form \deqn{Y_l = X_j B_{jl} + E_l,} where the scalar \eqn{B_{jl}} is a regression coefficient \eqn{E_l} is is a vector of length nobs of independent Gaussian random errors. For a multivariate outcome \eqn{Y} we define the PS for each outcome component l = 1,...,q and each individual i = 1,...,N by \deqn{PS_{il} = \sum_{j=1}^p X_{ij}\hat{B}_{jl},} where \eqn{\hat{B}_{jl}} is the maximum likelihood estimate of \eqn{B_{jl}}.
}
\examples{
N <- 500 #
q <- 10 #
p <- 20 #
set.seed(1)
x <- matrix(rbinom(n = N*p, size = 2, prob = 0.3), nrow=N, ncol=p)
B <- matrix(0, nrow = p, ncol = q)
B[1, 1:2] <- 2
y <- x \%*\% B + matrix(rnorm(N*q), nrow = N, ncol = q)
###
ps <- ps.geneJAM(x, y)

}
