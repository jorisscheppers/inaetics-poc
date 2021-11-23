cd container-linux-configs/
for f in *.conf 
    do
    echo "Processing $f"
    ignfile=${f%%.conf*}
    ct -pretty -strict -in-file ${f} -out-file ../ignition-configs/${ignfile}.ign 
done
#ct -pretty -strict -in-file container-linux-configs/c0-3f-d5-64-fd-54-pxe.conf -out-file ignition-configs/c0-3f-d5-64-fd-54-pxe.ign 
#ct -pretty -strict -in-file container-linux-configs/c0-3f-d5-64-fd-54-disk.conf -out-file ignition-configs/c0-3f-d5-64-fd-54-disk.ign 