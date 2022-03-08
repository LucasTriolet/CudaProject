
clang++ -Wall -O3 -o kMeans kMeans_CPU.cpp
echo "SIZE	K	Time(ms)	F(Hz)"
for (( K=4; K<=64; K+=4))
do
echo K = $K
for (( N=128; N<=65536; N+=256))
do
./kMeans_clang.exe $N $K 100 >> run_res_clang2.txt
done
done
