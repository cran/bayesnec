test_that("x must be a named list", {
  expect_error(compare_estimates(list(ecx4param, nec4param)))
  expect_error(compare_estimates(ecx4param, nec4param))
})

test_that("output is a list of appropriately name elements", {
  ce <- compare_estimates(list(ecx4param = ecx4param, nec4param = nec4param))
  expect_equal(class(ce), "list")
  expect_equal(length(ce), 5)
  expect_equal(names(ce), c("posterior_list", "posterior_data", "diff_list",
                            "diff_data", "prob_diff"))
})
