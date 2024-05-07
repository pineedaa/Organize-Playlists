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

get_title() {
  exiftool -m "$1" | grep -E "^Title\s*:" | cut -d ":" -f2 | awk '{gsub(/^ +| +$/,"")} {print $0}'
}

get_artist() {
  exiftool -m "$1" | grep -E "^Artist\s*:" | cut -d ":" -f2 | cut -d "," -f1 | awk '{gsub(/^ +| +$/,"")} {print $0}'
}

get_all_artists() {
  exiftool -m "$1" | grep -E "^Artist\s*:" | cut -d ":" -f2 | awk '{gsub(/^ +| +$/,"")} {print $0}'
}

get_album() {
  exiftool -m "$1" | grep -E "^Album\s*:" | cut -d ":" -f2 | awk '{gsub(/^ +| +$/,"")} {print $0}'
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

moved=0
stayed=0
for file in "$src_dir"/*; do
  if [ -f "$file" ]; then
    if [[ $(file --mime-type "$file" | grep -q "audio") && $(file --mime-type "$file" | grep -q "video") ]]; then
      continue
    fi

    artist="$(get_artist "$file")"
    artist="${artist//\//_}"
    album="$(get_album "$file")"
    album="${album//\//_}"
    name="$(get_title "$file")"
    name="${name//\//_}"
    all_artists="$(get_all_artists "$file")"
    all_artists="${all_artists//\//_}"
    extension=$(echo "$(basename "$file")" | awk -F. '{print $NF}')
    song="$name - $all_artists - $album.$extension"
    if [ ! -e "$dst_dir/$artist/$album" ]; then
      mkdir -p "$dst_dir/$artist/$album"
    fi

    if [[ (-e "$dst_dir/$artist/$album/$name" || -L "$dst_dir/$artist/$album/$name") && $force -ne 1 ]]; then
      ((stayed++))
    else
      ((moved++))
      if [[ $verbose -eq 1 ]]; then
        echo "moving $name to $dst_dir/$artist/$album..."
      fi

      if [[ $copy -eq 1 ]]; then
        cp "$file" "$dst_dir/$artist/$album/$song"
        continue
      fi

      if [[ $hard -eq 1 ]]; then
        ln "$file" "$dst_dir/$artist/$album/$song"
        continue
      fi

      if [[ $move -eq 1 ]]; then
        mv "$file" "$dst_dir/$artist/$album/$song"
        continue
      fi

      ln -s "$file" "$dst_dir/$artist/$album/$song"
    fi
  fi
done

echo "Moved files: $moved. Files alredy in $dst_dir: $stayed"
