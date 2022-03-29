while getopts ":f:m:e:" o; do  
  case ${o} in
    h)
      echo "Carry out Sfm using colmap commands"
      echo "Usage: colmapsfmgps.sh -m exhaustive_matcher -f myfolder -e JPG " 
      echo "	-m MATCH       : matching type (exhaustive_matcher, sequential_matcher, spatial_matcher, transitive_matcher)."
      echo "	-f DATASET_PATH        : work directory which must include a dir with images in called images"
      echo "    -e EXTENSION           : the image extension for exiftool to extract GPS"
      echo "	-h	             : displays this message and exits."
      echo " "  
      exit 0
      ;;
 	f)
      DATASET_PATH=${OPTARG}
      ;;
 	m)
      MATCH=${OPTARG}
      ;;
 	e)
      EXTENSION=${OPTARG}
      ;;             
    \?)
      echo "colmapSfm.sh: Invalid option: -${OPTARG}" >&1
      exit 1
      ;;
    :)
      echo "colmapSfm.sh: Option -${OPTARG} requires an argument." >&1
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))



# The project folder must contain a folder "images" with all the images.
#DATASET_PATH=/path/to/dataset

exiftool -filename -gpslatitude -gpslongitude -gpsaltitude $DATASET_PATH/images/*.$EXTENSION -n -T > $DATASET_PATH/gps.txt;

colmap feature_extractor \
   --database_path $DATASET_PATH/database.db \
   --image_path $DATASET_PATH/images;

colmap $MATCH \
   --database_path $DATASET_PATH/database.db;

mkdir $DATASET_PATH/sparse;

colmap mapper \
    --database_path $DATASET_PATH/database.db \
    --image_path $DATASET_PATH/images \
    --output_path $DATASET_PATH/sparse;

mkdir $DATASET_PATH/dense;
mkdir $DATASET_PATH/sparse_geo;

# this can replace --ref_images_path $DATASET_PATH/gps.txt if required
#(or --database_path /path/to/databse.db)

colmap model_aligner \
    --input_path $DATASET_PATH/sparse/0 \
    --output_path $DATASET_PATH/sparse_geo \
    --ref_images_path $DATASET_PATH/gps.txt \
    --ref_is_gps 1 \
    --alignment_type ecef \
    --robust_alignment 1 --robust_alignment_max_error 3.0; 

#(where 3.0 is the error threshold to be used in RANSAC)

colmap image_undistorter \
    --image_path $DATASET_PATH/images \
    --input_path $DATASET_PATH/sparse_geo/0 \
    --output_path $DATASET_PATH/dense \
    --output_type COLMAP \
    --max_image_size 2000;

colmap patch_match_stereo \
    --workspace_path $DATASET_PATH/dense \
    --workspace_format COLMAP \
    --PatchMatchStereo.geom_consistency true;

colmap stereo_fusion \
    --workspace_path $DATASET_PATH/dense \
    --workspace_format COLMAP \
    --input_type geometric \
    --output_path $DATASET_PATH/dense/fused.ply;

























