# `killer_palettes` lives in data/ and is lazy-loaded into the namespace, so it
# is always available to package code -- but R CMD check's static analysis
# cannot see that and reports it as an undefined global.
utils::globalVariables("killer_palettes")
