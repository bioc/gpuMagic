

test_that("Matrix upload and download",{
  for(i in 1:5){
  k=100
  mydata=1:k
  mydata1=gpuMatrix(mydata,i)
  mydata1[]=0
  mydata1=download(mydata1)
  expect_equal(mydata1@data,1:k)
  }
})



#Cannot pass now
test_that("Matrix assignment",{
  for(i in 1:5){
    k=100
    mydata=matrix(1:k,10)
    mydata1=gpuMatrix(mydata,i)
    
    mydata1[1]=10
    mydata1[2,]=11
    mydata1[,3]=12
    mydata1=sync(mydata1)
    
    mydata[1]=10
    mydata[2,]=11
    mydata[,3]=12
    
    mydata1[]=0
    mydata1=download(mydata1)
    
    expect_equal(as.matrix(mydata1),mydata)
  }
})