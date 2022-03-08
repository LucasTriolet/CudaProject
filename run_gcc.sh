
g++ -Wall -Ofast -o kMeans kMeans_CPU.cpp
echo "SIZE	K	Time(ms)	F(Hz)"
for (( K=4; K<=64; K+=4))
do
echo K = $K
for (( N=128; N<=65536; N+=256))
do
./kMeans.exe $N $K 20 >> run_res_long.txt
done
done
