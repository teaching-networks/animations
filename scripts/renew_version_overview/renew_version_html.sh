#!/bin/bash

###
# Check input arguments
###

usage() {
	echo "Renew version HTML tool USAGE:"
	echo "--- SYNTAX ---"
	echo "renew_version_html.sh <argument 1> <argument 2> ... <argument n>"
	echo "--- ARGUMENTS ---"
	echo "-t, --template			| HTML template file which contains \${TO_REPLACE} marker this tool is replacing with the directory names (branch names)"
	echo "-d, --directory			| Directory to operate upon (containing the branch folders)"
	echo "-o, --target			| Target HTML file to create or overwrite with the newly generated file (from the template file)"
}

template="template.html"
directory="."
target="version.html"

while [[ "$1" != "" ]]; do
	case $1 in
		-t | --template )	shift
					template=$1
					;;
		-d | --directory )	shift
					directory=$1
					;;
		-o | --target )		shift
					target=$1
					;;
		-h | --help )		usage
					exit
					;;
		* )			usage
					exit 1
	esac
	shift
done
	
echo "Using the following arguments:"
echo "HTML template:	'$template'"
echo "Directory:	'$directory'"
echo "Target file:	'$target'"


###
# Actual logic
###

# Fetch version names
versions=()
for d in $directory/*/; do
	p=$( realpath --relative-to=$( dirname $target ) $d )
	potential_version=$( basename "$p" )

	if [[ $potential_version =~ v[0-9]-[0-9](-[0-9])? ]]; then
		echo "$p -> Recognized as version pattern"
		versions=("${versions[@]}" $p)
	else
		echo "$p"
	fi
done

# Reverse the versions array (from newer to older)
min=0
max=$(( ${#versions[@]} -1 ))

while [[ $min -lt $max ]]; do
	x="${versions[$min]}"
	versions[$min]="${versions[$max]}"
	versions[$max]="$x"

	(( min++, max-- ))
done

output="<!-- START GENERATED HTML WITH VERSION TOOL renew_version_html.sh -->"

firstVersion=${versions[0]}

output="$output
<li class=\"newest\">
	<a href=\"/\">Current release ($( basename $firstVersion | tr - . ))</a>
</li>"

for version in ${versions[@]}; do
	output="$output
<li>
	<a href=\"$version\">Version $( basename $version | tr - . )</a>
</li>"
done

output="$output
<!-- END GENERATED HTML WITH VERSION TOOL renew_version_html.sh -->"

# Write output to file
TO_REPLACE="$output"
export TO_REPLACE
toSave=$( envsubst < "$template" )

echo "$toSave" > "$target"

echo "Done."
