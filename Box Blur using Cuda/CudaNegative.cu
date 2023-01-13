#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>

#include "lodepng.h"

//compile with c++ lodepng file

//nvcc CudaNegative.cu lodepng.cpp

__global__ void square(unsigned char * ImageOuput, unsigned char * Image, int a , int b){

	int x[]={NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};

	int red=0,green=0,blue=0,trans=0;
	int i = blockDim.x * blockIdx.x + threadIdx.x;
	if(i==0){
		x[0]=i;
		x[1]=i+1;
		x[2]=i+b;
		x[3]=i+b+1;

	}
	else if(i>0 && i<(b-1)){
		x[0]=i;
		x[1]=i+1;
		x[2]=i-1;
		x[3]=i+b;
		x[4]=1+i+b;
		x[5]=i+b-1;
	}
	else if (i==(b-1)){
		x[0]=i;
		x[1]=i-1;
		x[2]=i+b;
		x[3]=i+b-1;
	}
	else if(((i > b-1 && i< (a*b)-b) && ((i+1) % b ==0))){
		x[0]=i;
		x[1]=i-1;
		x[2]=i-b;
		x[3]=i-b-1;
		x[4]=i+b;
		x[5]=i+b-1;
	}
	else if (i==((a*b)-1)){
		x[0]=i;
		x[1]=i-1;
		x[2]=i-b-1;
		x[3]=i-b;
	}
	else if(i>((a*b)-b) && i < (a*b)){
		x[0]=i;
		x[1]=i+1;
		x[2]=i-1;
		x[3]=i-b;
		x[4]=i-b-1;
		x[5]=i-b+1;
	}
	else if(i==(a*b)-b){
		x[0]=i;
		x[1]=i+1;
		x[2]=i-b;
		x[3]=i-b+1;
	}
	else if((i>b-1 &&i<(a*b)-(2*b+1))&&i % b ==0){
		x[0]=i;
		x[1]=i+1;
		x[2]=i+b;
		x[3]=i+b+1;
		x[4]=i-b;
		x[5]=i-b+1;

	}
	else{
		x[0]=i;
		x[1]=i+1;
		x[2]=i-1;
		x[3]=i+b;
		x[4]=i+b+1;
		x[5]=i+b-1;
		x[6]=i-b;
		x[7]=i-b+1;
		x[8]=i-b-1;
	}
	int pixel = i*4;
	int c=0;
for (int i=0;i<sizeof(x)/sizeof(x[0]);i++){
	if(x[i]!=NULL){
		red+= Image[x[i]*4];
		green+= Image[x[i]*4+1];
		blue+= Image[x[i]*4+2];
		c++;
		}

	}
		red=red/c;
		green=green/c;
		blue=blue/c;
		trans=Image[i*4+3];
		ImageOuput[pixel] = red;
		ImageOuput[1+pixel] = green;
		ImageOuput[2+pixel] = blue;
		ImageOuput[3+pixel] = trans;
}

int main(int argc, char **argv){

	unsigned int error;
	unsigned int encError;
	unsigned char* image;
	unsigned int width;
	unsigned int height;
	const char* filename = "HCK.png";
	const char* newFileName = "generated_cuda.png";

	error = lodepng_decode32_file(&image, &width, &height, filename);
	if(error){
		printf("error %u: %s\n", error, lodepng_error_text(error));
	}

	const int ARRAY_SIZE = width*height*4;
	const int ARRAY_BYTES = ARRAY_SIZE * sizeof(unsigned char);

	unsigned char host_imageInput[ARRAY_SIZE * 4];
	unsigned char host_imageOutput[ARRAY_SIZE * 4];

	for (int i = 0; i < ARRAY_SIZE; i++) {
		host_imageInput[i] = image[i];
	}

	// declare GPU memory pointers
	unsigned char * d_in;
	unsigned char * d_out;
	int a=height;//height
	int b=width;//widht

	// allocate GPU memory
	cudaMalloc((void**) &d_in, ARRAY_BYTES);
	cudaMalloc((void**) &d_out, ARRAY_BYTES);
	// cudaMalloc((void*) &a, sizeof(int));
	// cudaMalloc(( void*) &b, sizeof(int));


	cudaMemcpy(d_in, host_imageInput, ARRAY_BYTES, cudaMemcpyHostToDevice);
	// cudaMemcpy(a, height, sizeof(int), cudaMemcpyHostToDevice);
	// cudaMemcpy(b, width, sizeof(int), cudaMemcpyHostToDevice);


	// launch the kernel
	square<<<height, width>>>(d_out, d_in,a,b);

	// copy back the result array to the CPU
	cudaMemcpy(host_imageOutput, d_out, ARRAY_BYTES, cudaMemcpyDeviceToHost);
	
	encError = lodepng_encode32_file(newFileName, host_imageOutput, width, height);
	if(encError){
		printf("error %u: %s\n", error, lodepng_error_text(encError));
	}
	printf("%d->%d",height, width);
	//free(image);
	//free(host_imageInput);
	cudaFree(d_in);
	cudaFree(d_out);

	return 0;
}
