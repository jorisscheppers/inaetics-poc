cd container-linux-configs/
for f in *.conf 
    do
    echo "Processing $f"
    ignfile=${f%%.conf*}
    ct -pretty -in-file ${f} -out-file ../ignition-configs/${ignfile}.ign #-strict 
done