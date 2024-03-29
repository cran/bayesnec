% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bayesnecformula.R
\name{check_formula}
\alias{check_formula}
\title{Check if input model formula is appropriate to use with
\code{\link[bayesnec:bayesnec-package]{bayesnec}}}
\usage{
check_formula(formula, data, run_par_checks = FALSE)
}
\arguments{
\item{formula}{An object of class \code{\link{bayesnecformula}} as returned
by function \code{\link{bayesnecformula}}.}

\item{data}{A \code{\link[base]{data.frame}} containing the variables
specified in \code{formula}.}

\item{run_par_checks}{See details. A \code{\link[base]{logical}} defining
whether random terms for specific parameters should be checked against the
underlying concentration-response model defined in \code{formula}.
Defaults to \code{FALSE}.}
}
\value{
A validated object of class \code{\link{bayesnecformula}} and
\code{\link[stats]{formula}}.
}
\description{
Perform a series of checks to ensure that the input formula is valid
for usage within \code{\link[bayesnec:bayesnec-package]{bayesnec}}.
}
\details{
This function allows the user to make sure that the input formula
will allow for a successful model fit with the function \code{\link{bnec}}.
Should all checks pass, the function returns the original formula. Otherwise
it will fail and requires that the user fixes it until they're able to use
it with \code{\link{bnec}}.

The argument \code{run_par_checks} is irrelevant for most usages of this
package because it only applies if three conditions are met: 1) the user has
specified a group-level effect; 2) the group-level effects is parameter
specific (e.g. \code{(par | group_variable)} rather than \code{pgl/ogl(group_variable)}); and 3) The user is keen to learn if the specified parameter
is found in the specified model (via argument \code{model} in the \code{crf} term -- see details in ?bayesnecformula).

\strong{NB:} \code{aterms} other than \code{trials()} and \code{weights()} are
currently omitted from \code{\link{model.frame}} output. If you need other
\code{aterms} as part of that output please raise an issue on our GitHub
page. See details about \code{aterms} in ?bayesnecformula.
}
\examples{
library(bayesnec)
nec3param <- function(beta, nec, top, x) {
  top * exp(-exp(beta) * (x - nec) *
    ifelse(x - nec < 0, 0, 1))
}

data <- data.frame(x = seq(1, 20, length.out = 10), tr = 100, wght = c(1, 2),
                   group_1 = sample(c("a", "b"), 10, replace = TRUE),
                   group_2 = sample(c("c", "d"), 10, replace = TRUE))
data$y <- nec3param(beta = -0.2, nec = 4, top = 100, data$x)

# returns error
# > f_1 <- y ~ crf(x, "nec3param") + z
# regular formula not allowed, wrap it with function bnf
# > check_formula(f_1, data)
# population-level covariates are not allowed
# > check_formula(bnf(f_1), data)

\donttest{
# expect a series of messages for because not all
# nec models have the "bot" parameter
f_2 <- y | trials(tr) ~ crf(x, "nec") + (nec + bot | group_1)
check_formula(bnf(f_2), data, run_par_checks = TRUE)
}
# runs fine
f_3 <- "y | trials(tr) ~ crf(sqrt(x), \"nec3param\")"
check_formula(bnf(f_3), data)
f_4 <- y | trials(tr) ~ crf(x, "nec3param") + ogl(group_1) + pgl(group_2)
inherits(check_formula(bnf(f_4), data), "bayesnecformula")

}
\seealso{
\code{\link{bnec}},
\code{\link{bayesnecformula}}
}
