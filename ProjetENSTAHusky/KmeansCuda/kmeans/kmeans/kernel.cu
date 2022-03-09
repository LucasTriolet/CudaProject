#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <device_functions.h>

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <time.h>

#define K 5
#define NUM_THREADS 32
#define NUM_BLOCKS	8
#define MAX_ITER	1

cudaError_t kmeansWithCuda();

__device__ int distance(int x1, int x2) {
	return sqrtf((x2 - x1)*(x2 - x1));
}

__global__ void kmeansClusterAssignmentKernel(int *d_dataPoints, int *d_clusterAssignment, int *d_centroids, int N){
	const int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx >= N) return;

	int min_dist = 5000;
	int closest_centroid = 0;

	for (int c = 0; c < K; c++) {
		int dist = distance(d_dataPoints[idx], d_centroids[c]);
		if (dist < min_dist) {
			min_dist = dist;
			closest_centroid = c;
		}
	}

	d_clusterAssignment[idx] = closest_centroid;
	//printf("idx du kernel : %d \n", idx);
}

/* Non fonctionnelle pour le moment */
__global__ void kmeansCentroidUpdate(int *d_dataPoints, int *d_clusterAssignment, int *d_centroids, int *d_clustersSize, int N) {
	const int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx >= N) return;	

	const int s_idx = threadIdx.x;
	__shared__ int s_dataPoints[32];
	s_dataPoints[s_idx] = d_dataPoints[idx];
	__shared__ int s_clusterAssignment[32];
	s_clusterAssignment[s_idx] = d_clusterAssignment[s_idx];

	__syncthreads();

	//On somme par l'indice 0 pour chaque bloc
	if (s_idx == 0) {
		int block_clusterDataPointsSum[K] = { 0 };
		int block_clustersSizes[K] = { 0 };

		//sommation
		for (int i = 0; i < blockDim.x; i++) {
			int clusterId = s_clusterAssignment[i];
			block_clusterDataPointsSum[clusterId] += s_dataPoints[i];
			block_clustersSizes[clusterId] += 1;
		}

		for (int j = 0; j < K; j++) {
			printf("atomicAdd, valeur de la centroide avant addition : %d \n", &d_centroids[j]);
			printf("valeur de la somme avant addition : %d \n", block_clusterDataPointsSum[j]);
			atomicAdd(&d_centroids[j], block_clusterDataPointsSum[j]);
			printf("valeur apres addition de centroide : %d \n", &d_centroids[j]);
			atomicAdd(&d_clustersSize[j], block_clustersSizes[j]);
		}
	}

	__syncthreads();

	if (idx < K) {
		d_centroids[idx] = d_centroids[idx] / d_clustersSize[idx];
	}

}

int main(){
    // Add vectors in parallel.
    cudaError_t cudaStatus = kmeansWithCuda();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "kmeansWithCuda failed!");
        return 1;
    }

    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }

    return 0;
}

std::string readFile(const std::string &toRead) {
	std::ifstream fd(toRead.c_str());
	std::string buffer;
	char ch;
	while (fd.get(ch)) buffer.push_back(ch);
	buffer.push_back('\n');
	return buffer;
}

std::vector<int> parseFile(const std::string &data) {
	std::vector<int> res;
	std::string tmp;

	for (int i = 0; i < data.length(); i++) {
		//std::cout << "i : " << i << " et fileData[i] : " << data[i] << std::endl;
		if (data[i] == ' ' || data[i] == '\n') {
			if (tmp.empty())	continue;
			res.push_back(std::stoi(tmp));
			tmp.erase();
		}
		else {
			tmp.push_back(data[i]);
		}
	}
	return res;
}

int* vector2int(const std::vector<int>& v, const int& size) {
	int *res = new int[size];
	for (int i = 0; i < size; i++) {
		res[i] = v[i];
	}
	return res;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t kmeansWithCuda(){
	std::ifstream file;
	std::string path = "C:/Users/Quentin/Desktop/Le Reste/ProjetENSTAHusky/carteDistance.txt";
	std::string fileData;
	srand(time(NULL));
    int *dev_dataPoints = 0;
    int *dev_clustersAssigned = 0;
    int *dev_centroids = 0;
	int *dev_clustersSize = 0;
	float millisecondsKernel = 0, millisecondsGlobal = 0;
	int centroids[K], clustersSize[K];
	for (int i = 0; i < K; i++) {
		centroids[i] = rand() % 200 + i*200;
		std::cout << "Centroide " << i << " : " << centroids[i] << std::endl;
		clustersSize[i] = 0;
	}
	int currentIter = 1;
    cudaError_t cudaStatus;
	cudaEvent_t startKernel, stopKernel, startGlobal, stopGlobal;
	cudaEventCreate(&startKernel);
	cudaEventCreate(&startGlobal);
	cudaEventCreate(&stopKernel);
	cudaEventCreate(&stopGlobal);

	// Récupération des données provenant d'un fichier txt d'entrée
	fileData = readFile(path);
	//std::cout << fileData << std::endl;
	std::cout << "nombre d'elements: " << fileData.length() << std::endl;
	std::vector<int> res = parseFile(fileData);
	int *resInt = vector2int(res, res.size());
	int *clusterAssigned = (int*)malloc(res.size() * sizeof(int));
	//for(size_t i = 0; i < res.size(); i++)	std::cout << res[i] << std::endl;
	//std::cout << "nombre d'elements dans le vecteur : " << res.size() << std::endl;
	std::cout << "Nombre d'elements du vecteur apres parsing : " << res.size() << std::endl;
	std::cout << "premier element du vecteur : " << res[0] << std::endl;
	std::cout << "premier element du tableau de int : " << resInt[0] << std::endl;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_clustersSize, K * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "dev_clustersSize - cudaMalloc failed! \n");
        goto Error;
    }

	cudaStatus = cudaMalloc((void**)&dev_centroids, K * sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "dev_centroids - cudaMalloc failed! \n");
		goto Error;
	}

    cudaStatus = cudaMalloc((void**)&dev_dataPoints, res.size() * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "resInt - cudaMalloc failed! \n");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_clustersAssigned, res.size() * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "dev_clustersAssigned - cudaMalloc failed! \n");
        goto Error;
    }
	
	std::cout << "Mallocs sur le device termines" << std::endl;
	cudaEventRecord(startGlobal);
    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_dataPoints, resInt, res.size() * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "hostToDevice - dataPoints - cudaMemcpy failed! \n");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_centroids, &centroids, K * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "hostToDevice - centroids - cudaMemcpy failed! \n");
        goto Error;
    }

	cudaStatus = cudaMemcpy(dev_clustersSize, clustersSize, K * sizeof(int), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "hostToDevice - clusterSize - cudaMemcpy failed! \n");
		goto Error;
	}

	std::cout << "Memcpy vers le device termines" << std::endl;


	cudaEventRecord(startKernel);
	while (currentIter < MAX_ITER) {
		// Launch a kernel on the GPU with one thread for each element.
		std::cout << "Lancement du kernel Cluster Assignment" << std::endl;
		kmeansClusterAssignmentKernel <<< (res.size() + NUM_THREADS - 1) / NUM_THREADS, NUM_THREADS >> > (dev_dataPoints, dev_clustersAssigned, dev_centroids, res.size());
		std::cout << "Kernel Cluster Assignment applique" << std::endl;

/*		cudaStatus = cudaMemcpy(centroids, dev_centroids, K * sizeof(int), cudaMemcpyDeviceToHost);
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "clusterAssigned - cudaMemcpy failed! \n");
			goto Error;
		}
		for (int i = 0; i < K; i++) {
			std::cout << "Iteration " << currentIter <<", centroide " << i << " situe a une distance " << centroids[i] << std::endl;
		}

		cudaMemset(dev_centroids, 0, K * sizeof(int));
		cudaMemset(dev_clustersSize, 0, K * sizeof(int));
		std::cout << "Lancement du kernel Centroid Update" << std::endl;
		kmeansCentroidUpdate <<< (res.size() + NUM_THREADS - 1) / NUM_THREADS, NUM_THREADS >> > (dev_dataPoints, dev_clustersAssigned, dev_centroids, dev_clustersSize, res.size());
		std::cout << "Kernel Centroid Update applique" << std::endl;*/
		currentIter++;
	}
	cudaEventRecord(stopKernel);


    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "kmeansClusterAssignmentKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching kmeansClusterAssignmentKernel!\n", cudaStatus);
        goto Error;
    }

	std::cout << "Avant memcpy de dev_cluster vers l'host" << std::endl;
    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(clusterAssigned, dev_clustersAssigned, res.size() * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "clusterAssigned - cudaMemcpy failed! \n");
        goto Error;
    }
	std::cout << "Memcpy de dev_cluster vers l'host termine" << std::endl;

	cudaEventRecord(stopGlobal);
	std::cout << "Memcpy vers l'host termines" << std::endl;
/*	for (int i = 0; i < res.size(); i++) {
		std::cout << "Clusters assignes pour i valant : " << i << " cluster : " << clusterAssigned[i] << std::endl;
	}*/

	cudaEventSynchronize(stopKernel);
	cudaEventSynchronize(stopGlobal);
	cudaEventElapsedTime(&millisecondsKernel, startKernel, stopKernel);
	cudaEventElapsedTime(&millisecondsGlobal, startGlobal, stopGlobal);
	
	printf("Performances du kernel : %f msec \n\r", millisecondsKernel);
	printf("Performances du kernel, avec transferts memoire : %f msec \n\r", millisecondsGlobal);

Error:
    cudaFree(dev_clustersAssigned);
    cudaFree(dev_dataPoints);
    cudaFree(dev_centroids);
	free(clusterAssigned);

    return cudaStatus;
}
