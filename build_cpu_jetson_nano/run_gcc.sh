g++ -Wall -O0 -o kMeans kMeans_CPU.cpp
echo "////////// O0 ///////////" 
for K in {4..32..4} 
do
	echo "K = $K" 
	for N in {128..8192..128} 
	do 
		./kMeans $N $K 20 >> run_gcc_O0.txt 
	done 
done

g++ -Wall -O1 -o kMeans kMeans_CPU.cpp
echo "////////// O1 ///////////" 
for K in {4..32..4} 
do
	echo "K = $K" 
	for N in {128..8192..128} 
	do 
		./kMeans $N $K 20 >> run_gcc_O1.txt 
	done 
done

g++ -Wall -O2 -o kMeans kMeans_CPU.cpp
echo "////////// O2 ///////////" 
for K in {4..32..4} 
do
	echo "K = $K" 
	for N in {128..8192..128} 
	do 
		./kMeans $N $K 20 >> run_gcc_O2.txt 
	done 
done

g++ -Wall -O3 -o kMeans kMeans_CPU.cpp
echo "////////// O3 ///////////" 
for K in {4..32..4} 
do
	echo "K = $K" 
	for N in {128..8192..128} 
	do 
		./kMeans $N $K 20 >> run_gcc_O3.txt 
	done 
done

g++ -Wall -Ofast -o kMeans kMeans_CPU.cpp
echo "////////// Ofast ///////////" 
for K in {4..32..4} 
do
	echo "K = $K" 
	for N in {128..8192..128} 
	do 
		./kMeans $N $K 20 >> run_gcc_Ofast.txt 
	done 
done
