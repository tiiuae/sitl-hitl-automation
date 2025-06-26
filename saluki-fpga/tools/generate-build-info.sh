#! /bin/bash
set -eu

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --variant) variant="$2"; shift ;;
        --output_dir) OUTPUT_DIR="$2"; shift ;;
	--bitstream_key) BITSTREAM_KEY="$2"; shift;;
	--bm3_keypair) BM3_KEYPAIR="$2"; shift;;
	--fpgenprog) FPGENPROG="$2"; shift;;
	--libero) LIBERO_EXECUTABLE="$2"; shift;;
	--softconsole_dir) SOFTCONSOLE_DIR="$2"; shift;;
	--version) version="$2"; shift;;
	--bl_elf) BL_ELF="$2"; shift;;
        *) echo "Unknown parameter: $1" ;;
    esac
    shift
done

variant_dir=$(echo $variant|tr _ -)
subdir="${variant//-/_}-fpga"
fpga_path=/firmware/combine/fpga/${variant_dir}/firmware/${subdir}/fpgajobfile/
echo "fpga_path: ${fpga_path}"

find_bootloader=bootloader_v2/ssrc_$variant_dir

echo "using output dir: ${OUTPUT_DIR}"
echo "building for hw: ${variant}"
echo "version: ${version}"

fileinfo_json=saluki_file_info.json
BL=""
BL_BUILD_URL=""
BL_SHA=""

# if build info file exists, use it to get the version
if [[ -f ${fileinfo_json} ]]; then
    echo "using build info file: ${fileinfo_json}"


    # notice using product name from above step instead of the provided variant
    # fetch only the first stage bootloader
    BL=$(jq '.files[] | select(.hw=="'${product}'" and .stage=="fsbl").filename' ${fileinfo_json})
    if [ -z "${BL}" ]; then
        echo "first stage bl not found, using full bootloader"
        BL=$(jq '.files[] | select(.hw=="'${product}'").filename' ${fileinfo_json})
    fi

    # exit if bootloader is not found
    if [ -z "${BL}" ]; then
        echo "ERROR: bootloader not found, please check the provided bootloader container is valid"
        exit 1
    fi

    BL=$(echo ${BL}|sed 's/"//g')

    # bootloader version info from .build_url and .sha
    BL_BUILD_URL=$(jq '.build_url' ${fileinfo_json}|sed 's/"//g')
    BL_SHA=$(jq '.sha' ${fileinfo_json}|sed 's/"//g')
#else
    # if build info file does not exist, try to find the correct bootloader
    BL=$(find bootloaders -type f -exec readlink -f {} \;|grep ${find_bootloader})
fi
echo "using bootloader: ${BL}"


# generate the build info file
fpga_fileinfo_json=${OUTPUT_DIR}/fpga_${variant}_file_info.json
echo "generating build info file: ${fpga_fileinfo_json}"

# find the generated files
fpga_output_files=("$OUTPUT_DIR"/*)
echo "found output files: ${fpga_output_files[@]}"

# categorize the files based on filename
function categorize_file( ) {
  local file=$1
  filetype="unknown"

  if [[ $file == "MPFS_ICICLE_KIT_BASE_DESIGN"* ]]; then
    filetype="fpga"
  elif [[ $file == "enable_user_key"* ]]; then
    filetype="enable_secure_boot"
  elif [[ $file == "envm_update_uek1"* ]]; then
    filetype="update_uek1"
  elif [[ $file == "full_build_uek1"* ]]; then
    filetype="secure_boot_full_build"
  fi

  if [[ $file == *".job" ]]; then
    filetype+="_job"
  elif [[ $file == *".digest" ]]; then
    filetype+="_digest"
  fi

  echo $filetype
}

json_output="["
for file in "${fpga_output_files[@]}"
do
  filename=$(basename ${file})
  echo "processing file: ${filename}"
  json_output+="{\"type\":\"$(categorize_file ${filename})\",\
            \"hw\":\"${variant}\",\
            \"bootloader_sha\":\"${BL_SHA}\",\
            \"bootloader_url\":\"${BL_BUILD_URL}\",\
            \"bootloader_container\":\"${BL_ELF}\",\
            \"fpga_version\":\"${version}\",\
            \"filename\":\"${fpga_path}${filename}\"},"
done
# remove the last comma
json_output="${json_output%,}"

json_output+="]"

echo ${json_output} | jq . > ${fpga_fileinfo_json}
