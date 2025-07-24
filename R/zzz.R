#' @importFrom pryr standardise_call
#' @importFrom Deriv Simplify
#' @importFrom digest digest
#' @importFrom DescTools StrAlign
#' @importFrom utils capture.output ls.str
#' @importFrom stringr str_match str_match_all str_extract_all
#' @import methods
#' @import BiocGenerics
#' @useDynLib gpuMagic, .registration = TRUE,  .fixes = 'C_'

.onDetach <- function(libpath) {
    gc()
}

.onUnload <- function(libpath) {
    .gpuResourcesManager$deleteEnv()
}
.onLoad <- function(libname, pkgname) {
  updateDeviceInfo()
    if(getTotalDeviceNum()!=0){
      setDevice(1)
    }
}

DEBUG = TRUE

.onAttach <- function(libname, pkgname) {
    msg <- sprintf(
        "Package '%s' is deprecated and will be removed from Bioconductor
         version %s", pkgname, "3.23")
    .Deprecated(msg=paste(strwrap(msg, exdent=2), collapse="\n"))
}

