

# A workflow to extract a dense cloud from colmap- this also uses a micmac function to extract gps from a point cloud. Colmap is easier to use and the orientation is superior to MicMac when processing unordered data (particularly urban structures, whereas MicMac you'd have to sort and merge various orientations.
#

# colmapsfm.sh my/workspace JPG



colmap feature_extractor --database_path $1/database.db  --image_path $1/images;

colmap exhaustive_matcher  --database_path $1/database.db;

mkdir $1/sparse;

colmap mapper --database_path $1/database.db --image_path $1/images --output_path $1/sparse;

mkdir $1/dense;

# The micmac command is here - this assumes your gps is reasonably accurate!!! Phantom users beware
mm3d XifGps2Txt $1/images/.*$2;

mkdir $1/sparse_geo;


colmap model_aligner --input_path $1/sparse/0 --output_path $1/sparse_geo --ref_images_path $1/images/GpsCoordinatesFromExif.txt --robust_alignment 1 --robust_alignment_max_error 0.3


colmap image_undistorter --image_path $1/images --input_path $1/sparse_geo --output_path $1/dense --output_type COLMAP --max_image_size 2000;

colmap patch_match_stereo --workspace_path $1/dense --workspace_format COLMAP --PatchMatchStereo.geom_consistency true;

colmap stereo_fusion --workspace_path $1/dense --workspace_format COLMAP --input_type geometric --output_path $1/dense/fused.ply;

colmap poisson_mesher --input_path $1/dense/fused.ply  --output_path $1/dense/meshed-poisson.ply;

colmap delaunay_mesher  --input_path $1/dense --output_path $1/dense/meshed-delaunay.ply
