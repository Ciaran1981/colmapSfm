while getopts ":f:m:" o; do  
  case ${o} in
    h)
      echo "Carry out Sfm using colmap commands"
      echo "Usage: colmapsfm.sh my/workspace -e JPG " 
      echo "	-m {MATCH}       : matching type (exahaustive_matcher, sequential_matcher, spatial_matcher, transitive_matcher)."
      echo "	-f Folder        : work directory which must include a dir with images in called images"
      echo "	-h	             : displays this message and exits."
      echo " "  
      exit 0
#      ;;    
#	e)
#      EXTENSION=${OPTARG}
      ;;
 	f)
      DATASET_PATH=${OPTARG}
      ;;
 	m)
      MATCH=${OPTARG}
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

colmap feature_extractor \
   --database_path $DATASET_PATH/database.db \
   --image_path $DATASET_PATH/images

colmap $MATCH \
   --database_path $DATASET_PATH/database.db

mkdir $DATASET_PATH/sparse

colmap mapper \
    --database_path $DATASET_PATH/database.db \
    --image_path $DATASET_PATH/images \
    --output_path $DATASET_PATH/sparse

mkdir $DATASET_PATH/dense

colmap image_undistorter \
    --image_path $DATASET_PATH/images \
    --input_path $DATASET_PATH/sparse/0 \
    --output_path $DATASET_PATH/dense \
    --output_type COLMAP \
    --max_image_size 2000

colmap patch_match_stereo \
    --workspace_path $DATASET_PATH/dense \
    --workspace_format COLMAP \
    --PatchMatchStereo.geom_consistency true

colmap stereo_fusion \
    --workspace_path $DATASET_PATH/dense \
    --workspace_format COLMAP \
    --input_type geometric \
    --output_path $DATASET_PATH/dense/fused.ply

colmap poisson_mesher \
    --input_path $DATASET_PATH/dense/fused.ply \
    --output_path $DATASET_PATH/dense/meshed-poisson.ply

colmap delaunay_mesher \
    --input_path $DATASET_PATH/dense \
    --output_path $DATASET_PATH/dense/meshed-delaunay.ply
