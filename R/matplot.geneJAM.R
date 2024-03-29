#' Adjacency matrix plot for a cv.geneJAM object
#'
#' @param x Fitted "geneJAM" object.
#' @param s Value(s) of the penalty parameters rho for which the corresponding adjacency matrix is plotted. Default is rho.min.
#' @param A True adjacency matrix (optional).
#' @param col Color(s) to fill or shade the non-zero entries with. The default is \code{col = "lightgrey"}.
#' @param col.border Color for rectangle border(s). The default is \code{col.border = "#D95F02"}.
#' @param bty A character string which determine the type of box which is drawn about plots. Default is "n" which suppresses the box.
#' @param xlab A label for the x axis, defaults to 1:nouts
#' @param ylab A label for the y axis, defaults to 1:nouts
#' @param axes A logical value indicating whether axes should be drawn on the plot.
#' @param frame.plot A logical value indicating whether a box should be drawn around the plot.
#' @param reorder A logical value indicating whether rows and columns of adjacency matrix should be ordered according to clusters.
#' @param ... Other paramters to be passed through to plotting functions.
#'
#' @details Plots are produced, and nothing is returned.
#'
#' @export
#'

matplot.geneJAM <- function (x, s = "rho.min", A = NULL,
                            col = "darkgrey", col.border = "#D95F02", bty = "n",
                            xlab = NULL, ylab = NULL,
                            axes = TRUE, frame.plot = FALSE, reorder = FALSE, ...) {

  obj <- x

  if (is.numeric(s)) rho <- s
  else
    if (is.character(s)) {
      s <- match.arg(s)
      rho <- obj[[s]]
    }
  else stop("Invalid form for s")

  for (i in 1:length(rho)) {
    rhoi <- rho[i]
    Ahat <- obj$A[[which(obj$rho == rhoi)]]
    q <- ncol(Ahat)
    if (is.null(xlab)) {
      xlabs <- (1:q)
    } else {
      if (length(xlab) == q) {
      xlabs <- xlab
      }
      else xlabs <- (1:q)
    }
    if (is.null(ylab)) {
      ylabs <- (1:q)
    } else {
      if (length(ylab) == q) {
        ylabs <- ylab
      }
      else ylabs <- (1:q)
    }

    if (isTRUE(reorder)) {
      neworder <- order(obj$clusters[[which(obj$rho == rhoi)]]$membership)
      Ahat <- Ahat[neworder, neworder]
      xlabs <- xlabs[neworder]
      ylabs <- ylabs[neworder]
    }

    plot(c(0,q), c(0,q), type = "n", ylim = c(0, q+2),
         xlab="", ylab="", xaxt='n', yaxt='n', bty = bty, asp = 1)
    # create the matrix
    for (i in seq(q)) {
      for (j in seq(q)) {
        graphics::rect(i-1,q+1-j,i,q-j,
             col = ifelse(Ahat[i,j] == 0, NA, col),
             density = ifelse(Ahat[i,j] == 0, 0, 50),
             border = ifelse(!is.null(A) && A[i,j] == 1, col.border, NA))
      }
    }
    rect(-.5,-.5,q+.5,q+.5,
         border = ifelse(frame.plot, "darkgrey", NA))
    if (isTRUE(axes)) {

      srtx <- ifelse(is.numeric(xlabs), 0, 90)
      text(y = q, x = (1:q) - .5, xlabs, xpd=TRUE, adj=1, srt=srtx, pos = 3)
      text(x = -.5, y = (1:q) - .5, rev(ylabs), xpd=TRUE, adj=1, pos = 2)

      #text(x = (1:q) - .5, y = q, labels = paste0(xlabs), pos = 3)
      #text(x = 0, y = (1:q) - .5, labels = paste0(rev(ylabs)), pos = 2)
    }
  }

  invisible()
}
