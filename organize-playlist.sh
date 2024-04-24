#!/bin/sh

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -v|--verbose)
            verbose=true
            ;;
        -m|--move)
            move=true
            ;;
        -c|--copy)
            copy=true
            ;;
        -f|--force)
            force=true
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

for file in "$src_dir"/*; do
  if [ -f "$file" ]; then
    if [[ ! $(file --mime-type "$file" | grep -q "audio") && ! $(file --mime-type "$file" | grep -q "audio") ]]; then
      continue
    fi

    artist=$(echo "$file" | awk -F " - " '{print $NF}' | cut -d "." -f1 | cut -d "," -f1 | awk '{gsub(/^ +| +$/,"")} {print $0}')
    if [ ! -e "$dst_dir/$artist" ]; then
      mkdir -p "$dst_dir/$artist"
    fi

    if [[ -e "$dst_dir/$artist/$(basename $file)" && ! $force ]]; then
      if [[ $verbose ]]; then
        echo "$(basename $file) alredy in $dst_dir/$artist"
      fi
    else
      if [ verbose ]; then
        echo "moving $(basename $file) to $dst_dir/$artist..."
      fi

      if [[ $copy ]]; then
        cp "$file" "$dst_dir/$artist"
        continue
      fi

      mv "$file" "$dst_dir/$artist"
    fi
  fi
done
