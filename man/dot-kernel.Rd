% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/kernelManager.R
\name{.kernel}
\alias{.kernel}
\title{Excute the openCL function}
\usage{
.kernel(
  src = "",
  kernel,
  parms,
  .device = "auto",
  .globalThreadNum = "length(FirstArg)",
  .options = kernel.getOption()
)
}
\arguments{
\item{src}{the source code, it can be either a file directory or the code}

\item{kernel}{the kernel function that will be called on the device}

\item{parms}{a list containing the function arguments.
The number of elements in the list has to match the number of function arguments.}

\item{.device}{the device that will excute the function.
If not specified, all the selected devices will be used.}

\item{.globalThreadNum}{the number of threads that will be created to excute the kernel.
If not specified, the length of the first argument will be used as the thread number}

\item{.options}{the kernel options}
}
\value{
A vector or a matrix
}
\description{
The function serves as a bridge between R and openCL, it sends the openCL code and
R matrix object to the device and excutes it on the device. The function has an auto-type
ability which can make the openCL code independent with the type of its function argument,
see detail and examples for the usage.
}
\details{
The function \code{.kernel()} is the low level API to communicate with openCL device.
It provides a way to run the customized code on the device, the source code should be
openCL code and the kernel is the kernel function that you want to run on the device.

You can specify with device the code should be run on by specifying the \code{.device} argument.
By default, if you do not specify any device, the first device in the device list will be used

The argument \code{.globalThreadNum} specifys the number of threads that will be used to excute the kernel.
The concept is the same as `global_work_size`` in openCL functions

There are multiple options that you can change in the kernel function.
You can call the function \code{kernel.getOption()} to obtain the default setting.
The most distinguishable feature in this package is probably the auto type function, which
can set the type of the kernel arguments as an macro in the openCL code. This feature allows the
user to create a type-free code. If the \code{kernelOption$autoType} in \code{.options} is true(Default),
four macros will be defined, they are(X is the position of the function arguments):

autoX: The variable type

gAutoX: Short for global autoX

lAutoX: short for local autoX

autoX_v4: Define a vector of length 4 with the same variable type as the X th function argument

Please refer to the example for the usage
}
\examples{
#The GPU code
code='
kernel void matAdd(gAuto1* A,gAuto2* B,gAuto3* C,gAuto4* size){
uint col_id=get_global_id(0);
uint rowNum=*size;
for(uint i=0;i<rowNum;i++){
C[i+col_id*rowNum]=A[i+col_id*rowNum]+B[i+col_id*rowNum];
}
}
'
#Create data in R
m=100
n=200
A=matrix(runif(m*n),m,n)
B=matrix(runif(m*n),m,n)
#Send the data to GPU
A_dev=gpuMatrix(A,type='double')
B_dev=gpuMatrix(B,type='double')
#Create an empty data matrix in GPU
C_dev=gpuEmptMatrix(row=m,col=n,type='double')

#Get the default options
options=kernel.getOption()
#Run the GPU function with n threads, each thread computes one column addition
.kernel(src = code,kernel='matAdd',parms=list(A_dev,B_dev,C_dev,m),
.globalThreadNum = n,.options = options)

#This is just a patch to fix check error
if(!is.null(C_dev)){
#Retrieve the data
C_dev=download(C_dev)
C=as.matrix(C_dev)
#Check the error
range(C-A-B)
}
}
