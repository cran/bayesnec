#' bnec
#'
#' Fits a variety of NEC models using Bayesian analysis and provides a model
#' averaged predictions based on WAIC model weights
#' 
#' @param formula Either a \code{\link[base]{character}} string defining an
#' R formula or an actual \code{\link[stats]{formula}} object. See
#' \code{\link{bayesnecformula}} and \code{\link{check_formula}}.
#' @param data A \code{\link[base]{data.frame}} containing the data to use with
#' the \code{formula}.
#' @param x_range A range of predictor values over which to consider extracting
#' ECx.
#' @param resolution The length of the predictor vector used for posterior
#' predictions, and over which to extract ECx values. Large values will be
#' slower but more precise.
#' @param sig_val Probability value to use as the lower quantile to test
#' significance of the predicted posterior values against the lowest observed
#' concentration (assumed to be the control), to estimate NEC as an
#' interpolated NOEC value from smooth ECx curves.
#' @param loo_controls A named \code{\link[base]{list}} of two elements
#' ("fitting" and/or "weights"), each being a named \code{\link[base]{list}}
#' containing the desired arguments to be passed on to \code{\link[brms]{loo}}
#' (via "fitting") or to \code{\link[loo]{loo_model_weights}} (via "weights").
#' If "weights" is
#' not provided by the user, \code{\link{bnec}} will set the default
#' \code{method} argument in \code{\link[loo]{loo_model_weights}} to
#' "pseudobma". See ?\code{\link[loo]{loo_model_weights}} for further info.
#' @param x_var Removed in version 2.0. Use formula instead. Used to be a
#' \code{\link[base]{character}} indicating the column heading
#' containing the predictor (concentration) variable.
#' @param y_var  Removed in version 2.0. Use formula instead. Used to be a
#' \code{\link[base]{character}} indicating the column heading
#' containing the response variable.
#' @param model Removed in version 2.0. Use formula instead. Used to be a
#' \code{\link[base]{character}} vector indicating the model(s)
#' to fit. See Details for more information.
#' @param trials_var Removed in version 2.0. Use formula instead. Used to be a
#' \code{\link[base]{character}} indicating the column
#' heading for the number of "trials" for binomial or "beta_binomial" response
#' data, as it appears in "data" (if data is supplied).
#' @param random Removed in version 2.0. Use formula instead. Used to be a
#' named \code{\link[base]{list}} containing the random model
#' formula to apply to model parameters.
#' @param random_vars Removed in version 2.0. Use formula instead. Used to be a
#' \code{\link[base]{character}} vector containing the
#' names of the columns containing the variables used in the random model
#' formula.
#' @param ... Further arguments to \code{\link[brms]{brm}}.
#'
#' @details
#'
#' \bold{Overview}
#'
#' \code{\link{bnec}} serves as a wrapper for (currently) 23 (mostly) non-linear
#' equations that are classically applied to concentration(dose)-response
#' problems. The primary goal of these equations is to provide the user with
#' estimates of No-Effect-Concentration (NEC),
#' No-Significant-Effect-Concentration (NSEC), and Effect-Concentration
#' (of specified percentage 'x', *ECx*) thresholds.
#' These in turn are fitted through the \code{\link[brms]{brm}} function from
#' package \pkg{brms} and therefore further arguments to \code{\link[brms]{brm}}
#' are allowed. In the absence of those arguments, \code{\link{bnec}} makes
#' its best attempt to calculate distribution family, priors and initialisation
#' values for the user based on the characteristics of the data. Moreover, in
#' the absence of user-specified values, \code{\link{bnec}} sets the number of
#' iterations to 1e4 and warmup period to \code{floor(iterations / 5) * 4}.
#' The chosen models can be extended by the addition of \pkg{brms} special
#' "aterms" as well as group-level effects. See \code{?\link{bayesnecformula}}
#' for details.
#' 
#' \bold{The available models/equations/formulas}
#'
#' The available equations (or models) can be found via the \code{\link{models}}
#' function. Since version 2.0, \code{\link{bnec}} requires a specific formula
#' structure
#' which is fully explained in the help file of \code{\link{bayesnecformula}}.
#' This formula incorporates the information regarding the chosen model(s). If
#' one single model is specified, \code{\link{bnec}} will return an object of
#' class \code{\link{bayesnecfit}}; otherwise if model is either a concatenation
#' of multiple models and/or a string indicating a family of models,
#' \code{\link{bnec}} will return an object of class
#' \code{\link{bayesmanecfit}}, providing they were successfully fitted. The
#' major difference being that the output of the latter includes Bayesian model
#' averaging statistics. These classes come with multiple associated
#' methods such as \code{\link[base]{plot}}, \code{\link[ggplot2]{autoplot}},
#' \code{\link[base]{summary}}, \code{\link[base]{print}},
#' \code{\link[stats]{model.frame}} and \code{\link[stats]{formula}}.
#'
#' \code{model} may also be one of "all", meaning all of the available models
#' will be fit; "ecx" meaning only models excluding a specific NEC step
#' parameter will be fit; "nec" meaning only models with a specific NEC step
#' parameter will be fit; "bot_free" meaning only models without a "bot"
#' parameter (without a bottom plateau) will be fit; "zero_bounded" are models
#' that are bounded to be zero; or "decline" excludes all hormesis models, i.e.,
#' only allows a strict decline in response across the whole predictor range.
#' Notice that if one of these group strings is provided together with a
#' user-specified named list for the \code{\link[brms]{brm}}'s argument
#' \code{prior}, the list names need to contain
#' the actual model names, and not the group string , e.g. if
#' \code{model = "ecx"} and \code{prior = my_priors} then
#' \code{names(my_priors)} must contain \code{models("ecx")}. To check
#' available models and associated parameters for each group,
#' use the function \code{\link{models}} or to check the parameters of a
#' specific model use the function \code{\link{show_params}}.
#' 
#' \bold{No-effect toxicity estimates}
#' 
#' Regardless of the model(s) fitted, the resulting object will contain a 
#' no-effect toxicity estimate. Where the fitted model(s) are NEC models (threshold 
#' models, containing a step function - all models with "nec" as a
#' prefix) the no-effect estimate is a true  
#' no-effect-concentration (NEC, see Fox 2010). Where the fitted model(s) are 
#' smooth ECx models with no step function (all models with "ecx" as a
#' prefix), the no-effect estimate is a no-significant-effect-concentration 
#' (NSEC, see Fisher and Fox 2023). 
#' In the case of a \code{\link{bayesmanecfit}} that contains a mixture of both 
#' NEC and ECx models, the no-effect estimate is a model averaged combination of 
#' the NEC and NSEC estimates, and is reported as the N(S)EC 
#' (see Fisher et al. 2023).
#'
#' \bold{Further argument to \code{\link[brms]{brm}}}
#'
#' If not supplied via the \code{\link[brms]{brm}} argument \code{family}, the
#' appropriate distribution will be guessed based on the characteristics of the
#' input data. Guesses include: "bernoulli" / bernoulli / bernoulli(), "Beta" /
#' Beta / Beta(), "binomial" / binomial / binomial(), "beta_binomial" /
#' "beta_binomial", "Gamma" / Gamma / Gamma(), "gaussian" / gaussian /
#' gaussian(), "negbinomial" / negbinomial / negbinomial(), or "poisson" /
#' poisson / poisson(). Note, however, that "negbinomial" and "betabinomimal2"
#' require knowledge on whether the data is over-dispersed. As
#' explained below in the Return section, the user can extract the dispersion
#' parameter from a \code{\link{bnec}} call, and if they so wish, can refit the
#' model using the "negbinomial" family.
#'
#' Other families can be considered as required, please raise an
#' \href{https://github.com/open-AIMS/bayesnec/issues}{issue} on the GitHub
#' development site if your required family is not currently available.
#'
#' As a default, \code{\link{bnec}} sets the \code{\link[brms]{brm}} argument
#' \code{sample_prior} to "yes" in order to sample draws from the priors in
#' addition to the posterior distributions. Among others, these samples can be
#' used to calculate Bayes factors for point hypotheses via
#' \code{\link[brms]{hypothesis}}.
#'
#' Model averaging is achieved through a weighted sample of each fitted models
#' posterior predictions, with weights derived using functions
#' \code{\link[brms]{loo}} and \code{\link[brms]{loo_model_weights}} from
#' \pkg{brms}. Argument to both these functions can be passed via the
#' \code{loo_controls} argument. Individual model fits can be pulled out
#' for examination using function \code{\link{pull_out}}.
#'
#' \bold{Additional technical notes}
#'
#' As some concentration-response data will use zero concentration
#' which can cause numerical estimation issues, a small offset is added (1 /
#' 10th of the next lowest value) to zero values of concentration where
#' \code{x_var} are distributed on a continuous scale from 0 to infinity, or
#' are bounded to 0, or 1.
#'
#' \bold{NAs are thrown away}
#' 
#' Stan's default behaviour is to fail when the input data contains NAs. For
#' that reason \pkg{brms} excludes any NAs from input data prior to fitting,
#' and does not allow them back in as is the case with e.g. \code{stats::lm} and
#' \code{na.action = exclude}. So we advise that you exclude any NAs in your
#' data prior to fitting because if you so wish that should facilitate merging
#' predictions back onto your original dataset.
#'
#' @return If argument model is a single string, then an object of class
#' \code{\link{bayesnecfit}}; if many strings or a set,
#' an object of class \code{\link{bayesmanecfit}}.
#'
#' @seealso
#'   \code{\link{bayesnecformula}},
#'   \code{\link{check_formula}},
#'   \code{\link{models}},
#'   \code{\link{show_params}}
#'   
#' @references
#' Fisher R, Barneche DR, Ricardo GF, Fox, DR (2024) An {R} Package for
#' Concentration-Response Modeling and Estimation of Toxicity Metrics
#' doi:10.18637/jss.v110.i05.
#'
#' Fisher R, Fox DR (2023). Introducing the no significant effect concentration 
#' (NSEC).Environmental Toxicology and Chemistry, 42(9), 2019–2028. 
#' doi: 10.1002/etc.5610.
#'
#' Fisher R, Fox DR, Negri AP, van Dam J, Flores F, Koppel D (2023). Methods for
#' estimating no-effect toxicity concentrations in ecotoxicology. Integrated 
#' Environmental Assessment and Management. doi:10.1002/ieam.4809.
#' 
#' Fox DR (2010). A Bayesian Approach for Determining the No Effect
#' Concentration and Hazardous Concentration in Ecotoxicology. Ecotoxicology
#' and Environmental Safety, 73(2), 123–131. doi: 10.1016/j.ecoenv.2009.09.012.
#'
#' @examples
#' \dontrun{
#' library(bayesnec)
#' data(nec_data)
#'
#' # A single model
#' exmp_a <- bnec(y ~ crf(x, model = "nec4param"), data = nec_data, chains = 2)
#' # Two models model
#' exmp_b <- bnec(y ~ crf(x, model = c("nec4param", "ecx4param")),
#'                data = nec_data, chains = 2)
#' }
#'
#' @importFrom stats model.frame
#' @importFrom chk chk_number
#'
#' @export
bnec <- function(formula, data, x_range = NA, resolution = 1000, sig_val = 0.01,
                 loo_controls, x_var = NULL, y_var = NULL, trials_var = NULL,
                 model = NULL, random = NULL, random_vars = NULL, ...) {
  chk_number(resolution)
  chk_number(sig_val)

  mf <- match.call(expand.dots = FALSE)
  m <- sapply(c("x_var", "y_var", "trials_var", "model", "random",
                "random_vars"), function(x, l) is.null(l[[x]]), l = mf)
  if (!all(m)) {
    warning("Arguments x_var, y_var, trials_var, model, random and random_vars",
            " are deprecated. Extracting relevant data and model information",
            " from argument formula. See ?bnec")
  }
  formula <- bayesnecformula(formula)
  bdat <- model.frame(formula, data = data, run_par_checks = TRUE)
  model <- get_model_from_formula(formula)
  brm_args <- list(...)
  brm_args$family <- retrieve_valid_family(brm_args, bdat)
  model <- check_models(model, brm_args$family, bdat)
  loo_controls <- define_loo_controls(loo_controls, brm_args$family$family)
  if (length(model) == 0) {
    stop("No valid models have been supplied for this data type.")
  } else if (length(model) > 1) {
    mod_fits <- vector(mode = "list", length = length(model))
    names(mod_fits) <- model
    for (m in seq_along(model)) {
      model_m <- model[m]
      fit_m <- try(
        fit_bayesnec(formula = formula, data = data, model = model_m,
                     brm_args = brm_args),
        silent = FALSE
      )
      if (!inherits(fit_m, "try-error")) {
        mod_fits[[m]] <- fit_m
      } else {
        mod_fits[[m]] <- NA
      }
    }
    formulas <- lapply(mod_fits, extract_formula)
    mod_fits <- expand_manec(mod_fits, formula = formulas, x_range = x_range,
                             resolution = resolution, sig_val = sig_val,
                             loo_controls = loo_controls)
    if (length(mod_fits) > 1) {
      allot_class(mod_fits, c("bayesmanecfit", "bnecfit"))
    } else {
      mod_fits <- expand_nec(mod_fits[[1]], formula = formula,
                             x_range = x_range, resolution = resolution,
                             sig_val = sig_val, loo_controls = loo_controls,
                             model = names(mod_fits))
      allot_class(mod_fits, c("bayesnecfit", "bnecfit"))
    }
  } else {
    mod_fit <- fit_bayesnec(formula = formula, data = data, model = model,
                            brm_args = brm_args)
    mod_fit <- expand_nec(mod_fit, formula = formula, x_range = x_range,
                          resolution = resolution, sig_val = sig_val,
                          loo_controls = loo_controls, model = model)
    allot_class(mod_fit, c("bayesnecfit", "bnecfit"))
  }
}
