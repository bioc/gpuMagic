#Expression should be a variable or a matrix subset
#R_oneIndex_exp_sub(varInfo,quote(A[tmp1]),3)
R_oneIndex_exp_sub<-function(varInfo,Exp,k,k_C=FALSE,opt=FALSE,optCode=list(),base=1){
  k=paste0(k,"+",1-base)
  k=CSimplify(k,k_C)
  if(k_C){
    k_C_ind=list(value=k)
  }else{
    k_C_ind=R_expression_sub(varInfo,k,1)
  }
  
  #If the expression is empty, return the k index.
  if(Exp==""){
    if(is.null(optCode[["rowVar"]]))
      return(list(value=k))
    else
      return(list(value=optCode[["rowVar"]]))
  }
  #Simplify the expression to make sure no 1+0 cases
  Exp=Simplify(Exp)
  #Check if the result is a number
  if(isNumeric(Exp)){
    if(isNumeric(k)&&as.character(k)!="1")
      stop("Incorrect subset index")
    return(list(value=as.character(Exp)))
  }
  #Convert the character to the expression
  Exp=toExpression(Exp)$expression
  
  #If the expression is a variable
  if(is.symbol(Exp)){
    res=oneIndex_to_twoIndex(varInfo,Exp,k_C_ind,rowNum=R_nrow(varInfo,Exp)
                              ,opt=opt,optCode=optCode)
    return(res)
  }
  #if the expression is a subset of a matrix
  if(Exp[[1]]=="["){
    curVar=Exp[[2]]
    args=matchBracketFunc(Exp)
    #if it is one index subset
    #j will be ignored
    if(is.null(args$j)){
      sub=args$i
      k_C_ind=R_oneIndex_exp_sub(varInfo,sub,k=k,k_C=k_C)
      res=R_oneIndex_exp_sub(varInfo,curVar,k=k_C_ind$value,k_C=TRUE,opt=opt,optCode=optCode)
      res$extCode=c(k_C_ind$extCode,res$extCode)
      return(res)
    }else{
      size=R_nrow(varInfo,Exp)
      res=oneIndex_to_twoIndex(varInfo,Exp,k_C_ind$value,rowNum=size
                                ,opt=opt,optCode=optCode)
      res$extCode=c(k_C_ind$extCode,res$extCode)
      return(res)
      
    }
  }
  stop("unrecognized code: ",deparse(Exp))
}
oneIndex_to_twoIndex<-function(varInfo,Exp,k_C_value,rowNum,opt=opt,optCode=optCode){
  tmpVar=GPUVar$getTmpVar()
  tmpVar_value=CSimplify(paste0("(",GPUVar$default_index_type,")((",k_C_value,"-1)/",rowNum,")"))
  #if the temporary variable is a constant, it will be plug into the code
  #Otherwise, create the temporary variable
  if(isNumeric(tmpVar_value)){
    tmpVar=tmpVar_value
    extCode=NULL
  }else{
    extCode=paste0(GPUVar$default_index_type," ",tmpVar,"=",tmpVar_value,";")
  }
  i_C_ind=paste0(k_C_value,"-",rowNum,"*",tmpVar)
  j_C_ind=paste0(tmpVar,"+1")
  
  res=R_expression_sub(varInfo,Exp,i=i_C_ind,j=j_C_ind,i_C=TRUE,j_C=TRUE,opt=opt,optCode=optCode)
  #If the temporary variable has been cancelled out, remove the extra code
  if(length(grep(tmpVar,res$value,fixed = TRUE))==0){
    extCode=NULL
  }
  res$extCode=c(extCode,res$extCode)
  return(res)
}


#get the i,jth element from the expression, 
#the expression can be a variable, a matrix subset or a number
#i,j can be interpreted as an R object or a C object, it is determined by i_C and j_C
#Special case:
#Exp can be empty, then i will be returned
#Exp can be a value, then the value will be returned
#Exp can be a scalar, then the value will be returned
#R_expression_sub(varInfo,quote(A[tmp1,]),3,6)
R_expression_sub<-function(varInfo,Exp,i,j=1,opt=FALSE,optCode=list(),i_C=FALSE,j_C=FALSE,base=1){
  #Convert all the 0-based index to 1-based index
  i=paste0(i,"+",1-base)
  j=paste0(j,"+",1-base)
  base=1
  i=CSimplify(i,i_C)
  j=CSimplify(j,j_C)
  
  #If the expression is empty, return the i index.
  if(Exp==""){
    if(isNumeric(j)&&as.character(j)!="1")
      stop("Incorrect subset index")
    if(is.null(optCode[["rowVar"]]))
      return(list(value=i))
    else
      return(list(value=optCode[["rowVar"]]))
  }
  #Simplify the expression to make sure no 1+0 cases
  Exp=Simplify(Exp)
  #Check if the result is a number
  if(isNumeric(Exp)){
    if(isNumeric(i)&&as.character(i)!="1")
      stop("Incorrect subset index")
    if(isNumeric(j)&&as.character(j)!="1")
      stop("Incorrect subset index")
    return(list(value=as.character(Exp)))
  }
  #Convert the character to the expression
  Exp=toExpression(Exp)$expression
  
  #if the expression contains only one element
  if(length(Exp)==1){
    curVar=deparse(Exp)
    #If the expression is a lazy reference
    if(getVarProperty(varInfo,curVar,"lazyRef")){
      refExp=parse(text=getVarProperty(varInfo,curVar,"ref"))[[1]]
      args=matchBracketFunc(refExp)
      if(is.null(args$j)){
        ref_k=args$i
        ref_k_C=R_oneIndex_exp_sub(varInfo,ref_k,k=i,k_C=i_C)
        res=R_oneIndex_exp_sub(varInfo,refExp[[2]],k=ref_k_C$value,k_C=TRUE,opt=opt,optCode=optCode)
        res$extCode=c(ref_k_C$extCode,res$extCode)
      }else{
        ref_i=args$i
        ref_j=args$j
        ref_i_C=R_oneIndex_exp_sub(varInfo,ref_i,k=i,k_C=i_C)
        ref_j_C=R_oneIndex_exp_sub(varInfo,ref_j,k=j,k_C=j_C)
        res=R_expression_sub(varInfo,refExp[[2]],i=ref_i_C$value,j=ref_j_C$value,
                             opt=opt,optCode=optCode,i_C=TRUE,j_C=TRUE)
        res$extCode=c(ref_i_C$extCode,ref_j_C$extCode,res$extCode)
      }
      return(res)
    }
    #If the expression is just a variable
    dataType=getVarProperty(varInfo,curVar,"dataType")
    #Scalar
    if(dataType==T_scale)
      return(list(value=getVarProperty(varInfo,curVar,"address",1)))
    #Matrix
    if(dataType==T_matrix){
      if(!i_C){
        i_C_ind=R_oneIndex_exp_sub(varInfo,i,k=1,k_C=TRUE)
      }else{
        i_C_ind=list(value=i)
      }
      if(!j_C){
        j_C_ind=R_oneIndex_exp_sub(varInfo,j,k=1,k_C=TRUE)
      }else{
        j_C_ind=list(value=j)
      }
      res=R_getVarSub(varInfo,Exp,i_C_ind$value,j_C_ind$value,opt=opt,optCode=optCode)
      res$extCode=c(i_C_ind$extCode,j_C_ind$extCode,res$extCode)
      return(res)
    }
    stop("unrecognized code: ",deparse(Exp))
  }
  #If the expression is also a subset of a matrix
  if(Exp[[1]]=="["){
    curVar=Exp[[2]]
    args=matchBracketFunc(Exp)
    
    #if it is one index subset
    #j will be ignored
    if(is.null(args$j)){
      sub=args$i
      k_C_ind=R_oneIndex_exp_sub(varInfo,sub,k=i,k_C=i_C)
      res=R_oneIndex_exp_sub(varInfo,curVar,k=k_C_ind$value,k_C=TRUE,opt=opt,optCode=optCode)
      res$extCode=c(k_C_ind$extCode,res$extCode)
    }else{
      #If the expression is a two index subset
      sub1=args$i
      sub2=args$j
      i_C_ind=R_oneIndex_exp_sub(varInfo,sub1,k=i,k_C=i_C)
      j_C_ind=R_oneIndex_exp_sub(varInfo,sub2,k=j,k_C=j_C)
      res=R_getVarSub(varInfo,curVar,i_C_ind$value,j_C_ind$value,opt=opt,optCode=optCode)
      res$extCode=c(i_C_ind$extCode,j_C_ind$extCode,res$extCode)
    }
    return(res)
  }
  stop("unrecognized code: ",deparse(Exp))
}


#Get an element from the matrix(eg. A[i,j]), the transpose will be taken into account
#i,j is 1-based index by default
#i,j should be either a number or a variable in C code
#If opt=FALSE, the c code will be returned
#If pt=TRUE, a list will be returned. list element: C_sub, rowOffset, colOffset
#optCode should be a list with rowVar,and colVar as the elements. Both element can be optional
R_getVarSub<-function(varInfo,var,i,j=1,opt=FALSE,optCode=list(),base=1){
  
  if(!is.character(var))
    var=deparse(var)
  
  if(var=="")
    return(list(value=as.character(i)))
  
  address=getVarProperty(varInfo,var,"address",1)
  transpose=getVarProperty(varInfo,var,"transpose")
  
  #Get the simplified index
  if(isNumeric(i)){
    sub1=Simplify(paste0(i,"-",base))
  }else{
    sub1=paste0(i,"-",base)
  }
  
  if(isNumeric(j)){
    sub2=Simplify(paste0(j,"-",base))
  }else{
    sub2=paste0(j,"-",base)
  }
  
  #compute the matrix offset
  size1=R_getVarSize1(varInfo,var)
  if(transpose){
    if(sub1==0)
      rowOffset=0
    else
      rowOffset=paste0("(",sub1,")*",size1)
    colOffset=sub2
  }else{
    rowOffset=sub1
    if(sub2==0)
      colOffset=0
    else
      colOffset=paste0("(",sub2,")*",size1)
  }
  
  if(!is.null(optCode[["rowVar"]]))
    rowOffset=optCode[["rowVar"]]
  if(!is.null(optCode[["colVar"]]))
    colOffset=optCode[["colVar"]]
  
  offset=paste0(rowOffset,"+",colOffset)
  c_sub=R_C_Sub(address,offset,simplification=TRUE)
  
  
  if(opt)
    return(list(value=c_sub,rowOffset=rowOffset,colOffset=colOffset))
  else
    return(list(value=c_sub))
}
#The C subset: var[offset]
#All the argument should be available in C code
R_C_Sub<-function(var,offset,simplification=FALSE){
  res=paste0(var,"[(",GPUVar$default_index_type,")(",offset,")]")
  if(simplification)
    res=CSimplify(res,TRUE)
  return(res)
}

#Get the number of rows for a matrix in C format
R_nrow<-function(varInfo,var){
  varExp=toExpression(var)
  var=varExp$expression
  var_char=varExp$char
  if(isNumeric(var_char))
    return(1)
  if(is.call(var))
    return(R_getVarSize1(varInfo,var))
  
  curInfo=getVarInfo(varInfo,var,1)
  ifelse(curInfo$transpose,
         R_getVarSize2(varInfo,var),
         R_getVarSize1(varInfo,var)
  )
}
#Get the number of rows for a matrix in C format
R_ncol<-function(varInfo,var){
  varExp=toExpression(var)
  var=varExp$expression
  var_char=varExp$char
  if(isNumeric(var_char))
    return(1)
  if(is.call(var))
    return(R_getVarSize2(varInfo,var))
  
  curInfo=getVarInfo(varInfo,var,1)
  ifelse(curInfo$transpose,
         R_getVarSize1(varInfo,var),
         R_getVarSize2(varInfo,var)
  )
}
R_length<-function(varInfo,var){
  return(Simplify(paste0(R_nrow(varInfo,var),"*",
                         R_ncol(varInfo,var))))
  
}


R_getVarSize<-function(varInfo,var,ind){
  varExp=toExpression(var)
  var=varExp$expression
  var_char=varExp$char
  
  #Detect if the variable is a subset of a matrix
  #Or a lazy reference
  Exp=NULL
  if(is.call(var)&&var[[1]]=="["){
    Exp=var
  }else{
    curInfo=getVarInfo(varInfo,var,1)
    if(curInfo$lazyRef){
      Exp=parse(text=curInfo$ref)[[1]]
    }
  }
  
  #If the variable is a subset of a matrix
  if(!is.null(Exp)){
    args=matchBracketFunc(Exp)
    refVar=Exp[[2]]
    if(ind==1){
      if(!is.null(args$i)&&args$i=="")
        return(R_nrow(varInfo,refVar))
      
      sub1=args$i
      if(isNumeric(sub1))
        return(1)
      
      return(R_length(varInfo,sub1))
    }
    if(ind==2){
      if(!is.null(args$j)&&args$j=="")
        return(R_ncol(varInfo,refVar))
      
      subs=args$j
      if(isNumeric(subs))
        return(1)
      
      return(R_length(varInfo,subs))
    }
  }
  
  
  #If the variable is just a variable and is not a lazy reference
  #curInfo is obtained above
  #curInfo=getVarInfo(varInfo,var,1)
  if(curInfo$dataType==T_scale) return(1)
  
  var_ind=varInfo$matrixInd[[var_char]]
  if(var_ind==""||is.na(var_ind))
    stop("Error in finding the matrix size") 
  loc=NA
  if(curInfo$location=="global"&&!curInfo$shared)
    loc="global_private_"
  if(curInfo$location=="global"&&curInfo$shared)
    loc="global_shared_"
  if(curInfo$location=="local"&&!curInfo$shared)
    loc="local_private_"
  if(curInfo$location=="local"&&curInfo$shared)
    loc="local_shared_"
  if(is.na(loc))
    stop("undetermined matrix property!")
  
  
  size=paste0(GPUVar[[paste0(loc,"size",ind)]],"[",var_ind,"]")
  
  size
}
#get the variable row number in C code format
#Use R_nrow instead, this function does not take the transpose into account
R_getVarSize1<-function(varInfo,var){
  R_getVarSize(varInfo,var,1)
}
#get the variable column number in C code format
#Use R_ncol instead, this function does not take the transpose into account
R_getVarSize2<-function(varInfo,var){
  R_getVarSize(varInfo,var,2)
}