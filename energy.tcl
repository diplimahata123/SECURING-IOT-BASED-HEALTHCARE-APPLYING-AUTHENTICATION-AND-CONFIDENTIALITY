# Define parameters for Curve25519
set p 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed  ;# Prime order of the base field
set a 486662 ;# Coefficient 'a' in the curve equation y^2 = x^3 + ax + b

# Function to calculate the inverse modulo p
proc mod_inverse {a p} {
    set t 0
    set newt 1
    set r $p
    set newr $a

    while {$newr != 0} {
        set quotient [expr {$r / $newr}]
        set temp $newt
        set newt [expr {$t - $quotient * $newt}]
        set t $temp
        set temp $newr
        set newr [expr {$r - $quotient * $newr}]
        set r $temp
    }

    if {$r > 1} {
        error "$a is not invertible"
    }
    if {$t < 0} {
        set t [expr {$t + $p}]
    }
    return $t
}

# Function to add two points on the curve
proc point_add {x1 y1 x2 y2} {
    global p a
    if {$x1 == $x2 && $y1 == $y2} {
        # Point doubling
        set l [expr {(3 * $x1 * $x1 + $a) * [mod_inverse [expr {2 * $y1}] $p] % $p}]
    } else {
        # Point addition
        set l [expr {($y2 - $y1) * [mod_inverse [expr {($x2 - $x1)}] $p] % $p}]
    }
    set x3 [expr {($l * $l - $x1 - $x2) % $p}]
    set y3 [expr {($l * ($x1 - $x3) - $y1) % $p}]
    return [list $x3 $y3]
}

# Function to perform scalar multiplication on the curve
proc scalar_multiply {k x y} {
    global p
    set x2 0
    set y2 1
    set x3 $x
    set y3 $y

    for {set i 254} {$i >= 0} {incr i -1} {
        if {[expr {($k >> $i) & 1}]} {
            set result [point_add $x2 $y2 $x3 $y3]
            set x2 [lindex $result 0]
            set y2 [lindex $result 1]
            set result [point_add $x3 $y3 $x3 $y3]
            set x3 [lindex $result 0]
            set y3 [lindex $result 1]
        } else {
            set result [point_add $x3 $y3 $x2 $y2]
            set x3 [lindex $result 0]
            set y3 [lindex $result 1]
            set result [point_add $x2 $y2 $x2 $y2]
            set x2 [lindex $result 0]
            set y2 [lindex $result 1]
        }
    }
    return [list $x2 $y2]
}

# Generate a 256-bit private key for Alice (example value)
set alice_private_key 0x123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

# Calculate Alice's public key
set alice_public_key [scalar_multiply $alice_private_key 9 1] ;# Base point for Curve25519 is (9, 1)

# Bob's private key is the same as Alice's (for demonstration)
set bob_private_key $alice_private_key

# Calculate Bob's public key
set bob_public_key [scalar_multiply $bob_private_key 9 1] ;# Base point for Curve25519 is (9, 1)

# Perform ECDH key exchange
set shared_key_alice [lindex [scalar_multiply $alice_private_key {*}$bob_public_key] 0]
set shared_key_bob [lindex [scalar_multiply $bob_private_key {*}$alice_public_key] 0]

puts "Alice's Private Key: $alice_private_key"
puts "Alice's Public Key: $alice_public_key"
puts "Bob's Private Key: $bob_private_key"
puts "Bob's Public Key: $bob_public_key"
puts "Shared Key (Alice): $shared_key_alice"
puts "Shared Key (Bob): $shared_key_bob"

# Confirm that the shared key is the same for both Alice and Bob
if {$shared_key_alice == $shared_key_bob} {
    puts "Shared key is the same for Alice and Bob"
} 


#===================================
#     Simulation parameters setup
#===================================
set val(chan)   Channel/WirelessChannel    ;# channel type
set val(prop)   Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)  Phy/WirelessPhy            ;# network interface type
set val(mac)    Mac/802_11                 ;# MAC type
set val(ifq)    Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)     LL                         ;# link layer type
set val(ant)    Antenna/OmniAntenna        ;# antenna model
set val(ifqlen) 50                         ;# max packet in ifq
set val(nn)     17                         ;# number of mobilenodes
set val(rp)     AODV                       ;# routing protocol
set val(x)      1151                      ;# X dimension of topography
set val(y)      100                      ;# Y dimension of topography
set val(stop)   16.0                         ;# time of simulation end

#===================================
#        Initialization        
#===================================
#Create a ns simulator
set ns [new Simulator]

#Setup topography object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)

#Open the NS trace file
set tracefile [open out.tr w]
$ns trace-all $tracefile

#Open the NAM trace file
set namfile [open out.nam w]
$ns namtrace-all $namfile
$ns namtrace-all-wireless $namfile $val(x) $val(y)
set chan [new $val(chan)];#Create wireless channel

#===================================
#     Mobile node parameter setup
#===================================
$ns node-config -adhocRouting  $val(rp) \
                -llType        $val(ll) \
                -macType       $val(mac) \
                -ifqType       $val(ifq) \
                -ifqLen        $val(ifqlen) \
                -antType       $val(ant) \
                -propType      $val(prop) \
                -phyType       $val(netif) \
                -channel       $chan \
                -topoInstance  $topo \
                -energyModel "EnergyModel" \
                -initialEnergy 100.0 \
                -txPower 0.9 \
                -rxPower 0.5 \
                -idlePower 0.45 \
                -sleepPower 0.05 \
                -agentTrace    ON \
                -routerTrace   ON \
                -macTrace      ON \
                -movementTrace ON \

#===================================
#        Nodes Definition        
#===================================
#Create 17 nodes
set n0 [$ns node]
$n0 set X_ 553
$n0 set Y_ 655
$n0 set Z_ 0.0
$ns initial_node_pos $n0 20
set n1 [$ns node]
$n1 set X_ 471
$n1 set Y_ 436
$n1 set Z_ 0.0
$ns initial_node_pos $n1 20
set n2 [$ns node]
$n2 set X_ 715
$n2 set Y_ 450
$n2 set Z_ 0.0
$ns initial_node_pos $n2 20
set n3 [$ns node]
$n3 set X_ 480
$n3 set Y_ 667
$n3 set Z_ 0.0
$ns initial_node_pos $n3 20
set n4 [$ns node]
$n4 set X_ 428
$n4 set Y_ 667
$n4 set Z_ 0.0
$ns initial_node_pos $n4 20
set n5 [$ns node]
$n5 set X_ 361
$n5 set Y_ 654
$n5 set Z_ 0.0
$ns initial_node_pos $n5 20
set n6 [$ns node]
$n6 set X_ 297
$n6 set Y_ 605
$n6 set Z_ 0.0
$ns initial_node_pos $n6 20
set n7 [$ns node]
$n7 set X_ 263
$n7 set Y_ 550
$n7 set Z_ 0.0
$ns initial_node_pos $n7 20
set n8 [$ns node]
$n8 set X_ 238
$n8 set Y_ 445
$n8 set Z_ 0.0
$ns initial_node_pos $n8 20
set n9 [$ns node]
$n9 set X_ 237
$n9 set Y_ 384
$n9 set Z_ 0.0
$ns initial_node_pos $n9 20
set n10 [$ns node]
$n10 set X_ 252
$n10 set Y_ 317
$n10 set Z_ 0.0
$ns initial_node_pos $n10 20
set n11 [$ns node]
$n11 set X_ 293
$n11 set Y_ 275
$n11 set Z_ 0.0
$ns initial_node_pos $n11 20
set n12 [$ns node]
$n12 set X_ 346
$n12 set Y_ 234
$n12 set Z_ 0.0
$ns initial_node_pos $n12 20
set n13 [$ns node]
$n13 set X_ 398
$n13 set Y_ 204
$n13 set Z_ 0.0
$ns initial_node_pos $n13 20
set n14 [$ns node]
$n14 set X_ 468
$n14 set Y_ 199
$n14 set Z_ 0.0
$ns initial_node_pos $n14 20
set n15 [$ns node]
$n15 set X_ 520
$n15 set Y_ 204
$n15 set Z_ 0.0
$ns initial_node_pos $n15 20
set n16 [$ns node]
$n16 set X_ 576
$n16 set Y_ 222
$n16 set Z_ 0.0
$ns initial_node_pos $n16 20

#===================================
#        Agents Definition        
#===================================
#Setup a TCP connection
set tcp0 [new Agent/TCP]
$ns attach-agent $n0 $tcp0
set sink15 [new Agent/TCPSink]
$ns attach-agent $n2 $sink15
$ns connect $tcp0 $sink15
$tcp0 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "Tdwdheugfyhdsbjkfdghf."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0
$ns at 1.0 "$ftp0 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 2.0 "$ftp0 stop"

#Setup a TCP connection
set tcp1 [new Agent/TCP]
$ns attach-agent $n3 $tcp1
set sink16 [new Agent/TCPSink]
$ns attach-agent $n2 $sink16
$ns connect $tcp1 $sink16
$tcp1 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "nfeufygeydsyfdyuhsfgfsduhufgy"
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"

#Setup a FTP Application over TCP connection
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ns at 2.0 "$ftp1 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 3.0 "$ftp1 stop"

#Setup a TCP connection
set tcp2 [new Agent/TCP]
$ns attach-agent $n4 $tcp2
set sink17 [new Agent/TCPSink]
$ns attach-agent $n2 $sink17
$ns connect $tcp2 $sink17
$tcp2 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "Mhjsgdygsufgskjdiyedfgtsfdtgs"
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ns at 3.0 "$ftp2 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 4.0 "$ftp2 stop"

#Setup a TCP connection
set tcp3 [new Agent/TCP]
$ns attach-agent $n5 $tcp3
set sink18 [new Agent/TCPSink]
$ns attach-agent $n2 $sink18
$ns connect $tcp3 $sink18
$tcp3 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "ghhdfwqtydfuasyfdtysgdu."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp3 [new Application/FTP]
$ftp3 attach-agent $tcp3
$ns at 4.0 "$ftp3 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 5.0 "$ftp3 stop"

#Setup a TCP connection
set tcp4 [new Agent/TCP]
$ns attach-agent $n6 $tcp4
set sink19 [new Agent/TCPSink]
$ns attach-agent $n2 $sink19
$ns connect $tcp4 $sink19
$tcp4 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp4 [new Application/FTP]
$ftp4 attach-agent $tcp4
$ns at 5.0 "$ftp4 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 6.0 "$ftp4 stop"

#Setup a TCP connection
set tcp5 [new Agent/TCP]
$ns attach-agent $n7 $tcp5
set sink20 [new Agent/TCPSink]
$ns attach-agent $n2 $sink20
$ns connect $tcp5 $sink20
$tcp5 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp5 [new Application/FTP]
$ftp5 attach-agent $tcp5
$ns at 6.0 "$ftp5 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 7.0 "$ftp5 stop"

#Setup a TCP connection
set tcp6 [new Agent/TCP]
$ns attach-agent $n8 $tcp6
set sink29 [new Agent/TCPSink]
$ns attach-agent $n2 $sink29
$ns connect $tcp6 $sink29
$tcp6 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp6 [new Application/FTP]
$ftp6 attach-agent $tcp6
$ns at 7.0 "$ftp6 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 8.0 "$ftp6 stop"

#Setup a TCP connection
set tcp7 [new Agent/TCP]
$ns attach-agent $n9 $tcp7
set sink22 [new Agent/TCPSink]
$ns attach-agent $n2 $sink22
$ns connect $tcp7 $sink22
$tcp7 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp7 [new Application/FTP]
$ftp7 attach-agent $tcp7
$ns at 8.0 "$ftp7 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 9.0 "$ftp7 stop"

#Setup a TCP connection
set tcp8 [new Agent/TCP]
$ns attach-agent $n10 $tcp8
set sink23 [new Agent/TCPSink]
$ns attach-agent $n2 $sink23
$ns connect $tcp8 $sink23
$tcp8 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp8 [new Application/FTP]
$ftp8 attach-agent $tcp8
$ns at 9.0 "$ftp8 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 10.0 "$ftp8 stop"

#Setup a TCP connection
set tcp9 [new Agent/TCP]
$ns attach-agent $n11 $tcp9
set sink24 [new Agent/TCPSink]
$ns attach-agent $n2 $sink24
$ns connect $tcp9 $sink24
$tcp9 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp9 [new Application/FTP]
$ftp9 attach-agent $tcp9
$ns at 10.0 "$ftp9 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 11.0 "$ftp9 stop"

#Setup a TCP connection
set tcp10 [new Agent/TCP]
$ns attach-agent $n12 $tcp10
set sink25 [new Agent/TCPSink]
$ns attach-agent $n2 $sink25
$ns connect $tcp10 $sink25
$tcp10 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp10 [new Application/FTP]
$ftp10 attach-agent $tcp10
$ns at 11.0 "$ftp10 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 12.0 "$ftp10 stop"

#Setup a TCP connection
set tcp11 [new Agent/TCP]
$ns attach-agent $n13 $tcp11
set sink21 [new Agent/TCPSink]
$ns attach-agent $n2 $sink21
$ns connect $tcp11 $sink21
$tcp11 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp11 [new Application/FTP]
$ftp11 attach-agent $tcp11
$ns at 12.0 "$ftp11 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 13.0 "$ftp11 stop"

#Setup a TCP connection
set tcp12 [new Agent/TCP]
$ns attach-agent $n14 $tcp12
set sink26 [new Agent/TCPSink]
$ns attach-agent $n2 $sink26
$ns connect $tcp12 $sink26
$tcp12 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp12 [new Application/FTP]
$ftp12 attach-agent $tcp12
$ns at 13.0 "$ftp12 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 14.0 "$ftp12 stop"

#Setup a TCP connection
set tcp13 [new Agent/TCP]
$ns attach-agent $n15 $tcp13
set sink27 [new Agent/TCPSink]
$ns attach-agent $n2 $sink27
$ns connect $tcp13 $sink27
$tcp13 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp13 [new Application/FTP]
$ftp13 attach-agent $tcp13
$ns at 14.0 "$ftp13 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 15.0 "$ftp13 stop"

#Setup a TCP connection
set tcp14 [new Agent/TCP]
$ns attach-agent $n16 $tcp14
set sink28 [new Agent/TCPSink]
$ns attach-agent $n2 $sink28
$ns connect $tcp14 $sink28
$tcp14 set packetSize_ 1500
# Define the plaintext to be encrypted
set plaintext "This is a secret message."
puts "Plaintext: $plaintext"

# Generate a 32-byte IV (64 characters)
set iv [exec openssl rand -hex 16]

# Derive symmetric encryption keys from the shared secret using MD5 hash function
set md5_hash_A [exec echo "$shared_key_alice" | openssl dgst -md5 -binary | xxd -p]
set md5_hash_B [exec echo "$shared_key_bob" | openssl dgst -md5 -binary | xxd -p]

# Pad md5_hash_A and md5_hash_B with zeros to make them 64 characters long
set md5_hash_A_padded [format %064s $md5_hash_A]
set md5_hash_B_padded [format %064s $md5_hash_B]

# Encrypt the plaintext using ECC-derived encryption key and the generated IV for party A
set encrypted [exec echo $plaintext | openssl enc -aes-256-cbc -a -e -K $md5_hash_A_padded -iv $iv]

# Print the encrypted text
puts "Encrypted: $encrypted"
#Setup a FTP Application over TCP connection
set ftp14 [new Application/FTP]
$ftp14 attach-agent $tcp14
$ns at 15.0 "$ftp14 start"
# Decrypt the encrypted text using ECC-derived decryption key for party B
set decrypted [exec echo $encrypted | openssl enc -aes-256-cbc -a -d -K $md5_hash_B_padded -iv $iv]
# Print the decrypted text
puts "Decrypted: $decrypted"
$ns at 16.0 "$ftp14 stop"

#===================================
#        Termination        
#===================================
#Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
    exec nam out.nam &
    exec awk -f extract_energy.awk out.tr > energy.dat
    exit 0
}
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "\$n$i reset"
}
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "finish"
$ns at $val(stop) "puts \"done\" ; $ns halt"
puts "starting simulation...."

$ns run

