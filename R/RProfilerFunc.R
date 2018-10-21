#The function list is on the buttom

profile_size<-function(varInfo,Exp){
  ExpInfo=getEmpyTable(1)
  ExpInfo$dataType=T_scale
  ExpInfo$precisionType=T_DEFAULT_INT
  ExpInfo$size1=1
  ExpInfo$size2=1
  ExpInfo$compileSize="Y"
  ExpInfo$compileData="Y"
  var_data=getVarInfo(varInfo,Exp[[2]])
  if(var_data$compileSize=="Y"){
    if(Exp[[1]]=="nrow")
      ExpInfo$value=var_data$size1
    if(Exp[[1]]=="ncol")
      ExpInfo$value=var_data$size2
    if(Exp[[1]]=="length"){
      Exp$value=paste0("(",var_data$size1,"*",var_data$size2,")")
    }
    return(ExpInfo)
  }
}



# Exp=parse(text="matrix(10,2,2)")[[1]]
# Exp=parse(text="matrix(a,2,2)")[[1]]
# Exp=parse(text="matrix(a,2)")[[1]]
# Exp=parse(text="matrix(a,ncol=2)")[[1]]
# Exp=parse(text="matrix(a,2,2)")[[1]]

profile_matrix<-function(varInfo,Exp){
  ExpRecord=Exp
  if(length(Exp)==1)
    stop("The matrix function is incomplete: ",deparse(ExpRecord))
  #Get the matrix data and size
  Exp=standardise_call(Exp)
  argNames=names(Exp)
  data_ind=which(argNames=="data")
  nrow_ind=which(argNames=="nrow")
  ncol_ind=which(argNames=="ncol")
  
  if(length(data_ind)==0)
    stop("Unrecognized code: ",deparse(ExpRecord))
  data=Exp[[data_ind]]
  #If the element is a numeric value(The only available form now)
  if(is.numeric(data)){
    #Find the row and column number
    if(length(nrow_ind)==0)
      rowNum=quote(1)
    else
      rowNum=Exp[[nrow_ind]]
    if(length(ncol_ind)==0)
      colNum=quote(1)
    else
      colNum=Exp[[ncol_ind]]
    #Check if the row and col is the number, if not, find the value of it.
    #If the value cannot be determined, an error will be given
    if(!is.numeric(rowNum)){
      var_data=getVarInfo(varInfo,rowNum)
      if(var_data$compileData=="Y"&&var_data$dataType==T_scale){
        rowNum=var_data$value
      }else{
        stop("Unsupported code: ",ExpRecord)
      }
    }
    if(!is.numeric(colNum)){
      var_data=getVarInfo(varInfo,colNum)
      if(var_data$compileData=="Y"&&var_data$dataType==T_scale){
        colNum=var_data$value
      }else{
        stop("Unsupported code: ",ExpRecord)
      }
    }
    ExpInfo=getEmpyTable(1)
    ExpInfo$dataType="matrix"
    ExpInfo$precisionType=T_DEFAULT_float
    ExpInfo$size1=rowNum
    ExpInfo$size2=colNum
    ExpInfo$compileSize="Y"
    ExpInfo$compileData="Y"
    ExpInfo$value=paste0("matrix(",data,",",rowNum,",",colNum,")")
    return(ExpInfo)
  }
  if(!is.numeric(data)){
    stop("Unsupported code: ",ExpRecord)
  }
}





# Exp=parse(text="1+100")[[1]]



profile_arithmetic<-function(varInfo,Exp){
  ExpInfo=getEmpyTable(1)
  leftExp=Exp[[2]]
  rightExp=Exp[[3]]
  if(is.numeric(leftExp)){
    leftInfo=getEmpyTable(1,type=T_scale)
    leftInfo$compileData="Y"
    leftInfo$value=deparse(leftExp)
  }else{
    leftInfo=getVarInfo(varInfo,leftExp)
  }
  if(is.numeric(rightExp)){
    rightInfo=getEmpyTable(1,type=T_scale)
    rightInfo$compileData="Y"
    rightInfo$value=deparse(rightExp)
  }else{
    rightInfo=getVarInfo(varInfo,rightExp)
  }
  ExpInfo$precisionType=typeInherit(leftInfo$precisionType,rightInfo$precisionType)
  if(leftInfo$compileSize=="Y"&&rightInfo$compileSize=="Y")
    ExpInfo$compileSize="Y"
  if(leftInfo$compileData=="Y"&&rightInfo$compileData=="Y"){
    ExpInfo$compileData="Y"
    ExpInfo$value=paste0("(",leftInfo$value,deparse(Exp[[1]]),rightInfo$value,")")
  }
  if(leftInfo$dataType==T_scale&&rightInfo$dataType==T_scale){
    ExpInfo$dataType=T_scale
    ExpInfo$size1=1
    ExpInfo$size2=1
  }
  if(leftInfo$dataType==T_scale&&rightInfo$dataType==T_matrix){
    ExpInfo$dataType=T_matrix
    ExpInfo$size1=rightInfo$size1
    ExpInfo$size2=rightInfo$size2
  }
  if(leftInfo$dataType==T_matrix&&rightInfo$dataType==T_scale){
    ExpInfo$dataType=T_matrix
    ExpInfo$size1=leftInfo$size1
    ExpInfo$size2=leftInfo$size2
  }
  if(leftInfo$dataType==T_matrix&&rightInfo$dataType==T_matrix){
    if(leftInfo$size1!=rightInfo$size1||leftInfo$size2!=rightInfo$size2)
      stop("The matrix size does not match: ",deparse(Exp))
    ExpInfo$dataType=T_matrix
    ExpInfo$size1=leftInfo$size1
    ExpInfo$size2=leftInfo$size2
  }
  return(ExpInfo)
}


getFuncArgs<-function(Exp,ArgName){
  
}



profile_subset<-function(varInfo,Exp){
  var_data=getVarInfo(varInfo,Exp[[2]])
  curType=NULL
  sub1=list()
  sub2=list()
  if(length(Exp)>=3){
    if(Exp[[3]]==""){
      if(length(Exp)==3)
        stop("Undefined code: ",deparse(Exp))
      sub1$compile="Y"
      sub1$compileSize="Y"
      sub1$size=var_data$size1
      sub1$type=T_matrix
    }else{
      if(is.numeric(Exp[[3]])){
        sub1$compile="Y"
        sub1$value=deparse(Exp[[3]])
        sub1$compileSize="Y"
        sub1$size=1
        sub1$type=T_scale
      }else{
        subVar=getVarInfo(varInfo,Exp[[3]])
        sub1$compile=subVar$compileData
        sub1$value=subVar$value
        sub1$compileSize=subVar$compileSize
        sub1$size=paste0("(",subVar$size1,"*",subVar$size2,")")
        sub1$type=subVar$dataType
      }
    }
  }
  if(length(Exp)==4){
    if(Exp[[4]]==""){
      sub2$compile="Y"
      sub2$compileSize="Y"
      sub2$size=var_data$size1
      sub2$type=T_matrix
    }else{
      if(is.numeric(Exp[[4]])){
        sub2$compile="Y"
        sub2$value=deparse(Exp[[4]])
        sub2$compileSize="Y"
        sub2$size=1
        sub2$type=T_scale
      }else{
        subVar=getVarInfo(varInfo,Exp[[4]])
        sub2$compile=subVar$compileData
        sub2$value=subVar$value
        sub2$compileSize=subVar$compileSize
        sub2$size=paste0("(",subVar$size1,"*",subVar$size2,")")
        sub2$type=subVar$dataType
      }
    }
  }
  
  ExpInfo=getEmpyTable(1)
  ExpInfo$dataType=T_matrix
  if(length(sub2)!=0){
    if(sub1$type==T_scale&&sub2$type==T_scale){
      ExpInfo$dataType=T_scale
    }
    if(ExpInfo$dataType==T_scale&&sub1$compile=="Y"&&sub2$compile=="Y"&&var_data$compileData=="Y"){
      ExpInfo$value=paste0("(",var_data$value,"[",sub1$value,",",sub2$value,"])")
      ExpInfo$compileData="Y"
    }
    if(sub1$compileSize=="Y"&&sub2$compileSize=="Y"&&var_data$compileSize=="Y"){
      ExpInfo$compileSize="Y"
      ExpInfo$size1=sub1$size
      ExpInfo$size2=sub2$size
    }else{
      stop("undetermined size: ",Exp)
    }
  }else{
    if(sub1$type==T_scale){
      ExpInfo$dataType=T_scale
    }
    if(ExpInfo$dataType==T_scale&&sub1$compile=="Y"&&var_data$compileData=="Y"){
      ExpInfo$value=paste0("(",var_data$value,"[",sub1$value,"])")
      ExpInfo$compileData="Y"
    }
    if(sub1$compileSize=="Y"&&var_data$compileSize=="Y"){
      ExpInfo$compileSize="Y"
      ExpInfo$size1=sub1$size
      ExpInfo$size2=1
    }else{
      stop("undetermined size: ",Exp)
    }
  }

  ExpInfo$precisionType=var_data$precisionType
  return(ExpInfo)
}

profile_numeric<-function(Exp){
  ExpInfo=getEmpyTable(1,type=T_scale)
  ExpInfo$value=as.character(Exp)
  ExpInfo$compileData="Y"
  return(ExpInfo)
}
profile_symbol<-function(varInfo,Exp){
  ExpInfo=getEmpyTable(1)
  var_data=getVarInfo(varInfo,Exp)
  content=c("dataType","precisionType", "size1","size2","value",
            "compileSize","compileData")
  ExpInfo[,content]=var_data[,content]
  ExpInfo
}

profile_floor<-function(varInfo,Exp){
  ExpInfo=profile_symbol(varInfo,Exp[[2]])
  return(ExpInfo)
}
profile_return<-function(varInfo,Exp){
  ExpInfo=profile_symbol(varInfo,Exp[[2]])
  ExpInfo$var=GPUVar$gpu_return_variable
  return(ExpInfo)
}


.profileFuncs=list()
.profileFuncs$nrow=profile_size
.profileFuncs$ncol=profile_size
.profileFuncs$length=profile_size
.profileFuncs$matrix=profile_matrix
.profileFuncs$"+"=profile_arithmetic
.profileFuncs$"-"=profile_arithmetic
.profileFuncs$"*"=profile_arithmetic
.profileFuncs$"/"=profile_arithmetic
.profileFuncs$"["=profile_subset
.profileFuncs$floor=profile_floor