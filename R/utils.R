# A tiny function that can make the output more compact Auto convert
# the unit between byte, kb, mb, and gb The input is the memory size in
# byte
format_memory_size <- function(x) {
  if (x > 10^9) 
    return(paste0(ceiling((x)/1024^3 * 100)/100, " GB"))
  if (x > 10^7) 
    return(paste0(ceiling((x)/1024^2 * 100)/100, " MB"))
  if (x > 10^4) 
    return(paste0(ceiling((x)/1024 * 100)/100, " KB"))
  
  return(paste0(x, " Byte"))
}


getTotalDeviceNum<-function(){
    deviceInfo <- .gpuResourcesManager$globalVars$deviceInfo
    if(is.null(deviceInfo))
        return(0)
    else
        return(nrow(deviceInfo))
}