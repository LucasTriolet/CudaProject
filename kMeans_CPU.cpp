#define _USE_MATH_DEFINES
#define EPS 0.001f

#include <stdio.h>
#include <stdlib.h>
#include <algorithm>
#include <time.h>
#include <cmath>
#include <intrin.h>
#include <ctime>

struct timespec start, end;
double timetaken;

template<typename T>
struct LidarData
{
  T d; //distance
  float a; //angle
  int k; //k_class
  LidarData() : d(0), a(0), k(-1) {}
  LidarData(int _d, float _a, int _k) : d(_d), a(_a), k(_k) {}
  LidarData(const LidarData<int>& ld) : d((T)ld.d), a(ld.a), k(ld.k) {}
  LidarData operator+=(const LidarData& ld)
  {
    d += ld.d;
    a += ld.a;
    //k &= ld.k;
    return *this;
  }
  void print() 
  {
    printf("[%.4f, %.4f, %i]  ", (float)d, a, k);
  }
  void print_to_file(FILE* f)
  {
    fprintf(f, "%.4f  %.4f  %i\n", d, a, k);
  }
  void mean(const int _s)
  {
    d /= (T)_s;
    a /= (float)_s;
  }
  bool near(const LidarData& ld, const float eps)
  {
    float v = std::min(abs(a - ld.a), abs( abs(a - ld.a) - 360));
    return v < eps && abs(ld.d - d) < eps;
  }
  float dist(const LidarData& ld)
  {
    float v = std::min(abs(a - ld.a), abs( abs(a - ld.a) - 360));
    return v + 10*abs(d - ld.d);
  }
};

struct { bool operator()(LidarData<float> a, LidarData<float> b) const { return a.k < b.k; } }k_less;

double kMeansST(LidarData<float> *ld, int size, const int k)
{
  int iter;
  int i,j;
  LidarData<float>  centroids[512], old_centroids[512];
  int        count_k[512];
  bool centroids_change = true;
  srand(time(NULL));

  clock_gettime(CLOCK_MONOTONIC, &start);
	/// <summary>
	/// Init 
	/// </summary>
	for (i = 0; i < size; i++)
	{
	  ld[i].d = (rand() % 10000) / 100.f;//100*(float)sin((double)i*M_PI / (double)size);
	  ld[i].a = (rand() % (360*4)) / (float)4;
	  ld[i].k = rand() % k;
	}

	iter = 0;

	/// <summary>
	/// Sort the Lidar Data 
	/// </summary>

	while (centroids_change || iter > CHAR_MAX)
	{
	  iter++;
	  for (i = 0; i < k; i++) { centroids[i] = LidarData<float>(0, 0, i); count_k[i] = 0; } //init

	  /// <summary>
	  /// Centroid Calculation
	  /// 
	  /// Complexity ST : size
	  /// Complexity Cuda : size*(log(size)+1) need to sort before to apply sum reduction efficiently
	  /// 
	  /// </summary>
	  for (i = 0; i < size; i++)
	  {
		centroids[ld[i].k] += LidarData<float>(ld[i]);
		count_k[ld[i].k] += 1;
	  }

	  /// <summary>
	  /// Means of centroids
	  /// 
	  /// Complexity ST : k (one divide)
	  /// Complexity Cuda : k (one divide)
	  /// 
	  /// </summary>
	  for (i = 0; i < k; i++)
	  {

		centroids[i].mean(count_k[i]);
		if (centroids[i].near(old_centroids[i], EPS)) centroids_change = false;
		old_centroids[i] = centroids[i];
	  }

	  /// <summary>
	  /// Reassignation of centroids
	  /// 
	  /// Complexity ST : size*k
	  /// Complexity Cuda : size*k => trivial // 
	  /// </summary>
	  for (i = 0; i < size; i++)
		for (j = 0; j < k; j++)
		{
		  if (ld[i].dist(centroids[ld[i].k]) > ld[i].dist(centroids[j]))
		  {
			ld[i].k = j;
		  }
		}
	  //for (j = 0; j < k; j++) centroids_add[j]->k = j;
	  //printf("\n");
	  //centroids_change = false;
	}
  clock_gettime(CLOCK_MONOTONIC, &end);
  timetaken = (end.tv_sec - start.tv_sec)*1e9;
  timetaken += (end.tv_nsec - start.tv_nsec);
  //printf("kmeans took %lf ns\n", timetaken);
  //for (i = 0; i < k; i++) centroids[i].print(); printf("\n");
  //for (i = 0; i < k; i++) old_centroids[i].print();
//  std::sort(ld, ld + size, k_less);
/*  FILE* f = fopen("results.txt", "w");
  for (i = 0; i < size; i++)
  {
	ld[i].print_to_file(f);
  }
  fclose(f);*/
  return timetaken;
}

int main(int argc, char** argv)
{
  int it, k, size;
  //printf("[.exe] [size] [k] [iter]\n");
  //printf("argc = %i \n", argc);
  
  //for (int i = 0; i < argc; i++) printf("argv[%i] = %s\n", i, argv[i]);
  if (argc > 2) k = atoi(argv[2]); else k = 16;
  if (argc > 1) size = atoi(argv[1]); else size = 32768;
  if (argc > 3) it = atoi(argv[3]); else it = 100;
  LidarData<float>* ld = new LidarData<float>[size];
  double t = 0;
  for(int i = 0; i < it; i++) t+=kMeansST(ld, size, k);
  //printf("average time : %.2lf ms\n", t/it / 1000000);
  printf("%i	%i	%.2lf	%.2lf\n", size, k, t/it / 1000000, it/t*1000000000);
  //k2ST()
  delete[] ld;
  return 0;
}
