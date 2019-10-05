# 
# AUTHOR: Johnathan Zhuang
# DATE: 2019-Oct-5th
#
# This script will take a series of videos (part 1), add fade in & fade out, and join each video to a single video
# Input:
#   - Series of videos: must be in folder "part1". Video must either be in .mov or .mp4
#   - Single Video to attach: must be in folder "part2/part2.mp4"
# 
# Output:
#   - part 1 processed to folder "part1_processed"
#   - output to folder "output"
#
# Required: ffmpeg
#

FRAMES_PER_SECOND=30
FADE_IN_DURATION=1  # in seconds
DIR_MP4="01.part1_MP4"
DIR_PROCESSED="02.part1_mp4_faded"
DIR_OUTPUT="03.output"
FILE_PART2="part2/part2.mp4"

if [ ! -d "$DIR_PROCESSED" ]; then
  mkdir $DIR_PROCESSED
fi
if [ ! -d "$DIR_OUTPUT" ]; then
  mkdir $DIR_OUTPUT
fi
if [ ! -d "$DIR_MP4" ]; then
  mkdir $DIR_MP4
fi

for file in part1/*; do

  file_name="${file#'part1/'}"

  ####### Part 1 Processing ########
  # Convert mov to mp4
  path_mp4="$DIR_MP4/${file_name/.mov/.mp4}"
  ffmpeg -y -i "$file" -q:v 0 "$path_mp4"

  file_name="${path_mp4#$DIR_MP4/}"

  let fade_in_frames_start=`echo "scale=0;$FADE_IN_DURATION * $FRAMES_PER_SECOND" | bc | awk '{print int($1+0.5)}'` 

  # Add Fade in to Part 1
  path_mp4_faded="$DIR_PROCESSED/$file_name"
  ffmpeg -y -i "$path_mp4" -vf 'fade=in:0:'"$fade_in_frames_start" -af 'afade=in:st=0:d=1' -c:v libx264 -crf 22 -preset fast $path_mp4_faded

  ####### Join Videos ########
  # Join after converting to streams
  ffmpeg -y -i "$path_mp4_faded" -c copy -bsf:v h264_mp4toannexb -f mpegts intermediate1.ts
  ffmpeg -y -i $FILE_PART2 -c copy -bsf:v h264_mp4toannexb -f mpegts intermediate2.ts
  ffmpeg -y -i "concat:intermediate1.ts|intermediate2.ts" -c copy -bsf:a aac_adtstoasc "$DIR_OUTPUT/$file_name"
done