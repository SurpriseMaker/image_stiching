#!/data/data/com.termux/files/usr/bin/bash
img_root_path=$1
server_ip_address=$2
img_ftp_upload_path=ftp://${server_ip_address}/src/
img_ftp_download_path=ftp://${server_ip_address}/out/output.png
cgi_stich_path=${server_ip_address}/cgi-bin/stich_image.py
cgi_clean_path=${server_ip_address}/cgi-bin/clean.py
net_rate=(100m 1m)

function clean(){
    curl $cgi_clean_path
}

function getdir(){
    for element in `ls $1`
    do  
        dir_or_file=$1"/"$element
        if [ -d $dir_or_file ]
        then 
            getdir $dir_or_file
        else
            echo $dir_or_file
	fi
    done
}

function stich_core(){
img_src_path=$1
net_rate=$2

echo "Step 1. Starting image stiching remotely."

#clean previous images
clean

time_upload_img_start=$(date +%s%N)
# find pictures
for file in ${img_src_path}/*
do

    if test -f $file
    then
            arr=(${arr[*]} $file)
            curl -T $file $img_ftp_upload_path --limit-rate $net_rate
    fi
done    
time_upload_img_end=$(date +%s%N)
time_upload_img_duration_ms=$[(time_upload_img_end-time_upload_img_start)/1000000]
echo "image uploaded: ${arr[@]}" 
echo "upload image duration =$time_upload_img_duration_ms ms"

#Request server to do image stiching
echo "Stiching images remotely, this may take a while of time."
echo "Waiting feedback..."
time_stich_img_remotely_start=$(date +%s%N)
curl $cgi_stich_path
time_stich_img_remotely_end=$(date +%s%N)
time_stich_img_remotely_duration_ms=$[(time_stich_img_remotely_end-time_stich_img_remotely_start)/1000000]
echo "Image stiched remotely duration = $time_stich_img_remotely_duration_ms ms"

#download the merged photo
time_download_img_start=$(date +%s%N)
curl -O $img_ftp_download_path --limit-rate $net_rate
time_download_img_end=$(date +%s%N)
time_download_img_duration_ms=$[(time_download_img_end-time_download_img_start)/1000000]
echo "Image download duration = $time_download_img_duration_ms ms"
echo "Image stiching remotely finished.\t\t."

#run image stiching locally
echo "Step 2. Starting image stiching locally.This may take a long time, please wait..."
time_local_stich_start=$(date +%s%N)
#python image_stitching.py --images $img_src_path --output output.png --crop 1
time_local_stich_end=$(date +%s%N)
time_local_stich_duration_ms=$[(time_local_stich_end-time_local_stich_start)/1000000]
echo "Image stiched locally duration =$time_local_stich_duration_ms  ms"
echo "Image stiching locally finished."

time_remote_faster_ms=$[(time_local_stich_duration_ms-time_upload_img_duration_ms-time_stich_img_remotely_duration-time_download_img_duration)]

echo "SUMMARIZE"
echo "upload image duration =$time_upload_img_duration_ms ms"
echo "Image stiched remotely duration = $time_stich_img_remotely_duration_ms ms"
echo "Image download duration = $time_download_img_duration_ms ms"
echo "Image stiched locally duration =$time_local_stich_duration_ms  ms"
echo "Stiching remotely is $time_remote_faster_ms ms faster than locally."
}

function stich_one_sample(){
    img_path=$1
	for element_rate in ${net_rate[@]}
	do
	    stich_core $img_path $element_rate
	done

}

function stich_all_samples(){
	for folder in ${img_root_path}/*
	do
		if test -d $folder
		then
			stich_one_sample $folder
		fi
	done
}

stich_all_samples
