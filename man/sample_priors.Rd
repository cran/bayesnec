% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sample_priors.R
\name{sample_priors}
\alias{sample_priors}
\title{sample_priors}
\usage{
sample_priors(priors, n_samples = 10000, plot = "ggplot")
}
\arguments{
\item{priors}{An object of class \code{\link[brms]{brmsprior}} from package
\pkg{brms}.}

\item{n_samples}{The number of prior samples to return.}

\item{plot}{NA returns a \code{\link[base]{list}} of numeric vectors of
sampled priors, "ggplot" (default) returns a \code{\link[ggplot2]{ggplot}}
and "base" returns a histogram in base R.}
}
\value{
A \code{\link[base]{list}} containing the initialisation values.
}
\description{
Creates list or generates a plot of prior samples
}
\examples{
library(bayesnec)
data(manec_example)
exmp <- pull_brmsfit(manec_example, model = "nec4param")
sample_priors(exmp$prior)

}
\seealso{
\code{\link{bnec}}
}
