#!/usr/bin/awk -f
BEGIN {
   i=0
   n=0
   total_energy=0.0
    energy_avail[s] = initenergy;
}

{
    event = $1
    time = $3
    node_id = $5
    energy_value=$7
    packet= $1500  # Assuming fixed packet size of 1500 bytes
    pkt_id=$41
    pkt_type-$35
    
    if (event == "N") {
        for(i=0;i<17;i++){
            if(i== node_id){
                energy_avail[i] = energy_avail[i]-(energy_avail[i] - energy_value);
                    # printf("%d-%f \n",i,energy_avail[i]);
            }
        
        }
        }
    
    }

    

END {
    for (i=0;i<17;i++) {
          printf("%d %f \n",i,energy_avail[i]);
    total_energy = total_energy + energy_avail[i];
      if(energy_avail[i] !=0)
      n++
    }
   # printf(" %f \n", total_energy);
   # printf("\n");
    }


