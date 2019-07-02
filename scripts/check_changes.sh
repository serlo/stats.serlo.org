set -e

# latest commit
LATEST_COMMIT=$(git rev-parse HEAD)

# latest commit where folder was changed
FOLDER_COMMIT=$(git log -1 --format=format:%H --full-diff $1)

if [ $FOLDER_COMMIT = $LATEST_COMMIT ];
    then
	    echo "files in folder $(pwd) has changed";
        exit 1;
else
	echo "no files in folder $(pwd) have changed";
     exit 0;
fi
