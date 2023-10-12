test_that("az_fmt_batch works correctly", {
  # Your function to test
  result <- az_fmt_batch(cand, address = "address", limit = 2)

  # Check that the result is a JSON string
  expect_type(result, "character")

  # Check that the JSON contains expected elements
  expect_match(result, "batchItems")
  expect_match(result, "?query=")
  expect_match(result, "&limit=2")

  # Check that each address in `cand` is represented in the result
  for (addr in cand$address) {
    expect_match(result, paste0("?query=", addr, "&limit=2"))
  }

})
