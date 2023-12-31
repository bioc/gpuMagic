% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gpuMatix-class.R
\name{ncol,gpuMatrix-method}
\alias{ncol,gpuMatrix-method}
\alias{ncol}
\title{gpuMatrix class}
\usage{
\S4method{ncol}{gpuMatrix}(x)
}
\arguments{
\item{x}{an gpuMatrix object}
}
\value{
\code{\link[=gpuMatrix]{gpuMatrix()}}: A gpuMatrix object

\code{\link[=gpuEmptMatrix]{gpuEmptMatrix()}}: A gpuMatrix object
}
\description{
gpuMatrix class
}
\details{
\code{gpuMatrix()}: Create a matrix in an openCL device

\code{gpuEmptMatrix()}: Create an empty matrix without initialization in an openCL device

\code{upload()}: The function will automatically be called when an gpuMatrix object is created.
It is only needed when you want to update value of the matrix.

\code{download()}: Get the data from the device. You should explicitly call it when you want to collect the data from the device.

\code{nrow()},\code{ncol()}: return the number of rows or columns present in \code{x}

\code{dim()}: Retrieve the dimension of an gpuMatrix object

\code{length()}: Get the length of an gpuMatrix object.

'getSize()': Get the matrix size in byte
}
\examples{
n=10
m=20
A=matrix(runif(n*m),n,m)
#Create a 64 bit floating point GPU matrix
A_dev=gpuMatrix(A,'double')

#Create an empty matrix
B_dev=gpuEmptMatrix(row=n,col=m)
}
