# Set terminal and output file
set terminal png
set output 'energy.png'

# Set plot properties
set title 'Energy Consumption Over Time'
set xlabel 'Time (s)'
set ylabel 'Energy'

# Plot data from energy.dat file
plot 'energy.dat' using 1:2 with lines title 'Residual Energy'

