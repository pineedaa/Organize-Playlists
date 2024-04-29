#!/bin/sh

help ()
{
  echo "How to use:"
  echo "  -o, --output        The output directory for storing the ordered playlist"
  echo "  -s, --source        The directory with all your music"
  echo "  -f, --force         Wheter to rewrite files or not if they alredy are in the output directory"
  echo "  -c, --copy          Copies instead of move the files to the output directory"
  echo "  -l, --link          Makes a simbolic link instead of copy the files to the output directory. This is the default option"
  echo "  -hl, --hard         Makes a hard link instead of copy the files to the output directory"
  echo "  -m, --move          Moves instead of copy the files to the output directory"
  echo "  -v, --verbose       Show verbosity"
  echo ""
  echo "The files should be named as follows:"
  echo "  [<whatever> - artist.extension] or [<whatever> - artist, artist, artist.extension]"
  echo "example:"
  echo "  <My Song - Year - More Data - Artist.m4a> <My Song - Me.mp3> <Someone's Song - Someone, Me.mp3>"
  exit 0
}

count=0
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            help
            ;;
        -v|--verbose)
            verbose=1
            ;;
        -m|--move)
            move=1
            ((count++))
            ;;
        -hl|--hard)
            hard=1
            ((count++))
            ;;
        -l|--link)
            link=1
            ((count++))
            ;;
        -c|--copy)
            copy=1
            ((count++))
            ;;
        -f|--force)
            force=1
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

if [[ $count -gt 1  ]];then
  echo "You must specify only one method of organize your files (-l/--link, -h/--hard, -c/--copy, -m/--move)" >&2
  exit 1
fi

for file in "$src_dir"/*; do
  if [ -f "$file" ]; then
    if [[ $(file --mime-type "$file" | grep -q "audio") && $(file --mime-type "$file" | grep -q "video") ]]; then
      continue
    fi

    artist=$(echo "$file" | awk -F " - " '{print $NF}' | cut -d "." -f1 | cut -d "," -f1 | awk '{gsub(/^ +| +$/,"")} {print $0}')
    name=$(basename "$file")
    if [ ! -e "$dst_dir/$artist" ]; then
      mkdir -p "$dst_dir/$artist"
    fi

    if [[ (-e "$dst_dir/$artist/$name" || -L "$dst_dir/$artist/$name") && $force -ne 1 ]]; then
      if [[ $verbose ]]; then
        echo "$name alredy in $dst_dir/$artist"
      fi
    else
      if [[ $verbose -eq 1 ]]; then
        echo "moving $name to $dst_dir/$artist..."
      fi

      if [[ $copy -eq 1 ]]; then
        cp "$file" "$dst_dir/$artist"
        continue
      fi

      if [[ $hard -eq 1 ]]; then
        ln "$file" "$dst_dir/$artist"
        continue
      fi

      if [[ $move -eq 1 ]]; then
        mv "$file" "$dst_dir/$artist"
        continue
      fi

      ln -s "$file" "$dst_dir/$artist"
    fi
  fi
done
