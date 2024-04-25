#!/bin/sh

help ()
{
  echo "How to use:"
  echo "  -o, --output        The output directory for storing the playlist"
  echo "  -s, --source        The directory with all your music ordered or not"
  echo "  -c, --copy          Copies instead of move the files to the output directory"
  echo "  -l, --link          Makes a simbolic link instead of copy the files to the output directory. This is the default option"
  echo "  -h, --hard          Makes a hard link instead of copy the files to the output directory"
  echo "  -m, --move          Moves instead of copy the files to the output directory"
  echo "  -v, --verbose       Show verbosity"
  echo ""
  echo "The files should be named as follows:"
  echo "  [<whatever> - artist.extension] or [<whatever> - artist, artist, artist.extension]"
  echo "example:"
  echo "  <My Song - Year - More Data - Artist.m4a> <My Song - Me.mp3> <Someone's Song - Someone, Me.mp3>"
  exit 0
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            help
            ;;
        -v|--verbose)
            verbose=true
            ;;
        -m|--move)
            move=true
            ;;
        -h|--hard)
            hard=true
            ;;
        -l|--link)
            link=true
            ;;
        -c|--copy)
            copy=true
            ;;
        -o|--output)
            dst_dir=$(realpath -m "$2")
            shift
            if [[ ! -e "$dst_dir" ]]; then
                echo "$dst_dir is not a valid directory" >&2
                exit 1
            fi
            ;;
        -s|--source)
            src_dir=$(realpath -m "$2")
            shift
            if [[ ! -e "$src_dir" ]]; then
                echo "$src_dir is not a valid directory" >&2
                exit 1
            fi
            ;;
        -n|--name)
            playlist="$2"
            shift
            if [[ ! -e "$dst_dir/$playlist" ]]; then
              mkdir "$dst_dir/$playlist"
            fi
            ;;

        *)  # Unknown arguments
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
    shift
done

if [[ ! -e "$src_dir" || ! -e "$dst_dir" ]]; then
  echo "You must specify your music dir (-s/--source) and the output dir (-o/--output)" >&2
  exit 1
fi
