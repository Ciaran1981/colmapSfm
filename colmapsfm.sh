

# A workflow to extract a dense cloud from colmap- this also uses a micmac function to extract gps from a point cloud. Colmap is easier to use and the orientation is superior to MicMac when processing unordered data (particularly urban structures, whereas MicMac you'd have to sort and merge various orientations).
#

# colmapsfm.sh my/workspace JPG

while getopts ":e:f:" o; do  
  case ${o} in
    h)
      echo "Carry out Sfm using colmap commands"
      echo "Usage: colmapsfm.sh my/workspace -e JPG " 
      echo "	-e {EXTENSION}     : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-f Folder        : work directory which must include a dir with images in called images"
      echo "	-h	             : displays this message and exits."
      echo " "  
      exit 0
      ;;    
	e)
      EXTENSION=${OPTARG}
      ;;
 	f)
      FOLDER=${OPTARG}
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

selection=
until [  "$selection" = "1" ]; do
    echo "
    CHECK PARAMETERS
	-e : image extenstion/file type
	-f : the working dir including a dir called images within which the images reside 
        This assumes you have installed both MicMac and Colmap

    echo 
    CHOOSE BETWEEN
    1 - Continue with these parameters
    0 - Exit program
    2 - Help
"
    echo -n "Enter selection: "
    read selection
    echo ""
    case $selection in
        1 ) echo "Let's process now" ; continue ;;
        0 ) exit ;;
    	2 ) echo "
		For help use : dense_cloud.sh -h
	   " >&1
	   exit 1 ;;
        * ) echo "
		Only 0 or 1 are valid choices
		For help use : dense_cloud.sh -h
		" >&1
		exit 1 ;;
    esac
done


mm3d XifGps2Txt $FOLDER/images/.*${EXTENSION} OutTxtFile=$FOLDER/gps.txt;

colmap feature_extractor --database_path $FOLDER/database.db  --image_path $FOLDER/images;

colmap exhaustive_matcher  --database_path $FOLDER/database.db;

mkdir $FOLDER/sparse;

colmap mapper --database_path $FOLDER/database.db --image_path $FOLDER/images --output_path $FOLDER/sparse;

mkdir $FOLDER/dense;

mkdir $FOLDER/sparse_geo;


colmap model_aligner --input_path $FOLDER/sparse/0 --output_path $FOLDER/sparse_geo --ref_images_path $FOLDER/gps.txt --robust_alignment 1 --robust_alignment_max_error 0.3


colmap image_undistorter --image_path $FOLDER/images --input_path $FOLDER/sparse_geo --output_path $FOLDER/dense --output_type COLMAP --max_image_size 2000;

colmap patch_match_stereo --workspace_path $FOLDER/dense --workspace_format COLMAP --PatchMatchStereo.geom_consistency true;

colmap stereo_fusion --workspace_path $FOLDER/dense --workspace_format COLMAP --input_type geometric --output_path $FOLDER/dense/fused.ply;

colmap poisson_mesher --input_path $FOLDER/dense/fused.ply  --output_path $FOLDER/dense/meshed-poisson.ply;

colmap delaunay_mesher  --input_path $FOLDER/dense --output_path $FOLDER/dense/meshed-delaunay.ply
