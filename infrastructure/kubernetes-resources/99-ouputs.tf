##############################################################################
## Module outputs to be reused by another modules
##
##############################################################################

output "sha256sum_qweb" {
  value = data.external.sha256sum_charts_qweb.result
}
