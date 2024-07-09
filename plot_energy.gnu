set terminal png
set output 'energy.png'
set title 'Throughput Over Time'
set xlabel 'Time (s)'
set ylabel 'Throughput (kbps)'

plot 'energy.dat' using 1:2 with lines title 'Residual Energy'

