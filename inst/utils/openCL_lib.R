##This is actually an R file##
get_os <- function(){
  sysinf <- Sys.info()
  if (!is.null(sysinf)){
    os <- sysinf['sysname']
    if (os == 'Darwin')
      os <- "osx"
  } else { ## mystery machine
    os <- .Platform$OS.type
    if (grepl("^darwin", R.version$os))
      os <- "osx"
    if (grepl("linux-gnu", R.version$os))
      os <- "linux"
  }
  tolower(os)
}


OS <- get_os()
if(!any(OS%in%c("linux","osx","windows"))){
  stop("Unable to determine the OS!")
}
if(OS == "linux"){
  cat("-lOpenCL")
}
if(OS == "osx"){
  cat("-framework OpenCL")
}
if(OS=="windows"){
  win_dir <-normalizePath(Sys.getenv("WINDIR"),winslash = "/")
  ## First location
  dll_path <- paste0(win_dir,"/system32/OpenCL.dll")
  if(file.exists(dll_path)){
    cat(dll_path)
  }else{
    ## Second location
    dll_path <- paste0(win_dir,"/SysWOW64/OpenCL.dll")
    if(file.exists(dll_path)){
      cat(dll_path)
    }else{
      cat("NotDefined")
    }
  }
}
